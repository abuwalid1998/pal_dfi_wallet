import 'verifiable_credential.dart';

enum IssuanceRequestStatus {
  pending,
  issued,
  rejected,
}

class StudentIssuanceRequest {
  final String requestId;
  final String studentId;
  final String studentNameEn;
  final String studentNameAr;
  final String nationalId;
  final AcademicDocumentType documentType;
  final DateTime requestDate;
  final String notes;
  IssuanceRequestStatus status;
  String? rejectionReason;
  String? issuedDocId;
  String? txId;
  DateTime? processedDate;

  StudentIssuanceRequest({
    required this.requestId,
    required this.studentId,
    required this.studentNameEn,
    required this.studentNameAr,
    required this.nationalId,
    required this.documentType,
    required this.requestDate,
    required this.notes,
    this.status = IssuanceRequestStatus.pending,
    this.rejectionReason,
    this.issuedDocId,
    this.txId,
    this.processedDate,
  });

  bool get isPending => status == IssuanceRequestStatus.pending;
  bool get isIssued => status == IssuanceRequestStatus.issued;
  bool get isRejected => status == IssuanceRequestStatus.rejected;

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
        return 'بطاقة الهوية الجامعية الرقمية';
      case AcademicDocumentType.graduationCertificate:
        return 'شهادة التخرج الجامعية الرسمية';
      case AcademicDocumentType.clearanceCertificate:
        return 'شهادة براءة الذمة الرسمية';
    }
  }
}
