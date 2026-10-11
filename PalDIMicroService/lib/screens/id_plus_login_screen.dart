import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/face_recognition_service.dart';
import '../core/services/id_plus_auth_service.dart';
import '../core/services/institution_governance_service.dart';
import '../core/services/wallet_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_footer.dart';
import '../widgets/face_recognition_dialog.dart';
import 'student_onboarding_screen.dart';

class IdPlusLoginScreen extends StatefulWidget {
  final Function(IdPlusRole role) onRoleSelected;
  final VoidCallback? onOpenAdminPortal;

  const IdPlusLoginScreen({
    super.key,
    required this.onRoleSelected,
    this.onOpenAdminPortal,
  });

  @override
  State<IdPlusLoginScreen> createState() => _IdPlusLoginScreenState();
}

class _IdPlusLoginScreenState extends State<IdPlusLoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _authTabController;
  final FaceRecognitionService _faceService = FaceRecognitionService();

  // Email & Domain Login State
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  ResolvedNetworkInfo? _detectedNetwork;
  String? _errorMessage;

  bool _isLoading = false;
  bool _isOnboarding = false;

  @override
  void initState() {
    super.initState();
    _authTabController = TabController(length: 2, vsync: this);
    _emailController.addListener(_onEmailChanged);
    _refreshState();
  }

  @override
  void dispose() {
    _authTabController.dispose();
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final text = _emailController.text.trim();
    if (text.isNotEmpty) {
      final info = IdPlusAuthService().resolveDomainNetwork(text);
      setState(() {
        _detectedNetwork = info;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _detectedNetwork = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _refreshState() async {
    await IdPlusAuthService().loadDynamicStudents();
    await InstitutionGovernanceService().syncWithBlockchain();
    await WalletStorageService().syncWithBlockchainLedger();
    if (mounted) setState(() {});
  }

  Future<void> _handleStudentLogin(String studentId) async {
    setState(() => _isLoading = true);
    await WalletStorageService().loadStudentWallet(studentId);
    await IdPlusAuthService().loginAsStudent(studentId);
    if (!mounted) return;
    setState(() => _isLoading = false);
    widget.onRoleSelected(IdPlusRole.student);
  }

  Future<void> _handleRoleLogin(IdPlusRole role) async {
    setState(() => _isLoading = true);
    if (role == IdPlusRole.universityManagement) {
      await IdPlusAuthService().loginAsUniversityManagement();
    } else if (role == IdPlusRole.thirdPartyVerifier) {
      await IdPlusAuthService().loginAsThirdParty();
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    widget.onRoleSelected(role);
  }

  Future<void> _handleEmailPasswordLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = AppLocalizations.isArabic
          ? 'يرجى إدخال البريد الإلكتروني المؤسسي'
          : 'Please enter your institutional email');
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = AppLocalizations.isArabic
          ? 'يرجى إدخال كلمة المرور'
          : 'Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await IdPlusAuthService().loginWithEmailAndDomain(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final role = res['role'] as IdPlusRole;
      if (role == IdPlusRole.student) {
        final session = res['session'] as IdPlusUserSession;
        if (session.studentId != null) {
          await WalletStorageService().loadStudentWallet(session.studentId!);
        }
      }
      widget.onRoleSelected(role);
    } else {
      setState(() {
        _errorMessage = res['error']?.toString() ?? 'Authentication failed';
      });
    }
  }

  void _openVectorFaceSearchLogin() {
    FaceRecognitionDialog.show(
      context: context,
      onAuthenticated: (result) async {
        if (result.role == 'student' || result.candidateId.startsWith('STU-')) {
          await _handleStudentLogin(result.candidateId);
        } else if (result.role == 'universityManagement' || result.candidateId.startsWith('EMP-')) {
          await _handleRoleLogin(IdPlusRole.universityManagement);
        } else {
          await _handleRoleLogin(IdPlusRole.thirdPartyVerifier);
        }
      },
    );
  }

  void _fillPreset(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
    _onEmailChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnboarding) {
      return StudentOnboardingScreen(
        onCancel: () => setState(() => _isOnboarding = false),
        onCompleted: () {
          setState(() => _isOnboarding = false);
          widget.onRoleSelected(IdPlusRole.student);
        },
      );
    }

    final isArabic = AppLocalizations.isArabic;

    return Directionality(
      textDirection: AppLocalizations.textDirection,
      child: Scaffold(
        backgroundColor: AppColors.obsidianBlack,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top header: Sandbox badge, Language toggle, Admin link
                    _buildTopBar(isArabic),
                    const SizedBox(height: 18),

                    // Brand Title & Logo
                    _buildBrandHeader(isArabic),
                    const SizedBox(height: 22),

                    // Primary Action Banner: Start With New Student Onboarding
                    _buildOnboardingBanner(isArabic),
                    const SizedBox(height: 18),

                    // Unified Authentication Mode Switcher (Tabs)
                    _buildAuthModeTabs(isArabic),
                    const SizedBox(height: 16),

                    // Active Tab View Content
                    AnimatedBuilder(
                      animation: _authTabController,
                      builder: (context, _) {
                        if (_authTabController.index == 0) {
                          return _buildFaceIdModeView(isArabic);
                        } else {
                          return _buildEmailDomainModeView(isArabic);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Admin Portal Shortcut
                    _buildAdminPortalShortcut(isArabic),
                    const SizedBox(height: 20),

                    const BrandFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isArabic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.goldAccent.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: AppColors.emeraldGreen, size: 8),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'PMA Sandbox • Live Fabric',
                    style: TextStyle(
                      color: AppColors.goldAccent,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  AppLocalizations.toggleLanguage();
                });
              },
              icon: const Icon(Icons.language, color: AppColors.goldAccent, size: 16),
              label: Text(
                isArabic ? 'English' : 'العربية',
                style: const TextStyle(color: AppColors.goldAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: isArabic ? 'بوابة الحوكمة والأوردرير' : 'Open Admin & Governance Portal',
              icon: const Icon(Icons.admin_panel_settings, color: AppColors.electricCyan),
              onPressed: widget.onOpenAdminPortal ?? () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrandHeader(bool isArabic) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00A3FF), Color(0xFFD4AF37)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldAccent.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.black, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            'PAL-DFI Sovereign Wallet',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'المحفظة الرقمية السيادية للهوية والأوراق الأكاديمية'
                : 'Palestinian Decentralized Identity & Academic Wallet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingBanner(bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.goldAccent.withOpacity(0.25),
            AppColors.electricCyan.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldAccent.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldAccent.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.how_to_reg, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'تسجيل طالب جديد (Start Onboarding)' : 'Start New Student Onboarding',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      isArabic ? 'بصمة الوجه • حفظ المتجهات • توثيق البلوكشين' : 'Face Scan • 128-D Vector DB • Fabric Smart Contract',
                      style: const TextStyle(color: AppColors.goldAccent, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              icon: const Icon(Icons.fingerprint, size: 18),
              label: Text(
                isArabic ? 'بدء تسجيل الطالب الآن' : 'Start Student Onboarding Now',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              onPressed: () => setState(() => _isOnboarding = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthModeTabs(bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TabBar(
        controller: _authTabController,
        indicator: BoxDecoration(
          color: AppColors.goldAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
        tabs: [
          Tab(
            icon: const Icon(Icons.face_retouching_natural, size: 18),
            text: isArabic ? 'بصمة الوجه (Face ID)' : 'Biometric Face ID',
          ),
          Tab(
            icon: const Icon(Icons.domain, size: 18),
            text: isArabic ? 'البريد والنطاق (Email & Domain)' : 'Email & Network Domain',
          ),
        ],
        onTap: (_) => setState(() {}),
      ),
    );
  }

  // --- TAB 1: BIOMETRIC FACE ID LOGIN ---
  Widget _buildFaceIdModeView(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F2243),
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppColors.electricCyan, width: 1.4),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 3,
          ),
          onPressed: _openVectorFaceSearchLogin,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, color: AppColors.electricCyan, size: 24),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isArabic ? 'تسجيل الدخول عبر مسح الوجه (Scan Face)' : 'Scan Face to Authenticate',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    Text(
                      'Powered By ID+ - PMA • 128-D Cosine Similarity',
                      style: TextStyle(color: AppColors.electricCyan.withOpacity(0.85), fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Dynamic Enrolled Students in Vector DB
        _buildEnrolledStudentsSection(isArabic),
        const SizedBox(height: 18),

        // Institutional Portals
        _buildRoleSelectionCards(isArabic),
      ],
    );
  }

  // --- TAB 2: EMAIL & DOMAIN-BASED NETWORK LOGIN ---
  Widget _buildEmailDomainModeView(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.midnightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldAccent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.hub, color: AppColors.goldAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'الدخول عبر البريد والنطاق المؤسسي' : 'Institutional Email & Network Domain',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'يتم التعرف تلقائياً على المؤسسة (NUVTE, Birzeit, Al-Quds, BOP...) وقناة البلوكشين وMSP ID من نطاق البريد.'
                : 'System auto-inspects the email domain to resolve the registered blockchain organization, channel & MSP ID.',
            style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11),
          ),
          const SizedBox(height: 14),

          // Email Field
          TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              labelText: isArabic ? 'البريد الإلكتروني المؤسسي' : 'Institutional Email Address',
              labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
              hintText: 'e.g. student@nuvte.edu.ps or admin@birzeit.edu',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              prefixIcon: const Icon(Icons.email, color: AppColors.goldAccent, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.goldAccent),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Password Field
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              labelText: isArabic ? 'كلمة المرور / الرمز السري' : 'Password / Security PIN',
              labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
              hintText: '••••••••',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              prefixIcon: const Icon(Icons.lock, color: AppColors.goldAccent, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.goldAccent),
              ),
            ),
            onSubmitted: (_) => _handleEmailPasswordLogin(),
          ),
          const SizedBox(height: 12),

          // Real-time Dynamic Network Resolution Badge
          if (_detectedNetwork != null) _buildDetectedNetworkBadge(isArabic),

          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.crimsonRevoked.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.crimsonRevoked.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.crimsonRevoked, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.crimsonRevoked, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Login Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              onPressed: _isLoading ? null : _handleEmailPasswordLogin,
              child: _isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'تسجيل الدخول والربط بالشبكة' : 'Authenticate & Enter Network',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Preset Quick Selectors
          _buildPresetShortcuts(isArabic),
        ],
      ),
    );
  }

  Widget _buildDetectedNetworkBadge(bool isArabic) {
    final net = _detectedNetwork!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF07192F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.electricCyan.withOpacity(0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricCyan.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.emeraldGreen, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isArabic ? net.organizationNameAr : net.organizationNameEn,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  net.mspId,
                  style: const TextStyle(color: AppColors.goldAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Channel: ${net.channel}',
                  style: const TextStyle(color: AppColors.electricCyan, fontSize: 10),
                ),
              ),
              Text(
                net.peerEndpoint,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetShortcuts(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'نماذج جاهزة للاختبار المباشر (Quick Presets):' : 'Demo Network Presets:',
          style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildPresetChip('NUVTE Registrar', 'registrar@nuvte.edu.ps', '123456'),
            _buildPresetChip('Birzeit Admin', 'admin@birzeit.edu', '123456'),
            _buildPresetChip('Al-Quds Admin', 'admissions@alquds.edu', '123456'),
            _buildPresetChip('Bank Verifier', 'compliance@bankofpalestine.com', '123456'),
            _buildPresetChip('Student (STU)', 'student@nuvte.edu.ps', '123456'),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, String email, String pwd) {
    return InkWell(
      onTap: () => _fillPreset(email, pwd),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.goldAccent, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEnrolledStudentsSection(bool isArabic) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: IdPlusAuthService().dynamicStudents,
      builder: (context, students, _) {
        if (students.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Icon(Icons.folder_open, color: Colors.white38, size: 26),
                const SizedBox(height: 6),
                Text(
                  isArabic ? 'لا يوجد طلاب مسجلون حالياً (Clean Slate)' : 'No Enrolled Students in Vector DB (Clean Slate)',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic ? 'اضغط على "تسجيل طالب جديد" بالأعلى للبدء.' : 'Click "Start Student Onboarding" above to register.',
                  style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'الطلاب المسجلون في قاعدة البيانات' : 'Enrolled Sovereign Students',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${students.length} on-chain',
                    style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...students.map((s) => _buildStudentCard(s, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, bool isArabic) {
    final sId = student['studentId'] ?? student['candidateId'] ?? 'STU-001';
    final nameEn = student['fullNameEn'] ?? 'Enrolled Student';
    final nameAr = student['fullNameAr'] ?? 'طالب مسجل';
    final progEn = student['programEn'] ?? 'B.Sc. in Computer Systems & Cybersecurity';
    final progAr = student['programAr'] ?? 'بكالوريوس هندسة أنظمة الحاسوب والأمن السيبراني';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.midnightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.goldAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.goldAccent.withOpacity(0.2),
            foregroundColor: AppColors.goldAccent,
            radius: 16,
            child: const Icon(Icons.person, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? nameAr : nameEn,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  '$sId • ${isArabic ? progAr : progEn}',
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => _handleStudentLogin(sId),
            child: Text(
              isArabic ? 'دخول' : 'Login',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelectionCards(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'بوابات الجهات المعتمدة (Institutional Portals)' : 'Ecosystem Institutional Portals',
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                title: isArabic ? 'عمادة التسجيل' : 'University Registrar',
                subtitle: 'NUVTE Faculty Node',
                icon: Icons.account_balance,
                color: AppColors.goldAccent,
                onTap: () => _handleRoleLogin(IdPlusRole.universityManagement),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleCard(
                title: isArabic ? 'الجهة المدققة' : 'Third-Party Verifier',
                subtitle: 'Bank of Palestine KYC',
                icon: Icons.verified_user,
                color: AppColors.electricCyan,
                onTap: () => _handleRoleLogin(IdPlusRole.thirdPartyVerifier),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.midnightCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
            Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPortalShortcut(bool isArabic) {
    return InkWell(
      onTap: widget.onOpenAdminPortal,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.electricCyan.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: AppColors.electricCyan, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'بوابة الحوكمة والإدارة المستقلة (Admin Portal)' : 'Dedicated Admin & Orderer Portal',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const Text(
                    'URL: /#/admin • Orderer, Smart Contract Factory, Node Explorer',
                    style: TextStyle(color: AppColors.electricCyan, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }
}
