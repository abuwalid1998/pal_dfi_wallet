import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/verifiable_credential.dart';
import '../core/services/fabric_ledger_service.dart';
import '../theme/app_theme.dart';
import '../widgets/json_ld_viewer.dart';
import '../widgets/status_badge.dart';

class CredentialDetailScreen extends StatefulWidget {
  final VerifiableCredential credential;

  const CredentialDetailScreen({
    super.key,
    required this.credential,
  });

  @override
  State<CredentialDetailScreen> createState() => _CredentialDetailScreenState();
}

class _CredentialDetailScreenState extends State<CredentialDetailScreen> {
  bool _isVerifying = false;
  LedgerVerificationResult? _verificationResult;

  Future<void> _verifyAgainstLedger() async {
    setState(() {
      _isVerifying = true;
    });

    final result = await FabricLedgerService().queryStatusList(
      statusListIndex: widget.credential.statusListIndex,
      anchorHash: widget.credential.onChainAnchorHash,
      signature: widget.credential.proof['proofValue'] as String? ?? '',
      docId: widget.credential.fabricDocId,
    );

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _verificationResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.credential.student;
    final isArabic = AppLocalizations.isArabic;

    return Directionality(
      textDirection: AppLocalizations.textDirection,
      child: Scaffold(
        backgroundColor: AppColors.obsidianBlack,
        appBar: AppBar(
          title: Text(
            AppLocalizations.tr('metadata_inspector_title'),
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
              // Header Status Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slateCard,
                  borderRadius: BorderRadius.circular(16),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${student.studentId} • Bitstring #${widget.credential.statusListIndex}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: student.status),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Live Blockchain Verification Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withAlpha(90),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.goldPrimary.withAlpha(140),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.hub_rounded,
                          color: AppColors.goldPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hyperledger Fabric 2.5 Trust Check',
                          style: GoogleFonts.inter(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Queries NUVTE BitstringStatusList2021 on-chain without exposing student PII.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),

                    ElevatedButton.icon(
                      onPressed: _isVerifying ? null : _verifyAgainstLedger,
                      icon: _isVerifying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.obsidianBlack,
                              ),
                            )
                          : const Icon(Icons.security_update_good_rounded, size: 18),
                      label: Text(
                        _isVerifying
                            ? (isArabic ? 'جاري الاستعلام من البلوكشين...' : 'Querying Fabric Ledger...')
                            : (isArabic ? 'التحقق من حالة الإلغاء على البلوكشين' : 'Check Revocation Status On-Chain'),
                      ),
                    ),

                    if (_verificationResult != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.obsidianBlack,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _verificationResult!.isValid
                                ? AppColors.statusActive
                                : AppColors.statusRevoked,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _verificationResult!.isValid
                                      ? Icons.check_circle_rounded
                                      : Icons.error_rounded,
                                  color: _verificationResult!.isValid
                                      ? AppColors.statusActive
                                      : AppColors.statusRevoked,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _verificationResult!.statusDescription,
                                    style: TextStyle(
                                      color: _verificationResult!.isValid
                                          ? const Color(0xFFD1FAE5)
                                          : const Color(0xFFFEE2E2),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _verificationResult!.isLiveNetwork ? AppColors.statusActive : AppColors.goldPrimary,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _verificationResult!.isLiveNetwork
                                      ? 'Live Hyperledger Fabric 2.5 (nuvte-academic-channel)'
                                      : 'PAL-DFI Sandbox Simulation',
                                  style: const TextStyle(fontSize: 10, color: AppColors.goldLight, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tx ID: ${_verificationResult!.transactionId}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontFamily: 'monospace',
                                color: AppColors.goldPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Response Time: ${_verificationResult!.responseTimeMs}ms (< 3000ms NFR) • ${_verificationResult!.blockNumber}',
                              style: GoogleFonts.robotoMono(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Cryptographic Proofs Table
              _buildSectionTitle('Cryptographic Parameters & DIDs'),
              const SizedBox(height: 10),

              _buildInfoTile('Issuer DID', widget.credential.issuer),
              _buildInfoTile('Verification Method', '${widget.credential.issuer}#key-1'),
              _buildInfoTile('Signature Proof Type', 'Ed25519Signature2020'),
              _buildInfoTile('On-Chain Anchor Hash (SHA-256)', widget.credential.onChainAnchorHash, isMono: true),
              _buildInfoTile('Status List URI', widget.credential.statusListUri),

              const SizedBox(height: 20),

              // Raw JSON-LD Viewer
              _buildSectionTitle('W3C VC 2.0 JSON-LD Payload'),
              const SizedBox(height: 10),
              JsonLdViewer(credential: widget.credential),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: AppColors.goldPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {bool isMono = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.slateCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slateCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSubtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: isMono
                ? GoogleFonts.robotoMono(
                    color: AppColors.textLight,
                    fontSize: 11.5,
                  )
                : const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
          ),
        ],
      ),
    );
  }
}
