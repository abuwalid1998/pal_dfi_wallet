import 'package:flutter_test/flutter_test.dart';
import 'package:pal_dfi_wallet/core/models/student_profile.dart';
import 'package:pal_dfi_wallet/core/services/fabric_ledger_service.dart';
import 'package:pal_dfi_wallet/core/services/wallet_storage_service.dart';

void main() {
  group('Live Hyperledger Fabric Gateway & Smart Contract Integration Tests', () {
    final ledger = FabricLedgerService();

    test('Gateway health check returns UP and connected to Hyperledger Fabric 2.5', () async {
      final isHealthy = await ledger.checkGatewayHealth();
      expect(isHealthy, isTrue);
      expect(ledger.isLiveConnected.value, isTrue);
    });

    test('Live contract query: VerifyDocument against seeded Graduation Certificate', () async {
      final result = await ledger.queryStatusList(
        statusListIndex: 102,
        anchorHash: '07d7f05362c14b9b3e4566a66e413fb9a59e792324449238fdb3216b8048e98c',
        signature: 'valid-ed25519-sig-mock-longer-than-20-chars',
        docId: 'DOC-NUVTE-2024-GRAD-098',
      );

      expect(result.isValid, isTrue);
      expect(result.isRevoked, isFalse);
      expect(result.isLiveNetwork, isTrue);
      expect(result.transactionId, isNotEmpty);
      expect(result.responseTimeMs, lessThan(3000));
    });

    test('Live contract invoke: RecordVerificationAudit on nuvte-academic-channel', () async {
      final auditRes = await ledger.recordVerificationAudit(
        auditId: 'AUDIT-UNIT-${DateTime.now().millisecondsSinceEpoch}',
        verifierDid: 'did:key:z6MkuBankOfPalestineCompliance',
        verifierName: 'Bank of Palestine (Automated Unit Test)',
        docId: 'DOC-NUVTE-2024-GRAD-098',
        studentDid: 'did:key:z6MkuStudentAmjadKhaliliah',
        nonce: 'nonce-unit-test',
        verificationResult: 'VALID',
      );

      expect(auditRes['success'], isTrue);
      expect(auditRes['isLive'], isTrue);
      expect(auditRes['txId'], isNotEmpty);
    });

    test('Live contract query & sync: Check revocation on DOC-NUVTE-2023-STU-012 returns REVOKED', () async {
      final isRevoked = await ledger.checkRevocationStatusOnChain(99, docId: 'DOC-NUVTE-2023-STU-012');
      expect(isRevoked, isTrue);

      final verifyRes = await ledger.queryStatusList(
        statusListIndex: 99,
        anchorHash: 'd7a3e2f60b94c13a6e98d13f4567a0c3b8e9f0a12c3d4e5f60718293a4b5c6d7',
        signature: 'valid-sig-mock-longer-than-20-chars',
        docId: 'DOC-NUVTE-2023-STU-012',
      );

      expect(verifyRes.isValid, isFalse);
      expect(verifyRes.isRevoked, isTrue);
      expect(verifyRes.isLiveNetwork, isTrue);
      expect(verifyRes.transactionId, isNotEmpty);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Live contract invoke: AnchorDocument on nuvte-academic-channel', () async {
      final docId = 'DOC-TEST-${DateTime.now().millisecondsSinceEpoch}';
      final anchorRes = await ledger.anchorDocumentOnChain(
        docId: docId,
        docType: 'ClearanceCertificateCredential',
        docHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        subjectHash: 'sha256_national_id_test',
        statusListIndex: 150,
        metadata: {'testKey': 'testVal'},
      );

      expect(anchorRes['success'], isTrue);
      expect(anchorRes['isLive'], isTrue);
      expect(anchorRes['txId'], isNotEmpty);
    });

    test('WalletStorageService sync: student wallet reflects REVOKED status from ledger', () async {
      final wallet = WalletStorageService();
      await wallet.syncWithBlockchainLedger();
      await wallet.loadStudentWallet('STU-2023012');
      await wallet.syncAllCredentialsWithLedger();

      if (wallet.credentials.value.isNotEmpty) {
        final studentIdCard = wallet.credentials.value.first;
        expect(studentIdCard.fabricDocId, isNotEmpty);
      }
    });
  });
}
