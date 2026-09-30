import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/verifiable_credential.dart';
import '../core/models/verifiable_presentation.dart';
import '../core/services/crypto_vault_service.dart';
import '../core/services/wallet_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dynamic_qr_view.dart';
import 'verifier_scanner_screen.dart';

class PresentCredentialScreen extends StatefulWidget {
  final VerifiableCredential credential;

  const PresentCredentialScreen({
    super.key,
    required this.credential,
  });

  @override
  State<PresentCredentialScreen> createState() => _PresentCredentialScreenState();
}

class _PresentCredentialScreenState extends State<PresentCredentialScreen> {
  bool _consentApproved = false;
  final Set<String> _selectedAttributes = {
    'fullName',
    'faculty',
    'program',
    'degreeLevel',
    'status',
  };

  VerifiablePresentation? _currentPresentation;

  @override
  void initState() {
    super.initState();
    _generateFreshPresentation();
  }

  void _generateFreshPresentation() {
    final nonce = VerifiablePresentation.generateNonce();
    final holderDid = CryptoVaultService().didKey;
    final timestamp = DateTime.now();

    final payloadToSign = 'OpenID4VP-$nonce-${widget.credential.id}-$timestamp';
    final proofSignature = CryptoVaultService().signPayload(payloadToSign);

    final presentation = VerifiablePresentation(
      id: 'urn:uuid:nuvte-vp-${DateTime.now().millisecondsSinceEpoch}',
      type: ['VerifiablePresentation'],
      credential: widget.credential,
      holderDid: holderDid,
      nonce: nonce,
      audience: 'did:paldfi:verifier:campus-gate-01',
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

    // Record in local audit trail
    WalletStorageService().recordPresentation(
      verifierName: 'Campus Security Access Gate',
      disclosedAttributes: _selectedAttributes.toList(),
      nonce: nonce,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLocalizations.textDirection,
      child: Scaffold(
        backgroundColor: AppColors.obsidianBlack,
        appBar: AppBar(
          title: Text(
            AppLocalizations.tr('presentation_title'),
            style: GoogleFonts.cairo(
              fontSize: 17,
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
              // If consent not yet approved, show Selective Disclosure Consent
              if (!_consentApproved) ...[
                _buildConsentCard(),
              ] else ...[
                // Dynamic QR presentation view
                _buildPresentationView(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentCard() {
    final isArabic = AppLocalizations.isArabic;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.slateCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slateCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldPrimary),
                ),
                child: const Icon(
                  Icons.privacy_tip_rounded,
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
                      AppLocalizations.tr('consent_title'),
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      AppLocalizations.tr('consent_desc'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: AppColors.slateCardBorder),
          const SizedBox(height: 10),

          Text(
            isArabic ? 'البيانات التي سيتم مشاركتها في رمز الاستجابة:' : 'Select attributes to include in this presentation:',
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          _buildAttributeCheckbox('fullName', isArabic ? 'الاسم الكامل' : 'Full Name (Amjad Khaliliah)'),
          _buildAttributeCheckbox('faculty', isArabic ? 'الكلية' : 'Faculty (Engineering & Technology)'),
          _buildAttributeCheckbox('program', isArabic ? 'التخصص' : 'Program (Computer Systems & Cyber)'),
          _buildAttributeCheckbox('degreeLevel', isArabic ? 'الدرجة العلمية' : 'Degree Level (B.Sc.)'),
          _buildAttributeCheckbox('status', isArabic ? 'حالة الاعتماد' : 'Verification Status (Active)'),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _consentApproved = true;
                _generateFreshPresentation();
              });
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(
              isArabic ? 'توليد رمز الاستجابة المتجدد (OpenID4VP)' : 'Generate Dynamic QR Presentation',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeCheckbox(String key, String label) {
    final isSelected = _selectedAttributes.contains(key);
    return CheckboxListTile(
      value: isSelected,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.goldPrimary,
      checkColor: AppColors.obsidianBlack,
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.textLight : AppColors.textSubtle,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onChanged: (bool? val) {
        setState(() {
          if (val == true) {
            _selectedAttributes.add(key);
          } else {
            _selectedAttributes.remove(key);
          }
        });
      },
    );
  }

  Widget _buildPresentationView() {
    final isArabic = AppLocalizations.isArabic;

    if (_currentPresentation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Text(
          AppLocalizations.tr('presentation_instruction'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12.5,
          ),
        ),

        const SizedBox(height: 20),

        DynamicQrView(
          presentation: _currentPresentation!,
          onRefreshRequested: _generateFreshPresentation,
        ),

        const SizedBox(height: 24),

        // Quick verification testing action
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
                  const Icon(Icons.verified_rounded, color: AppColors.goldPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'اختبار التحقق الفوري (محاكي المدقق)' : 'Simulate Campus Verifier Validation',
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
                    ? 'اختبر التحقق الرياضي اللحظي من هذا الرمز في وضع المدقق دون الحاجة لجهاز ثانٍ.'
                    : 'Test real-time cryptographic verification of this presentation token without needing a second device.',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerifierScannerScreen(
                        incomingPresentation: _currentPresentation,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.security_rounded, size: 16),
                label: Text(
                  isArabic ? 'فتح ماسح الحرم الجامعي وفحص الرمز' : 'Verify in Campus Scanner Mode',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        TextButton.icon(
          onPressed: () {
            setState(() {
              _consentApproved = false;
            });
          },
          icon: const Icon(Icons.tune_rounded, size: 16, color: AppColors.goldPrimary),
          label: Text(
            isArabic ? 'تعديل البيانات المصرح بها' : 'Adjust Disclosed Attributes',
            style: const TextStyle(color: AppColors.goldPrimary, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
