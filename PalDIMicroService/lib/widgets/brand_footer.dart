import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class BrandFooter extends StatelessWidget {
  final bool compact;
  final bool showFacePal;
  final bool showIdPlus;
  final String? customSubtext;

  const BrandFooter({
    super.key,
    this.compact = false,
    this.showFacePal = true,
    this.showIdPlus = true,
    this.customSubtext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.charcoalDark.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slateCardBorder.withAlpha(150)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIdPlus) ...[
                // iD+ Official Logo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.idPlusNavy.withAlpha(80),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/id_plus_logo.png',
                        height: compact ? 22 : 28,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          'iD+',
                          style: GoogleFonts.inter(
                            color: AppColors.idPlusNavy,
                            fontWeight: FontWeight.w900,
                            fontSize: compact ? 14 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Divider between logos
              if (showIdPlus && showFacePal)
                Container(
                  height: compact ? 20 : 26,
                  width: 1.5,
                  color: AppColors.slateCardBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),

              if (showFacePal) ...[
                const SizedBox(width: 10),
                // FacePal Sense Official Logo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.facepalBlue.withAlpha(80),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          'assets/images/facepal_sense_logo.jpg',
                          height: compact ? 22 : 28,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.face_retouching_natural_rounded, color: AppColors.facepalBlue, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                'FacePal',
                                style: GoogleFonts.inter(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: compact ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Primary Brand Text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 4-color iD+ Brand Quadrant dot
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 4, height: 4, color: AppColors.idPlusPurple),
                  Container(width: 4, height: 4, color: AppColors.idPlusCyan),
                ],
              ),
              const SizedBox(width: 6),
              Text(
                'Powered By ID+ - PMA',
                style: GoogleFonts.inter(
                  color: AppColors.facepalBlueLight,
                  fontSize: compact ? 11 : 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 4, height: 4, color: AppColors.idPlusNavy),
                  Container(width: 4, height: 4, color: AppColors.idPlusGold),
                ],
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Subtext / Security Standard
          Text(
            customSubtext ?? 'Palestine Monetary Authority Sovereign ID & FacePal Sense™ Biometrics',
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoMono(
              color: AppColors.textMuted,
              fontSize: compact ? 9.5 : 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
