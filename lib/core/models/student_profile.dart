enum CredentialStatus {
  active,
  revoked,
  expired,
}

class StudentProfile {
  final String studentId; // e.g. STU-2024098
  final String nationalId; // e.g. 983421560 (local vault only - strictly zero on-chain)
  final String fullNameEn;
  final String fullNameAr;
  final String facultyEn;
  final String facultyAr;
  final String programEn;
  final String programAr;
  final String degreeLevelEn;
  final String degreeLevelAr;
  final String academicYear;
  final double gpa;
  final String bloodType;
  final String photoSeed;
  final CredentialStatus status;
  final int statusListIndex;
  final DateTime issueDate;
  final DateTime expiryDate;

  // Graduation specifics
  final DateTime? graduationDate;
  final String honorsEn;
  final String honorsAr;
  final String deansDecreeNumber;

  // Clearance specifics
  final DateTime? clearanceDate;
  final bool isLibraryCleared;
  final bool isFinanceCleared;
  final bool isLabsCleared;
  final bool isStudentAffairsCleared;
  final bool isRegistrationCleared;
  final String clearanceReferenceNumber;

  StudentProfile({
    required this.studentId,
    required this.nationalId,
    required this.fullNameEn,
    required this.fullNameAr,
    required this.facultyEn,
    required this.facultyAr,
    required this.programEn,
    required this.programAr,
    required this.degreeLevelEn,
    required this.degreeLevelAr,
    required this.academicYear,
    required this.gpa,
    required this.bloodType,
    required this.photoSeed,
    required this.status,
    required this.statusListIndex,
    required this.issueDate,
    required this.expiryDate,
    this.graduationDate,
    this.honorsEn = 'First Class Honors (High Distinction)',
    this.honorsAr = 'ممتاز مع مرتبة الشرف الأولى',
    this.deansDecreeNumber = 'NUVTE-DEC-2024-884',
    this.clearanceDate,
    this.isLibraryCleared = true,
    this.isFinanceCleared = true,
    this.isLabsCleared = true,
    this.isStudentAffairsCleared = true,
    this.isRegistrationCleared = true,
    this.clearanceReferenceNumber = 'CLR-2024-00912',
  });

  bool get isActive => status == CredentialStatus.active;
  bool get isRevoked => status == CredentialStatus.revoked;
  bool get isExpired => status == CredentialStatus.expired;
  bool get isFullyCleared =>
      isLibraryCleared &&
      isFinanceCleared &&
      isLabsCleared &&
      isStudentAffairsCleared &&
      isRegistrationCleared;

  StudentProfile copyWith({
    CredentialStatus? status,
    int? statusListIndex,
    DateTime? graduationDate,
    DateTime? clearanceDate,
    bool? isLibraryCleared,
    bool? isFinanceCleared,
    bool? isLabsCleared,
    bool? isStudentAffairsCleared,
    bool? isRegistrationCleared,
  }) {
    return StudentProfile(
      studentId: studentId,
      nationalId: nationalId,
      fullNameEn: fullNameEn,
      fullNameAr: fullNameAr,
      facultyEn: facultyEn,
      facultyAr: facultyAr,
      programEn: programEn,
      programAr: programAr,
      degreeLevelEn: degreeLevelEn,
      degreeLevelAr: degreeLevelAr,
      academicYear: academicYear,
      gpa: gpa,
      bloodType: bloodType,
      photoSeed: photoSeed,
      status: status ?? this.status,
      statusListIndex: statusListIndex ?? this.statusListIndex,
      issueDate: issueDate,
      expiryDate: expiryDate,
      graduationDate: graduationDate ?? this.graduationDate,
      honorsEn: honorsEn,
      honorsAr: honorsAr,
      deansDecreeNumber: deansDecreeNumber,
      clearanceDate: clearanceDate ?? this.clearanceDate,
      isLibraryCleared: isLibraryCleared ?? this.isLibraryCleared,
      isFinanceCleared: isFinanceCleared ?? this.isFinanceCleared,
      isLabsCleared: isLabsCleared ?? this.isLabsCleared,
      isStudentAffairsCleared: isStudentAffairsCleared ?? this.isStudentAffairsCleared,
      isRegistrationCleared: isRegistrationCleared ?? this.isRegistrationCleared,
      clearanceReferenceNumber: clearanceReferenceNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'nationalId': nationalId,
      'fullNameEn': fullNameEn,
      'fullNameAr': fullNameAr,
      'facultyEn': facultyEn,
      'facultyAr': facultyAr,
      'programEn': programEn,
      'programAr': programAr,
      'degreeLevelEn': degreeLevelEn,
      'degreeLevelAr': degreeLevelAr,
      'academicYear': academicYear,
      'gpa': gpa,
      'bloodType': bloodType,
      'photoSeed': photoSeed,
      'status': status.name,
      'statusListIndex': statusListIndex,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'graduationDate': graduationDate?.toIso8601String(),
      'honorsEn': honorsEn,
      'honorsAr': honorsAr,
      'deansDecreeNumber': deansDecreeNumber,
      'clearanceDate': clearanceDate?.toIso8601String(),
      'isLibraryCleared': isLibraryCleared,
      'isFinanceCleared': isFinanceCleared,
      'isLabsCleared': isLabsCleared,
      'isStudentAffairsCleared': isStudentAffairsCleared,
      'isRegistrationCleared': isRegistrationCleared,
      'clearanceReferenceNumber': clearanceReferenceNumber,
    };
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      studentId: json['studentId'] as String,
      nationalId: json['nationalId'] as String,
      fullNameEn: json['fullNameEn'] as String,
      fullNameAr: json['fullNameAr'] as String,
      facultyEn: json['facultyEn'] as String,
      facultyAr: json['facultyAr'] as String,
      programEn: json['programEn'] as String,
      programAr: json['programAr'] as String,
      degreeLevelEn: json['degreeLevelEn'] as String,
      degreeLevelAr: json['degreeLevelAr'] as String,
      academicYear: json['academicYear'] as String,
      gpa: (json['gpa'] as num).toDouble(),
      bloodType: json['bloodType'] as String,
      photoSeed: json['photoSeed'] as String,
      status: CredentialStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CredentialStatus.active,
      ),
      statusListIndex: json['statusListIndex'] as int,
      issueDate: DateTime.parse(json['issueDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      graduationDate: json['graduationDate'] != null
          ? DateTime.parse(json['graduationDate'] as String)
          : null,
      honorsEn: json['honorsEn'] as String? ?? 'First Class Honors',
      honorsAr: json['honorsAr'] as String? ?? 'مرتبة الشرف الأولى',
      deansDecreeNumber: json['deansDecreeNumber'] as String? ?? 'NUVTE-DEC-2024-884',
      clearanceDate: json['clearanceDate'] != null
          ? DateTime.parse(json['clearanceDate'] as String)
          : null,
      isLibraryCleared: json['isLibraryCleared'] as bool? ?? true,
      isFinanceCleared: json['isFinanceCleared'] as bool? ?? true,
      isLabsCleared: json['isLabsCleared'] as bool? ?? true,
      isStudentAffairsCleared: json['isStudentAffairsCleared'] as bool? ?? true,
      isRegistrationCleared: json['isRegistrationCleared'] as bool? ?? true,
      clearanceReferenceNumber: json['clearanceReferenceNumber'] as String? ?? 'CLR-2024-00912',
    );
  }
}
