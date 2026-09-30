import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/student_profile.dart';
import '../core/models/verifiable_credential.dart';
import '../core/services/face_recognition_service.dart';
import '../core/services/id_plus_auth_service.dart';
import '../core/services/wallet_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_footer.dart';
import '../widgets/face_camera_view.dart';

class StudentOnboardingScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final VoidCallback? onCancel;

  const StudentOnboardingScreen({
    super.key,
    this.onCompleted,
    this.onCancel,
  });

  @override
  State<StudentOnboardingScreen> createState() => _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0; // 0: Student Info, 1: Face Biometrics Scan, 2: Blockchain & Vector Anchor, 3: Success

  // Controllers
  final _fullNameEnController = TextEditingController(text: 'Amjad Khaliliah');
  final _fullNameArController = TextEditingController(text: 'أمجد خليلية');
  final _nationalIdController = TextEditingController(text: '983421560');
  final _studentIdController = TextEditingController(text: 'STU-2024098');
  final _gpaController = TextEditingController(text: '3.88');

  String _selectedFaculty = 'Faculty of Engineering & Technology';
  String _selectedProgram = 'B.Sc. in Computer Systems & Cybersecurity';
  String _selectedBloodType = 'O+';

  final List<String> _faculties = [
    'Faculty of Engineering & Technology',
    'Faculty of Applied & Vocational Sciences',
    'Faculty of Vocational Business',
    'Faculty of Digital Health Sciences',
  ];

  final Map<String, List<String>> _facultyPrograms = {
    'Faculty of Engineering & Technology': [
      'B.Sc. in Computer Systems & Cybersecurity',
      'B.Sc. in Software Engineering & AI',
      'B.Sc. in Telecommunications & IoT',
    ],
    'Faculty of Applied & Vocational Sciences': [
      'B.Tech. in Renewable Energy Technologies',
      'B.Tech. in Mechatronics & Robotics',
      'B.Tech. in Industrial Automation',
    ],
    'Faculty of Vocational Business': [
      'Diploma in Digital Financial Technologies',
      'B.Sc. in FinTech & Blockchain Systems',
      'B.Sc. in Business Data Analytics',
    ],
    'Faculty of Digital Health Sciences': [
      'B.Sc. in Medical Informatics & Bioinformatics',
      'Diploma in Digital Healthcare Operations',
    ],
  };

  // State for Face Biometrics
  bool _isCameraStreaming = false;
  String? _capturedFaceBase64;
  bool _isProcessing = false;
  String _processingStage = '';
  double _processingProgress = 0.0;

  // Output Result
  Map<String, dynamic>? _onboardingResult;

  @override
  void dispose() {
    _fullNameEnController.dispose();
    _fullNameArController.dispose();
    _nationalIdController.dispose();
    _studentIdController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  void _onNextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() {
          _currentStep = 1;
        });
      }
    } else if (_currentStep == 1) {
      _executeBiometricOnboarding();
    }
  }

  Future<void> _executeBiometricOnboarding() async {
    setState(() {
      _currentStep = 2;
      _isProcessing = true;
      _processingProgress = 0.15;
      _processingStage = '1/4: Extracting 128-D Biometric Facial Vector Embedding...';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _processingProgress = 0.45;
      _processingStage = '2/4: Storing Biometric Vector into PMA ID+ Vector Database...';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _processingProgress = 0.75;
      _processingStage = '3/4: Executing Hyperledger Fabric Smart Contract (AnchorDocument)...';
    });

    final res = await WalletStorageService().onboardNewStudent(
      fullNameEn: _fullNameEnController.text.trim(),
      fullNameAr: _fullNameArController.text.trim(),
      nationalId: _nationalIdController.text.trim(),
      studentId: _studentIdController.text.trim(),
      facultyEn: _selectedFaculty,
      facultyAr: _getFacultyAr(_selectedFaculty),
      programEn: _selectedProgram,
      programAr: _getProgramAr(_selectedProgram),
      gpa: double.tryParse(_gpaController.text.trim()) ?? 3.85,
      bloodType: _selectedBloodType,
      base64Face: _capturedFaceBase64 ?? '',
    );

    setState(() {
      _processingProgress = 1.0;
      _processingStage = '4/4: Biometric DID & W3C Verifiable Credential Generated!';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isProcessing = false;
      _onboardingResult = res;
      _currentStep = 3;
    });
  }

  String _getFacultyAr(String en) {
    switch (en) {
      case 'Faculty of Engineering & Technology':
        return 'كلية الهندسة والتكنولوجيا';
      case 'Faculty of Applied & Vocational Sciences':
        return 'كلية المهن والعلوم التطبيقية';
      case 'Faculty of Vocational Business':
        return 'كلية الأعمال المهنية والتقنية';
      default:
        return 'كلية العلوم الصحية الرقمية';
    }
  }

  String _getProgramAr(String en) {
    if (en.contains('Cybersecurity')) return 'بكالوريوس هندسة أنظمة الحاسوب والأمن السيبراني';
    if (en.contains('Software')) return 'بكالوريوس هندسة البرمجيات والذكاء الاصطناعي';
    if (en.contains('Renewable')) return 'بكالوريوس تكنولوجيا الطاقة المتجددة';
    if (en.contains('Financial')) return 'دبلوم التكنولوجيا المالية الرقمية';
    if (en.contains('FinTech')) return 'بكالوريوس التكنولوجيا المالية وسلاسل الكتل';
    return 'بكالوريوس المعلوماتية الطبية الرقمية';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: _buildCurrentStepContent(),
                  ),
                ),
              ),
            ),
            const BrandFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.midnightCard,
        border: Border(bottom: BorderSide(color: AppColors.goldAccent.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: widget.onCancel ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student Onboarding • تسجيل طالب جديد',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'PMA ID+ Biometric Enclave & Hyperledger Fabric',
                  style: TextStyle(
                    color: AppColors.electricCyan,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.goldAccent.withOpacity(0.4)),
            ),
            child: Text(
              'Step ${_currentStep + 1} / 4',
              style: const TextStyle(
                color: AppColors.goldAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0StudentInfo();
      case 1:
        return _buildStep1FaceScan();
      case 2:
        return _buildStep2Processing();
      case 3:
        return _buildStep3Success();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep0StudentInfo() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardContainer(
            title: '1. Personal & Academic Credentials',
            icon: Icons.person_add_alt_1,
            child: Column(
              children: [
                TextFormField(
                  controller: _fullNameEnController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Full Name (English)', 'e.g. Amjad Khaliliah', Icons.badge_outlined),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter English name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullNameArController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('الاسم الكامل (بالعربية)', 'مثال: أمجد خليلية', Icons.badge),
                  validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال الاسم بالعربية' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nationalIdController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('National ID (9 digits)', '983421560', Icons.fingerprint),
                        validator: (v) => (v == null || v.length < 8) ? 'Enter valid ID' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _studentIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Student ID', 'STU-2024098', Icons.numbers),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter Student ID' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedFaculty,
                  dropdownColor: AppColors.midnightCard,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('Faculty / الكلية', '', Icons.school),
                  items: _faculties.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedFaculty = val;
                        _selectedProgram = _facultyPrograms[val]!.first;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedProgram,
                  dropdownColor: AppColors.midnightCard,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('Academic Program / التخصص', '', Icons.menu_book),
                  items: (_facultyPrograms[_selectedFaculty] ?? [])
                      .map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProgram = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gpaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('GPA (Max 4.0)', '3.88', Icons.grade),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter GPA' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBloodType,
                        dropdownColor: AppColors.midnightCard,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _inputDecoration('Blood Type', '', Icons.bloodtype),
                        items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                            .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedBloodType = v ?? 'O+'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            label: 'Proceed to Biometric Face Scan • متابعة لبصمة الوجه',
            icon: Icons.face,
            onPressed: _onNextStep,
          ),
        ],
      ),
    );
  }

  Widget _buildStep1FaceScan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardContainer(
          title: '2. PMA Biometric Enclave Face Capture',
          icon: Icons.camera_front,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.electricCyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.electricCyan.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.electricCyan, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'PMA ID+ will capture 68 3D facial landmarks, extract a 128-D vector embedding, and anchor it in the Biometric Vector Database.',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Live camera preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 280,
                  width: double.infinity,
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FaceCameraView(
                        isStreaming: true,
                        onFrameCaptured: (base64) {
                          _capturedFaceBase64 = base64;
                        },
                      ),
                      // Holographic Face Mesh HUD
                      Container(
                        width: 170,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(85),
                          border: Border.all(
                            color: AppColors.goldAccent.withOpacity(0.8),
                            width: 2.0,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.electricCyan.withOpacity(0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: AppColors.electricCyan, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Powered By ID+ - PMA • Biometric Enclave',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Candidate: ${_fullNameEnController.text} (${_studentIdController.text})',
                style: const TextStyle(
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => setState(() => _currentStep = 0),
                child: const Text('Back / السابق', style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildActionButton(
                label: 'Capture & Deploy to Ledger • اعتماد وتسجيل',
                icon: Icons.fingerprint,
                onPressed: _onNextStep,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Processing() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.midnightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.electricCyan.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Deploying Student Identity to Blockchain',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _processingStage,
            style: TextStyle(
              color: AppColors.electricCyan.withOpacity(0.9),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: _processingProgress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.electricCyan),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 16),
          Text(
            'Channel: nuvte-academic-channel | Peer: peer0.nuvte.edu.ps:7051',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Success() {
    final did = _onboardingResult?['derivedDid'] ?? 'did:paldfi:face:unknown';
    final txId = _onboardingResult?['txId'] ?? 'tx-onboard-success';
    final docId = _onboardingResult?['docId'] ?? 'DOC-NUVTE-2024-STU-098';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.midnightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.goldAccent.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldAccent.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emeraldGreen.withOpacity(0.2),
                  border: Border.all(color: AppColors.emeraldGreen, width: 2),
                ),
                child: const Icon(Icons.check, color: AppColors.emeraldGreen, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Student Onboarded Successfully!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'تم تسجيل الطالب وتوثيق الهوية الرقمية بنجاح على البلوكشين',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 20),
              _buildInfoRow('Student ID', _studentIdController.text),
              _buildInfoRow('Full Name', _fullNameEnController.text),
              _buildInfoRow('National ID', _nationalIdController.text),
              _buildInfoRow('Program', _selectedProgram),
              _buildInfoRow('On-Chain Document', docId),
              _buildInfoRow('Transaction ID', txId, isMonospace: true),
              _buildInfoRow('Sovereign Face DID', did, isMonospace: true, isHighlight: true),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.goldAccent.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: AppColors.goldAccent, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '128-D Biometric Vector stored in PMA ID+ Database. You can now login instantly using Face Recognition Search!',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          label: 'Launch Sovereign Wallet • دخول المحفظة',
          icon: Icons.account_balance_wallet,
          onPressed: () async {
            await IdPlusAuthService().loginAsStudent(_studentIdController.text.trim());
            widget.onCompleted?.call();
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: isHighlight ? AppColors.goldAccent : Colors.white60,
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isHighlight ? AppColors.electricCyan : Colors.white,
                fontSize: 12,
                fontFamily: isMonospace ? 'monospace' : null,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.midnightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.goldAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
      prefixIcon: Icon(icon, color: AppColors.goldAccent, size: 18),
      filled: true,
      fillColor: Colors.black26,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.electricCyan),
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.goldAccent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
