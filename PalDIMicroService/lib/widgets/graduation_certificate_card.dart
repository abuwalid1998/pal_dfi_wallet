import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/verifiable_credential.dart';
import '../theme/app_theme.dart';
import 'holographic_ribbon.dart';
import 'status_badge.dart';

class GraduationCertificateCard extends StatelessWidget {
  final VerifiableCredential credential;
  final VoidCallback? onTap;

  const GraduationCertificateCard({
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
              Color(0xFF04101F),
              Color(0xFF081B33),
              Color(0xFF0F2C52),
              Color(0xFF051324),
            ],
          ),
          border: Border.all(
            color: isRevoked ? AppColors.statusRevoked : AppColors.goldPrimary,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isRevoked
                  ? AppColors.statusRevoked.withAlpha(50)
                  : AppColors.goldPrimary.withAlpha(55),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Watermark Diploma Icon
              Positioned(
                right: isArabic ? null : -20,
                left: isArabic ? -20 : null,
                bottom: -20,
                child: Opacity(
                  opacity: 0.04,
                  child: Icon(
                    Icons.workspace_premium_rounded,
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
                    // University Header Row
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
                            Icons.workspace_premium_rounded,
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
                                'OFFICIAL GRADUATION DIPLOMA • W3C VC 2.0',
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
                    const SizedBox(height: 16),

                    // Conferred Statement
                    Center(
                      child: Text(
                        isArabic
                            ? 'يشهد مجلس عمداء الجامعة بأن الطالب المذكور أدناه قد أتم بنجاح متطلبات نيل:'
                            : 'The University Council of Deans hereby confers upon:',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Student Name
                    Center(
                      child: Text(
                        isArabic ? student.fullNameAr : student.fullNameEn,
                        style: GoogleFonts.cairo(
                          color: AppColors.goldLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Degree Conferred
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.obsidianBlack.withAlpha(180),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.slateCardBorder),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isArabic ? student.degreeLevelAr : student.degreeLevelEn,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.textLight,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isArabic ? student.programAr : student.programEn,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.goldPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Honors & Resolution Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? 'التقدير الأكاديمي:' : 'Honors Classification:',
                                style: const TextStyle(color: AppColors.textSubtle, fontSize: 10),
                              ),
                              Text(
                                isArabic ? student.honorsAr : student.honorsEn,
                                style: const TextStyle(
                                  color: AppColors.goldLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isArabic ? 'المعدل التراكمي:' : 'Cumulative GPA:',
                              style: const TextStyle(color: AppColors.textSubtle, fontSize: 10),
                            ),
                            Text(
                              '${student.gpa.toStringAsFixed(2)} / 4.00',
                              style: GoogleFonts.robotoMono(
                                color: AppColors.textLight,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
}
