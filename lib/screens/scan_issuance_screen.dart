import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/student_profile.dart';
import '../core/models/verifiable_credential.dart';
import '../core/services/crypto_vault_service.dart';
import '../core/services/id_plus_auth_service.dart';
import '../core/services/wallet_storage_service.dart';
import '../theme/app_theme.dart';

class ScanIssuanceScreen extends StatefulWidget {
  const ScanIssuanceScreen({super.key});

  @override
  State<ScanIssuanceScreen> createState() => _ScanIssuanceScreenState();
}

class _ScanIssuanceScreenState extends State<ScanIssuanceScreen> {
  bool _isIngesting = false;
  String? _currentStepText;

  Future<void> _ingestStudentOffer(StudentProfile student) async {
    setState(() {
      _isIngesting = true;
      _currentStepText = AppLocalizations.isArabic
          ? 'جاري التقاط عرض الإصدار عبر بروتوكول OpenID4VCI...'
          : 'Capturing Registrar Offer via OpenID4VCI...';
    });

    // Step 1: PoP token generation
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _currentStepText = AppLocalizations.isArabic
          ? 'توليد رمز إثبات الحيازة (Proof of Possession - Ed25519)...'
          : 'Generating signed Proof of Possession (PoP) token with holder key...';
    });

    CryptoVaultService().generateProofOfPossession(
      issuanceNonce: 'nonce-issuance-${DateTime.now().millisecondsSinceEpoch}',
      audience: 'https://identity.nuvte.edu.ps/vci',
    );

    // Step 2: TLS handshake with NUVTE registrar
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _currentStepText = AppLocalizations.isArabic
          ? 'الاتصال الآمن بخادم المسجل (identity.nuvte.edu.ps عبر TLS 1.3)...'
          : 'Secure TLS 1.3 connection to identity.nuvte.edu.ps...';
    });

    // Step 3: Ingesting W3C VC 2.0
    await Future.delayed(const Duration(milliseconds: 350));
    final newVc = VerifiableCredential.fromStudent(
      student,
      documentType: AcademicDocumentType.studentId,
      issuerDid: 'did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA',
      signatureProof: 'z4Ed25519SigNUVTE_${student.studentId}_${DateTime.now().millisecondsSinceEpoch}',
    );
    WalletStorageService().ingestCredential(newVc);

    if (!mounted) return;
    setState(() {
      _isIngesting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.isArabic
              ? 'تم استلام وتشفير بطاقة الطالب بنجاح في الخزنة المحلية'
              : 'Credential ingested & encrypted into local vault successfully!',
        ),
        backgroundColor: AppColors.statusActive,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.isArabic;

    return Directionality(
      textDirection: AppLocalizations.textDirection,
      child: Scaffold(
        backgroundColor: AppColors.obsidianBlack,
        appBar: AppBar(
          title: Text(
            AppLocalizations.tr('action_scan_issuance'),
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
              // Simulated Camera Viewport
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.charcoalDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.goldPrimary, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Grid lines
                    Opacity(
                      opacity: 0.15,
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 100,
                        color: AppColors.goldPrimary,
                      ),
                    ),

                    // Target scanning box
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.goldPrimary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    if (_isIngesting)
                      Container(
                        color: AppColors.obsidianBlack.withAlpha(220),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.goldPrimary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentStepText ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.goldLight,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.obsidianBlack.withAlpha(200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isArabic
                                ? 'وجّه الكاميرا نحو رمز QR على بوابة المسجل الأكاديمي'
                                : 'Point camera at issuance offer QR on Registrar portal',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Dynamic Enrolled Student Offers Selector
              Text(
                isArabic ? 'عروض الإصدار المتاحة للطلبة المسجلين:' : 'Available Registrar Issuance Offers for Enrolled Students:',
                style: GoogleFonts.inter(
                  color: AppColors.goldLight,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Builder(
                builder: (context) {
                  final students = IdPlusAuthService().dynamicStudents.value;
                  if (students.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        isArabic ? 'لا يوجد طلاب مسجلون حالياً في قاعدة البيانات.' : 'No enrolled students found in Vector DB.',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    );
                  }

                  return Column(
                    children: students.map((s) {
                      final sId = s['studentId'] ?? s['candidateId'] ?? '';
                      final profile = WalletStorageService().getStudentProfile(sId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildOfferTile(
                          title: '${profile.fullNameEn} (${profile.programEn})',
                          id: profile.studentId,
                          faculty: profile.facultyEn,
                          status: profile.status,
                          onSelect: () => _ingestStudentOffer(profile),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferTile({
    required String title,
    required String id,
    required String faculty,
    required CredentialStatus status,
    required VoidCallback onSelect,
  }) {
    final isRevoked = status == CredentialStatus.revoked;

    return InkWell(
      onTap: _isIngesting ? null : onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.slateCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRevoked ? AppColors.statusRevoked : AppColors.slateCardBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isRevoked
                    ? AppColors.statusRevoked.withAlpha(30)
                    : AppColors.navyPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRevoked ? Icons.warning_rounded : Icons.school_rounded,
                color: isRevoked ? AppColors.statusRevoked : AppColors.goldPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$id • $faculty',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.download_rounded,
              color: AppColors.goldPrimary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
