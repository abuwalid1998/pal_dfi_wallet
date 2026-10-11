import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pal_dfi_wallet/main.dart';
import 'package:pal_dfi_wallet/core/models/third_party_request.dart';
import 'package:pal_dfi_wallet/core/models/verifiable_credential.dart';
import 'package:pal_dfi_wallet/core/models/verifiable_presentation.dart';
import 'package:pal_dfi_wallet/core/services/crypto_vault_service.dart';
import 'package:pal_dfi_wallet/core/services/fabric_ledger_service.dart';
import 'package:pal_dfi_wallet/core/services/id_plus_auth_service.dart';
import 'package:pal_dfi_wallet/core/services/mock_data_factory.dart';
import 'package:pal_dfi_wallet/core/services/wallet_storage_service.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    IdPlusAuthService().logout();
    await WalletStorageService().initializeWallet();
  });

  group('PAL-DFI Cryptography & Domain Tests', () {
    test('CryptoVaultService generates Ed25519 keypair and did:key anchor', () async {
      final vault = CryptoVaultService();
      await vault.initializeKeypair(forceRegenerate: true);

      expect(vault.isKeyGenerated, isTrue);
      expect(vault.didKey.startsWith('did:key:z6Mku'), isTrue);
      expect(vault.publicKeyHex.length, greaterThanOrEqualTo(32));

      // Test Proof of Possession (PoP) token generation
      final pop = vault.generateProofOfPossession(
        issuanceNonce: 'nonce-test-1234',
        audience: 'https://identity.nuvte.edu.ps',
      );

      expect(pop['header']?['alg'], equals('EdDSA'));
      expect(pop['payload']?['nonce'], equals('nonce-test-1234'));
      expect(pop['signature'], isNotEmpty);
    });

    test('W3C VC 2.0 serialization for official documents with SHA-256 On-Chain Anchor', () {
      final student = MockDataFactory.primaryStudent;
      final docs = MockDataFactory.createAllStudentDocuments(student);

      expect(docs.length, equals(3));

      // 1. Digital Student ID
      final idDoc = docs.firstWhere((d) => d.documentType == AcademicDocumentType.studentId);
      expect(idDoc.type.contains('StudentIdentityCredential'), isTrue);
      expect(idDoc.onChainAnchorHash.length, equals(64));
      expect(idDoc.statusListIndex, equals(101));

      // 2. Graduation Certificate
      final gradDoc = docs.firstWhere((d) => d.documentType == AcademicDocumentType.graduationCertificate);
      expect(gradDoc.type.contains('GraduationCertificateCredential'), isTrue);
      expect(gradDoc.onChainAnchorHash.length, equals(64));
      expect(gradDoc.statusListIndex, equals(102));
      expect(gradDoc.student.gpa, equals(3.88));

      // 3. Certificate of Discharge / Clearance Certificate
      final clearDoc = docs.firstWhere((d) => d.documentType == AcademicDocumentType.clearanceCertificate);
      expect(clearDoc.type.contains('ClearanceCertificateCredential'), isTrue);
      expect(clearDoc.onChainAnchorHash.length, equals(64));
      expect(clearDoc.statusListIndex, equals(103));
      expect(clearDoc.student.isFullyCleared, isTrue);
    });

    test('Hyperledger Fabric BitstringStatusList2021 query (< 3.0s NFR)', () async {
      final ledger = FabricLedgerService();
      final student = MockDataFactory.primaryStudent;
      final vc = MockDataFactory.createVerifiableCredential(student);

      // 1. Check Active Student
      ledger.setRevocationStatus(vc.statusListIndex, false);
      final activeRes = await ledger.queryStatusList(
        statusListIndex: vc.statusListIndex,
        anchorHash: vc.onChainAnchorHash,
        signature: 'z4Ed25519SigNUVTE984a1738c89b21f98d021c4e99f018e',
        docId: vc.fabricDocId,
      );

      expect(activeRes.isValid, isTrue);
      expect(activeRes.isRevoked, isFalse);
      expect(activeRes.responseTimeMs, lessThan(3000));

      // 2. Toggle Revocation On-Chain
      ledger.setRevocationStatus(vc.statusListIndex, true);
      final revokedRes = await ledger.queryStatusList(
        statusListIndex: vc.statusListIndex,
        anchorHash: vc.onChainAnchorHash,
        signature: 'z4Ed25519SigNUVTE984a1738c89b21f98d021c4e99f018e',
        docId: vc.fabricDocId,
      );

      expect(revokedRes.isValid, isFalse);
      expect(revokedRes.isRevoked, isTrue);
      expect(revokedRes.responseTimeMs, lessThan(3000));
    });
  });

  group('PAL-DFI 3-Step Third-Party Verification Workflow', () {
    test('Execute Step 1 (Request) -> Step 2 (Authorize & Decrypt) -> Step 3 (Blockchain Verify)', () async {
      final storage = WalletStorageService();
      final ledger = FabricLedgerService();

      // Onboard student first to establish vault
      await storage.onboardNewStudent(
        fullNameEn: 'Amjad Khaliliah',
        fullNameAr: 'أمجد خليلية',
        nationalId: '983421560',
        studentId: 'STU-2024098',
        facultyEn: 'Faculty of Engineering & Technology',
        facultyAr: 'كلية الهندسة والتكنولوجيا',
        programEn: 'B.Sc. in Computer Systems & Cybersecurity',
        programAr: 'بكالوريوس هندسة أنظمة الحاسوب والأمن السيبراني',
        gpa: 3.88,
        bloodType: 'O+',
      );

      // Step 1: Third-party creates request
      final request = ThirdPartyRequest(
        requestId: 'REQ-TEST-BANK-001',
        verifierNameEn: 'Arab Bank Palestine',
        verifierNameAr: 'البنك العربي - فلسطين',
        verifierOrgType: 'Commercial Banking',
        verifierDid: 'did:paldfi:verifier:arab-bank-01',
        targetStudentId: 'STU-2024098',
        documentTypeRequested: AcademicDocumentType.studentId,
        purposeEn: 'Graduate Trainee KYC Verification',
        purposeAr: 'التحقق من المؤهل الأكاديمي لبرنامج تدريب الخريجين',
        nonce: VerifiablePresentation.generateNonce(),
        timestamp: DateTime.now(),
      );

      storage.submitThirdPartyRequest(request);
      expect(storage.thirdPartyRequests.value.any((r) => r.requestId == 'REQ-TEST-BANK-001'), isTrue);

      // Step 2: Student authorizes and shares decrypted presentation
      final presentation = storage.authorizeThirdPartyRequest('REQ-TEST-BANK-001');
      expect(presentation.credential.documentType, equals(AcademicDocumentType.studentId));
      expect(presentation.holderDid.startsWith('did:key:'), isTrue);
      expect(presentation.proof['proofValue'], isNotEmpty);

      final updatedReq = storage.thirdPartyRequests.value.firstWhere((r) => r.requestId == 'REQ-TEST-BANK-001');
      expect(updatedReq.status, equals(ThirdPartyRequestStatus.authorized));
      expect(updatedReq.presentation, isNotNull);

      // Step 3: Third party verifies against Fabric ledger
      ledger.setRevocationStatus(presentation.credential.statusListIndex, false);
      final result = await ledger.queryStatusList(
        statusListIndex: presentation.credential.statusListIndex,
        anchorHash: presentation.credential.onChainAnchorHash,
        signature: 'z4Ed25519SigNUVTE984a1738c89b21f98d021c4e99f018e',
      );

      expect(result.isValid, isTrue);
      expect(result.isRevoked, isFalse);
      expect(result.isAnchorVerified, isTrue);

      storage.markThirdPartyRequestVerified('REQ-TEST-BANK-001');
      final verifiedReq = storage.thirdPartyRequests.value.firstWhere((r) => r.requestId == 'REQ-TEST-BANK-001');
      expect(verifiedReq.status, equals(ThirdPartyRequestStatus.verified));
    });
  });

  group('PAL-DFI Role Operations & ID+ Authentication', () {
    testWidgets('Renders PMA ID+ Gateway with Student Onboarding and Role options', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const PalDfiWalletApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PAL-DFI Sovereign Wallet'), findsOneWidget);
      expect(find.text('Start New Student Onboarding'), findsOneWidget);
      expect(find.text('Biometric Face ID'), findsOneWidget);
      expect(find.text('Email & Network Domain'), findsOneWidget);
    });

    test('Domain-Aware Network Resolver resolves institutional emails properly', () {
      final auth = IdPlusAuthService();

      // 1. NUVTE
      final nuvte = auth.resolveDomainNetwork('registrar@nuvte.edu.ps');
      expect(nuvte, isNotNull);
      expect(nuvte!.mspId, equals('NUVTEMSP'));
      expect(nuvte.channel, equals('nuvte-academic-channel'));

      // 2. Birzeit University
      final bzu = auth.resolveDomainNetwork('admin@birzeit.edu');
      expect(bzu, isNotNull);
      expect(bzu!.mspId, equals('BZUMSP'));

      // 3. Al-Quds University
      final aqu = auth.resolveDomainNetwork('admissions@alquds.edu');
      expect(aqu, isNotNull);
      expect(aqu!.mspId, equals('AQUMSP'));

      // 4. Bank of Palestine
      final bop = auth.resolveDomainNetwork('compliance@bankofpalestine.com');
      expect(bop, isNotNull);
      expect(bop!.mspId, equals('BOPMSP'));
      expect(bop.detectedRole, equals(IdPlusRole.thirdPartyVerifier));
    });

    testWidgets('Logs in as University Management and accesses Registrar Portal (2 Operations)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const PalDfiWalletApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Login as University Management
      await IdPlusAuthService().loginAsUniversityManagement(skipDelay: true);
      await tester.pump(const Duration(milliseconds: 100));

      // Management portal elements
      expect(find.text('Faculty of Registration & Academic Affairs'), findsWidgets);
      expect(find.text('1. Student Requests'), findsOneWidget);
      expect(find.text('2. Revocation Registry'), findsOneWidget);

      // Logout
      IdPlusAuthService().logout();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('PAL-DFI Sovereign Wallet'), findsOneWidget);
    });

    testWidgets('Logs in as Third-Party Verifier and accesses Verifier Portal', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const PalDfiWalletApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Login as Third-Party Verifier
      await IdPlusAuthService().loginAsThirdParty(skipDelay: true);
      await tester.pump(const Duration(milliseconds: 100));

      // Verifier portal elements
      expect(find.text('Bank of Palestine • HR & Compliance'), findsOneWidget);
      expect(find.text('1. Request Document'), findsOneWidget);
      expect(find.text('2. Shared Docs & Verify'), findsOneWidget);

      // Logout
      IdPlusAuthService().logout();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('PAL-DFI Sovereign Wallet'), findsOneWidget);
    });

    test('Full End-to-End Workflow: Student Request -> Registrar Issuance on Chain -> Vault Update', () async {
      final storage = WalletStorageService();
      
      // Onboard Yara Mansour
      await storage.onboardNewStudent(
        fullNameEn: 'Yara Mansour',
        fullNameAr: 'يارا منصور',
        nationalId: '984123567',
        studentId: 'STU-2024105',
        facultyEn: 'Faculty of Applied & Vocational Sciences',
        facultyAr: 'كلية المهن والعلوم التطبيقية',
        programEn: 'B.Tech. in Renewable Energy Technologies',
        programAr: 'بكالوريوس تكنولوجيا الطاقة المتجددة',
        gpa: 3.92,
        bloodType: 'A+',
      );

      // 1. Student requests a Clearance Certificate
      storage.submitStudentIssuanceRequest(
        studentId: 'STU-2024105',
        documentType: AcademicDocumentType.clearanceCertificate,
        notes: 'Graduation Clearance Request for Bank Job Application',
      );

      final req = storage.studentIssuanceRequests.value.firstWhere(
        (r) => r.studentId == 'STU-2024105' && r.documentType == AcademicDocumentType.clearanceCertificate,
      );

      expect(req.status.name, equals('pending'));
      expect(storage.studentIssuanceRequests.value.any((r) => r.requestId == req.requestId), isTrue);

      // 2. University Registrar reviews and approves issuance
      final issueRes = await storage.approveAndIssueStudentDocument(
        requestId: req.requestId,
        employeeId: 'EMP-90012',
      );

      expect(issueRes['success'], isTrue);
      expect(issueRes['txId'], isNotEmpty);

      // 3. Document is anchored on chain and available in Yara's vault
      final updatedReq = storage.studentIssuanceRequests.value.firstWhere((r) => r.requestId == req.requestId);
      expect(updatedReq.status.name, equals('issued'));

      // Check Yara's credentials
      expect(storage.credentials.value.any((c) => c.documentType == AcademicDocumentType.clearanceCertificate), isTrue);
    });
  });
}
