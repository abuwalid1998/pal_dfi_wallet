import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/student_issuance_request.dart';
import '../core/services/fabric_ledger_service.dart';
import '../core/services/id_plus_auth_service.dart';
import '../core/services/wallet_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_footer.dart';

class RegistrarIssuancePortalScreen extends StatefulWidget {
  const RegistrarIssuancePortalScreen({super.key});

  @override
  State<RegistrarIssuancePortalScreen> createState() =>
      _RegistrarIssuancePortalScreenState();
}

class _RegistrarIssuancePortalScreenState
    extends State<RegistrarIssuancePortalScreen> with SingleTickerProviderStateMixin {
  final FabricLedgerService _ledger = FabricLedgerService();
  final WalletStorageService _walletStorage = WalletStorageService();

  late TabController _tabController;
  bool _isProcessing = false;

  // Selected student for Revocation Registry (Operation 2)
  String _selectedStudentIdForRevocation = 'STU-2024098';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- OPERATION 1: ISSUE OR REJECT STUDENT REQUEST ---

  Future<void> _handleApproveAndIssue(StudentIssuanceRequest req) async {
    setState(() => _isProcessing = true);

    final res = await _walletStorage.approveAndIssueStudentDocument(
      requestId: req.requestId,
      employeeId: 'EMP-90012',
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    final isArabic = AppLocalizations.isArabic;
    if (res['success'] == true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.charcoalDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.goldPrimary),
          ),
          title: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.statusActive, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? 'تم الإصدار على البلوكشين بنجاح' : 'Issued on Hyperledger Fabric',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic
                    ? 'تم توثيق وثيقة (${req.documentTitleAr}) للطالب ${req.studentNameAr} على القناة الأكاديمية بنجاح.'
                    : 'Credential (${req.documentTitleEn}) successfully anchored for ${req.studentNameEn}.',
                style: const TextStyle(color: AppColors.textLight, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.obsidianBlack,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.slateCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Document ID: ${res["docId"]}', style: GoogleFonts.robotoMono(color: AppColors.goldLight, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('Fabric Tx: ${res["txId"]}', style: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary, foregroundColor: AppColors.obsidianBlack),
              child: Text(isArabic ? 'حسناً' : 'Done'),
            ),
          ],
        ),
      );
    }
  }

  void _handleRejectDialog(StudentIssuanceRequest req) {
    final isArabic = AppLocalizations.isArabic;
    final reasonController = TextEditingController(
      text: isArabic ? 'استحقاقات مالية متبقية أو عدم استكمال متطلبات التخرج' : 'Outstanding tuition fees or incomplete requirements',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoalDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.statusRevoked),
        ),
        title: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: AppColors.statusRevoked, size: 24),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'رفض طلب الوثيقة' : 'Reject Issuance Request',
              style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                ? 'يرجى توضيح سبب رفض طلب (${req.documentTitleAr}) للطالب ${req.studentNameAr}:'
                : 'State the rejection reason for ${req.studentNameEn}\'s request:',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textLight, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.slateCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              _walletStorage.rejectStudentIssuanceRequest(
                requestId: req.requestId,
                reason: reasonController.text.trim(),
              );
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isArabic ? 'تم رفض الطلب وتحديث حالة الطالب' : 'Request rejected.'),
                  backgroundColor: AppColors.statusRevoked,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRevoked, foregroundColor: Colors.white),
            child: Text(isArabic ? 'تأكيد الرفض' : 'Confirm Reject'),
          ),
        ],
      ),
    );
  }

  // --- OPERATION 2: REVOKE OR REINSTATE DOCUMENT ---

  Future<void> _toggleDocumentRevocation({
    required String docId,
    required int bitIndex,
    required bool isCurrentlyRevoked,
    required String docTitle,
  }) async {
    final nextState = !isCurrentlyRevoked;
    setState(() => _isProcessing = true);

    final res = await _ledger.toggleDocumentRevocationOnChain(
      docId: docId,
      statusListIndex: bitIndex,
      isRevoking: nextState,
      reason: nextState ? 'Disciplinary Board Suspension Decree' : 'Official Registrar Reinstatement Decree',
    );

    _ledger.setRevocationStatus(bitIndex, nextState);
    await _walletStorage.syncStudentVault(_selectedStudentIdForRevocation);
    if (_walletStorage.currentStudentId.value == _selectedStudentIdForRevocation) {
      await _walletStorage.syncAllCredentialsWithLedger();
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    final isArabic = AppLocalizations.isArabic;
    final isLive = res['isLive'] == true;
    final txId = res['txId'] as String? ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'تم تحديث حالة الوثيقة ($docTitle) على البلوكشين: ${nextState ? "ملغاة (Bit=1)" : "نشطة (Bit=0)"}'
                  : '$docTitle status updated on Fabric: ${nextState ? "REVOKED (Bit=1)" : "ACTIVE (Bit=0)"}.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              '${isLive ? "🟢 Fabric Tx:" : "🟡 Local Tx:"} $txId',
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ],
        ),
        backgroundColor: nextState ? AppColors.statusRevoked : AppColors.statusActive,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.goldPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'عمادة القبول والتسجيل • جامعة نابلس' : 'Faculty of Registration & Academic Affairs',
                      style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isArabic ? 'د. رائد القطب • صلاحيات جهة الإصدار' : 'Dr. Raed Al-Qutob • University Issuer Node',
                      style: GoogleFonts.robotoMono(fontSize: 10, color: AppColors.goldLight),
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
                icon: const Icon(Icons.inbox_rounded, size: 18),
                text: isArabic ? '١. طلبات وثائق الطلبة' : '1. Student Requests',
              ),
              Tab(
                icon: const Icon(Icons.gavel_rounded, size: 18),
                text: isArabic ? '٢. سجل إلغاء الوثائق' : '2. Revocation Registry',
              ),
            ],
          ),
        ),
        body: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.goldPrimary),
                    SizedBox(height: 14),
                    Text(
                      'Committing transaction to Hyperledger Fabric...',
                      style: TextStyle(color: AppColors.goldLight, fontSize: 12),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildStudentRequestsTab(),
                  _buildRevocationRegistryTab(),
                ],
              ),
      ),
    );
  }

  // --- TAB 1: STUDENT REQUESTS QUEUE ---
  Widget _buildStudentRequestsTab() {
    final isArabic = AppLocalizations.isArabic;

    return ValueListenableBuilder<List<StudentIssuanceRequest>>(
      valueListenable: _walletStorage.studentIssuanceRequests,
      builder: (context, requests, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Operational Guidance Banner
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
                            ? 'العملية الأولى: مراجعة طلبات الوثائق المقدمة من الطلبة، وإصدارها وتوثيقها مباشرة على بلوكشين فابريك أو رفضها.'
                            : 'Operation 1: Review incoming document requests from students and anchor them on Hyperledger Fabric or reject.',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (requests.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.slateCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      isArabic ? 'لا توجد طلبات وثائق واردة حالياً.' : 'No student requests in queue.',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ] else ...[
                ...requests.map((req) => _buildRequestCard(req)),
              ],

              const SizedBox(height: 20),
              const BrandFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(StudentIssuanceRequest req) {
    final isArabic = AppLocalizations.isArabic;
    Color statusColor;
    String statusTitle;

    if (req.isIssued) {
      statusColor = AppColors.statusActive;
      statusTitle = isArabic ? 'تم الإصدار على البلوكشين' : 'ISSUED ON FABRIC';
    } else if (req.isRejected) {
      statusColor = AppColors.statusRevoked;
      statusTitle = isArabic ? 'مرفوض' : 'REJECTED';
    } else {
      statusColor = AppColors.goldPrimary;
      statusTitle = isArabic ? 'بانتظار قرار العمادة' : 'PENDING APPROVAL';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slateCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: req.isPending ? AppColors.goldPrimary.withAlpha(120) : AppColors.slateCardBorder,
          width: req.isPending ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.goldPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? req.studentNameAr : req.studentNameEn,
                      style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${req.studentId} • ID: ${req.nationalId}',
                      style: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusTitle,
                  style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.charcoalDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_rounded, color: AppColors.goldLight, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isArabic ? req.documentTitleAr : req.documentTitleEn,
                        style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${isArabic ? "ملاحظات الطالب:" : "Student Note:"} ${req.notes}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                if (req.isIssued && req.issuedDocId != null) ...[
                  const SizedBox(height: 6),
                  Text('Anchored Doc ID: ${req.issuedDocId}', style: GoogleFonts.robotoMono(color: AppColors.statusActive, fontSize: 10)),
                  Text('Tx ID: ${req.txId}', style: GoogleFonts.robotoMono(color: AppColors.textSubtle, fontSize: 9.5)),
                ] else if (req.isRejected && req.rejectionReason != null) ...[
                  const SizedBox(height: 6),
                  Text('${isArabic ? "سبب الرفض:" : "Reason:"} ${req.rejectionReason}', style: const TextStyle(color: AppColors.statusRevoked, fontSize: 11)),
                ],
              ],
            ),
          ),
          if (req.isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApproveAndIssue(req),
                    icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                    label: Text(
                      isArabic ? 'إصدار وتثبيت على البلوكشين' : 'Issue & Anchor on Chain',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: AppColors.obsidianBlack,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _handleRejectDialog(req),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(isArabic ? 'رفض' : 'Reject', style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusRevoked,
                    side: const BorderSide(color: AppColors.statusRevoked),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 2: REVOCATION REGISTRY ---
  Widget _buildRevocationRegistryTab() {
    final isArabic = AppLocalizations.isArabic;
    final dynamicStudentsList = IdPlusAuthService().dynamicStudents.value;
    
    // Fallback if selected student is not set or not found
    if (dynamicStudentsList.isNotEmpty &&
        !dynamicStudentsList.any((s) => s['studentId'] == _selectedStudentIdForRevocation || s['candidateId'] == _selectedStudentIdForRevocation)) {
      _selectedStudentIdForRevocation = dynamicStudentsList.first['studentId'] ?? dynamicStudentsList.first['candidateId'] ?? 'STU-2024098';
    }

    final selectedStudent = _walletStorage.getStudentProfile(_selectedStudentIdForRevocation);
    final studentDocs = _walletStorage.getStudentDocuments(_selectedStudentIdForRevocation);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Operation 2 Guidance Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.charcoalDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.statusRevoked.withAlpha(100)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gavel_rounded, color: AppColors.statusRevoked, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'العملية الثانية: إدارة سجل إلغاء وتفعيل الوثائق الصادرة للطلبة على البلوكشين عبر تعديل مصفوفة W3C Bitstring.'
                        : 'Operation 2: Revoke or reinstate academic documents on Hyperledger Fabric by flipping W3C status list bits.',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Student Selector Chips
          Text(
            isArabic ? 'اختر الطالب لإدارة وثائقه:' : 'Select Student to Manage Documents:',
            style: GoogleFonts.cairo(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),

          if (dynamicStudentsList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                isArabic ? 'لا يوجد طلاب مسجلون حالياً. ابدأ بتسجيل طالب جديد.' : 'No enrolled students found. Start onboarding a new student.',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: dynamicStudentsList.map((s) {
                  final sId = s['studentId'] ?? s['candidateId'] ?? '';
                  final name = isArabic ? (s['fullNameAr'] ?? sId) : (s['fullNameEn'] ?? sId);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildStudentSelectorChip(sId, name),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 18),

          // Selected Student Summary Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slateCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slateCardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded, color: AppColors.goldPrimary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${isArabic ? selectedStudent.fullNameAr : selectedStudent.fullNameEn} • ${selectedStudent.studentId} • ${selectedStudent.academicYear}',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // List of Documents for this Student
          ...studentDocs.map((doc) {
            final bitIndex = doc.statusListIndex;
            final isRevokedOnChain = _ledger.isBitRevoked(bitIndex);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.charcoalDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRevokedOnChain ? AppColors.statusRevoked.withAlpha(120) : AppColors.statusActive.withAlpha(100),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isRevokedOnChain ? AppColors.statusRevoked.withAlpha(25) : AppColors.statusActive.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isRevokedOnChain ? Icons.block_rounded : Icons.verified_rounded,
                      color: isRevokedOnChain ? AppColors.statusRevoked : AppColors.statusActive,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? doc.documentTitleAr : doc.documentTitleEn,
                          style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${doc.fabricDocId} • Bit #$bitIndex',
                          style: GoogleFonts.robotoMono(color: AppColors.goldLight, fontSize: 10.5),
                        ),
                        Text(
                          isRevokedOnChain
                              ? (isArabic ? 'الحالة: ملغاة رسمياً على البلوكشين' : 'Status: REVOKED ON LEDGER')
                              : (isArabic ? 'الحالة: نشطة وصالحة' : 'Status: ACTIVE ON LEDGER'),
                          style: TextStyle(
                            color: isRevokedOnChain ? AppColors.statusRevoked : AppColors.statusActive,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _toggleDocumentRevocation(
                      docId: doc.fabricDocId,
                      bitIndex: bitIndex,
                      isCurrentlyRevoked: isRevokedOnChain,
                      docTitle: isArabic ? doc.documentTitleAr : doc.documentTitleEn,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRevokedOnChain ? AppColors.statusActive : AppColors.statusRevoked,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      isRevokedOnChain
                          ? (isArabic ? 'إعادة تفعيل' : 'Reinstate')
                          : (isArabic ? 'إلغاء الوثيقة' : 'Revoke'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),
          const BrandFooter(),
        ],
      ),
    );
  }

  Widget _buildStudentSelectorChip(String studentId, String label) {
    final isSelected = _selectedStudentIdForRevocation == studentId;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.goldPrimary,
      backgroundColor: AppColors.slateCard,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.obsidianBlack : AppColors.textLight,
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedStudentIdForRevocation = studentId);
        }
      },
    );
  }
}
