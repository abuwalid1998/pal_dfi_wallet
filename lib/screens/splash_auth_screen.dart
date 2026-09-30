import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/wallet_storage_service.dart';
import '../theme/app_theme.dart';

class SplashAuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const SplashAuthScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<SplashAuthScreen> createState() => _SplashAuthScreenState();
}

class _SplashAuthScreenState extends State<SplashAuthScreen> {
  String _pin = '';
  String? _errorMessage;

  void _onKeypadTap(String val) {
    if (_pin.length < 6) {
      setState(() {
        _pin += val;
        _errorMessage = null;
      });

      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _verifyPin() {
    final success = WalletStorageService().unlockWithPin(_pin);
    if (success) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _errorMessage = AppLocalizations.isArabic
            ? 'رمز الأمان غير صحيح، يرجى المحاولة مجدداً'
            : 'Incorrect security PIN. Please try again.';
        _pin = '';
      });
    }
  }

  void _unlockWithBiometrics() {
    WalletStorageService().unlockWithBiometrics();
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.isArabic;

    return Directionality(
      textDirection: AppLocalizations.textDirection,
      child: Scaffold(
        backgroundColor: AppColors.obsidianBlack,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top row with Language Toggle & Sandbox badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.navyPrimary.withAlpha(160),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.goldPrimary.withAlpha(120),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.tr('sandbox_badge'),
                                  style: GoogleFonts.inter(
                                    color: AppColors.goldLight,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  AppLocalizations.toggleLanguage();
                                });
                              },
                              icon: const Icon(
                                Icons.language_rounded,
                                color: AppColors.goldPrimary,
                                size: 18,
                              ),
                              label: Text(
                                isArabic ? 'English' : 'العربية',
                                style: GoogleFonts.cairo(
                                  color: AppColors.goldPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // University Logo & Crest
                        Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    AppColors.navyLight,
                                    AppColors.navyPrimary,
                                    AppColors.obsidianBlack,
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.goldPrimary,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.goldPrimary.withAlpha(80),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.account_balance_rounded,
                                  color: AppColors.goldPrimary,
                                  size: 40,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Text(
                              AppLocalizations.tr('app_title'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                color: AppColors.textLight,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              AppLocalizations.tr('sub_title'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12.5,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Zero on chain PII pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.charcoalDark,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.slateCardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.shield_rounded,
                                    size: 13,
                                    color: AppColors.goldPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.tr('zero_pii_badge'),
                                    style: const TextStyle(
                                      color: AppColors.goldLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // PIN Input Dots
                        Column(
                          children: [
                            Text(
                              AppLocalizations.tr('wallet_locked'),
                              style: GoogleFonts.inter(
                                color: AppColors.textLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.tr('enter_pin_desc'),
                              style: const TextStyle(
                                color: AppColors.textSubtle,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 6 Dots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (index) {
                                final filled = index < _pin.length;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 7),
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: filled
                                        ? AppColors.goldPrimary
                                        : AppColors.charcoalDark,
                                    border: Border.all(
                                      color: filled
                                          ? AppColors.goldPrimary
                                          : AppColors.slateCardBorder,
                                      width: 1.5,
                                    ),
                                    boxShadow: filled
                                        ? [
                                            BoxShadow(
                                              color: AppColors.goldPrimary.withAlpha(120),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                );
                              }),
                            ),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.statusRevoked,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Keypad (0-9, Backspace, Biometrics)
                        Container(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Column(
                            children: [
                              _buildKeypadRow(['1', '2', '3']),
                              const SizedBox(height: 12),
                              _buildKeypadRow(['4', '5', '6']),
                              const SizedBox(height: 12),
                              _buildKeypadRow(['7', '8', '9']),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Biometrics button
                                  _buildKeypadButton(
                                    child: const Icon(
                                      Icons.fingerprint_rounded,
                                      color: AppColors.goldPrimary,
                                      size: 28,
                                    ),
                                    onTap: _unlockWithBiometrics,
                                  ),
                                  _buildKeypadButton(
                                    child: const Text(
                                      '0',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                    onTap: () => _onKeypadTap('0'),
                                  ),
                                  // Backspace button
                                  _buildKeypadButton(
                                    child: const Icon(
                                      Icons.backspace_outlined,
                                      color: AppColors.textMuted,
                                      size: 22,
                                    ),
                                    onTap: _onBackspace,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Pilot hint
                        Text(
                          AppLocalizations.tr('default_pin_hint'),
                          style: const TextStyle(
                            color: AppColors.textSubtle,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        return _buildKeypadButton(
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          onTap: () => _onKeypadTap(key),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.charcoalDark,
          border: Border.all(color: AppColors.slateCardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(90),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
