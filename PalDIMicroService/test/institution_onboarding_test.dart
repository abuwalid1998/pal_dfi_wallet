import 'package:flutter_test/flutter_test.dart';
import 'package:pal_dfi_wallet/core/models/institution.dart';
import 'package:pal_dfi_wallet/core/models/smart_contract_definition.dart';
import 'package:pal_dfi_wallet/core/models/student_profile.dart';
import 'package:pal_dfi_wallet/core/models/verifiable_credential.dart';
import 'package:pal_dfi_wallet/core/services/institution_governance_service.dart';
import 'package:pal_dfi_wallet/core/services/wallet_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Institution Onboarding & Governance Lifecycle', () {
    late InstitutionGovernanceService govService;
    late WalletStorageService walletStorage;

    setUp(() {
      govService = InstitutionGovernanceService();
      walletStorage = WalletStorageService();
    });

    test('Initial seeded institutions contain Orderer and pending universities', () {
      final all = govService.institutions.value;
      expect(all.isNotEmpty, isTrue);

      final active = govService.getActiveInstitutions();
      expect(active.any((i) => i.id == 'INST-NUVTE-001'), isTrue);

      final pending = all.where((i) => i.isPending).toList();
      expect(pending.any((i) => i.id == 'INST-BZU-002'), isTrue);
      expect(pending.any((i) => i.id == 'INST-AQU-003'), isTrue);
    });

    test('Orderer approves pending institution and deploys it to blockchain', () async {
      final initialPendingCount = govService.institutions.value.where((i) => i.isPending).length;
      final bzu = govService.institutions.value.firstWhere((i) => i.id == 'INST-BZU-002');
      expect(bzu.isPending, isTrue);

      final result = await govService.approveAndDeployInstitutionOnChain(bzu.id);

      expect(result['success'], isTrue);
      final Institution approvedInst = result['institution'];
      expect(approvedInst.status, equals(InstitutionStatus.active));
      expect(approvedInst.txId, isNotNull);
      expect(approvedInst.approvalDate, isNotNull);

      // Pending count decreased by 1
      final currentPending = govService.institutions.value.where((i) => i.isPending).length;
      expect(currentPending, equals(initialPendingCount - 1));
      // Active count now includes Birzeit University
      expect(govService.getActiveInstitutions().any((i) => i.id == 'INST-BZU-002'), isTrue);
    });

    test('Onboarded institution can create and deploy custom smart contract', () async {
      final bzu = govService.institutions.value.firstWhere((i) => i.id == 'INST-BZU-002');

      final deployRes = await govService.deploySmartContractOnChain(
        institutionId: bzu.id,
        nameEn: "Master of Science in Cybersecurity",
        nameAr: "ماجستير الأمن السيبراني والتحقيق الجنائي الرقمي",
        descriptionEn: "Academic smart contract for postgraduate degree issuance",
        descriptionAr: "عقد ذكي أكاديمي لإصدار شهادات الدراسات العليا",
        version: "1.0.0",
        schemaAttributes: [
          'studentId',
          'nationalId',
          'fullName',
          'degreeTitle',
          'major',
          'gpa',
          'issueDate',
          'thesisTitle',
        ],
      );

      expect(deployRes['success'], isTrue);
      final SmartContractDefinition contract = deployRes['contract'];
      expect(contract.status, equals(ContractDeploymentStatus.deployed));
      expect(contract.deployTxId, isNotNull);

      final bzuContracts = govService.getContractsForInstitution(bzu.id);
      expect(bzuContracts.any((c) => c.contractId == contract.contractId), isTrue);
    });

    test('Institution employee can issue document to citizen and write to vault', () async {
      final bzu = govService.institutions.value.firstWhere((i) => i.id == 'INST-BZU-002');
      final bzuContracts = govService.getContractsForInstitution(bzu.id);
      final contract = bzuContracts.first;

      const targetCitizenId = 'STU-2024098'; // Amjad Khaliliah
      final initialDocsCount = walletStorage.getStudentDocuments(targetCitizenId).length;

      final issueRes = await govService.issueDocumentFromInstitution(
        institutionId: bzu.id,
        contractId: contract.contractId,
        studentId: targetCitizenId,
        documentTitleEn: "Master of Science in Cybersecurity Degree",
        documentTitleAr: "شهادة درجة الماجستير في الأمن السيبراني",
        documentType: AcademicDocumentType.graduationCertificate,
        attributes: {
          'degreeTitle': 'Master of Science in Cybersecurity',
          'major': 'Cybersecurity & Digital Forensics',
          'gpa': '3.95',
          'honors': 'High Distinction / مرتبة الشرف الأولى',
          'thesisTitle': 'Zero Knowledge Verification for Academic Credentials',
        },
        employeeId: 'BZU-EMP-01',
      );

      expect(issueRes['success'], isTrue);
      final VerifiableCredential issuedVc = issueRes['credential'];
      expect(issuedVc.id, startsWith('DOC-'));
      expect(issuedVc.student.studentId, equals(targetCitizenId));
      expect(issuedVc.student.status, equals(CredentialStatus.active));
      expect(issuedVc.statusListIndex, inInclusiveRange(0, 1000));

      // Verify document appears directly in the citizen's vault
      final updatedDocs = walletStorage.getStudentDocuments(targetCitizenId);
      expect(updatedDocs.length, equals(initialDocsCount + 1));
      expect(updatedDocs.any((d) => d.id == issuedVc.id), isTrue);
    });

    test('Direct submission of new institution onboarding request', () async {
      final newInst = Institution(
        id: 'INST-PPU-005',
        nameEn: "Palestine Polytechnic University",
        nameAr: "جامعة بوليتكنك فلسطين",
        orgMspId: "PPUMSP",
        type: InstitutionType.university,
        domain: "ppu.edu.ps",
        adminNameEn: "Dr. Ayman Sultan",
        adminNameAr: "د. أيمن سلطان",
        adminEmail: "blockchain@ppu.edu.ps",
        adminDid: "did:key:z6MkuPPUUniversityAuthority2024",
        peerEndpoint: "peer0.ppu.edu.ps:7051",
        caEndpoint: "ca.ppu.edu.ps:7054",
        reasonEn: "Deploy academic smart contracts for engineering faculties.",
        reasonAr: "نشر عقود ذكية لكليات الهندسة وتكنولوجيا المعلومات.",
        requestDate: DateTime.now(),
        status: InstitutionStatus.pending,
      );

      govService.submitOnboardingRequest(newInst);

      expect(govService.institutions.value.any((i) => i.id == newInst.id && i.isPending), isTrue);

      // Orderer approves it
      final approved = await govService.approveAndDeployInstitutionOnChain(newInst.id);

      expect(approved['success'], isTrue);
      final Institution approvedInst = approved['institution'];
      expect(approvedInst.status, equals(InstitutionStatus.active));
      expect(approvedInst.txId, isNotNull);
    });
  });
}
