import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/student_issuance_request.dart';
import '../core/models/third_party_request.dart';
import '../core/models/verifiable_credential.dart';
import '../core/services/crypto_vault_service.dart';
import '../core/services/fabric_ledger_service.dart';
import '../core/services/id_plus_auth_service.dart';
import '../core/services/institution_governance_service.dart';
import '../core/services/wallet_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_footer.dart';
import '../widgets/clearance_certificate_card.dart';
import '../widgets/digital_id_card.dart';
import '../widgets/graduation_certificate_card.dart';
import '../widgets/unified_share_screen.dart';
import 'credential_detail_screen.dart';

class WalletHomeScreen extends StatefulWidget {
  final VoidCallback onLock;

  const WalletHomeScreen({
    super.key,
    required this.onLock,
  });

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends State<WalletHomeScreen> {
  final WalletStorageService _walletStorage = WalletStorageService();
  final CryptoVaultService _cryptoVault = CryptoVaultService();
  final IdPlusAuthService _idPlusAuth = IdPlusAuthService();

  @override
  void initState() {
    super.initState();
    _walletStorage.refreshActiveCredentialStatus();
  }

  void _handleIncomingRequestAuthorization(ThirdPartyRequest req) {
    _walletStorage.authorizeThirdPartyRequest(req.requestId);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.isArabic
              ? 'تم فك تشفير الوثيقة ومشاركتها مع جهة التحقق بنجاح!'
              : 'Document decrypted and shared with verifier!',
        ),
        backgroundColor: AppColors.statusActive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleIncomingRequestRejection(ThirdPartyRequest req) {
    _walletStorage.rejectThirdPartyRequest(req.requestId);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.isArabic ? 'تم رفض طلب المشاركة' : 'Sharing request rejected.',
        ),
        backgroundColor: AppColors.statusRevoked,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Operation 3: Show dialog for student to request document issuance from University / Onboarded Institutions
  void _openRequestDocumentDialog() {
    final isArabic = AppLocalizations.isArabic;
    final currentStudentId = _walletStorage.currentStudentId.value;
    final activeInstitutions = InstitutionGovernanceService().getActiveInstitutions();
    String selectedInstId = activeInstitutions.isNotEmpty ? activeInstitutions.first.id : 'INST-NUVTE-001';
    AcademicDocumentType selectedType = AcademicDocumentType.clearanceCertificate;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Directionality(
              textDirection: AppLocalizations.textDirection,
              child: AlertDialog(
                backgroundColor: AppColors.charcoalDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.goldPrimary, width: 1.2),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.post_add_rounded, color: AppColors.goldPrimary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isArabic ? 'طلب إصدار وثيقة من مؤسسة معتمدة' : 'Request Document from Institution',
                        style: GoogleFonts.cairo(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'اختر المؤسسة الأكاديمية / الحكومية:' : 'Select Issuing Institution / Authority:',
                        style: const TextStyle(color: AppColors.goldLight, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),

                      // Institution Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.slateCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.slateCardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedInstId,
                            isExpanded: true,
                            dropdownColor: AppColors.slateCard,
                            items: activeInstitutions.map((inst) {
                              return DropdownMenuItem<String>(
                                value: inst.id,
                                child: Text(
                                  isArabic ? inst.nameAr : inst.nameEn,
                                  style: const TextStyle(color: AppColors.textLight, fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedInstId = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        isArabic ? 'حدد نوع الوثيقة المطلوبة:' : 'Select Requested Document Type:',
                        style: const TextStyle(color: AppColors.goldLight, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),

                      // Document Type Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.slateCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.slateCardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<AcademicDocumentType>(
                            value: selectedType,
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
                              if (val != null) {
                                setDialogState(() => selectedType = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Notes / Justification
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: isArabic
                              ? 'سبب الطلب أو ملاحظات (مثلاً: استكمال مسوغات التوظيف)...'
                              : 'Reason or notes (e.g., employment onboarding)...',
                          hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.slateCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.slateCardBorder),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(
                      isArabic ? 'إلغاء' : 'Cancel',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _walletStorage.submitStudentIssuanceRequest(
                        studentId: currentStudentId,
                        documentType: selectedType,
                        notes: notesController.text.trim().isEmpty
                            ? 'Official academic document request.'
                            : notesController.text.trim(),
                      );
                      Navigator.pop(dialogCtx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isArabic
                                ? 'تم إرسال طلب إصدار الوثيقة لعمادة القبول والتسجيل بنجاح!'
                                : 'Issuance request submitted to the University Registrar!',
                          ),
                          backgroundColor: AppColors.statusActive,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text(isArabic ? 'إرسال الطلب' : 'Submit Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: AppColors.obsidianBlack,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.isArabic;
    final currentUser = _idPlusAuth.currentUser.value;
    final currentStudentId = _walletStorage.currentStudentId.value;

    return Directionality(
      textDirection: AppLocalizations.textDirection,
      child: Scaffold(
        backgroundColor: AppColors.obsidianBlack,
        appBar: AppBar(
          backgroundColor: AppColors.obsidianBlack,
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
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.goldPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser != null
                          ? (isArabic ? currentUser.fullNameAr : currentUser.fullNameEn)
                          : (isArabic ? 'محفظة الطالب' : 'Student Wallet'),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$currentStudentId • ${currentUser?.nationalId ?? "983421560"}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        color: AppColors.goldLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Language Switcher
            TextButton(
              onPressed: () {
                setState(() {
                  AppLocalizations.toggleLanguage();
                });
              },
              child: Text(
                isArabic ? 'English' : 'العربية',
                style: GoogleFonts.cairo(
                  color: AppColors.goldPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

            // Logout / ID+ switch
            IconButton(
              icon: const Icon(Icons.exit_to_app_rounded),
              color: AppColors.goldPrimary,
              tooltip: 'Switch Account (PMA ID+)',
              onPressed: widget.onLock,
            ),
          ],
        ),
        body: ValueListenableBuilder<List<VerifiableCredential>>(
          valueListenable: _walletStorage.credentials,
          builder: (context, credentialList, _) {
            return ValueListenableBuilder<VerifiableCredential?>(
              valueListenable: _walletStorage.activeCredential,
              builder: (context, activeVc, _) {
                if (activeVc == null && credentialList.isNotEmpty) {
                  activeVc = credentialList.first;
                }

                final isRevoked = activeVc?.student.isRevoked ?? false;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Blockchain Network Status Pill
                      _buildBlockchainStatusBadge(),
                      const SizedBox(height: 14),

                      // ==========================================
                      // OPERATION 2: THIRD-PARTY REQUEST NOTIFICATIONS
                      // ==========================================
                      _buildIncomingRequestsSection(currentStudentId),

                      // ==========================================
                      // OPERATION 1: ACADEMIC CREDENTIALS (FROM ISSUER)
                      // ==========================================
                      _buildSectionHeader(
                        title: isArabic ? '١. بيانات ووثائق الطالب من الجامعة' : '1. Academic Credentials from University',
                        subtitle: isArabic ? 'وثائق رقمية معتمدة ومثبتة على بلوكشين فابريك' : 'Verified credentials anchored on Hyperledger Fabric',
                        icon: Icons.badge_rounded,
                      ),
                      const SizedBox(height: 8),

                      // Revocation Alert Banner
                      if (isRevoked) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.statusRevoked.withAlpha(25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.statusRevoked, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.statusRevoked, size: 26),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isArabic
                                      ? 'تنبيه: تم إلغاء هذه الوثيقة في سجل البلوكشين من قبل إدارة الجامعة.'
                                      : 'ALERT: Credential marked as REVOKED on Hyperledger Fabric ledger.',
                                  style: const TextStyle(color: AppColors.statusRevoked, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (activeVc != null) ...[
                        // Document Type Tabs Selector (ID, Graduation, Clearance)
                        _buildDocumentTypeTabs(activeVc),
                        const SizedBox(height: 12),

                        // Active Document Card
                        _buildActiveDocumentCard(activeVc),
                        const SizedBox(height: 14),

                        // Actions for credential
                        Row(
                          children: [
                            // Unified Share / Present
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UnifiedShareScreen(
                                        initialCredential: activeVc!,
                                        actorTitle: 'Student Wallet Presentation',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                                label: Text(
                                  isArabic ? 'مشاركة الوثيقة' : 'Present QR / VP',
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.goldPrimary,
                                  foregroundColor: AppColors.obsidianBlack,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Inspect W3C & Blockchain Anchor
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openInspector(activeVc!),
                                icon: const Icon(Icons.verified_rounded, size: 18),
                                label: Text(
                                  isArabic ? 'فحص البلوكشين' : 'Inspect on Chain',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.goldLight,
                                  side: const BorderSide(color: AppColors.slateCardBorder),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.slateCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.slateCardBorder),
                          ),
                          child: Center(
                            child: Text(
                              isArabic ? 'لا توجد وثائق صادرة لهذا الطالب بعد.' : 'No credentials issued for this student yet.',
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ==========================================
                      // OPERATION 3: REQUEST DOCUMENT FROM ISSUER
                      // ==========================================
                      _buildSectionHeader(
                        title: isArabic ? '٣. طلب إصدار وثيقة جديدة من الجامعة' : '3. Request Document from University',
                        subtitle: isArabic ? 'تقديم طلب رسمي لعمادة القبول والتسجيل لإصدار شهادة' : 'Submit official request to Registrar to anchor new document',
                        icon: Icons.post_add_rounded,
                      ),
                      const SizedBox(height: 10),

                      // Action Button to Open Request Dialog
                      ElevatedButton.icon(
                        onPressed: _openRequestDocumentDialog,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        label: Text(
                          isArabic ? 'تقديم طلب إصدار وثيقة جديدة' : 'Submit New Document Request',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyPrimary,
                          foregroundColor: AppColors.goldPrimary,
                          side: const BorderSide(color: AppColors.goldPrimary, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Student's Requests History List
                      _buildStudentRequestsHistory(currentStudentId),

                      const SizedBox(height: 20),

                      // Security Vault Footer
                      _buildSecurityVaultCard(),

                      const SizedBox(height: 16),

                      // Brand Footer with ID+ & FacePal Sense
                      const BrandFooter(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.goldPrimary, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  color: AppColors.goldLight,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  /// Operation 2: Notifications when third party requests a document
  Widget _buildIncomingRequestsSection(String currentStudentId) {
    final isArabic = AppLocalizations.isArabic;
    return ValueListenableBuilder<List<ThirdPartyRequest>>(
      valueListenable: _walletStorage.thirdPartyRequests,
      builder: (context, allRequests, _) {
        final studentRequests = allRequests.where((r) => r.targetStudentId == currentStudentId).toList();
        final pending = studentRequests.where((r) => r.isPending).toList();

        if (pending.isEmpty) {
          // Check if there are authorized/shared requests to show status
          final authorized = studentRequests.where((r) => r.isShared).toList();
          if (authorized.isNotEmpty) {
            final latestAuth = authorized.first;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.charcoalDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.statusActive.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.statusActive, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      latestAuth.isVerified
                          ? (isArabic
                              ? 'تمت مشاركة (${latestAuth.requestedDocTitleAr}) والتحقق منها بنجاح من قبل ${latestAuth.verifierNameAr}'
                              : 'Shared (${latestAuth.requestedDocTitleEn}) & verified on Fabric by ${latestAuth.verifierNameEn}')
                          : (isArabic
                              ? 'تمت مشاركة (${latestAuth.requestedDocTitleAr}) مع ${latestAuth.verifierNameAr}'
                              : 'Shared (${latestAuth.requestedDocTitleEn}) with ${latestAuth.verifierNameEn}'),
                      style: const TextStyle(color: AppColors.textLight, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final req = pending.first;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.navyPrimary.withAlpha(140),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.goldPrimary, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldPrimary.withAlpha(50),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notification_important_rounded, color: AppColors.goldPrimary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isArabic ? 'إشعار طلب وثيقة من جهة خارجية' : 'Incoming Document Request Alert',
                      style: GoogleFonts.cairo(
                        color: AppColors.goldLight,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isArabic ? 'مطلوب موافقتك' : 'APPROVAL REQUIRED',
                      style: const TextStyle(color: AppColors.obsidianBlack, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${isArabic ? "الجهة الطالبة:" : "Request from:"} ${isArabic ? req.verifierNameAr : req.verifierNameEn}',
                style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              Text(
                '${isArabic ? "الوثيقة المطلوبة:" : "Requested Document:"} ${isArabic ? req.requestedDocTitleAr : req.requestedDocTitleEn}',
                style: const TextStyle(color: AppColors.goldLight, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${isArabic ? "الغرض:" : "Purpose:"} ${isArabic ? req.purposeAr : req.purposeEn}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleIncomingRequestAuthorization(req),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusActive,
                        foregroundColor: AppColors.obsidianBlack,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(
                        isArabic ? 'موافقة ومشاركة الوثيقة' : 'Approve & Share Document',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _handleIncomingRequestRejection(req),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusRevoked,
                      side: const BorderSide(color: AppColors.statusRevoked),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: Text(
                      isArabic ? 'رفض' : 'Reject',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Operation 3: Displays student's request history
  Widget _buildStudentRequestsHistory(String studentId) {
    final isArabic = AppLocalizations.isArabic;
    return ValueListenableBuilder<List<StudentIssuanceRequest>>(
      valueListenable: _walletStorage.studentIssuanceRequests,
      builder: (context, allRequests, _) {
        final myRequests = allRequests.where((r) => r.studentId == studentId).toList();
        if (myRequests.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.slateCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slateCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'سجل طلبات الوثائق المقدمة للجامعة:' : 'My Document Requests to Registrar:',
                style: GoogleFonts.cairo(
                  color: AppColors.textLight,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...myRequests.map((req) {
                Color statusColor;
                String statusLabel;
                if (req.isIssued) {
                  statusColor = AppColors.statusActive;
                  statusLabel = isArabic ? 'تم الإصدار على البلوكشين' : 'ISSUED ON FABRIC';
                } else if (req.isRejected) {
                  statusColor = AppColors.statusRevoked;
                  statusLabel = isArabic ? 'مرفوض' : 'REJECTED';
                } else {
                  statusColor = AppColors.goldPrimary;
                  statusLabel = isArabic ? 'قيد المراجعة' : 'PENDING REGISTRAR';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.charcoalDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withAlpha(90)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        req.isIssued ? Icons.verified_rounded : (req.isRejected ? Icons.cancel_rounded : Icons.pending_rounded),
                        color: statusColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? req.documentTitleAr : req.documentTitleEn,
                              style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            if (req.isIssued && req.issuedDocId != null) ...[
                              Text(
                                '${req.issuedDocId} • Tx: ${req.txId?.substring(0, 14)}...',
                                style: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 9.5),
                              ),
                            ] else if (req.isRejected && req.rejectionReason != null) ...[
                              Text(
                                '${isArabic ? "السبب:" : "Reason:"} ${req.rejectionReason}',
                                style: const TextStyle(color: AppColors.statusRevoked, fontSize: 10.5),
                              ),
                            ] else ...[
                              Text(
                                req.notes,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockchainStatusBadge() {
    return ValueListenableBuilder<bool>(
      valueListenable: FabricLedgerService().isLiveConnected,
      builder: (context, isLive, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isLive ? const Color(0xFF0F2E1E) : AppColors.navyPrimary.withAlpha(120),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isLive ? const Color(0xFF22C55E) : AppColors.goldPrimary.withAlpha(120),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLive ? const Color(0xFF22C55E) : AppColors.goldPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isLive
                      ? 'Live Hyperledger Fabric 2.5 Active (nuvte-academic-channel @ peer0:7051)'
                      : 'Connecting to Hyperledger Fabric Network...',
                  style: TextStyle(
                    color: isLive ? const Color(0xFF86EFAC) : AppColors.goldLight,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.obsidianBlack,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLive ? 'PORT 5050' : 'FABRIC',
                  style: const TextStyle(
                    color: AppColors.goldPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentTypeTabs(VerifiableCredential activeVc) {
    final allDocs = _walletStorage.credentials.value;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: allDocs.map((doc) {
          final isSelected = doc.id == activeVc.id;
          IconData icon;
          switch (doc.documentType) {
            case AcademicDocumentType.studentId:
              icon = Icons.badge_rounded;
              break;
            case AcademicDocumentType.graduationCertificate:
              icon = Icons.workspace_premium_rounded;
              break;
            case AcademicDocumentType.clearanceCertificate:
              icon = Icons.verified_user_rounded;
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.obsidianBlack : AppColors.goldPrimary,
              ),
              label: Text(
                AppLocalizations.isArabic ? doc.documentTitleAr : doc.documentTitleEn,
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
                  _walletStorage.activeCredential.value = doc;
                  _walletStorage.refreshActiveCredentialStatus();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveDocumentCard(VerifiableCredential activeVc) {
    switch (activeVc.documentType) {
      case AcademicDocumentType.studentId:
        return DigitalIdCard(
          credential: activeVc,
          onTap: () => _openInspector(activeVc),
        );
      case AcademicDocumentType.graduationCertificate:
        return GraduationCertificateCard(
          credential: activeVc,
          onTap: () => _openInspector(activeVc),
        );
      case AcademicDocumentType.clearanceCertificate:
        return ClearanceCertificateCard(
          credential: activeVc,
          onTap: () => _openInspector(activeVc),
        );
    }
  }

  void _openInspector(VerifiableCredential vc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CredentialDetailScreen(credential: vc),
      ),
    );
  }

  Widget _buildSecurityVaultCard() {
    final didKey = _cryptoVault.didKey;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slateCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.goldPrimary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.isArabic ? 'الخزينة الرقمية السيادية (W3C DID)' : 'Sovereign Digital Enclave (W3C DID)',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            didKey,
            style: GoogleFonts.robotoMono(
              color: AppColors.goldLight,
              fontSize: 9.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
