import 'package:flutter_test/flutter_test.dart';
import 'package:pal_dfi_wallet/core/services/face_recognition_service.dart';

void main() {
  group('PAL-DFI Docker Face Recognition & Biometric DID Tests', () {
    final faceService = FaceRecognitionService();

    test('Docker Face Recognition Container Health Check', () async {
      final isOnline = await faceService.checkServiceHealth();
      expect(isOnline, isTrue, reason: 'Docker container paldfi_face_recognition must be listening on port 5060');
    });

    test('Verify Student (Amjad Khaliliah) FaceID & Derive DID', () async {
      final res = await faceService.verifyFaceAndDeriveDid(candidateId: 'STU-2024098');
      expect(res.success, isTrue);
      expect(res.verified, isTrue);
      expect(res.candidateId, equals('STU-2024098'));
      expect(res.fullNameEn, equals('Amjad Khaliliah'));
      expect(res.derivedDid, startsWith('did:paldfi:face:'));
      expect(res.didKey, startsWith('did:key:z6Mku'));
      expect(res.poweredBy, equals('Powered By ID+ - PMA'));
    });

    test('Verify University Registrar (Dr. Raed Al-Qutob) FaceID & Derive DID', () async {
      final res = await faceService.verifyFaceAndDeriveDid(candidateId: 'EMP-90012');
      expect(res.success, isTrue);
      expect(res.verified, isTrue);
      expect(res.candidateId, equals('EMP-90012'));
      expect(res.fullNameEn, equals('Dr. Raed Al-Qutob'));
      expect(res.derivedDid, startsWith('did:paldfi:face:'));
      expect(res.didKey, startsWith('did:key:z6Mku'));
      expect(res.poweredBy, equals('Powered By ID+ - PMA'));
    });

    test('Verify Third-Party (Bank of Palestine) FaceID & Derive DID', () async {
      final res = await faceService.verifyFaceAndDeriveDid(candidateId: 'BOP-VERIFIER');
      expect(res.success, isTrue);
      expect(res.verified, isTrue);
      expect(res.candidateId, equals('BOP-VERIFIER'));
      expect(res.fullNameEn, contains('Bank of Palestine'));
      expect(res.derivedDid, startsWith('did:paldfi:face:'));
      expect(res.didKey, startsWith('did:key:z6Mku'));
      expect(res.poweredBy, equals('Powered By ID+ - PMA'));
    });
  });
}
