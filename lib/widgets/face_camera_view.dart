import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// Conditional helper for web camera stream if running in browser
import 'face_web_camera_stub.dart'
    if (dart.library.html) 'face_web_camera_web.dart';

class FaceCameraView extends StatefulWidget {
  final bool isScanning;
  final bool isVerified;
  final String statusText;
  final String candidateName;
  final bool isStreaming;
  final Function(String base64Frame)? onFrameCaptured;

  const FaceCameraView({
    super.key,
    this.isScanning = true,
    this.isVerified = false,
    this.statusText = 'Align your face inside biometric frame',
    this.candidateName = 'Citizen FaceID',
    this.isStreaming = true,
    this.onFrameCaptured,
  });

  @override
  State<FaceCameraView> createState() => _FaceCameraViewState();
}

class _FaceCameraViewState extends State<FaceCameraView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  bool _cameraActive = false;
  final String _viewId = 'face-cam-view-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      final active = await initializeWebCamera(_viewId);
      if (mounted) {
        setState(() => _cameraActive = active);
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    if (kIsWeb) {
      disposeWebCamera(_viewId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: AppColors.obsidianBlack,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isVerified
                ? AppColors.statusActive
                : (widget.isScanning ? AppColors.goldPrimary : AppColors.slateCardBorder),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isVerified
                  ? AppColors.statusActive.withAlpha(60)
                  : (widget.isScanning
                      ? AppColors.goldPrimary.withAlpha(50)
                      : Colors.transparent),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Live Camera Feed if on Web with permission
            if (kIsWeb && _cameraActive)
              Positioned.fill(
                child: buildWebCameraWidget(_viewId),
              )
            else
              // High-tech dark gradient backdrop
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.9,
                      colors: [
                        Color(0xFF0F1B2E),
                        Color(0xFF090E17),
                        AppColors.obsidianBlack,
                      ],
                    ),
                  ),
                ),
              ),

            // 2. Animated 68-Point Biometric Facial Mesh Painter
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: BiometricFaceMeshPainter(
                      progress: _animCtrl.value,
                      isVerified: widget.isVerified,
                      isScanning: widget.isScanning,
                    ),
                  );
                },
              ),
            ),

            // 3. Top Biometric HUD Stats
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.obsidianBlack.withAlpha(190),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.isVerified
                            ? AppColors.statusActive
                            : AppColors.goldPrimary.withAlpha(140),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isVerified
                                ? AppColors.statusActive
                                : (_cameraActive
                                    ? AppColors.statusActive
                                    : AppColors.goldLight),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _cameraActive ? 'LIVE WEBCAM' : 'FRONT SENSOR',
                          style: GoogleFonts.robotoMono(
                            color: AppColors.textLight,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.obsidianBlack.withAlpha(190),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.slateCardBorder),
                    ),
                    child: Text(
                      'PMA-ENCLAVE: 68-D MESH',
                      style: GoogleFonts.robotoMono(
                        color: AppColors.goldLight,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Bottom Status HUD
            Positioned(
              bottom: 10,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.obsidianBlack.withAlpha(210),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isVerified
                        ? AppColors.statusActive
                        : AppColors.goldPrimary.withAlpha(120),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isVerified
                          ? Icons.check_circle_rounded
                          : Icons.center_focus_strong_rounded,
                      color: widget.isVerified
                          ? AppColors.statusActive
                          : AppColors.goldPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.statusText,
                        style: GoogleFonts.cairo(
                          color: AppColors.textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isScanning && !widget.isVerified)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BiometricFaceMeshPainter extends CustomPainter {
  final double progress;
  final bool isVerified;
  final bool isScanning;

  BiometricFaceMeshPainter({
    required this.progress,
    required this.isVerified,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final primaryColor = isVerified ? AppColors.statusActive : AppColors.goldPrimary;
    final cyanColor = isVerified ? AppColors.statusActive : const Color(0xFF00E5FF);

    // 1. Draw Face Oval Reticle
    final ovalRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: size.width * 0.44,
      height: size.height * 0.68,
    );

    final ovalPaint = Paint()
      ..color = primaryColor.withAlpha(isVerified ? 200 : 120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawOval(ovalRect, ovalPaint);

    // 2. Corner Bracket Reticles
    final cornerPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    const cornerLen = 16.0;
    final l = ovalRect.left - 8;
    final r = ovalRect.right + 8;
    final t = ovalRect.top - 8;
    final b = ovalRect.bottom + 8;

    // Top-Left
    canvas.drawLine(Offset(l, t), Offset(l + cornerLen, t), cornerPaint);
    canvas.drawLine(Offset(l, t), Offset(l, t + cornerLen), cornerPaint);
    // Top-Right
    canvas.drawLine(Offset(r, t), Offset(r - cornerLen, t), cornerPaint);
    canvas.drawLine(Offset(r, t), Offset(r, t + cornerLen), cornerPaint);
    // Bottom-Left
    canvas.drawLine(Offset(l, b), Offset(l + cornerLen, b), cornerPaint);
    canvas.drawLine(Offset(l, b), Offset(l, b - cornerLen), cornerPaint);
    // Bottom-Right
    canvas.drawLine(Offset(r, b), Offset(r - cornerLen, b), cornerPaint);
    canvas.drawLine(Offset(r, b), Offset(r, b - cornerLen), cornerPaint);

    // 3. Facial Landmark Nodes (Eyes, Nose, Mouth, Jawline)
    final nodes = <Offset>[
      // Eyes
      Offset(cx - 28, cy - 20),
      Offset(cx - 16, cy - 20),
      Offset(cx + 16, cy - 20),
      Offset(cx + 28, cy - 20),
      // Nose Bridge & Tip
      Offset(cx, cy - 22),
      Offset(cx, cy - 6),
      Offset(cx, cy + 6),
      Offset(cx - 10, cy + 10),
      Offset(cx + 10, cy + 10),
      // Mouth
      Offset(cx - 18, cy + 30),
      Offset(cx, cy + 26),
      Offset(cx + 18, cy + 30),
      Offset(cx, cy + 34),
      // Jawline
      Offset(cx - 45, cy),
      Offset(cx - 36, cy + 36),
      Offset(cx, cy + 56),
      Offset(cx + 36, cy + 36),
      Offset(cx + 45, cy),
    ];

    final nodePaint = Paint()
      ..color = cyanColor.withAlpha(isVerified ? 255 : (160 + (progress * 90).toInt()))
      ..style = PaintingStyle.fill;

    for (final pt in nodes) {
      canvas.drawCircle(pt, 2.2, nodePaint);
    }

    // Connect node lines with subtle cyan mesh
    final linePaint = Paint()
      ..color = cyanColor.withAlpha(isVerified ? 120 : 50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Eye line
    canvas.drawLine(nodes[0], nodes[1], linePaint);
    canvas.drawLine(nodes[2], nodes[3], linePaint);
    // Nose bridge
    canvas.drawLine(nodes[4], nodes[5], linePaint);
    canvas.drawLine(nodes[5], nodes[6], linePaint);
    canvas.drawLine(nodes[7], nodes[8], linePaint);
    // Mouth
    canvas.drawLine(nodes[9], nodes[10], linePaint);
    canvas.drawLine(nodes[10], nodes[11], linePaint);
    canvas.drawLine(nodes[11], nodes[12], linePaint);
    canvas.drawLine(nodes[12], nodes[9], linePaint);
    // Jaw
    canvas.drawLine(nodes[13], nodes[14], linePaint);
    canvas.drawLine(nodes[14], nodes[15], linePaint);
    canvas.drawLine(nodes[15], nodes[16], linePaint);
    canvas.drawLine(nodes[16], nodes[17], linePaint);

    // 4. Moving Laser Scan Line
    if (isScanning && !isVerified) {
      final scanY = ovalRect.top + (ovalRect.height * progress);
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            primaryColor.withAlpha(220),
            primaryColor,
            primaryColor.withAlpha(220),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(ovalRect.left, scanY, ovalRect.width, 2.5))
        ..strokeWidth = 2.5;

      canvas.drawLine(
        Offset(ovalRect.left + 5, scanY),
        Offset(ovalRect.right - 5, scanY),
        scanPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BiometricFaceMeshPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isVerified != isVerified ||
        oldDelegate.isScanning != isScanning;
  }
}
