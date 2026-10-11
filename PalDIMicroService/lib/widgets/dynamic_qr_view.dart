import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/verifiable_presentation.dart';
import '../theme/app_theme.dart';

class DynamicQrView extends StatefulWidget {
  final VerifiablePresentation presentation;
  final VoidCallback onRefreshRequested;

  const DynamicQrView({
    super.key,
    required this.presentation,
    required this.onRefreshRequested,
  });

  @override
  State<DynamicQrView> createState() => _DynamicQrViewState();
}

class _DynamicQrViewState extends State<DynamicQrView> {
  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.presentation.remainingSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final rem = widget.presentation.remainingSeconds;
      setState(() {
        _remainingSeconds = rem;
      });
      if (rem <= 0) {
        timer.cancel();
        widget.onRefreshRequested();
      }
    });
  }

  @override
  void didUpdateWidget(covariant DynamicQrView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.nonce != widget.presentation.nonce) {
      _remainingSeconds = widget.presentation.remainingSeconds;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / widget.presentation.validitySeconds;
    final isWarning = _remainingSeconds <= 10;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Container with Gold & Slate Border
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isWarning ? AppColors.statusRevoked : AppColors.goldPrimary,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (isWarning ? AppColors.statusRevoked : AppColors.goldPrimary)
                    .withAlpha(90),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: QrImageView(
            data: widget.presentation.toQrPayload(),
            version: QrVersions.auto,
            size: 220.0,
            gapless: true,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.navyPrimary,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: AppColors.obsidianBlack,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Countdown Timer & Refresh Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.slateCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slateCardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular countdown indicator
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 3.5,
                      backgroundColor: AppColors.slateCardBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isWarning ? AppColors.statusRevoked : AppColors.goldPrimary,
                      ),
                    ),
                    Text(
                      '$_remainingSeconds',
                      style: TextStyle(
                        color: isWarning ? AppColors.statusRevoked : AppColors.goldPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.tr('time_remaining'),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$_remainingSeconds ${AppLocalizations.tr('seconds')}',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Immediate Refresh Button
              IconButton(
                onPressed: widget.onRefreshRequested,
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.goldPrimary,
                tooltip: 'Regenerate Nonce Now',
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Nonce & Security Info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.charcoalDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_clock_rounded,
                size: 13,
                color: AppColors.goldLight,
              ),
              const SizedBox(width: 6),
              Text(
                'NONCE: ${widget.presentation.nonce}',
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
