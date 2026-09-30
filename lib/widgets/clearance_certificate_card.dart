import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/verifiable_credential.dart';
import '../theme/app_theme.dart';
import 'holographic_ribbon.dart';
import 'status_badge.dart';

class ClearanceCertificateCard extends StatelessWidget {
  final VerifiableCredential credential;
  final VoidCallback? onTap;

  const ClearanceCertificateCard({
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
              Color(0xFF07192C),
              Color(0xFF0C2B4E),
              Color(0xFF0F3B66),
              Color(0xFF091F38),
            ],
          ),
          border: Border.all(
            color: isRevoked ? AppColors.statusRevoked : AppColors.goldPrimary,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isRevoked
                  ? AppColors.statusRevoked.withAlpha(50)
                  : AppColors.goldPrimary.withAlpha(50),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            children: [
              // Background Watermark Shield
              Positioned(
                right: isArabic ? null : -20,
                left: isArabic ? -20 : null,
                bottom: -20,
                child: Opacity(
                  opacity: 0.04,
                  child: Icon(
                    Icons.assignment_turned_in_rounded,
                    size: 240,
                    color: AppColors.goldPrimary,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.obsidianBlack,
                            border: Border.all(color: AppColors.goldPrimary, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.goldPrimary,
                            size: 24,
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
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'CERTIFICATE OF DISCHARGE • براءة ذمة',
                                style: GoogleFonts.inter(
                                  color: AppColors.goldPrimary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const HolographicRibbon(height: 6),
                    const SizedBox(height: 14),

                    // Student & Reference Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.obsidianBlack.withAlpha(200),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slateCardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? student.fullNameAr : student.fullNameEn,
                                  style: GoogleFonts.cairo(
                                    color: AppColors.textLight,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'ID: ${student.studentId} • ${student.programEn}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.navyPrimary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              student.clearanceReferenceNumber,
                              style: GoogleFonts.robotoMono(
                                color: AppColors.goldLight,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Cleared Departments Checklist
                    Text(
                      isArabic ? 'الدوائر المستوفاة والمبرأة ذمتها:' : 'Cleared University Entities:',
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildClearedPill(isArabic ? 'المكتبة' : 'Library'),
                        _buildClearedPill(isArabic ? 'الدائرة المالية' : 'Finance (0 Debt)'),
                        _buildClearedPill(isArabic ? 'المختبرات والورش' : 'Labs & Workshops'),
                        _buildClearedPill(isArabic ? 'شؤون الطلبة' : 'Student Affairs'),
                        _buildClearedPill(isArabic ? 'القبول والتسجيل' : 'Registration'),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Footer Row with Status & Inspect Action
                    Container(
                      padding: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFF1E3A5F))),
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

  Widget _buildClearedPill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF06281E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF10B981).withAlpha(120), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
