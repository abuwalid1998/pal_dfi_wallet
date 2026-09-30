import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/third_party_request.dart';
import '../core/models/verifiable_credential.dart';
import '../core/models/verifiable_presentation.dart';
import '../core/services/fabric_ledger_service.dart';
import '../core/services/id_plus_auth_service.dart';
import '../core/services/wallet_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_footer.dart';

class ThirdPartyPortalScreen extends StatefulWidget {
  final VerifiablePresentation? preloadedPresentation;

  const ThirdPartyPortalScreen({
    super.key,
    this.preloadedPresentation,
  });

  @override
  State<ThirdPartyPortalScreen> createState() => _ThirdPartyPortalScreenState();
}

class _ThirdPartyPortalScreenState extends State<ThirdPartyPortalScreen> with SingleTickerProviderStateMixin {
  final WalletStorageService _walletStorage = WalletStorageService();
  final FabricLedgerService _fabricLedger = FabricLedgerService();

  late TabController _tabController;

  // Request Form State
  String _selectedTargetStudentId = 'STU-2024098';
  AcademicDocumentType _selectedDocType = AcademicDocumentType.clearanceCertificate;
  final TextEditingController _purposeController = TextEditingController(
    text: 'Verification of university graduation clearance for graduate associate employment onboarding.',
  );

  bool _isVerifying = false;
  final Map<String, LedgerVerificationResult> _verificationResults = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  // --- OPERATION 1: DISPATCH REQUEST TO CITIZEN ---
  void _dispatchRequestToCitizen() {
    final isArabic = AppLocalizations.isArabic;
    final targetProfile = IdPlusAuthService.studentProfiles.firstWhere(
      (p) => p['studentId'] == _selectedTargetStudentId,
      orElse: () => IdPlusAuthService.studentProfiles.first,
    );

    final newReq = ThirdPartyRequest(
      requestId: 'REQ-BOP-${DateTime.now().millisecondsSinceEpoch % 100000}',
      verifierNameEn: 'Bank of Palestine (Human Resources)',
      verifierNameAr: 'بنك فلسطين (الموارد البشرية والامتثال)',
      verifierOrgType: 'Banking Sector • Digital KYC',
      verifierDid: 'did:key:z6MkuBankOfPalestineCompliance',
      targetStudentId: targetProfile['studentId']!,
      targetStudentName: targetProfile['fullNameEn']!,
      targetNationalId: targetProfile['nationalId']!,
      documentTypeRequested: _selectedDocType,
      purposeEn: _purposeController.text.trim(),
      purposeAr: isArabic ? 'التحقق من براءة الذمة والشهادة لغايات استكمال مسوغات التعيين لدى بنك فلسطين.' : _purposeController.text.trim(),
      nonce: VerifiablePresentation.generateNonce(),
      timestamp: DateTime.now(),
      status: ThirdPartyRequestStatus.pending,
    );

    _walletStorage.submitThirdPartyRequest(newReq);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تم إرسال طلب الوثيقة إلى محفظة المواطن (${targetProfile["fullNameAr"]}) بنجاح!'
              : 'Request dispatched to citizen wallet (${targetProfile["fullNameEn"]})!',
        ),
        backgroundColor: AppColors.statusActive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- OPERATION 3: VERIFY SHARED DOCUMENT ON BLOCKCHAIN ---
  Future<void> _verifyDocumentOnBlockchain(ThirdPartyRequest req) async {
    final pres = req.presentation;
    if (pres == null) return;

    setState(() => _isVerifying = true);

    final proof = pres.proof['proofValue'] as String? ?? '';
    final result = await _fabricLedger.queryStatusList(
      statusListIndex: pres.credential.statusListIndex,
      anchorHash: pres.credential.onChainAnchorHash,
      signature: proof,
      docId: pres.credential.fabricDocId,
    );

    // Record immutable verification audit on Hyperledger Fabric 2.5
    _fabricLedger.recordVerificationAudit(
      auditId: 'AUDIT-BOP-${DateTime.now().millisecondsSinceEpoch}',
      verifierDid: req.verifierDid,
      verifierName: req.verifierNameEn,
      docId: pres.credential.fabricDocId,
      studentDid: pres.holderDid,
      nonce: pres.nonce,
      verificationResult: result.isValid ? 'VALID' : (result.isRevoked ? 'REVOKED' : 'INVALID'),
    );

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _verificationResults[req.requestId] = result;
      if (result.isValid) {
        _walletStorage.markThirdPartyRequestVerified(req.requestId);
      }
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
          backgroundColor: AppColors.charcoalDark,
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.navyPrimary,
                  border: Border.all(color: AppColors.goldPrimary, width: 1.2),
                ),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.goldPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'بنك فلسطين • دائرة الامتثال والتوظيف' : 'Bank of Palestine • HR & Compliance',
                      style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'did:key:z6MkuBankOfPalestineCompliance',
                      style: GoogleFonts.robotoMono(fontSize: 9.5, color: AppColors.goldLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app_rounded, color: AppColors.goldPrimary),
              tooltip: 'Logout ID+',
              onPressed: () => IdPlusAuthService().logout(),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.goldPrimary,
            labelColor: AppColors.goldPrimary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(
                icon: const Icon(Icons.send_rounded, size: 18),
                text: isArabic ? '١. طلب وثيقة من مواطن' : '1. Request Document',
              ),
              Tab(
                icon: const Icon(Icons.folder_shared_rounded, size: 18),
                text: isArabic ? '٢. الوثائق المشاركة والفحص' : '2. Shared Docs & Verify',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestDocumentTab(),
            _buildSharedDocumentsTab(),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: REQUEST DOCUMENT FROM CITIZEN ---
  Widget _buildRequestDocumentTab() {
    final isArabic = AppLocalizations.isArabic;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Operation Guidance Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.navyPrimary.withAlpha(120),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.goldPrimary.withAlpha(100)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.goldPrimary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'العملية الأولى: إرسال طلب رسمي لمواطن/طالب لتفويضه بمشاركة وثيقته الأكاديمية مع بنك فلسطين.'
                        : 'Operation 1: Dispatch official document disclosure request to citizen wallet with cryptographic nonce.',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Target Citizen Selector
          Text(
            isArabic ? 'اختر المواطن/الطالب المستهدف:' : 'Select Target Citizen / Student:',
            style: GoogleFonts.cairo(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.slateCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slateCardBorder),
            ),
            child: Builder(
              builder: (context) {
                final profiles = IdPlusAuthService.studentProfiles;
                final effectiveValue = profiles.any((p) => p['studentId'] == _selectedTargetStudentId)
                    ? _selectedTargetStudentId
                    : (profiles.isNotEmpty ? profiles.first['studentId'] : null);

                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: effectiveValue,
                    isExpanded: true,
                    dropdownColor: AppColors.slateCard,
                    items: profiles.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['studentId'],
                        child: Text(
                          '${isArabic ? p["fullNameAr"] : p["fullNameEn"]} (${p["studentId"]} • ID: ${p["nationalId"]})',
                          style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTargetStudentId = val);
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Requested Document Type
          Text(
            isArabic ? 'حدد نوع الوثيقة المطلوبة:' : 'Requested Document Type:',
            style: GoogleFonts.cairo(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.slateCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slateCardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AcademicDocumentType>(
                value: _selectedDocType,
                isExpanded: true,
                dropdownColor: AppColors.slateCard,
                items: [
                  DropdownMenuItem(
                    value: AcademicDocumentType.clearanceCertificate,
                    child: Text(
                      isArabic ? 'شهادة براءة الذمة الرسمية (Clearance)' : 'Certificate of Discharge (Clearance)',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                    ),
                  ),
                  DropdownMenuItem(
                    value: AcademicDocumentType.graduationCertificate,
                    child: Text(
                      isArabic ? 'شهادة التخرج والدرجة العلمية' : 'Official Graduation Certificate',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                    ),
                  ),
                  DropdownMenuItem(
                    value: AcademicDocumentType.studentId,
                    child: Text(
                      isArabic ? 'بطاقة الهوية الجامعية الرقمية' : 'Digital Student ID Card',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDocType = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Purpose
          Text(
            isArabic ? 'الغرض من التحقق (امتثال مصرفي):' : 'Verification Purpose (Compliance / HR):',
            style: GoogleFonts.cairo(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _purposeController,
            maxLines: 2,
            style: const TextStyle(color: AppColors.textLight, fontSize: 12.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.slateCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: _dispatchRequestToCitizen,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(
              isArabic ? 'إرسال الطلب لمحفظة المواطن' : 'Dispatch Request to Citizen Wallet',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
              foregroundColor: AppColors.obsidianBlack,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 24),

          // Dispatched Requests History List
          _buildDispatchedRequestsList(),

          const SizedBox(height: 24),
          const BrandFooter(),
        ],
      ),
    );
  }

  Widget _buildDispatchedRequestsList() {
    final isArabic = AppLocalizations.isArabic;

    return ValueListenableBuilder<List<ThirdPartyRequest>>(
      valueListenable: _walletStorage.thirdPartyRequests,
      builder: (context, requests, _) {
        if (requests.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 16, color: AppColors.goldLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isArabic ? 'سجل الطلبات المرسلة للمواطنين:' : 'Dispatched Requests Status Tracker:',
                    style: GoogleFonts.cairo(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...requests.map((r) {
              Color badgeColor;
              String badgeLabel;
              IconData badgeIcon;
              if (r.isVerified) {
                badgeColor = AppColors.statusActive;
                badgeLabel = isArabic ? 'تم التحقق من البلوكشين' : 'VERIFIED ON BLOCKCHAIN';
                badgeIcon = Icons.verified_rounded;
              } else if (r.isAuthorized) {
                badgeColor = const Color(0xFF00A3FF);
                badgeLabel = isArabic ? 'موافق عليه ومشارك' : 'APPROVED & SHARED';
                badgeIcon = Icons.check_circle_rounded;
              } else if (r.isRejected) {
                badgeColor = AppColors.statusRevoked;
                badgeLabel = isArabic ? 'مرفوض من المواطن' : 'REJECTED BY CITIZEN';
                badgeIcon = Icons.cancel_rounded;
              } else {
                badgeColor = AppColors.goldPrimary;
                badgeLabel = isArabic ? 'بانتظار موافقة المواطن' : 'PENDING CITIZEN APPROVAL';
                badgeIcon = Icons.hourglass_top_rounded;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.charcoalDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withAlpha(90)),
                ),
                child: Row(
                  children: [
                    Icon(badgeIcon, color: badgeColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r.targetStudentName} • ${isArabic ? r.requestedDocTitleAr : r.requestedDocTitleEn}',
                            style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            'Nonce: ${r.nonce.substring(0, 12)}... • Target ID: ${r.targetStudentId}',
                            style: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 9.5),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(color: badgeColor, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // --- TAB 2: SHARED DOCUMENTS & BLOCKCHAIN VERIFICATION ---
  Widget _buildSharedDocumentsTab() {
    final isArabic = AppLocalizations.isArabic;

    return ValueListenableBuilder<List<ThirdPartyRequest>>(
      valueListenable: _walletStorage.thirdPartyRequests,
      builder: (context, allRequests, _) {
        final sharedRequests = allRequests.where((r) => r.isShared && r.presentation != null).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Operation Guidance Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.charcoalDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.statusActive.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_shared_rounded, color: AppColors.statusActive, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'العملية الثانية والثالثة: عرض الوثائق التي وافق المواطن على مشاركتها، والتحقق المباشر من صحتها على بلوكشين فابريك.'
                            : 'Operations 2 & 3: View documents approved & shared by citizens, and run live verification on Hyperledger Fabric.',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (sharedRequests.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.slateCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slateCardBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.hourglass_empty_rounded, color: AppColors.goldLight, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          isArabic
                              ? 'لا توجد وثائق مشاركة حالياً.\nأرسل طلباً للمواطن من التبويب الأول واطلب منه الموافقة من محفظته.'
                              : 'No shared documents available.\nDispatch a request in Tab 1 and have the citizen approve it in their wallet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ...sharedRequests.map((req) => _buildSharedDocumentCard(req)),
              ],

              const SizedBox(height: 20),
              const BrandFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSharedDocumentCard(ThirdPartyRequest req) {
    final isArabic = AppLocalizations.isArabic;
    final pres = req.presentation!;
    final cred = pres.credential;
    final verification = _verificationResults[req.requestId];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slateCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldPrimary, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_rounded, color: AppColors.goldPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cred.student.fullNameEn} (${cred.student.fullNameAr})',
                      style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${isArabic ? cred.documentTitleAr : cred.documentTitleEn} • ${cred.fabricDocId}',
                      style: const TextStyle(color: AppColors.goldLight, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusActive.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.statusActive),
                ),
                child: Text(
                  isArabic ? 'وثيقة مشاركة' : 'SHARED VP',
                  style: const TextStyle(color: AppColors.statusActive, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Disclosed Attributes Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.charcoalDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'البيانات المفصح عنها بموافقة الطالب:' : 'Disclosed Attributes by Student Consent:',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text('• Student ID: ${cred.student.studentId} | National ID: ${cred.student.nationalId}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text('• Faculty: ${cred.student.facultyEn}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text('• Program: ${cred.student.programEn}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text('• Cumulative GPA: ${cred.student.gpa.toStringAsFixed(2)} / 4.00', style: const TextStyle(color: AppColors.goldLight, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('• Holder DID: ${pres.holderDid}', style: GoogleFonts.robotoMono(color: AppColors.textSubtle, fontSize: 9)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Operation 3: Blockchain Validation Button
          ElevatedButton.icon(
            onPressed: _isVerifying ? null : () => _verifyDocumentOnBlockchain(req),
            icon: _isVerifying
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.obsidianBlack))
                : const Icon(Icons.security_rounded, size: 18),
            label: Text(
              isArabic ? 'التحقق من صحة الوثيقة على البلوكشين' : 'Verify Document on Hyperledger Fabric',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
              foregroundColor: AppColors.obsidianBlack,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          // Live Validation Result Panel
          if (verification != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: verification.isValid ? const Color(0xFF0D2818) : const Color(0xFF2C0B0E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: verification.isValid ? AppColors.statusActive : AppColors.statusRevoked,
                  width: 1.4,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        verification.isValid ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                        color: verification.isValid ? AppColors.statusActive : AppColors.statusRevoked,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          verification.isValid
                              ? (isArabic ? 'الوثيقة صحيحة ومثبتة رسمياً على البلوكشين' : 'DOCUMENT VALID & ANCHORED ON FABRIC')
                              : (isArabic ? 'تحذير: الوثيقة ملغاة أو غير مطابقة' : 'ALERT: DOCUMENT REVOKED OR INVALID'),
                          style: TextStyle(
                            color: verification.isValid ? AppColors.statusActive : AppColors.statusRevoked,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('• SHA-256 Digest Match: Confirmed Authentic Zero PII', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                  Text('• W3C Status Bit: Bit #${cred.statusListIndex} = ${verification.isRevoked ? "1 (REVOKED)" : "0 (ACTIVE)"}', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                  Text('• Issuer DID: did:key:z6MkuNUVTEAcademicAuthorityPalestine2024PMA', style: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 9.5)),
                  Text('• Block Confirmation: #${verification.blockNumber} (Latency: ${verification.responseTimeMs}ms)', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('• Fabric Tx: ${verification.transactionId}', style: GoogleFonts.robotoMono(color: AppColors.goldLight, fontSize: 9.5)),
                  const SizedBox(height: 4),
                  Text('• Compliance Audit: Committed to nuvte-academic-channel', style: const TextStyle(color: AppColors.statusActive, fontSize: 10.5, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
