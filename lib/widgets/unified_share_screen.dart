import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/verifiable_credential.dart';
import '../core/models/verifiable_presentation.dart';
import '../core/services/crypto_vault_service.dart';
import '../core/services/wallet_storage_service.dart';
import '../screens/third_party_portal_screen.dart';
import '../theme/app_theme.dart';
import 'dynamic_qr_view.dart';

class UnifiedShareScreen extends StatefulWidget {
  final VerifiableCredential initialCredential;
  final String actorTitle; // "Student Wallet" or "University Management"

  const UnifiedShareScreen({
    super.key,
    required this.initialCredential,
    this.actorTitle = 'Citizen & Student Wallet',
  });

  @override
  State<UnifiedShareScreen> createState() => _UnifiedShareScreenState();
}

class _UnifiedShareScreenState extends State<UnifiedShareScreen> {
  late VerifiableCredential _selectedCredential;
  VerifiablePresentation? _currentPresentation;

  final Set<String> _selectedAttributes = {
    'fullName',
    'faculty',
    'program',
    'degreeLevel',
    'status',
  };

  @override
  void initState() {
    super.initState();
    _selectedCredential = widget.initialCredential;
    _generateFreshPresentation();
  }

  void _generateFreshPresentation() {
    final nonce = VerifiablePresentation.generateNonce();
    final holderDid = CryptoVaultService().didKey;
    final timestamp = DateTime.now();

    final payloadToSign =
        'OpenID4VP-$nonce-${_selectedCredential.id}-$timestamp';
    final proofSignature = CryptoVaultService().signPayload(payloadToSign);

    final presentation = VerifiablePresentation(
      id: 'urn:uuid:nuvte-vp-${timestamp.millisecondsSinceEpoch}',
      type: ['VerifiablePresentation'],
      credential: _selectedCredential,
      holderDid: holderDid,
      nonce: nonce,
      audience: 'did:paldfi:verifier:third-party-authority',
      timestamp: timestamp,
      validitySeconds: 60,
      disclosedAttributes: Set.from(_selectedAttributes),
      proof: {
        'type': 'Ed25519Signature2020',
        'created': timestamp.toIso8601String(),
        'verificationMethod': '$holderDid#key-1',
        'proofPurpose': 'authentication',
        'proofValue': proofSignature,
      },
    );

    setState(() {
      _currentPresentation = presentation;
    });

    WalletStorageService().recordPresentation(
      verifierName: 'Authorized Verifier Gateway',
      disclosedAttributes: _selectedAttributes.toList(),
      nonce: nonce,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.isArabic;
    final allDocs = WalletStorageService().credentials.value;

    return Directionality(
      textDirection: AppLocalizations.textDirection,
      child: Scaffold(
        backgroundColor: AppColors.obsidianBlack,
        appBar: AppBar(
          title: Text(
            AppLocalizations.tr('presentation_title'),
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Actor & Document Type Selector Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.charcoalDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slateCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.goldPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.actorTitle,
                          style: GoogleFonts.inter(
                            color: AppColors.goldLight,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isArabic ? 'اختر الوثيقة المراد مشاركتها:' : 'Select Document to Present:',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Document selector chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: allDocs.map((doc) {
                        final isSelected = doc.id == _selectedCredential.id;
                        return ChoiceChip(
                          label: Text(
                            isArabic ? doc.documentTitleAr : doc.documentTitleEn,
                            style: TextStyle(
                              color: isSelected ? AppColors.obsidianBlack : AppColors.textLight,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.goldPrimary,
                          backgroundColor: AppColors.slateCard,
                          side: BorderSide(
                            color: isSelected ? AppColors.goldPrimary : AppColors.slateCardBorder,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCredential = doc;
                                _generateFreshPresentation();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                AppLocalizations.tr('presentation_instruction'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 16),

              if (_currentPresentation != null)
                DynamicQrView(
                  presentation: _currentPresentation!,
                  onRefreshRequested: _generateFreshPresentation,
                ),

              const SizedBox(height: 20),

              // Transmit to Third-Party Verifier Gateway Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withAlpha(90),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.goldPrimary.withAlpha(120)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, color: AppColors.goldPrimary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'إرسال إلى جهة التحقق الخارجية (طرف ثالث)' : 'Send to Third-Party Verifier Portal',
                          style: GoogleFonts.inter(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isArabic
                          ? 'انتقل مباشرة إلى بوابة الطرف الثالث (مثل بنك فلسطين) واختبر التحقق من هذه الوثيقة على البلوكشين.'
                          : 'Transmit this decrypted presentation directly to the Third-Party Verifier for real-time Fabric blockchain validation.',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ThirdPartyPortalScreen(
                              preloadedPresentation: _currentPresentation,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(
                        isArabic ? 'فتح بوابة الطرف الثالث وفحص الوثيقة' : 'Open Third-Party Portal & Verify',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary,
                        foregroundColor: AppColors.obsidianBlack,
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
