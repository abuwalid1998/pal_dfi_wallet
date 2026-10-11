import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/verifiable_credential.dart';
import '../theme/app_theme.dart';
import 'holographic_ribbon.dart';
import 'status_badge.dart';

class DigitalIdCard extends StatelessWidget {
  final VerifiableCredential credential;
  final VoidCallback? onTap;

  const DigitalIdCard({
    super.key,
    required this.credential,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final student = credential.student;
    final isArabic = AppLocalizations.isArabic;
    final isRevoked = student.isRevoked;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF061426),
              AppColors.navyPrimary,
              Color(0xFF0F2D54),
              AppColors.navyDark,
            ],
            stops: [0.0, 0.35, 0.75, 1.0],
          ),
          border: Border.all(
            color: isRevoked
                ? AppColors.statusRevoked
                : AppColors.goldPrimary.withAlpha(200),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isRevoked
                  ? AppColors.statusRevoked.withAlpha(60)
                  : AppColors.goldPrimary.withAlpha(45),
              blurRadius: 22,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(180),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            children: [
              // Background Decorative Watermark (NUVTE emblem pattern)
              Positioned(
                right: isArabic ? null : -25,
                left: isArabic ? -25 : null,
                bottom: -25,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(
                    Icons.school_rounded,
                    size: 260,
                    color: AppColors.goldPrimary,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Header Row: University Name & Emblem
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // University Logo / Emblem Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.obsidianBlack,
                            border: Border.all(
                              color: AppColors.goldPrimary,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.goldPrimary.withAlpha(80),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: AppColors.goldPrimary,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic
                                    ? 'جامعة نابلس للتعليم المهني والتقني'
                                    : 'Nablus University for Vocational & Technical Education',
                                style: GoogleFonts.cairo(
                                  color: AppColors.textLight,
                                  fontSize: isArabic ? 13.5 : 12,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'NUVTE • PAL-DFI TRUST NETWORK',
                                    style: GoogleFonts.inter(
                                      color: AppColors.goldPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Contactless NFC wave icon
                                  const Icon(
                                    Icons.contactless_rounded,
                                    color: AppColors.goldLight,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Shimmering Holographic Security Ribbon
                    const HolographicRibbon(height: 6),

                    const SizedBox(height: 16),

                    // Middle Row: Smart Chip + Photo + Student Details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Student Photo with Gold Border + Smart Chip below
                        Column(
                          children: [
                            // Student Photo
                            Container(
                              width: 74,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.goldPrimary,
                                  width: 1.8,
                                ),
                                color: AppColors.charcoalDark,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(120),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(
                                      color: const Color(0xFF162338),
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 58,
                                        color: AppColors.goldPrimary.withAlpha(200),
                                      ),
                                    ),
                                    // Subtle verified watermark
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: AppColors.obsidianBlack,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.verified_user_rounded,
                                          size: 14,
                                          color: AppColors.goldPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Simulated Metallic Smart Card Chip
                            Container(
                              width: 38,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE5C07B),
                                    Color(0xFFD4AF37),
                                    Color(0xFFB8860B),
                                    Color(0xFFE5C07B),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.black.withAlpha(140),
                                  width: 0.8,
                                ),
                              ),
                              child: CustomPaint(
                                painter: _SmartChipPainter(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // Right: Student Academic Information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full Name
                              Text(
                                isArabic ? student.fullNameAr : student.fullNameEn,
                                style: GoogleFonts.cairo(
                                  color: AppColors.textLight,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Student ID with monospaced style
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.obsidianBlack,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.slateCardBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  student.studentId,
                                  style: GoogleFonts.robotoMono(
                                    color: AppColors.goldPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Faculty
                              Text(
                                isArabic ? student.facultyAr : student.facultyEn,
                                style: TextStyle(
                                  color: AppColors.textLight.withAlpha(220),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 2),

                              // Program / Major
                              Text(
                                isArabic ? student.programAr : student.programEn,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 6),

                              // Degree & Academic Year
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      isArabic ? student.degreeLevelAr : student.degreeLevelEn,
                                      style: const TextStyle(
                                        color: AppColors.goldLight,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Text(
                                    ' • ',
                                    style: TextStyle(color: AppColors.textSubtle),
                                  ),
                                  Text(
                                    student.academicYear,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bottom Row: Status Badge + Tap for JSON-LD hint
                    Container(
                      padding: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Color(0xFF1E3A5F),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(status: student.status, compact: true),
                          Row(
                            children: [
                              Text(
                                AppLocalizations.tr('action_inspect'),
                                style: const TextStyle(
                                  color: AppColors.goldPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.goldPrimary,
                                size: 10,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Contact lines
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.35, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, 0),
      Offset(size.width * 0.65, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
