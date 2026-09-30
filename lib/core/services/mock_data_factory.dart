import '../models/student_profile.dart';
import '../models/verifiable_credential.dart';
import 'fabric_ledger_service.dart';

class MockDataFactory {
  static StudentProfile get primaryStudent {
    return StudentProfile(
      studentId: 'STU-2024098',
      nationalId: '983421560',
      fullNameEn: 'Amjad Khaliliah',
      fullNameAr: 'أمجد خليلية',
      facultyEn: 'Faculty of Engineering & Technology',
      facultyAr: 'كلية الهندسة والتكنولوجيا',
      programEn: 'B.Sc. in Computer Systems & Cybersecurity',
      programAr: 'بكالوريوس هندسة أنظمة الحاسوب والأمن السيبراني',
      degreeLevelEn: 'Bachelor of Science (B.Sc.)',
      degreeLevelAr: 'درجة البكالوريوس في العلوم',
      academicYear: '2024 - 2028',
      gpa: 3.88,
      bloodType: 'O+',
      photoSeed: 'amjad_nuvte',
      status: CredentialStatus.active,
      statusListIndex: 101,
      issueDate: DateTime(2024, 9, 1),
      expiryDate: DateTime(2028, 6, 30),
      graduationDate: DateTime(2024, 6, 25),
      honorsEn: 'First Class Honors (Summa Cum Laude)',
      honorsAr: 'مرتبة الشرف الأولى مع الامتياز العالي',
      deansDecreeNumber: 'NUVTE-DEC-2024-884',
      clearanceDate: DateTime(2024, 7, 2),
      isLibraryCleared: true,
      isFinanceCleared: true,
      isLabsCleared: true,
      isStudentAffairsCleared: true,
      isRegistrationCleared: true,
      clearanceReferenceNumber: 'CLR-NUVTE-2024-00912',
    );
  }

  static StudentProfile get vocationalStudent {
    return StudentProfile(
      studentId: 'STU-2024105',
      nationalId: '984123567',
      fullNameEn: 'Yara Mansour',
      fullNameAr: 'يارا منصور',
      facultyEn: 'Faculty of Applied & Vocational Sciences',
      facultyAr: 'كلية المهن والعلوم التطبيقية',
      programEn: 'B.Tech. in Renewable Energy Technologies',
      programAr: 'بكالوريوس تكنولوجيا الطاقة المتجددة',
      degreeLevelEn: 'Bachelor of Technology (B.Tech.)',
      degreeLevelAr: 'درجة البكالوريوس المهني',
      academicYear: '2024 - 2028',
      gpa: 3.92,
      bloodType: 'A+',
      photoSeed: 'yara_nuvte',
      status: CredentialStatus.active,
      statusListIndex: 105,
      issueDate: DateTime(2024, 9, 1),
      expiryDate: DateTime(2028, 6, 30),
      graduationDate: DateTime(2024, 6, 25),
      honorsEn: 'First Class Honors',
      honorsAr: 'مرتبة الشرف الأولى',
      deansDecreeNumber: 'NUVTE-DEC-2024-885',
      clearanceDate: DateTime(2024, 7, 2),
      isLibraryCleared: true,
      isFinanceCleared: true,
      isLabsCleared: true,
      isStudentAffairsCleared: true,
      isRegistrationCleared: true,
      clearanceReferenceNumber: 'CLR-NUVTE-2024-00915',
    );
  }

  static StudentProfile get revokedStudent {
    final isRev = FabricLedgerService().isBitRevoked(99);
    return StudentProfile(
      studentId: 'STU-2023012',
      nationalId: '971842901',
      fullNameEn: 'Kareem Al-Qadi',
      fullNameAr: 'كريم القاضي',
      facultyEn: 'Faculty of Vocational Business',
      facultyAr: 'كلية الأعمال المهنية والتقنية',
      programEn: 'Diploma in Digital Financial Technologies',
      programAr: 'دبلوم التكنولوجيا المالية الرقمية',
      degreeLevelEn: 'Intermediate Vocational Diploma',
      degreeLevelAr: 'دبلوم مهني متوسط',
      academicYear: '2023 - 2025',
      gpa: 2.10,
      bloodType: 'B+',
      photoSeed: 'kareem_nuvte',
      status: isRev ? CredentialStatus.revoked : CredentialStatus.active,
      statusListIndex: 99,
      issueDate: DateTime(2023, 9, 1),
      expiryDate: DateTime(2025, 6, 30),
    );
  }

  static StudentProfile getStudentById(String id) {
    if (id == 'STU-2024105') return vocationalStudent;
    if (id == 'STU-2023012') return revokedStudent;
    return primaryStudent;
  }

  static VerifiableCredential createVerifiableCredential(
    StudentProfile student, {
    AcademicDocumentType documentType = AcademicDocumentType.studentId,
    int? customStatusListIndex,
    String? customDocId,
    String? customAnchorHash,
  }) {
    final issuerDid = FabricLedgerService().issuerDid;
    const signature = 'z4Ed25519SigNUVTE984a1738c89b21f98d021c4e99f018e';

    final vc = VerifiableCredential.fromStudent(
      student,
      documentType: documentType,
      issuerDid: issuerDid,
      signatureProof: signature,
      customDocId: customDocId,
      customAnchorHash: customAnchorHash,
      customStatusListIndex: customStatusListIndex,
    );

    // Anchor on Fabric ledger cache
    final block = 104820 + vc.statusListIndex;
    FabricLedgerService().anchorCredentialHash(vc.onChainAnchorHash, block);
    return vc;
  }

  /// Creates academic documents for the student matching on-chain documents
  static List<VerifiableCredential> createAllStudentDocuments(StudentProfile student) {
    if (student.studentId == 'STU-2024105') {
      // Yara Mansour
      final idCard = createVerifiableCredential(
        student.copyWith(statusListIndex: 105),
        documentType: AcademicDocumentType.studentId,
        customDocId: 'DOC-NUVTE-2024-STU-105',
        customAnchorHash: 'b5e1c0d48f72a91e4c76b91d2345e8a1f6c7d8e90a1b2c3d4e5f60718293a4b5',
        customStatusListIndex: 105,
      );
      final gradCert = createVerifiableCredential(
        student.copyWith(statusListIndex: 106),
        documentType: AcademicDocumentType.graduationCertificate,
        customDocId: 'DOC-NUVTE-2024-GRAD-105',
        customAnchorHash: 'c6f2d1e59a83b02f5d87c02e3456f9b2a7d8e9f01b2c3d4e5f60718293a4b5c6',
        customStatusListIndex: 106,
      );
      return [idCard, gradCert];
    } else if (student.studentId == 'STU-2023012') {
      // Kareem Al-Qadi (Dynamically checked against ledger)
      final isRev = FabricLedgerService().isBitRevoked(99);
      final idCard = createVerifiableCredential(
        student.copyWith(
          statusListIndex: 99,
          status: isRev ? CredentialStatus.revoked : CredentialStatus.active,
        ),
        documentType: AcademicDocumentType.studentId,
        customDocId: 'DOC-NUVTE-2023-STU-012',
        customAnchorHash: 'd7a3e2f60b94c13a6e98d13f4567a0c3b8e9f0a12c3d4e5f60718293a4b5c6d7',
        customStatusListIndex: 99,
      );
      return [idCard];
    } else {
      // Amjad Khaliliah (Primary)
      final idCard = createVerifiableCredential(
        student.copyWith(statusListIndex: 101),
        documentType: AcademicDocumentType.studentId,
        customDocId: 'DOC-NUVTE-2024-STU-098',
        customAnchorHash: '81b888542dc4e686edd9890430beaafd1e98d066479ef854ae447dee167a2126',
        customStatusListIndex: 101,
      );

      final gradCert = createVerifiableCredential(
        student.copyWith(statusListIndex: 102),
        documentType: AcademicDocumentType.graduationCertificate,
        customDocId: 'DOC-NUVTE-2024-GRAD-098',
        customAnchorHash: '07d7f05362c14b9b3e4566a66e413fb9a59e792324449238fdb3216b8048e98c',
        customStatusListIndex: 102,
      );

      final clearanceCert = createVerifiableCredential(
        student.copyWith(statusListIndex: 103),
        documentType: AcademicDocumentType.clearanceCertificate,
        customDocId: 'DOC-NUVTE-2024-CLR-098',
        customAnchorHash: 'ad147ab8a475fedf5574b6b458879de5f6c92279c24057a4407291c8e7b585f4',
        customStatusListIndex: 103,
      );

      return [idCard, gradCert, clearanceCert];
    }
  }
}
