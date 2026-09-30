import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/student_issuance_request.dart';
import '../models/student_profile.dart';
import '../models/third_party_request.dart';
import '../models/verifiable_credential.dart';
import '../models/verifiable_presentation.dart';
import 'crypto_vault_service.dart';
import 'fabric_ledger_service.dart';
import 'face_recognition_service.dart';
import 'id_plus_auth_service.dart';

class PresentationAuditRecord {
  final String id;
  final String verifierName;
  final DateTime timestamp;
  final List<String> disclosedAttributes;
  final String nonce;

  PresentationAuditRecord({
    required this.id,
    required this.verifierName,
    required this.timestamp,
    required this.disclosedAttributes,
    required this.nonce,
  });
}

class WalletStorageService {
  static final WalletStorageService _instance = WalletStorageService._internal();
  factory WalletStorageService() => _instance;
  WalletStorageService._internal();

  final ValueNotifier<bool> isUnlocked = ValueNotifier<bool>(true);
  
  // Active student identity & credentials
  final ValueNotifier<String> currentStudentId = ValueNotifier<String>('');
  final ValueNotifier<List<VerifiableCredential>> credentials =
      ValueNotifier<List<VerifiableCredential>>([]);
  final ValueNotifier<VerifiableCredential?> activeCredential =
      ValueNotifier<VerifiableCredential?>(null);
  
  // Storage of credentials across all students: Map<studentId, List<VerifiableCredential>>
  final Map<String, List<VerifiableCredential>> _studentVaults = {};

  // Storage of student profiles: Map<studentId, StudentProfile>
  final Map<String, StudentProfile> _studentProfiles = {};

  final ValueNotifier<List<PresentationAuditRecord>> presentationLogs =
      ValueNotifier<List<PresentationAuditRecord>>([]);

  // Third-party incoming requests
  final ValueNotifier<List<ThirdPartyRequest>> thirdPartyRequests =
      ValueNotifier<List<ThirdPartyRequest>>([]);

  // Student document issuance requests to University Registration Faculty
  final ValueNotifier<List<StudentIssuanceRequest>> studentIssuanceRequests =
      ValueNotifier<List<StudentIssuanceRequest>>([]);

  // Reactive revision counter for revocation changes across all candidate views
  final ValueNotifier<int> revocationRevision = ValueNotifier<int>(0);

  final String _userPin = '123456';

  Future<void> initializeWallet() async {
    // Generate asymmetric keypair inside simulated secure keystore
    await CryptoVaultService().initializeKeypair();

    // Load enrolled candidates from Vector DB
    final enrolled = await IdPlusAuthService().loadDynamicStudents();

    // Direct synchronization from Hyperledger Fabric ledger
    await syncWithBlockchainLedger();

    // If there are enrolled students, set active
    if (enrolled.isNotEmpty) {
      final firstId = enrolled.first['studentId'] ?? enrolled.first['candidateId'] ?? '';
      if (firstId.isNotEmpty) {
        await loadStudentWallet(firstId);
      }
    }
  }

  /// Reset all local state to clean start
  Future<void> resetAllStateToClean() async {
    _studentVaults.clear();
    _studentProfiles.clear();
    credentials.value = [];
    activeCredential.value = null;
    currentStudentId.value = '';
    thirdPartyRequests.value = [];
    studentIssuanceRequests.value = [];
    presentationLogs.value = [];
    revocationRevision.value++;

    // Reset Vector DB and Blockchain Gateway
    await FaceRecognitionService().resetVectorDatabase();
    try {
      await http.post(Uri.parse('http://localhost:5050/api/blockchain/reset'))
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    await IdPlusAuthService().loadDynamicStudents();
  }

  /// Onboard a new student into Vector DB + Hyperledger Fabric Ledger + Sovereign Wallet
  Future<Map<String, dynamic>> onboardNewStudent({
    required String fullNameEn,
    required String fullNameAr,
    required String nationalId,
    required String studentId,
    required String facultyEn,
    required String facultyAr,
    required String programEn,
    required String programAr,
    required double gpa,
    required String bloodType,
    String base64Face = '',
  }) async {
    // 1. Enroll into Biometric 128-D Vector Database
    final faceRes = await FaceRecognitionService().enrollFaceVector(
      candidateId: studentId,
      nationalId: nationalId,
      fullNameEn: fullNameEn,
      fullNameAr: fullNameAr,
      role: 'student',
      roleTitleEn: 'Enrolled NUVTE Student • $programEn',
      roleTitleAr: 'طالب مسجل - جامعة نابلس • $programAr',
      base64Frame: base64Face,
      metadata: {
        'facultyEn': facultyEn,
        'facultyAr': facultyAr,
        'programEn': programEn,
        'programAr': programAr,
        'gpa': gpa.toString(),
        'bloodType': bloodType,
      },
    );

    final derivedDid = faceRes['derivedDid'] ?? 'did:paldfi:face:${studentId.toLowerCase()}';
    final didKey = faceRes['didKey'] ?? 'did:key:z6MkuFaceID${studentId.replaceAll('-', '')}';

    // 2. Create Student Profile
    final now = DateTime.now();
    final profile = StudentProfile(
      studentId: studentId,
      nationalId: nationalId,
      fullNameEn: fullNameEn,
      fullNameAr: fullNameAr,
      facultyEn: facultyEn,
      facultyAr: facultyAr,
      programEn: programEn,
      programAr: programAr,
      degreeLevelEn: 'Bachelor of Science (B.Sc.)',
      degreeLevelAr: 'درجة البكالوريوس في العلوم',
      academicYear: '${now.year} - ${now.year + 4}',
      gpa: gpa,
      bloodType: bloodType,
      photoSeed: studentId.toLowerCase(),
      status: CredentialStatus.active,
      statusListIndex: 100 + _studentProfiles.length + 1,
      issueDate: now,
      expiryDate: DateTime(now.year + 4, 6, 30),
      isLibraryCleared: true,
      isFinanceCleared: true,
      isLabsCleared: true,
      isStudentAffairsCleared: true,
      isRegistrationCleared: true,
      clearanceReferenceNumber: 'CLR-NUVTE-${now.year}-${studentId.replaceAll(RegExp(r'[^0-9]'), '')}',
    );

    _studentProfiles[studentId] = profile;

    // 3. Anchor Identity Credential on Hyperledger Fabric Smart Contract
    final docId = 'DOC-NUVTE-${now.year}-STU-${studentId.replaceAll(RegExp(r'[^0-9]'), '')}';
    final issuerDid = 'did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA';
    
    final vc = VerifiableCredential.fromStudent(
      profile,
      documentType: AcademicDocumentType.studentId,
      issuerDid: issuerDid,
      signatureProof: 'z4Ed25519SigNUVTE_${studentId}_${now.millisecondsSinceEpoch}',
      customDocId: docId,
      customStatusListIndex: profile.statusListIndex,
    );

    // Call Gateway on-chain anchor
    String txId = 'tx-onboard-${now.millisecondsSinceEpoch}';
    try {
      final res = await http.post(
        Uri.parse('http://localhost:5050/api/students/onboard'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentId': studentId,
          'nationalId': nationalId,
          'fullNameEn': fullNameEn,
          'fullNameAr': fullNameAr,
          'facultyEn': facultyEn,
          'facultyAr': facultyAr,
          'programEn': programEn,
          'programAr': programAr,
          'gpa': gpa.toString(),
          'bloodType': bloodType,
          'did': derivedDid,
          'docHash': vc.onChainAnchorHash,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        txId = data['txId'] ?? txId;
      }
    } catch (_) {}

    // 4. Save to student vault
    _studentVaults[studentId] = [vc];

    // 5. Register student in Auth Service
    IdPlusAuthService().registerDynamicStudent({
      'studentId': studentId,
      'candidateId': studentId,
      'nationalId': nationalId,
      'fullNameEn': fullNameEn,
      'fullNameAr': fullNameAr,
      'facultyEn': facultyEn,
      'facultyAr': facultyAr,
      'programEn': programEn,
      'programAr': programAr,
      'derivedDid': derivedDid,
      'didKey': didKey,
      'photoSeed': studentId.toLowerCase(),
      'role': 'student',
      'metadata': {
        'gpa': gpa.toString(),
        'bloodType': bloodType,
      }
    });

    // 6. Set as active wallet
    await loadStudentWallet(studentId);

    return {
      'success': true,
      'studentId': studentId,
      'derivedDid': derivedDid,
      'txId': txId,
      'docId': docId,
      'credential': vc,
    };
  }

  /// Switch the active student wallet view to studentId
  Future<void> loadStudentWallet(String studentId) async {
    currentStudentId.value = studentId;
    final docs = await syncStudentVault(studentId);
    credentials.value = docs;
    activeCredential.value = docs.isNotEmpty ? docs.first : null;
  }

  /// Get student documents from their vault
  List<VerifiableCredential> getStudentDocuments(String studentId) {
    return _studentVaults[studentId] ?? [];
  }

  /// Get student profile
  StudentProfile getStudentProfile(String studentId) {
    if (_studentProfiles.containsKey(studentId)) {
      return _studentProfiles[studentId]!;
    }
    // Fallback default profile
    final now = DateTime.now();
    return StudentProfile(
      studentId: studentId,
      nationalId: '983421560',
      fullNameEn: 'Enrolled Sovereign Student',
      fullNameAr: 'طالب سيادي مسجل',
      facultyEn: 'Faculty of Engineering & Technology',
      facultyAr: 'كلية الهندسة والتكنولوجيا',
      programEn: 'B.Sc. in Computer Systems & Cybersecurity',
      programAr: 'بكالوريوس هندسة أنظمة الحاسوب والأمن السيبراني',
      degreeLevelEn: 'Bachelor of Science (B.Sc.)',
      degreeLevelAr: 'درجة البكالوريوس في العلوم',
      academicYear: '${now.year} - ${now.year + 4}',
      gpa: 3.85,
      bloodType: 'O+',
      photoSeed: studentId.toLowerCase(),
      status: CredentialStatus.active,
      statusListIndex: 101,
      issueDate: now,
      expiryDate: DateTime(now.year + 4, 6, 30),
    );
  }

  /// Sync all student documents directly from Hyperledger Fabric ledger
  Future<void> syncWithBlockchainLedger() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:5050/api/documents'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List docsJson = data['documents'] ?? [];

        for (final item in docsJson) {
          final docId = item['docId'] as String? ?? '';
          final statusStr = item['status'] as String? ?? 'ACTIVE';
          final statusListIndex = item['statusListIndex'] as int? ?? 100;
          final docTypeStr = item['docType'] as String? ?? '';
          final metaStr = item['metadataJson'] as String? ?? '{}';
          Map<String, dynamic> meta = {};
          try {
            meta = jsonDecode(metaStr);
          } catch (_) {}

          String? stuId = meta['studentId'];
          if (stuId == null && docId.contains('STU-')) {
            final match = RegExp(r'STU-?([0-9]+)').firstMatch(docId);
            if (match != null) {
              stuId = 'STU-${match.group(1)}';
            }
          }

          if (stuId != null) {
            final isRevoked = (statusStr == 'REVOKED');
            final currentStatus = isRevoked ? CredentialStatus.revoked : CredentialStatus.active;
            
            // Build profile if not exists
            if (!_studentProfiles.containsKey(stuId)) {
              final now = DateTime.now();
              _studentProfiles[stuId] = StudentProfile(
                studentId: stuId,
                nationalId: meta['nationalId'] ?? '983421560',
                fullNameEn: meta['fullNameEn'] ?? 'Enrolled Student',
                fullNameAr: meta['fullNameAr'] ?? 'طالب مسجل',
                facultyEn: meta['facultyEn'] ?? 'Faculty of Engineering & Technology',
                facultyAr: meta['facultyAr'] ?? 'كلية الهندسة والتكنولوجيا',
                programEn: meta['programEn'] ?? 'B.Sc. in Computer Systems & Cybersecurity',
                programAr: meta['programAr'] ?? 'بكالوريوس هندسة أنظمة الحاسوب والأمن السيبراني',
                degreeLevelEn: 'Bachelor of Science (B.Sc.)',
                degreeLevelAr: 'درجة البكالوريوس في العلوم',
                academicYear: '${now.year} - ${now.year + 4}',
                gpa: double.tryParse(meta['gpa']?.toString() ?? '3.85') ?? 3.85,
                bloodType: meta['bloodType'] ?? 'O+',
                photoSeed: stuId.toLowerCase(),
                status: currentStatus,
                statusListIndex: statusListIndex,
                issueDate: now,
                expiryDate: DateTime(now.year + 4, 6, 30),
              );
            }

            final studentBase = _studentProfiles[stuId]!;
            final updatedStudent = studentBase.copyWith(
              status: currentStatus,
              statusListIndex: statusListIndex,
            );

            AcademicDocumentType docType = AcademicDocumentType.studentId;
            if (docTypeStr.contains('Graduation') || docId.contains('-GRAD-')) {
              docType = AcademicDocumentType.graduationCertificate;
            } else if (docTypeStr.contains('Clearance') || docId.contains('-CLR-')) {
              docType = AcademicDocumentType.clearanceCertificate;
            }

            final vc = VerifiableCredential.fromStudent(
              updatedStudent,
              documentType: docType,
              issuerDid: 'did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA',
              signatureProof: 'z4Ed25519SigNUVTE_${stuId}_ledger',
              customDocId: docId,
              customStatusListIndex: statusListIndex,
            );

            final list = _studentVaults[stuId] ?? [];
            final existingIdx = list.indexWhere((d) => d.id == docId || d.fabricDocId == docId);
            if (existingIdx != -1) {
              list[existingIdx] = vc;
            } else {
              list.add(vc);
            }
            _studentVaults[stuId] = list;
          }
        }

        final currentId = currentStudentId.value;
        if (_studentVaults.containsKey(currentId)) {
          credentials.value = _studentVaults[currentId]!;
          if (activeCredential.value != null) {
            final actId = activeCredential.value!.id;
            activeCredential.value = _studentVaults[currentId]!.firstWhere(
              (c) => c.id == actId,
              orElse: () => _studentVaults[currentId]!.first,
            );
          }
        }
        revocationRevision.value++;
      }
    } catch (_) {}
  }

  /// Synchronize a specific student's vault against live on-chain status
  Future<List<VerifiableCredential>> syncStudentVault(String studentId) async {
    final docs = List<VerifiableCredential>.from(getStudentDocuments(studentId));
    if (docs.isEmpty) return docs;
    for (int i = 0; i < docs.length; i++) {
      final cred = docs[i];
      final isRevoked = await FabricLedgerService().checkRevocationStatusOnChain(
        cred.statusListIndex,
        docId: cred.fabricDocId,
      );
      final currentStatus = isRevoked ? CredentialStatus.revoked : CredentialStatus.active;
      if (cred.student.status != currentStatus) {
        final updatedStudent = cred.student.copyWith(status: currentStatus);
        docs[i] = cred.copyWithStudent(updatedStudent);
      }
    }

    _studentVaults[studentId] = docs;
    if (currentStudentId.value == studentId) {
      credentials.value = docs;
      if (activeCredential.value != null) {
        final currentActiveId = activeCredential.value!.id;
        final updatedActive = docs.firstWhere(
          (c) => c.id == currentActiveId,
          orElse: () => docs.first,
        );
        activeCredential.value = updatedActive;
      }
    }
    revocationRevision.value++;
    return docs;
  }

  /// Checks whether a student currently has a revoked status on ledger
  bool isStudentRevoked(String studentId) {
    final docs = getStudentDocuments(studentId);
    if (docs.isEmpty) return false;
    for (final doc in docs) {
      if (FabricLedgerService().isBitRevoked(doc.statusListIndex)) {
        return true;
      }
      if (doc.student.status == CredentialStatus.revoked) {
        return true;
      }
    }
    return false;
  }

  void notifyRevocationChanged() {
    revocationRevision.value++;
  }

  bool unlockWithPin(String pin) {
    if (pin == _userPin) {
      isUnlocked.value = true;
      return true;
    }
    return false;
  }

  bool unlockWithBiometrics() {
    isUnlocked.value = true;
    return true;
  }

  void lockWallet() {
    isUnlocked.value = false;
  }

  void addCredential(VerifiableCredential credential) {
    final stuId = credential.student.studentId;
    final vault = _studentVaults[stuId] ?? [];
    vault.insert(0, credential);
    _studentVaults[stuId] = vault;

    if (currentStudentId.value == stuId) {
      credentials.value = List.from(vault);
      activeCredential.value = credential;
    }
  }

  void ingestCredential(VerifiableCredential credential) {
    addCredential(credential);
  }

  Future<void> syncAllCredentialsWithLedger() async {
    final list = List<VerifiableCredential>.from(credentials.value);
    if (list.isEmpty) return;
    bool changed = false;

    for (int i = 0; i < list.length; i++) {
      final cred = list[i];
      final isRevoked = await FabricLedgerService().checkRevocationStatusOnChain(
        cred.statusListIndex,
        docId: cred.fabricDocId,
      );
      final currentStatus = isRevoked ? CredentialStatus.revoked : CredentialStatus.active;
      if (cred.student.status != currentStatus) {
        final updatedStudent = cred.student.copyWith(status: currentStatus);
        list[i] = cred.copyWithStudent(updatedStudent);
        changed = true;
      }
    }

    if (changed) {
      credentials.value = list;
      _studentVaults[currentStudentId.value] = list;
      if (activeCredential.value != null) {
        final currentActiveId = activeCredential.value!.id;
        final updatedActive = list.firstWhere(
          (c) => c.id == currentActiveId,
          orElse: () => list.first,
        );
        activeCredential.value = updatedActive;
      }
    }
  }

  Future<void> refreshActiveCredentialStatus() async {
    await syncAllCredentialsWithLedger();
  }

  // --- Student Document Issuance Requests (Student -> University) ---

  void submitStudentIssuanceRequest({
    required String studentId,
    required AcademicDocumentType documentType,
    required String notes,
  }) {
    final student = getStudentProfile(studentId);
    final newReq = StudentIssuanceRequest(
      requestId: 'REQ-ISSUE-${DateTime.now().millisecondsSinceEpoch % 100000}',
      studentId: student.studentId,
      studentNameEn: student.fullNameEn,
      studentNameAr: student.fullNameAr,
      nationalId: student.nationalId,
      documentType: documentType,
      requestDate: DateTime.now(),
      notes: notes,
      status: IssuanceRequestStatus.pending,
    );

    final list = List<StudentIssuanceRequest>.from(studentIssuanceRequests.value);
    list.insert(0, newReq);
    studentIssuanceRequests.value = list;
  }

  Future<Map<String, dynamic>> approveAndIssueStudentDocument({
    required String requestId,
    required String employeeId,
  }) async {
    final list = List<StudentIssuanceRequest>.from(studentIssuanceRequests.value);
    final index = list.indexWhere((r) => r.requestId == requestId);
    if (index == -1) return {'success': false, 'error': 'Request not found'};

    final req = list[index];
    final student = getStudentProfile(req.studentId);

    final docTypePrefix = req.documentType == AcademicDocumentType.clearanceCertificate
        ? 'CLR'
        : (req.documentType == AcademicDocumentType.graduationCertificate ? 'GRAD' : 'STU');
    final docId = 'DOC-NUVTE-2024-$docTypePrefix-${student.studentId.replaceAll(RegExp(r'[^0-9]'), "")}';
    final statusListIndex = 110 + (list.length);

    final vc = VerifiableCredential.fromStudent(
      student.copyWith(statusListIndex: statusListIndex),
      documentType: req.documentType,
      issuerDid: 'did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA',
      signatureProof: 'z4Ed25519SigNUVTE_${student.studentId}_${DateTime.now().millisecondsSinceEpoch}',
      customDocId: docId,
      customStatusListIndex: statusListIndex,
    );

    final anchorRes = await FabricLedgerService().anchorDocumentOnChain(
      docId: docId,
      docType: req.documentType.toString().split('.').last,
      docHash: vc.onChainAnchorHash,
      subjectHash: 'hash-${student.nationalId}',
      statusListIndex: statusListIndex,
      metadata: {
        'studentId': student.studentId,
        'issuedBy': employeeId,
        'issuedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );

    req.status = IssuanceRequestStatus.issued;
    req.issuedDocId = docId;
    req.txId = anchorRes['txId'] ?? 'tx-issued-${DateTime.now().millisecondsSinceEpoch}';
    req.processedDate = DateTime.now();
    list[index] = req;
    studentIssuanceRequests.value = list;

    addCredential(vc);

    return {
      'success': true,
      'txId': req.txId,
      'docId': docId,
      'isLive': anchorRes['isLive'] ?? false,
    };
  }

  void rejectStudentIssuanceRequest({
    required String requestId,
    required String reason,
  }) {
    final list = List<StudentIssuanceRequest>.from(studentIssuanceRequests.value);
    final index = list.indexWhere((r) => r.requestId == requestId);
    if (index != -1) {
      final req = list[index];
      req.status = IssuanceRequestStatus.rejected;
      req.rejectionReason = reason;
      req.processedDate = DateTime.now();
      list[index] = req;
      studentIssuanceRequests.value = list;
    }
  }

  // --- Third-Party Request & Verification Flow ---

  void submitThirdPartyRequest(ThirdPartyRequest request) {
    final list = List<ThirdPartyRequest>.from(thirdPartyRequests.value);
    list.insert(0, request);
    thirdPartyRequests.value = list;
  }

  List<ThirdPartyRequest> getRequestsForStudent(String studentId) {
    return thirdPartyRequests.value
        .where((r) => r.targetStudentId == studentId)
        .toList();
  }

  VerifiablePresentation authorizeThirdPartyRequest(String requestId) {
    final list = List<ThirdPartyRequest>.from(thirdPartyRequests.value);
    final index = list.indexWhere((r) => r.requestId == requestId);
    if (index == -1) {
      throw StateError('Request not found');
    }

    final req = list[index];
    final targetDocs = getStudentDocuments(req.targetStudentId);
    final cred = targetDocs.firstWhere(
      (c) => c.documentType == req.documentTypeRequested,
      orElse: () => targetDocs.isNotEmpty ? targetDocs.first : credentials.value.first,
    );

    final holderDid = CryptoVaultService().didKey;
    final timestamp = DateTime.now();
    final payloadToSign = 'PALDFI-VP-${req.nonce}-${cred.id}-$timestamp';
    final proofSignature = CryptoVaultService().signPayload(payloadToSign);

    final presentation = VerifiablePresentation(
      id: 'urn:uuid:nuvte-vp-thirdparty-${timestamp.millisecondsSinceEpoch}',
      type: ['VerifiablePresentation'],
      credential: cred,
      holderDid: holderDid,
      nonce: req.nonce,
      audience: req.verifierDid,
      timestamp: timestamp,
      validitySeconds: 300,
      disclosedAttributes: {'fullName', 'studentId', 'faculty', 'program', 'status'},
      proof: {
        'type': 'Ed25519Signature2020',
        'created': timestamp.toIso8601String(),
        'verificationMethod': '$holderDid#key-1',
        'proofPurpose': 'authentication',
        'proofValue': proofSignature,
      },
    );

    req.status = ThirdPartyRequestStatus.authorized;
    req.presentation = presentation;
    list[index] = req;
    thirdPartyRequests.value = list;

    recordPresentation(
      verifierName: req.verifierNameEn,
      disclosedAttributes: presentation.disclosedAttributes.toList(),
      nonce: req.nonce,
    );

    return presentation;
  }

  void rejectThirdPartyRequest(String requestId) {
    final list = List<ThirdPartyRequest>.from(thirdPartyRequests.value);
    final index = list.indexWhere((r) => r.requestId == requestId);
    if (index != -1) {
      list[index].status = ThirdPartyRequestStatus.rejected;
      thirdPartyRequests.value = list;
    }
  }

  void markThirdPartyRequestVerified(String requestId) {
    final list = List<ThirdPartyRequest>.from(thirdPartyRequests.value);
    final index = list.indexWhere((r) => r.requestId == requestId);
    if (index != -1) {
      list[index].status = ThirdPartyRequestStatus.verified;
      thirdPartyRequests.value = list;
    }
  }

  void recordPresentation({
    required String verifierName,
    required List<String> disclosedAttributes,
    required String nonce,
  }) {
    final record = PresentationAuditRecord(
      id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
      verifierName: verifierName,
      timestamp: DateTime.now(),
      disclosedAttributes: disclosedAttributes,
      nonce: nonce,
    );
    final logs = List<PresentationAuditRecord>.from(presentationLogs.value);
    logs.insert(0, record);
    presentationLogs.value = logs;
  }
}
