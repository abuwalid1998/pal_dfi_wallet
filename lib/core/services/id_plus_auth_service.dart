import 'package:flutter/foundation.dart';
import '../models/institution.dart';
import 'face_recognition_service.dart';
import 'institution_governance_service.dart';

enum IdPlusRole {
  student,
  universityManagement,
  thirdPartyVerifier,
}

class ResolvedNetworkInfo {
  final String domain;
  final String organizationNameEn;
  final String organizationNameAr;
  final String mspId;
  final String channel;
  final String peerEndpoint;
  final String nodeRole;
  final IdPlusRole detectedRole;
  final bool isRegistered;
  final Institution? institution;

  ResolvedNetworkInfo({
    required this.domain,
    required this.organizationNameEn,
    required this.organizationNameAr,
    required this.mspId,
    this.channel = 'nuvte-academic-channel',
    required this.peerEndpoint,
    required this.nodeRole,
    required this.detectedRole,
    required this.isRegistered,
    this.institution,
  });
}

class IdPlusUserSession {
  final String nationalId;
  final String? studentId;
  final String fullNameEn;
  final String fullNameAr;
  final IdPlusRole role;
  final String roleTitleEn;
  final String roleTitleAr;
  final String token;
  final String pmaKycLevel;
  final String derivedDid;
  final DateTime loginTime;
  final Map<String, dynamic> metadata;

  IdPlusUserSession({
    required this.nationalId,
    this.studentId,
    required this.fullNameEn,
    required this.fullNameAr,
    required this.role,
    required this.roleTitleEn,
    required this.roleTitleAr,
    required this.token,
    this.pmaKycLevel = 'PMA-KYC-LEVEL-3 (Biometric + Banking Certified)',
    this.derivedDid = '',
    required this.loginTime,
    this.metadata = const {},
  });

  bool get isStudent => role == IdPlusRole.student;
  bool get isManagement => role == IdPlusRole.universityManagement;
  bool get isThirdParty => role == IdPlusRole.thirdPartyVerifier;
}

class IdPlusAuthService {
  static final IdPlusAuthService _instance = IdPlusAuthService._internal();
  factory IdPlusAuthService() => _instance;
  IdPlusAuthService._internal();

  final ValueNotifier<IdPlusUserSession?> currentUser =
      ValueNotifier<IdPlusUserSession?>(null);

  // Dynamic enrolled students in memory (populated from Vector DB & Blockchain)
  final ValueNotifier<List<Map<String, dynamic>>> dynamicStudents =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static List<Map<String, dynamic>> get studentProfiles {
    final dyn = IdPlusAuthService().dynamicStudents.value;
    if (dyn.isNotEmpty) return dyn;
    return [
      {
        'studentId': 'STU-2024098',
        'candidateId': 'STU-2024098',
        'nationalId': '983421560',
        'fullNameEn': 'Amjad Khaliliah',
        'fullNameAr': 'أمجد خليلية',
        'facultyEn': 'Faculty of Engineering & Technology',
        'facultyAr': 'كلية الهندسة والتكنولوجيا',
        'programEn': 'B.Sc. in Computer Systems & Cybersecurity',
        'programAr': 'بكالوريوس هندسة أنظمة الحاسوب والأمن السيبراني',
        'status': 'ACTIVE',
      }
    ];
  }

  static const Map<String, dynamic> universityEmployee = {
    'employeeId': 'EMP-90012',
    'nationalId': '900123841',
    'fullNameEn': 'Dr. Raed Al-Qutob',
    'fullNameAr': 'د. رائد القطب',
    'roleTitleEn': 'Dean of Admission & Registration • NUVTE',
    'roleTitleAr': 'عميد القبول والتسجيل والشؤون الأكاديمية - جامعة نابلس',
  };

  static const Map<String, dynamic> thirdPartyProfile = {
    'verifierDid': 'did:key:z6MkuBankOfPalestineCompliance',
    'nationalId': '990884210',
    'fullNameEn': 'Bank of Palestine (Compliance & HR Dept)',
    'fullNameAr': 'بنك فلسطين (دائرة الامتثال والموارد البشرية)',
    'roleTitleEn': 'Authorized Financial Verifier • Digital KYC',
    'roleTitleAr': 'جهة مالية ومصرفية معتمدة للتحقق الرقمي',
  };

  bool get isAuthenticated => currentUser.value != null;

  /// Fetch dynamic students from Vector DB
  Future<List<Map<String, dynamic>>> loadDynamicStudents() async {
    final candidates = await FaceRecognitionService().getEnrolledCandidates();
    final studentList = candidates.where((c) => c['role'] == 'student' || c['candidateId'].toString().startsWith('STU-')).toList();
    dynamicStudents.value = studentList;
    return studentList;
  }

  /// Register dynamic student session right after onboarding
  void registerDynamicStudent(Map<String, dynamic> studentData) {
    final list = List<Map<String, dynamic>>.from(dynamicStudents.value);
    final idx = list.indexWhere((s) => s['studentId'] == studentData['studentId'] || s['candidateId'] == studentData['candidateId']);
    if (idx != -1) {
      list[idx] = studentData;
    } else {
      list.insert(0, studentData);
    }
    dynamicStudents.value = list;
  }

  /// Dynamically resolves an email or domain to its on-chain organization, MSP, and network topology node
  ResolvedNetworkInfo? resolveDomainNetwork(String emailOrDomain) {
    if (emailOrDomain.trim().isEmpty) return null;

    String domain = emailOrDomain.trim().toLowerCase();
    String username = '';
    if (domain.contains('@')) {
      final parts = domain.split('@');
      username = parts[0].trim();
      domain = parts.length > 1 ? parts[1].trim() : '';
    }

    if (domain.isEmpty) return null;

    // Check active / on-chain institutions from InstitutionGovernanceService
    final registeredInsts = InstitutionGovernanceService().institutions.value;
    final match = registeredInsts.where((i) {
      final d = i.domain.trim().toLowerCase();
      return domain == d || domain.endsWith('.$d') || d.contains(domain);
    }).firstOrNull;

    if (match != null) {
      final isStudent = username.startsWith('stu') ||
          username.contains('student') ||
          dynamicStudents.value.any((s) => (s['studentId'] ?? s['candidateId'] ?? '').toString().toLowerCase() == username);

      final isVerifier = match.type == InstitutionType.bank || username.contains('verifier') || username.contains('compliance');

      IdPlusRole role = IdPlusRole.universityManagement;
      if (isStudent) {
        role = IdPlusRole.student;
      } else if (isVerifier) {
        role = IdPlusRole.thirdPartyVerifier;
      }

      return ResolvedNetworkInfo(
        domain: domain,
        organizationNameEn: match.nameEn,
        organizationNameAr: match.nameAr,
        mspId: match.orgMspId,
        channel: match.channelName,
        peerEndpoint: match.peerEndpoint,
        nodeRole: '${match.typeLabelEn} Node',
        detectedRole: role,
        isRegistered: match.isActive,
        institution: match,
      );
    }

    // Static known network domains fallback
    if (domain == 'nuvte.edu.ps') {
      final isStu = username.startsWith('stu') || username.contains('student') || username.isEmpty;
      return ResolvedNetworkInfo(
        domain: domain,
        organizationNameEn: 'Nablus University for Vocational & Technical Education',
        organizationNameAr: 'جامعة نابلس للتعليم المهني والتقني',
        mspId: 'NUVTEMSP',
        peerEndpoint: 'peer0.nuvte.edu.ps:7051',
        nodeRole: 'Genesis Academic Peer & Channel Creator',
        detectedRole: isStu ? IdPlusRole.student : IdPlusRole.universityManagement,
        isRegistered: true,
      );
    }

    if (domain == 'birzeit.edu' || domain == 'bzu.edu.ps') {
      return ResolvedNetworkInfo(
        domain: domain,
        organizationNameEn: 'Birzeit University (Faculty of Graduate Studies)',
        organizationNameAr: 'جامعة بيرزيت (عمادة الدراسات العليا)',
        mspId: 'BZUMSP',
        peerEndpoint: 'peer0.bzu.edu.ps:8051',
        nodeRole: 'Academic Consortium Node',
        detectedRole: username.startsWith('stu') ? IdPlusRole.student : IdPlusRole.universityManagement,
        isRegistered: true,
      );
    }

    if (domain == 'alquds.edu') {
      return ResolvedNetworkInfo(
        domain: domain,
        organizationNameEn: 'Al-Quds University (Faculty of Medicine)',
        organizationNameAr: 'جامعة القدس (كلية الطب البشري والعلوم الصحية)',
        mspId: 'AQUMSP',
        peerEndpoint: 'peer0.alquds.edu.ps:9051',
        nodeRole: 'Medical & Academic Authority Node',
        detectedRole: username.startsWith('stu') ? IdPlusRole.student : IdPlusRole.universityManagement,
        isRegistered: true,
      );
    }

    if (domain == 'mohe.pna.ps') {
      return ResolvedNetworkInfo(
        domain: domain,
        organizationNameEn: 'Ministry of Higher Education & Scientific Research',
        organizationNameAr: 'وزارة التعليم العالي والبحث العلمي الفلسطينية',
        mspId: 'MOHEMSP',
        peerEndpoint: 'peer0.mohe.pna.ps:10051',
        nodeRole: 'Sovereign Accreditation Authority Node',
        detectedRole: IdPlusRole.universityManagement,
        isRegistered: true,
      );
    }

    if (domain == 'bankofpalestine.com' || domain == 'bop.ps') {
      return ResolvedNetworkInfo(
        domain: domain,
        organizationNameEn: 'Bank of Palestine (Compliance & KYC Node)',
        organizationNameAr: 'بنك فلسطين (دائرة الامتثال والتحقق الرقمي)',
        mspId: 'BOPMSP',
        peerEndpoint: 'peer0.bop.ps:7051',
        nodeRole: 'Authorized Financial Verifier Node',
        detectedRole: IdPlusRole.thirdPartyVerifier,
        isRegistered: true,
      );
    }

    if (domain == 'pma.gov.ps') {
      return ResolvedNetworkInfo(
        domain: domain,
        organizationNameEn: 'Palestine Monetary Authority (PMA Orderer)',
        organizationNameAr: 'سلطة النقد الفلسطينية - أوردرير الشبكة',
        mspId: 'PMAOrdererMSP',
        peerEndpoint: 'orderer.pma.gov.ps:7050',
        nodeRole: 'Consensus Orderer (Raft Leader)',
        detectedRole: IdPlusRole.universityManagement,
        isRegistered: true,
      );
    }

    // Generic newly entered educational / organizational domain
    return ResolvedNetworkInfo(
      domain: domain,
      organizationNameEn: 'Organization Domain ($domain)',
      organizationNameAr: 'نطاق مؤسسي مسجل ($domain)',
      mspId: '${domain.split('.').first.toUpperCase()}MSP',
      peerEndpoint: 'peer0.$domain:7051',
      nodeRole: 'Dynamic Consortium Participant Node',
      detectedRole: username.startsWith('stu') ? IdPlusRole.student : IdPlusRole.universityManagement,
      isRegistered: false,
    );
  }

  /// Log in with email and password, auto-detecting the registered network organization
  Future<Map<String, dynamic>> loginWithEmailAndDomain({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) {
      return {'success': false, 'error': 'Please enter your institutional email address.'};
    }
    if (password.trim().isEmpty) {
      return {'success': false, 'error': 'Please enter your password or PIN.'};
    }

    final netInfo = resolveDomainNetwork(email);
    final cleanEmail = email.trim().toLowerCase();
    final username = cleanEmail.split('@').first;
    final now = DateTime.now();

    IdPlusUserSession session;

    if (netInfo != null && netInfo.detectedRole == IdPlusRole.thirdPartyVerifier) {
      session = await loginAsThirdParty(skipDelay: true);
    } else if (netInfo != null && netInfo.detectedRole == IdPlusRole.student) {
      // Find or create student session
      final studentId = dynamicStudents.value.isNotEmpty
          ? (dynamicStudents.value.first['studentId'] ?? dynamicStudents.value.first['candidateId'] ?? 'STU-2024098')
          : 'STU-2024098';
      session = await loginAsStudent(studentId, skipDelay: true);
    } else {
      // University Management / Registrar for this specific institution
      final inst = netInfo?.institution;
      final adminNameEn = inst?.adminNameEn ?? (cleanEmail.contains('nuvte') ? universityEmployee['fullNameEn'] : 'Authorized Dean / Registrar');
      final adminNameAr = inst?.adminNameAr ?? (cleanEmail.contains('nuvte') ? universityEmployee['fullNameAr'] : 'عميد القبول والتسجيل المعتمد');
      final msp = netInfo?.mspId ?? 'NUVTEMSP';
      final orgNameEn = netInfo?.organizationNameEn ?? 'NUVTE';
      final orgNameAr = netInfo?.organizationNameAr ?? 'جامعة نابلس';

      session = IdPlusUserSession(
        nationalId: inst?.adminDid ?? '900123841',
        fullNameEn: adminNameEn,
        fullNameAr: adminNameAr,
        role: IdPlusRole.universityManagement,
        roleTitleEn: 'Registrar & Authority • $orgNameEn ($msp)',
        roleTitleAr: 'عمادة القبول والتسجيل • $orgNameAr',
        token: 'idplus-jwt-$msp-${now.millisecondsSinceEpoch}',
        derivedDid: inst?.adminDid ?? 'did:key:z6Mku${msp}Authority2024',
        loginTime: now,
        metadata: {
          'mspId': msp,
          'domain': netInfo?.domain ?? 'nuvte.edu.ps',
          'peerEndpoint': netInfo?.peerEndpoint ?? 'peer0.nuvte.edu.ps:7051',
          'institutionId': inst?.id,
        },
      );
      currentUser.value = session;
    }

    return {
      'success': true,
      'session': session,
      'role': session.role,
      'networkInfo': netInfo,
    };
  }

  /// Log in as a dynamic enrolled student
  Future<IdPlusUserSession> loginAsStudent(String studentId, {bool skipDelay = false}) async {
    if (!skipDelay) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    
    // Find in dynamic students or create session from ID
    final profile = dynamicStudents.value.firstWhere(
      (p) => (p['studentId'] == studentId || p['candidateId'] == studentId),
      orElse: () => {
        'studentId': studentId,
        'candidateId': studentId,
        'nationalId': '983421560',
        'fullNameEn': 'Enrolled Student ($studentId)',
        'fullNameAr': 'طالب مسجل ($studentId)',
        'programEn': 'B.Sc. Cybersecurity & Digital Forensics',
        'programAr': 'بكالوريوس هندسة أنظمة الحاسوب والأمن السيبراني',
        'derivedDid': 'did:paldfi:face:$studentId',
      },
    );

    final now = DateTime.now();
    final sId = profile['studentId'] ?? profile['candidateId'] ?? studentId;
    final fullNameEn = profile['fullNameEn'] ?? 'Enrolled Student';
    final fullNameAr = profile['fullNameAr'] ?? 'طالب مسجل';
    final natId = profile['nationalId'] ?? '983421560';
    final progEn = profile['programEn'] ?? 'B.Sc. in Computer Systems & Cybersecurity';
    final progAr = profile['programAr'] ?? 'بكالوريوس هندسة أنظمة الحاسوب والأمن السيبراني';
    final did = profile['derivedDid'] ?? 'did:paldfi:face:${sId.toLowerCase()}';

    final session = IdPlusUserSession(
      nationalId: natId,
      studentId: sId,
      fullNameEn: fullNameEn,
      fullNameAr: fullNameAr,
      role: IdPlusRole.student,
      roleTitleEn: 'Enrolled NUVTE Student • $progEn',
      roleTitleAr: 'طالب مسجل - جامعة نابلس • $progAr',
      token: 'idplus-jwt-$sId-${now.millisecondsSinceEpoch}',
      derivedDid: did,
      loginTime: now,
      metadata: profile['metadata'] ?? {},
    );

    currentUser.value = session;
    return session;
  }

  /// Log in as University Registrar
  Future<IdPlusUserSession> loginAsUniversityManagement({bool skipDelay = false}) async {
    if (!skipDelay) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    final now = DateTime.now();
    final session = IdPlusUserSession(
      nationalId: universityEmployee['nationalId']!,
      fullNameEn: universityEmployee['fullNameEn']!,
      fullNameAr: universityEmployee['fullNameAr']!,
      role: IdPlusRole.universityManagement,
      roleTitleEn: universityEmployee['roleTitleEn']!,
      roleTitleAr: universityEmployee['roleTitleAr']!,
      token: 'idplus-jwt-registrar-${now.millisecondsSinceEpoch}',
      derivedDid: 'did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA',
      loginTime: now,
    );

    currentUser.value = session;
    return session;
  }

  /// Log in as Third-Party Verifier (Bank of Palestine)
  Future<IdPlusUserSession> loginAsThirdParty({bool skipDelay = false}) async {
    if (!skipDelay) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    final now = DateTime.now();
    final session = IdPlusUserSession(
      nationalId: thirdPartyProfile['nationalId']!,
      fullNameEn: thirdPartyProfile['fullNameEn']!,
      fullNameAr: thirdPartyProfile['fullNameAr']!,
      role: IdPlusRole.thirdPartyVerifier,
      roleTitleEn: thirdPartyProfile['roleTitleEn']!,
      roleTitleAr: thirdPartyProfile['roleTitleAr']!,
      token: 'idplus-jwt-verifier-${now.millisecondsSinceEpoch}',
      derivedDid: thirdPartyProfile['verifierDid']!,
      loginTime: now,
    );

    currentUser.value = session;
    return session;
  }

  /// Role login
  Future<IdPlusUserSession> loginWithRole(IdPlusRole role, {bool skipDelay = false, String? studentId}) async {
    switch (role) {
      case IdPlusRole.student:
        return loginAsStudent(studentId ?? (dynamicStudents.value.isNotEmpty ? (dynamicStudents.value.first['studentId'] ?? dynamicStudents.value.first['candidateId']) : 'STU-NEW'), skipDelay: skipDelay);
      case IdPlusRole.universityManagement:
        return loginAsUniversityManagement(skipDelay: skipDelay);
      case IdPlusRole.thirdPartyVerifier:
        return loginAsThirdParty(skipDelay: skipDelay);
    }
  }

  void logout() {
    currentUser.value = null;
  }
}
