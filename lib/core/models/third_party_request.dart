import 'verifiable_credential.dart';
import 'verifiable_presentation.dart';

enum ThirdPartyRequestStatus {
  pending,
  authorized,
  rejected,
  verified,
}

class ThirdPartyRequest {
  final String requestId;
  final String verifierNameEn;
  final String verifierNameAr;
  final String verifierOrgType;
  final String verifierDid;
  final String targetStudentId;
  final String targetStudentName;
  final String targetNationalId;
  final AcademicDocumentType documentTypeRequested;
  final String purposeEn;
  final String purposeAr;
  final String nonce;
  final DateTime timestamp;
  ThirdPartyRequestStatus status;
  VerifiablePresentation? presentation;

  ThirdPartyRequest({
    required this.requestId,
    required this.verifierNameEn,
    required this.verifierNameAr,
    required this.verifierOrgType,
    required this.verifierDid,
    this.targetStudentId = 'STU-2024098',
    this.targetStudentName = 'Amjad Khaliliah',
    this.targetNationalId = '983421560',
    required this.documentTypeRequested,
    required this.purposeEn,
    required this.purposeAr,
    required this.nonce,
    required this.timestamp,
    this.status = ThirdPartyRequestStatus.pending,
    this.presentation,
  });

  bool get isPending => status == ThirdPartyRequestStatus.pending;
  bool get isAuthorized => status == ThirdPartyRequestStatus.authorized;
  bool get isRejected => status == ThirdPartyRequestStatus.rejected;
  bool get isVerified => status == ThirdPartyRequestStatus.verified;
  bool get isShared => status == ThirdPartyRequestStatus.authorized || status == ThirdPartyRequestStatus.verified;

  String get requestedDocTitleEn {
    switch (documentTypeRequested) {
      case AcademicDocumentType.studentId:
        return 'Student Identity Card';
      case AcademicDocumentType.graduationCertificate:
        return 'Official Graduation Certificate';
      case AcademicDocumentType.clearanceCertificate:
        return 'Certificate of Discharge (Clearance)';
    }
  }

  String get requestedDocTitleAr {
    switch (documentTypeRequested) {
      case AcademicDocumentType.studentId:
        return 'بطاقة الطالب الجامعية';
      case AcademicDocumentType.graduationCertificate:
        return 'شهادة التخرج والدرجة العلمية';
      case AcademicDocumentType.clearanceCertificate:
        return 'شهادة براءة الذمة الجامعية';
    }
  }
}
