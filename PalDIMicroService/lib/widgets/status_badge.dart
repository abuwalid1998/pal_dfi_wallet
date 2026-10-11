import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/student_profile.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final CredentialStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color textColor;
    String labelKey;
    IconData icon;

    switch (status) {
      case CredentialStatus.active:
        badgeColor = AppColors.statusActive;
        textColor = const Color(0xFFD1FAE5);
        labelKey = 'status_active';
        icon = Icons.verified_rounded;
        break;
      case CredentialStatus.revoked:
        badgeColor = AppColors.statusRevoked;
        textColor = const Color(0xFFFEE2E2);
        labelKey = 'status_revoked';
        icon = Icons.cancel_rounded;
        break;
      case CredentialStatus.expired:
        badgeColor = AppColors.statusExpired;
        textColor = const Color(0xFFFEF3C7);
        labelKey = 'status_expired';
        icon = Icons.timelapse_rounded;
        break;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withAlpha(40),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: badgeColor.withAlpha(120), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor,
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withAlpha(160),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              AppLocalizations.tr(labelKey),
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: badgeColor.withAlpha(140), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withAlpha(40),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.tr(labelKey),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
