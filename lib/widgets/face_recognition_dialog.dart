import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/face_recognition_service.dart';
import '../core/services/id_plus_auth_service.dart';
import '../theme/app_theme.dart';
import 'face_camera_view.dart';

enum FaceScanStage {
  initiating,
  scanningGeometry,
  vectorSearching,
  generatingDid,
  completed,
  noMatchFound,
  failed,
}

class FaceRecognitionDialog extends StatefulWidget {
  final String? candidateIdHint;
  final Function(FaceRecognitionResult result) onAuthenticated;

  const FaceRecognitionDialog({
    super.key,
    this.candidateIdHint,
    required this.onAuthenticated,
  });

  static Future<void> show({
    required BuildContext context,
    String? candidateIdHint,
    required Function(FaceRecognitionResult result) onAuthenticated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FaceRecognitionDialog(
        candidateIdHint: candidateIdHint,
        onAuthenticated: onAuthenticated,
      ),
    );
  }

  @override
  State<FaceRecognitionDialog> createState() => _FaceRecognitionDialogState();
}

class _FaceRecognitionDialogState extends State<FaceRecognitionDialog>
    with SingleTickerProviderStateMixin {
  final FaceRecognitionService _faceService = FaceRecognitionService();

  FaceScanStage _stage = FaceScanStage.initiating;
  FaceRecognitionResult? _result;
  String _statusMessage = 'Accessing Camera Sensor...';
  double _scanProgress = 0.0;
  String _capturedFrame = '';

  // DID Generation Animation fields
  int _didStepIndex = 0;
  String _displayedDid = '';
  String _displayedDidKey = '';

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _startFaceRecognitionFlow();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startFaceRecognitionFlow() async {
    final isArabic = AppLocalizations.isArabic;

    // Phase 1: Camera Access & Optical Alignment (0 - 1.2s)
    setState(() {
      _stage = FaceScanStage.scanningGeometry;
      _statusMessage = isArabic
          ? 'جاري فحص ملامح الوجه وتطابق الهندسة الحيوية...'
          : 'Scanning facial geometry & 3D biometric depth...';
      _scanProgress = 0.25;
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Phase 2: Vector Search with Cosine Similarity (1.2 - 2.4s)
    setState(() {
      _stage = FaceScanStage.vectorSearching;
      _statusMessage = isArabic
          ? 'البحث في قاعدة البيانات الشعاعية (Vector Database - Cosine Similarity)...'
          : 'Querying 128-D Vector Database (Cosine Similarity Search)...';
      _scanProgress = 0.60;
    });

    final res = await _faceService.searchFaceAndAuthenticate(
      base64Frame: _capturedFrame,
      candidateIdHint: widget.candidateIdHint,
    );
    _result = res;

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    if (!res.verified && !res.success) {
      setState(() {
        _stage = FaceScanStage.noMatchFound;
        _statusMessage = isArabic
            ? 'لم يتم العثور على بصمة مطابقة. يرجى تسجيل طالب جديد أولاً.'
            : 'No matching face vector found in Vector DB. Please onboard first.';
      });
      return;
    }

    // Phase 3: Holographic DID Generation Animation (2.4 - 4.5s)
    setState(() {
      _stage = FaceScanStage.generatingDid;
      _statusMessage = isArabic
          ? 'توليد المعرف اللامركزي (DID) عبر بصمة الوجه...'
          : 'Deriving Decentralized Identifier (DID) from FaceID...';
      _scanProgress = 0.85;
    });

    await _animateDidGeneration(res);

    if (!mounted) return;

    // Phase 4: Authenticated Completion
    setState(() {
      _stage = FaceScanStage.completed;
      _statusMessage = isArabic
          ? 'تم التحقق الحيوي بنجاح • جاري الدخول للمحفظة السيادية'
          : 'Biometric Vector Match Verified • Accessing Sovereign Wallet';
      _scanProgress = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    Navigator.of(context).pop();
    widget.onAuthenticated(res);
  }

  Future<void> _animateDidGeneration(FaceRecognitionResult res) async {
    final fullDid = res.derivedDid;
    final fullKey = res.didKey;

    // Step 1: Entropy Hashing
    setState(() {
      _didStepIndex = 1;
      _displayedDid = 'SHA256(FaceVector128D + PMA_Root_Salt)...';
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Step 2: Key Derivation
    setState(() {
      _didStepIndex = 2;
      _displayedDidKey = fullKey.length > 24 ? '${fullKey.substring(0, 24)}...' : fullKey;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Step 3: W3C Sovereign DID String
    setState(() {
      _didStepIndex = 3;
      _displayedDid = fullDid;
      _displayedDidKey = fullKey;
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1527),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _stage == FaceScanStage.completed
                ? AppColors.emeraldGreen
                : (_stage == FaceScanStage.noMatchFound
                    ? AppColors.crimsonRevoked
                    : AppColors.goldAccent.withOpacity(0.6)),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (_stage == FaceScanStage.completed
                      ? AppColors.emeraldGreen
                      : AppColors.goldAccent)
                  .withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildScannerBody(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111E38),
        border: Border(
          bottom: BorderSide(color: AppColors.goldAccent.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.face, color: AppColors.goldAccent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ID+ Biometric Face Recognition',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '128-D Vector Database & Cosine Similarity',
                  style: TextStyle(
                    color: AppColors.electricCyan,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (_stage != FaceScanStage.completed && _stage != FaceScanStage.generatingDid)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Camera / Holographic Scanner Viewport
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _stage == FaceScanStage.completed
                    ? AppColors.emeraldGreen
                    : AppColors.electricCyan.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FaceCameraView(
                    isStreaming: _stage != FaceScanStage.completed && _stage != FaceScanStage.noMatchFound,
                    onFrameCaptured: (base64) {
                      _capturedFrame = base64;
                    },
                  ),
                  _buildFaceTargetHud(),
                  if (_stage == FaceScanStage.generatingDid || _stage == FaceScanStage.completed)
                    _buildDidOverlay(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Status & Progress Message
          Text(
            _statusMessage,
            style: TextStyle(
              color: _stage == FaceScanStage.completed
                  ? AppColors.emeraldGreen
                  : (_stage == FaceScanStage.noMatchFound ? AppColors.crimsonRevoked : AppColors.goldAccent),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Progress Bar
          LinearProgressIndicator(
            value: _scanProgress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(
              _stage == FaceScanStage.completed
                  ? AppColors.emeraldGreen
                  : (_stage == FaceScanStage.noMatchFound ? AppColors.crimsonRevoked : AppColors.electricCyan),
            ),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),

          if (_result != null && _result!.verified) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.emeraldGreen, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Matched: ${_result!.fullNameEn} (${_result!.candidateId}) • Cosine Sim: ${(_result!.similarityScore * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],

          if (_stage == FaceScanStage.noMatchFound) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Start Student Onboarding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaceTargetHud() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final scale = 1.0 + (_pulseCtrl.value * 0.04);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 130,
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(65),
              border: Border.all(
                color: _stage == FaceScanStage.completed
                    ? AppColors.emeraldGreen
                    : AppColors.goldAccent.withOpacity(0.8),
                width: 2.0,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDidOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_open, color: AppColors.goldAccent, size: 28),
          const SizedBox(height: 8),
          const Text(
            'Biometric Sovereign DID Derived',
            style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            _displayedDid,
            style: GoogleFonts.firaCode(color: AppColors.electricCyan, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF080D1A),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, color: AppColors.goldAccent, size: 14),
          SizedBox(width: 6),
          Text(
            'Powered By ID+ - PMA • Biometric Enclave',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
