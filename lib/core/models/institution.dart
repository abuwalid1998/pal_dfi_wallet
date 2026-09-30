enum InstitutionStatus {
  pending,
  approved,
  rejected,
  active,
}

enum InstitutionType {
  university,
  ministry,
  bank,
  governmentAgency,
}

class Institution {
  final String id;
  final String nameEn;
  final String nameAr;
  final String orgMspId;
  final InstitutionType type;
  final String domain;
  final String adminNameEn;
  final String adminNameAr;
  final String adminEmail;
  final String adminDid;
  final String channelName;
  final String peerEndpoint;
  final String caEndpoint;
  final String reasonEn;
  final String reasonAr;
  final DateTime requestDate;
  InstitutionStatus status;
  DateTime? approvalDate;
  String? txId;
  String? blockNumber;

  Institution({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.orgMspId,
    required this.type,
    required this.domain,
    required this.adminNameEn,
    required this.adminNameAr,
    required this.adminEmail,
    required this.adminDid,
    this.channelName = 'nuvte-academic-channel',
    required this.peerEndpoint,
    required this.caEndpoint,
    required this.reasonEn,
    required this.reasonAr,
    required this.requestDate,
    this.status = InstitutionStatus.pending,
    this.approvalDate,
    this.txId,
    this.blockNumber,
  });

  bool get isPending => status == InstitutionStatus.pending;
  bool get isApproved => status == InstitutionStatus.approved || status == InstitutionStatus.active;
  bool get isRejected => status == InstitutionStatus.rejected;
  bool get isActive => status == InstitutionStatus.active;

  String get typeLabelEn {
    switch (type) {
      case InstitutionType.university:
        return 'Academic Institution / University';
      case InstitutionType.ministry:
        return 'Government Ministry';
      case InstitutionType.bank:
        return 'Banking & Financial Authority';
      case InstitutionType.governmentAgency:
        return 'Sovereign Public Agency';
    }
  }

  String get typeLabelAr {
    switch (type) {
      case InstitutionType.university:
        return 'مؤسسة أكاديمية / جامعة';
      case InstitutionType.ministry:
        return 'وزارة وهيئة حكومية';
      case InstitutionType.bank:
        return 'جهة مصرفية ومالية';
      case InstitutionType.governmentAgency:
        return 'سلطة وهيئة عامة سيادية';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameEn': nameEn,
    'nameAr': nameAr,
    'orgMspId': orgMspId,
    'type': type.name,
    'domain': domain,
    'adminNameEn': adminNameEn,
    'adminNameAr': adminNameAr,
    'adminEmail': adminEmail,
    'adminDid': adminDid,
    'channelName': channelName,
    'peerEndpoint': peerEndpoint,
    'caEndpoint': caEndpoint,
    'reasonEn': reasonEn,
    'reasonAr': reasonAr,
    'requestDate': requestDate.toIso8601String(),
    'status': status.name,
    'approvalDate': approvalDate?.toIso8601String(),
    'txId': txId,
    'blockNumber': blockNumber,
  };
}
