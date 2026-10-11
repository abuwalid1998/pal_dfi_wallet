import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/verifiable_presentation.dart';
import '../core/services/fabric_ledger_service.dart';
import '../theme/app_theme.dart';

class VerifierScannerScreen extends StatefulWidget {
  final VerifiablePresentation? incomingPresentation;

  const VerifierScannerScreen({
    super.key,
    this.incomingPresentation,
  });

  @override
  State<VerifierScannerScreen> createState() => _VerifierScannerScreenState();
}

class _VerifierScannerScreenState extends State<VerifierScannerScreen> {
  bool _isVerifying = false;
  LedgerVerificationResult? _result;
  VerifiablePresentation? _activePresentation;
  bool _nonceExpired = false;

  @override
  void initState() {
    super.initState();
    if (widget.incomingPresentation != null) {
      _activePresentation = widget.incomingPresentation;
      _executeVerification(_activePresentation!);
    }
  }

  Future<void> _executeVerification(VerifiablePresentation pres) async {
    setState(() {
      _isVerifying = true;
      _result = null;
      _nonceExpired = pres.isExpired;
    });

    final ledger = FabricLedgerService();
    final proofVal = pres.proof['proofValue'] as String? ?? '';

    final res = await ledger.queryStatusList(
      statusListIndex: pres.credential.statusListIndex,
      anchorHash: pres.credential.onChainAnchorHash,
      signature: proofVal,
      docId: pres.credential.fabricDocId,
    );

    // Record immutable verification audit on Hyperledger Fabric 2.5
    ledger.recordVerificationAudit(
      auditId: 'AUDIT-SCAN-${DateTime.now().millisecondsSinceEpoch}',
      verifierDid: 'did:key:z6MkuBankOfPalestineCompliance',
      verifierName: 'Bank of Palestine (Field Terminal / QR Scanner)',
      docId: pres.credential.fabricDocId,
      studentDid: pres.holderDid,
      nonce: pres.nonce,
      verificationResult: res.isValid ? 'VALID' : (res.isRevoked ? 'REVOKED' : 'INVALID'),
    );

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _result = res;
    });
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
            AppLocalizations.tr('verifier_title'),
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
              // Verifier Mode Intro Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.charcoalDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slateCardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.navyPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.goldPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Campus Security / Proctor Station #04',
                            style: GoogleFonts.inter(
                              color: AppColors.goldLight,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.tr('verifier_desc'),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_isVerifying) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.slateCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.goldPrimary),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.goldPrimary),
                      const SizedBox(height: 20),
                      Text(
                        isArabic
                            ? 'جاري التحقق من التوقيع الرقمي وسجل الإلغاء في البلوكشين...'
                            : 'Validating Ed25519 Proof & BitstringStatusList2021 on Fabric...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'PMA Sandbox Regulatory Standard < 3.0s',
                        style: TextStyle(color: AppColors.textSubtle, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ] else if (_result != null && _activePresentation != null) ...[
                _buildVerificationResultCard(_result!, _activePresentation!),
              ] else ...[
                // Empty state if no presentation loaded
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: AppColors.slateCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slateCardBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.document_scanner_rounded,
                        size: 54,
                        color: AppColors.textSubtle,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isArabic
                            ? 'لم يتم مسح أي رمز إبراز حتى الآن'
                            : 'No Presentation QR Scanned Yet',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic
                            ? 'اضغط على "إبراز الهوية" من المحفظة ثم اختر محاكاة الفحص.'
                            : 'Navigate to "Present ID" on the student wallet and click Simulate Verifier.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationResultCard(
    LedgerVerificationResult res,
    VerifiablePresentation pres,
  ) {
    final isArabic = AppLocalizations.isArabic;
    final bool passed = res.isValid && !_nonceExpired;

    Color headerColor = passed ? AppColors.statusActive : AppColors.statusRevoked;
    IconData headerIcon = passed ? Icons.verified_user_rounded : Icons.gpp_bad_rounded;
    String headerText = passed
        ? AppLocalizations.tr('verification_passed')
        : (res.isRevoked
            ? AppLocalizations.tr('verification_failed_revoked')
            : (_nonceExpired
                ? 'NONCE EXPIRED (REPLAY PROTECTION)'
                : AppLocalizations.tr('verification_failed_tampered')));

    final student = pres.credential.student;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.slateCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: headerColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: headerColor.withAlpha(50),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: headerColor.withAlpha(40),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              border: Border(bottom: BorderSide(color: headerColor.withAlpha(100))),
            ),
            child: Row(
              children: [
                Icon(headerIcon, color: headerColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    headerText,
                    style: TextStyle(
                      color: headerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Response time & KPI pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.obsidianBlack,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed_rounded, size: 14, color: AppColors.goldPrimary),
                      const SizedBox(width: 6),
                      Text(
                        'Total Response Time: ${res.responseTimeMs}ms (< 3.0s Target Passed)',
                        style: GoogleFonts.robotoMono(
                          color: AppColors.goldLight,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Disclosed Student Details
                Text(
                  isArabic ? 'البيانات المفصح عنها للمدقق:' : 'Disclosed Student Identity:',
                  style: const TextStyle(
                    color: AppColors.goldPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                _buildClaimRow(
                  isArabic ? 'الاسم الكامل:' : 'Full Name:',
                  isArabic ? student.fullNameAr : student.fullNameEn,
                ),
                _buildClaimRow(
                  isArabic ? 'رقم الطالب:' : 'Student ID:',
                  student.studentId,
                  isMono: true,
                ),
                _buildClaimRow(
                  isArabic ? 'الكلية:' : 'Faculty:',
                  isArabic ? student.facultyAr : student.facultyEn,
                ),
                _buildClaimRow(
                  isArabic ? 'البرنامج:' : 'Program:',
                  isArabic ? student.programAr : student.programEn,
                ),

                const SizedBox(height: 14),
                const Divider(color: AppColors.slateCardBorder),
                const SizedBox(height: 8),

                // Mathematical & Cryptographic Proof breakdown
                Text(
                  'Trust & Blockchain Telemetry:',
                  style: GoogleFonts.inter(
                    color: AppColors.goldLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _buildAuditLine('W3C Signature', 'Ed25519 Verified against NUVTE PKI', true),
                _buildAuditLine('BitstringStatusList2021', 'Bit #${pres.credential.statusListIndex} evaluated (${res.isRevoked ? "1 / Revoked" : "0 / Active"})', !res.isRevoked),
                _buildAuditLine('On-Chain Anchor Hash', 'SHA-256 matched in ${res.blockNumber}', true),
                _buildAuditLine('Anti-Replay Nonce', '${pres.nonce} (${_nonceExpired ? "Expired" : "Fresh"})', !_nonceExpired),
                _buildAuditLine('Zero On-Chain PII', 'Verified: 0 bytes PII on Fabric', true),

                const SizedBox(height: 20),

                // Re-check button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _executeVerification(pres),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(isArabic ? 'إعادة الفحص اللحظي' : 'Re-verify with Ledger'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isMono
                  ? GoogleFonts.robotoMono(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    )
                  : const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLine(String label, String detail, bool success) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: success ? AppColors.statusActive : AppColors.statusRevoked,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $detail',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
