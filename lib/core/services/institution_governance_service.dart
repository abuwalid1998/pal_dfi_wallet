import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/institution.dart';
import '../models/smart_contract_definition.dart';
import '../models/verifiable_credential.dart';
import 'fabric_ledger_service.dart';
import 'wallet_storage_service.dart';

class InstitutionGovernanceService {
  static final InstitutionGovernanceService _instance =
      InstitutionGovernanceService._internal();
  factory InstitutionGovernanceService() => _instance;
  InstitutionGovernanceService._internal() {
    _seedInitialData();
    syncWithBlockchain();
  }

  final ValueNotifier<List<Institution>> institutions =
      ValueNotifier<List<Institution>>([]);

  final ValueNotifier<List<SmartContractDefinition>> smartContracts =
      ValueNotifier<List<SmartContractDefinition>>([]);

  final String _gatewayUrl = 'http://localhost:5050';

  void _seedInitialData() {
    institutions.value = [
      // 1. Orderer & Founder: NUVTE (Active)
      Institution(
        id: 'INST-NUVTE-001',
        nameEn: 'Nablus University for Vocational & Technical Education',
        nameAr: 'جامعة نابلس للتعليم المهني والتقني',
        orgMspId: 'NUVTEMSP',
        type: InstitutionType.university,
        domain: 'nuvte.edu.ps',
        adminNameEn: 'Prof. Dr. Raed Al-Qutob',
        adminNameAr: 'أ.د. رائد القطب',
        adminEmail: 'registrar@nuvte.edu.ps',
        adminDid: 'did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA',
        peerEndpoint: 'peer0.nuvte.edu.ps:7051',
        caEndpoint: 'ca.nuvte.edu.ps:7054',
        reasonEn: 'Primary Academic Orderer & Channel Creator Node',
        reasonAr: 'العقدة المؤسسة والأوردرير الرئيسي لقناة التعليم العالي',
        requestDate: DateTime(2024, 1, 15),
        status: InstitutionStatus.active,
        approvalDate: DateTime(2024, 1, 15),
        txId: 'tx-genesis-nuvte-orderer-001',
        blockNumber: '1',
      ),

      // 2. Birzeit University (Pending Onboarding Request)
      Institution(
        id: 'INST-BZU-002',
        nameEn: 'Birzeit University (Faculty of Graduate Studies)',
        nameAr: 'جامعة بيرزيت (عمادة الدراسات العليا والقبول والتسجيل)',
        orgMspId: 'BZUMSP',
        type: InstitutionType.university,
        domain: 'birzeit.edu',
        adminNameEn: 'Dr. Talal Shahwan',
        adminNameAr: 'د. طلال شهوان',
        adminEmail: 'reg-admin@birzeit.edu',
        adminDid: 'did:key:z6MkuBirzeitUniversityGraduateAuthority2024',
        peerEndpoint: 'peer0.bzu.edu.ps:8051',
        caEndpoint: 'ca.bzu.edu.ps:8054',
        reasonEn: 'Join nuvte-academic-channel to issue W3C Master and Bachelor verifiable credentials.',
        reasonAr: 'الانضمام للقناة الأكاديمية لإصدار الشهادات والوثائق الجامعية لطلبة الدراسات العليا.',
        requestDate: DateTime.now().subtract(const Duration(hours: 6)),
        status: InstitutionStatus.pending,
      ),

      // 3. Al-Quds University (Pending Onboarding Request)
      Institution(
        id: 'INST-AQU-003',
        nameEn: 'Al-Quds University (Faculty of Medicine & Health Sciences)',
        nameAr: 'جامعة القدس (كلية الطب والعلوم الصحية)',
        orgMspId: 'AQUMSP',
        type: InstitutionType.university,
        domain: 'alquds.edu',
        adminNameEn: 'Prof. Imad Abu Kishek',
        adminNameAr: 'أ.د. عماد أبو كشك',
        adminEmail: 'admissions@alquds.edu',
        adminDid: 'did:key:z6MkuAlQudsUniversityMedicalAuthority2024',
        peerEndpoint: 'peer0.alquds.edu.ps:9051',
        caEndpoint: 'ca.alquds.edu.ps:9054',
        reasonEn: 'Issue digital medical doctorate degrees and professional health certificates.',
        reasonAr: 'إصدار شهادات الطب البشري والمهن الطبية المعتمدة رقمياً على البلوكشين.',
        requestDate: DateTime.now().subtract(const Duration(days: 1)),
        status: InstitutionStatus.pending,
      ),

      // 4. Ministry of Higher Education & Scientific Research (Pending Onboarding Request)
      Institution(
        id: 'INST-MOHE-004',
        nameEn: 'Ministry of Higher Education & Scientific Research',
        nameAr: 'وزارة التعليم العالي والبحث العلمي الفلسطينية',
        orgMspId: 'MOHEMSP',
        type: InstitutionType.ministry,
        domain: 'mohe.pna.ps',
        adminNameEn: 'Dr. Ihab Al-Qubaj',
        adminNameAr: 'د. إيهاب القبج',
        adminEmail: 'accreditation@mohe.pna.ps',
        adminDid: 'did:key:z6MkuStateOfPalestineMOHEAuthority2024',
        peerEndpoint: 'peer0.mohe.pna.ps:10051',
        caEndpoint: 'ca.mohe.pna.ps:10054',
        reasonEn: 'Sovereign accreditation of university degrees and cross-institutional certificate equivalencies.',
        reasonAr: 'التصديق السيادي ومعادلة الشهادات الأكاديمية والاعتماد العام لكافة الجامعات.',
        requestDate: DateTime.now().subtract(const Duration(days: 2)),
        status: InstitutionStatus.pending,
      ),
    ];

    // Seed initial Core Academic Smart Contract
    smartContracts.value = [
      SmartContractDefinition(
        contractId: 'paldfi_academic_contract',
        institutionId: 'INST-NUVTE-001',
        institutionNameEn: 'NUVTE',
        institutionNameAr: 'جامعة نابلس',
        nameEn: 'NUVTE Core Academic Credential Contract',
        nameAr: 'عقد الوثائق والشهادات الأكاديمية الأساسي - جامعة نابلس',
        descriptionEn: 'Anchors Student IDs, Graduation Certificates, and Discharge Clearances on Hyperledger Fabric 2.5 with W3C Bitstring status lists.',
        descriptionAr: 'توثيق بطاقات الطلبة، شهادات التخرج، وبراءة الذمة مع مصفوفة الإلغاء W3C على البلوكشين.',
        version: '1.0.0',
        channel: 'nuvte-academic-channel',
        endorsementPolicy: "OR('NUVTEMSP.peer')",
        schemaAttributes: ['studentId', 'nationalId', 'degreeTitle', 'faculty', 'gpa', 'issueDate', 'statusListIndex'],
        startingBitIndex: 100,
        status: ContractDeploymentStatus.deployed,
        deployedAt: DateTime(2024, 1, 15),
        deployedBy: 'NUVTE Academic Authority',
        deployTxId: '98a1738c89b21f98d021c4e99f018e',
        deployBlockNumber: 104820,
      ),
    ];
  }

  /// Synchronize institution and contract registration directly with the Hyperledger Fabric ledger
  Future<void> syncWithBlockchain() async {
    try {
      final res = await http.get(Uri.parse('$_gatewayUrl/api/institutions'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List onChainInsts = data['institutions'] ?? [];
        final list = List<Institution>.from(institutions.value);

        for (final item in onChainInsts) {
          final docId = item['docId'] as String? ?? '';
          final statusStr = item['status'] as String? ?? 'ACTIVE';
          final txId = item['txId'] as String? ?? '';
          final issuanceDateStr = item['issuanceDate'] as String? ?? '';

          String rawId = docId.replaceFirst('INST-ONBOARD-', '');
          final idx = list.indexWhere((i) => i.id == rawId || i.id == docId);

          Map<String, dynamic> meta = {};
          if (item['metadata'] != null) {
            if (item['metadata'] is Map) {
              meta = Map<String, dynamic>.from(item['metadata']);
            } else if (item['metadata'] is String) {
              try {
                meta = jsonDecode(item['metadata']);
              } catch (_) {}
            }
          }

          if (idx != -1) {
            if (statusStr == 'ACTIVE') {
              list[idx].status = InstitutionStatus.active;
              list[idx].txId = txId.isNotEmpty ? txId : list[idx].txId;
              list[idx].approvalDate = DateTime.tryParse(issuanceDateStr) ?? list[idx].approvalDate ?? DateTime.now();
            }
          } else {
            // Newly discovered on-chain institution!
            final nameEn = meta['nameEn'] ?? rawId;
            final nameAr = meta['nameAr'] ?? nameEn;
            final orgMspId = meta['orgMspId'] ?? 'OrgMSP';
            final domain = meta['domain'] ?? '$rawId.edu.ps';
            final adminNameEn = meta['adminNameEn'] ?? 'Institution Administrator';
            final adminNameAr = meta['adminNameAr'] ?? 'مسؤول المؤسسة';
            final adminEmail = meta['adminEmail'] ?? 'admin@$domain';
            final adminDid = meta['adminDid'] ?? 'did:key:z6Mku$rawId';
            final peerEndpoint = meta['peerEndpoint'] ?? 'peer0.$domain:7051';
            final caEndpoint = meta['caEndpoint'] ?? 'ca.$domain:7054';
            final reasonEn = meta['reasonEn'] ?? 'Enrolled consortium member.';
            final reasonAr = meta['reasonAr'] ?? 'عضو معتمد في شبكة التعليم العالي.';
            final typeStr = meta['type'] ?? 'university';
            InstitutionType iType = InstitutionType.university;
            if (typeStr == 'ministry') iType = InstitutionType.ministry;
            if (typeStr == 'bank') iType = InstitutionType.bank;
            if (typeStr == 'governmentAgency') iType = InstitutionType.governmentAgency;

            final newInst = Institution(
              id: rawId,
              nameEn: nameEn,
              nameAr: nameAr,
              orgMspId: orgMspId,
              type: iType,
              domain: domain,
              adminNameEn: adminNameEn,
              adminNameAr: adminNameAr,
              adminEmail: adminEmail,
              adminDid: adminDid,
              peerEndpoint: peerEndpoint,
              caEndpoint: caEndpoint,
              reasonEn: reasonEn,
              reasonAr: reasonAr,
              requestDate: DateTime.tryParse(issuanceDateStr) ?? DateTime.now(),
              status: InstitutionStatus.active,
              approvalDate: DateTime.tryParse(issuanceDateStr) ?? DateTime.now(),
              txId: txId,
            );
            list.add(newInst);
          }
        }

        institutions.value = list;
      }

      final contractsRes = await http.get(Uri.parse('$_gatewayUrl/api/contracts'))
          .timeout(const Duration(seconds: 4));
      if (contractsRes.statusCode == 200) {
        final cData = jsonDecode(contractsRes.body);
        final List onChainContracts = cData['contracts'] ?? [];
        final cList = List<SmartContractDefinition>.from(smartContracts.value);
        for (final item in onChainContracts) {
          final docId = item['docId'] as String? ?? '';
          final txId = item['txId'] as String? ?? '';
          final cId = docId.replaceFirst('SMARTCONTRACT-', '');
          final existingIdx = cList.indexWhere((c) => c.contractId == cId);
          if (existingIdx != -1) {
            cList[existingIdx].deployTxId = txId.isNotEmpty ? txId : cList[existingIdx].deployTxId;
          }
        }
        smartContracts.value = cList;
      }
    } catch (_) {
      // Local fallback
    }
  }

  /// Submit a new institution onboarding request
  void submitOnboardingRequest(Institution newInst) {
    final list = List<Institution>.from(institutions.value);
    list.add(newInst);
    institutions.value = list;
  }

  /// Orderer (NUVTE / PMA) approves and automatically onboards the institution to Hyperledger Fabric
  Future<Map<String, dynamic>> approveAndDeployInstitutionOnChain(String institutionId) async {
    final list = List<Institution>.from(institutions.value);
    final idx = list.indexWhere((i) => i.id == institutionId);
    if (idx == -1) return {'success': false, 'error': 'Institution not found'};

    final inst = list[idx];
    String txId = 'tx-onboard-${DateTime.now().millisecondsSinceEpoch}';
    String blockNumber = '1048${80 + list.length}';
    bool isLive = false;

    try {
      final res = await http.post(
        Uri.parse('$_gatewayUrl/api/institutions/onboard'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(inst.toJson()),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        txId = data['txId'] ?? txId;
        isLive = true;
      }
    } catch (_) {
      // Local fallback
    }

    inst.status = InstitutionStatus.active;
    inst.approvalDate = DateTime.now();
    inst.txId = txId;
    inst.blockNumber = blockNumber;
    list[idx] = inst;
    institutions.value = list;

    return {
      'success': true,
      'isLive': isLive,
      'txId': txId,
      'blockNumber': blockNumber,
      'institution': inst,
    };
  }

  /// Orderer rejects an institution onboarding request
  void rejectInstitutionRequest(String institutionId, String reason) {
    final list = List<Institution>.from(institutions.value);
    final idx = list.indexWhere((i) => i.id == institutionId);
    if (idx != -1) {
      list[idx].status = InstitutionStatus.rejected;
      institutions.value = list;
    }
  }

  /// Institution creates and automatically deploys a new Smart Contract to the blockchain channel
  Future<Map<String, dynamic>> deploySmartContractOnChain({
    required String institutionId,
    required String nameEn,
    required String nameAr,
    required String descriptionEn,
    required String descriptionAr,
    required String version,
    required List<String> schemaAttributes,
    String? customContractId,
  }) async {
    final inst = institutions.value.firstWhere(
      (i) => i.id == institutionId,
      orElse: () => institutions.value.first,
    );

    final contractId = customContractId ??
        'paldfi_${inst.orgMspId.toLowerCase()}_${nameEn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), "_")}';

    final startingBit = 200 + (smartContracts.value.length * 50);

    final contract = SmartContractDefinition(
      contractId: contractId,
      institutionId: inst.id,
      institutionNameEn: inst.nameEn,
      institutionNameAr: inst.nameAr,
      nameEn: nameEn,
      nameAr: nameAr,
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
      version: version,
      channel: inst.channelName,
      endorsementPolicy: "OR('${inst.orgMspId}.peer', 'NUVTEMSP.peer')",
      schemaAttributes: schemaAttributes,
      startingBitIndex: startingBit,
      status: ContractDeploymentStatus.deploying,
    );

    String txId = 'tx-deploy-cc-${DateTime.now().millisecondsSinceEpoch}';
    int blockNumber = 104900 + smartContracts.value.length;
    bool isLive = false;

    try {
      final res = await http.post(
        Uri.parse('$_gatewayUrl/api/contracts/deploy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(contract.toJson()),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        txId = data['txId'] ?? txId;
        isLive = true;
      }
    } catch (_) {
      // Local fallback
    }

    contract.status = ContractDeploymentStatus.deployed;
    contract.deployedAt = DateTime.now();
    contract.deployedBy = '${inst.adminNameEn} (${inst.orgMspId})';
    contract.deployTxId = txId;
    contract.deployBlockNumber = blockNumber;

    final list = List<SmartContractDefinition>.from(smartContracts.value);
    list.insert(0, contract);
    smartContracts.value = list;

    return {
      'success': true,
      'isLive': isLive,
      'txId': txId,
      'blockNumber': blockNumber,
      'contract': contract,
    };
  }

  /// Issues a document from an onboarded institution using a deployed smart contract, anchoring on blockchain and writing to citizen vault
  Future<Map<String, dynamic>> issueDocumentFromInstitution({
    required String institutionId,
    required String contractId,
    required String studentId,
    required String documentTitleEn,
    required String documentTitleAr,
    required AcademicDocumentType documentType,
    required Map<String, dynamic> attributes,
    required String employeeId,
  }) async {
    final inst = institutions.value.firstWhere((i) => i.id == institutionId);
    final contract = smartContracts.value.firstWhere((c) => c.contractId == contractId);
    final student = WalletStorageService().getStudentProfile(studentId);

    final docIdPrefix = inst.orgMspId.replaceAll('MSP', '');
    final docId = 'DOC-$docIdPrefix-2024-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final statusListIndex = contract.startingBitIndex + (DateTime.now().millisecondsSinceEpoch % 40);

    // Create VC from dynamic student profile
    final vc = VerifiableCredential.fromStudent(
      student.copyWith(statusListIndex: statusListIndex),
      documentType: documentType,
      issuerDid: inst.adminDid,
      signatureProof: 'z4Ed25519Sig_${inst.orgMspId}_${DateTime.now().millisecondsSinceEpoch}',
      customDocId: docId,
      customStatusListIndex: statusListIndex,
    );

    // Anchor on Fabric smart contract
    final anchorRes = await FabricLedgerService().anchorDocumentOnChain(
      docId: docId,
      docType: contract.nameEn,
      docHash: vc.onChainAnchorHash,
      subjectHash: 'hash-${student.nationalId}',
      statusListIndex: statusListIndex,
      metadata: {
        'institutionId': inst.id,
        'institutionName': inst.nameEn,
        'contractId': contract.contractId,
        'issuedBy': employeeId,
        'issuedAt': DateTime.now().toUtc().toIso8601String(),
        'attributes': attributes,
      },
    );

    // Ingest directly into citizen's wallet vault
    WalletStorageService().addCredential(vc);

    return {
      'success': true,
      'isLive': anchorRes['isLive'] ?? false,
      'txId': anchorRes['txId'] ?? 'tx-inst-issued-${DateTime.now().millisecondsSinceEpoch}',
      'docId': docId,
      'credential': vc,
    };
  }

  /// Get active institutions that citizens can request documents from
  List<Institution> getActiveInstitutions() {
    return institutions.value.where((i) => i.isActive).toList();
  }

  /// Get deployed smart contracts for a specific institution
  List<SmartContractDefinition> getContractsForInstitution(String institutionId) {
    return smartContracts.value
        .where((c) => c.institutionId == institutionId && c.isDeployed)
        .toList();
  }
}
