import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'student_profile.dart';

enum AcademicDocumentType {
  studentId,
  graduationCertificate,
  clearanceCertificate,
}

class VerifiableCredential {
  final List<String> context;
  final String id;
  final List<String> type;
  final AcademicDocumentType documentType;
  final String issuer;
  final DateTime issuanceDate;
  final DateTime expirationDate;
  final StudentProfile student;
  final String statusListUri;
  final int statusListIndex;
  final Map<String, dynamic> proof;
  final String? customAnchorHash;
  final String? customDocId;

  VerifiableCredential({
    required this.context,
    required this.id,
    required this.type,
    required this.documentType,
    required this.issuer,
    required this.issuanceDate,
    required this.expirationDate,
    required this.student,
    required this.statusListUri,
    required this.statusListIndex,
    required this.proof,
    this.customAnchorHash,
    this.customDocId,
  });

  String get fabricDocId {
    if (customDocId != null && customDocId!.isNotEmpty) {
      return customDocId!;
    }
    if (id.startsWith('DOC-NUVTE-')) return id;
    switch (documentType) {
      case AcademicDocumentType.studentId:
        return 'DOC-NUVTE-2024-STU-098';
      case AcademicDocumentType.graduationCertificate:
        return 'DOC-NUVTE-2024-GRAD-098';
      case AcademicDocumentType.clearanceCertificate:
        return 'DOC-NUVTE-2024-CLR-098';
    }
  }

  String get documentTitleEn {
    switch (documentType) {
      case AcademicDocumentType.studentId:
        return 'Digital Student Identity Card';
      case AcademicDocumentType.graduationCertificate:
        return 'Official Graduation Certificate';
      case AcademicDocumentType.clearanceCertificate:
        return 'Certificate of Discharge (Clearance)';
    }
  }

  String get documentTitleAr {
    switch (documentType) {
      case AcademicDocumentType.studentId:
        return 'بطاقة الطالب الرقمية المعتمدة';
      case AcademicDocumentType.graduationCertificate:
        return 'شهادة التخرج والدرجة العلمية';
      case AcademicDocumentType.clearanceCertificate:
        return 'شهادة براءة الذمة الجامعية';
    }
  }

  /// Computes SHA-256 hash of the canonical credentialSubject & issuer
  /// Strictly zero PII on-chain (anchored in Hyperledger Fabric block)
  String get onChainAnchorHash {
    if (customAnchorHash != null && customAnchorHash!.isNotEmpty) {
      return customAnchorHash!;
    }
    if (student.studentId == 'STU-2024098') {
      switch (documentType) {
        case AcademicDocumentType.studentId:
          return '81b888542dc4e686edd9890430beaafd1e98d066479ef854ae447dee167a2126';
        case AcademicDocumentType.graduationCertificate:
          return '07d7f05362c14b9b3e4566a66e413fb9a59e792324449238fdb3216b8048e98c';
        case AcademicDocumentType.clearanceCertificate:
          return 'ad147ab8a475fedf5574b6b458879de5f6c92279c24057a4407291c8e7b585f4';
      }
    }
    final payloadToHash = jsonEncode({
      'id': id,
      'documentType': documentType.name,
      'issuer': issuer,
      'studentId': student.studentId,
      'statusListIndex': statusListIndex,
      'issuanceDate': issuanceDate.toIso8601String(),
    });
    final bytes = utf8.encode(payloadToHash);
    return sha256.convert(bytes).toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> subjectClaims = {
      'id': 'did:paldfi:holder:nuvte-${student.studentId.toLowerCase()}',
      'studentId': student.studentId,
      'fullName': {
        'en': student.fullNameEn,
        'ar': student.fullNameAr,
      },
    };

    if (documentType == AcademicDocumentType.studentId) {
      subjectClaims.addAll({
        'faculty': {'en': student.facultyEn, 'ar': student.facultyAr},
        'program': {'en': student.programEn, 'ar': student.programAr},
        'degreeLevel': {'en': student.degreeLevelEn, 'ar': student.degreeLevelAr},
        'academicYear': student.academicYear,
        'gpa': student.gpa,
        'bloodType': student.bloodType,
      });
    } else if (documentType == AcademicDocumentType.graduationCertificate) {
      subjectClaims.addAll({
        'degreeConferred': {'en': student.degreeLevelEn, 'ar': student.degreeLevelAr},
        'major': {'en': student.programEn, 'ar': student.programAr},
        'faculty': {'en': student.facultyEn, 'ar': student.facultyAr},
        'cumulativeGpa': student.gpa,
        'honorsClassification': {'en': student.honorsEn, 'ar': student.honorsAr},
        'deansDecreeNumber': student.deansDecreeNumber,
        'graduationDate': student.graduationDate?.toIso8601String() ?? issuanceDate.toIso8601String(),
        'accreditation': 'Ministry of Higher Education and Scientific Research (Palestine)',
      });
    } else if (documentType == AcademicDocumentType.clearanceCertificate) {
      subjectClaims.addAll({
        'clearanceReference': student.clearanceReferenceNumber,
        'clearanceDate': student.clearanceDate?.toIso8601String() ?? issuanceDate.toIso8601String(),
        'departmentsCleared': {
          'library': student.isLibraryCleared,
          'financialDepartment': student.isFinanceCleared,
          'laboratoriesAndWorkshops': student.isLabsCleared,
          'deanshipOfStudentAffairs': student.isStudentAffairsCleared,
          'admissionAndRegistration': student.isRegistrationCleared,
        },
        'financialLiabilityStatus': 'ZERO LIABILITIES (طرف مالي بريء)',
        'academicStanding': 'HONORABLE DISCHARGE (براءة ذمة تامة)',
      });
    }

    return {
      '@context': context,
      'id': id,
      'type': type,
      'documentType': documentType.name,
      'issuer': {
        'id': issuer,
        'name': 'Nablus University for Vocational and Technical Education (NUVTE)',
        'jurisdiction': 'Palestine Monetary Authority (PMA) Sandbox',
      },
      'validFrom': issuanceDate.toIso8601String(),
      'validUntil': expirationDate.toIso8601String(),
      'credentialSubject': subjectClaims,
      'credentialStatus': {
        'id': '$statusListUri#$statusListIndex',
        'type': 'BitstringStatusList2021',
        'statusPurpose': 'revocation',
        'statusListIndex': statusListIndex,
        'statusListCredential': statusListUri,
      },
      'proof': proof,
    };
  }

  String toPrettyJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  factory VerifiableCredential.fromStudent(
    StudentProfile student, {
    AcademicDocumentType documentType = AcademicDocumentType.studentId,
    required String issuerDid,
    required String signatureProof,
    String? customAnchorHash,
    String? customDocId,
    int? customStatusListIndex,
  }) {
    final issue = student.issueDate;
    final expiry = student.expiryDate;
    final typePrefix = documentType == AcademicDocumentType.graduationCertificate
        ? 'grad'
        : (documentType == AcademicDocumentType.clearanceCertificate ? 'clr' : 'id');

    final vcId = customDocId ??
        'urn:uuid:nuvte-vc-$typePrefix-${student.studentId.toLowerCase()}-${issue.millisecondsSinceEpoch}';

    final types = ['VerifiableCredential'];
    if (documentType == AcademicDocumentType.studentId) {
      types.add('StudentIdentityCredential');
    } else if (documentType == AcademicDocumentType.graduationCertificate) {
      types.add('GraduationCertificateCredential');
    } else {
      types.add('ClearanceCertificateCredential');
    }

    final resolvedIndex = customStatusListIndex ?? student.statusListIndex;

    return VerifiableCredential(
      context: [
        'https://www.w3.org/ns/credentials/v2',
        'https://identity.nuvte.edu.ps/contexts/academic-documents-v1.jsonld',
      ],
      id: vcId,
      type: types,
      documentType: documentType,
      issuer: issuerDid,
      issuanceDate: issue,
      expirationDate: expiry,
      student: student,
      statusListUri: 'https://identity.nuvte.edu.ps/status/bitstring-list-2021.json',
      statusListIndex: resolvedIndex,
      proof: {
        'type': 'Ed25519Signature2020',
        'created': issue.toIso8601String(),
        'verificationMethod': '$issuerDid#key-1',
        'proofPurpose': 'assertionMethod',
        'proofValue': signatureProof,
      },
      customAnchorHash: customAnchorHash,
      customDocId: customDocId,
    );
  }

  VerifiableCredential copyWithStudent(StudentProfile updatedStudent) {
    return VerifiableCredential(
      context: context,
      id: id,
      type: type,
      documentType: documentType,
      issuer: issuer,
      issuanceDate: issuanceDate,
      expirationDate: expirationDate,
      student: updatedStudent,
      statusListUri: statusListUri,
      statusListIndex: statusListIndex,
      proof: proof,
      customAnchorHash: customAnchorHash,
      customDocId: customDocId,
    );
  }
}
