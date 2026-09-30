import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/institution.dart';
import '../core/services/id_plus_auth_service.dart';
import '../core/services/institution_governance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_footer.dart';
import 'institution_portal_screen.dart';

class OrdererGovernanceScreen extends StatefulWidget {
  const OrdererGovernanceScreen({super.key});

  @override
  State<OrdererGovernanceScreen> createState() => _OrdererGovernanceScreenState();
}

class _OrdererGovernanceScreenState extends State<OrdererGovernanceScreen>
    with SingleTickerProviderStateMixin {
  final InstitutionGovernanceService _govService =
      InstitutionGovernanceService();

  late TabController _tabController;
  bool _isProcessing = false;

  // New Application Form Controllers
  final _nameEnController = TextEditingController();
  final _nameArController = TextEditingController();
  final _mspController = TextEditingController();
  final _domainController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _reasonController = TextEditingController();
  InstitutionType _selectedType = InstitutionType.university;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _govService.syncWithBlockchain().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameEnController.dispose();
    _nameArController.dispose();
    _mspController.dispose();
    _domainController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // --- ORDERER ACTION: APPROVE & DEPLOY TO FABRIC ---
  Future<void> _handleApproveAndDeploy(Institution inst) async {
    final isArabic = AppLocalizations.isArabic;
    setState(() => _isProcessing = true);

    final res = await _govService.approveAndDeployInstitutionOnChain(inst.id);
    await _govService.syncWithBlockchain();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (res['success'] == true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.charcoalDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.goldPrimary, width: 1.4),
          ),
          title: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.statusActive, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isArabic ? 'تم اعتماد المؤسسة ونشرها على البلوكشين' : 'Institution Deployed to Fabric',
                  style: GoogleFonts.cairo(
                    color: AppColors.textLight,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic
                      ? 'تمت إضافة مؤسسة (${inst.nameAr}) إلى مصفوفة الأوردرير واعتمادها بنجاح على القناة الأكاديمية.'
                      : 'Institution (${inst.nameEn}) successfully onboarded and enrolled to nuvte-academic-channel.',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 12.5),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.obsidianBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slateCardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Org MSP ID: ${inst.orgMspId}', style: GoogleFonts.robotoMono(color: AppColors.goldLight, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Channel: ${inst.channelName}', style: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 10.5)),
                      const SizedBox(height: 4),
                      Text('Admin DID: ${inst.adminDid}', style: GoogleFonts.robotoMono(color: AppColors.textSubtle, fontSize: 9.5)),
                      const SizedBox(height: 4),
                      Text('Fabric Tx: ${res["txId"]}', style: GoogleFonts.robotoMono(color: AppColors.statusActive, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text('Block Confirmation: #${res["blockNumber"]}', style: GoogleFonts.robotoMono(color: AppColors.goldLight, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.textMuted),
              child: Text(isArabic ? 'إغلاق' : 'Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InstitutionPortalScreen(institution: inst),
                  ),
                );
              },
              icon: const Icon(Icons.dashboard_customize_rounded, size: 16),
              label: Text(isArabic ? 'الدخول لبوابة المؤسسة' : 'Enter Institution Portal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: AppColors.obsidianBlack,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _handleSubmitNewApplication() {
    final isArabic = AppLocalizations.isArabic;
    if (_nameEnController.text.trim().isEmpty || _mspController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'يرجى تعبئة اسم المؤسسة ورمز MSP' : 'Please fill institution name and MSP ID.'),
          backgroundColor: AppColors.statusRevoked,
        ),
      );
      return;
    }

    final msp = _mspController.text.trim().toUpperCase().replaceAll(' ', '');
    final newInst = Institution(
      id: 'INST-$msp-${DateTime.now().millisecondsSinceEpoch % 1000}',
      nameEn: _nameEnController.text.trim(),
      nameAr: _nameArController.text.trim().isEmpty ? _nameEnController.text.trim() : _nameArController.text.trim(),
      orgMspId: msp.endsWith('MSP') ? msp : '${msp}MSP',
      type: _selectedType,
      domain: _domainController.text.trim().isEmpty ? '${msp.toLowerCase()}.edu.ps' : _domainController.text.trim(),
      adminNameEn: _adminNameController.text.trim().isEmpty ? 'Institution Registrar' : _adminNameController.text.trim(),
      adminNameAr: _adminNameController.text.trim().isEmpty ? 'عمادة القبول والتسجيل' : _adminNameController.text.trim(),
      adminEmail: _adminEmailController.text.trim().isEmpty ? 'admin@${msp.toLowerCase()}.edu.ps' : _adminEmailController.text.trim(),
      adminDid: 'did:key:z6Mku${msp}Authority2024',
      peerEndpoint: 'peer0.${msp.toLowerCase()}.edu.ps:7051',
      caEndpoint: 'ca.${msp.toLowerCase()}.edu.ps:7054',
      reasonEn: _reasonController.text.trim().isEmpty ? 'Academic credential issuance on nuvte-academic-channel' : _reasonController.text.trim(),
      reasonAr: _reasonController.text.trim().isEmpty ? 'إصدار الوثائق الأكاديمية والشهادات على البلوكشين' : _reasonController.text.trim(),
      requestDate: DateTime.now(),
      status: InstitutionStatus.pending,
    );

    _govService.submitOnboardingRequest(newInst);

    _nameEnController.clear();
    _nameArController.clear();
    _mspController.clear();
    _domainController.clear();
    _adminNameController.clear();
    _adminEmailController.clear();
    _reasonController.clear();

    setState(() {});
    _tabController.animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تم تقديم طلب انضمام المؤسسة بنجاح! بانتظار اعتماد الأوردرير.'
              : 'Onboarding application submitted! Awaiting Orderer approval.',
        ),
        backgroundColor: AppColors.statusActive,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.navyPrimary,
                  border: Border.all(color: AppColors.goldPrimary, width: 1.4),
                ),
                child: const Icon(Icons.hub_rounded, color: AppColors.goldPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'إدارة الأوردرير وانضمام المؤسسات' : 'Orderer Governance & Onboarding',
                      style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'NUVTE Orderer • nuvte-academic-channel',
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
                icon: const Icon(Icons.pending_actions_rounded, size: 18),
                text: isArabic ? '١. طلبات الانضمام' : '1. Pending Requests',
              ),
              Tab(
                icon: const Icon(Icons.domain_verification_rounded, size: 18),
                text: isArabic ? '٢. المؤسسات المعتمدة' : '2. Active Orgs',
              ),
              Tab(
                icon: const Icon(Icons.add_business_rounded, size: 18),
                text: isArabic ? '٣. تقديم طلب انضمام' : '3. Apply Onboard',
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
                    SizedBox(height: 16),
                    Text(
                      'Enrolling Organization & Committing to Hyperledger Fabric...',
                      style: TextStyle(color: AppColors.goldLight, fontSize: 12),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingRequestsTab(),
                  _buildActiveInstitutionsTab(),
                  _buildApplyOnboardingTab(),
                ],
              ),
      ),
    );
  }

  // --- TAB 1: PENDING ONBOARDING REQUESTS ---
  Widget _buildPendingRequestsTab() {
    final isArabic = AppLocalizations.isArabic;

    return ValueListenableBuilder<List<Institution>>(
      valueListenable: _govService.institutions,
      builder: (context, allInst, _) {
        final pending = allInst.where((i) => i.isPending).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withAlpha(120),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.goldPrimary.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gavel_rounded, color: AppColors.goldPrimary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'صلاحيات الأوردرير: مراجعة طلبات انضمام الجامعات والوزارات للبلوكشين، واعتمادها تلقائياً لنشر هويتها وعقدها الذكي.'
                            : 'Orderer Authority: Review institution onboarding applications and deploy them to Hyperledger Fabric channel.',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (pending.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.slateCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slateCardBorder),
                  ),
                  child: Center(
                    child: Text(
                      isArabic ? 'لا توجد طلبات انضمام معلقة حالياً.' : 'No pending onboarding requests.',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ] else ...[
                ...pending.map((inst) => _buildPendingCard(inst)),
              ],

              const SizedBox(height: 20),
              const BrandFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingCard(Institution inst) {
    final isArabic = AppLocalizations.isArabic;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slateCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldPrimary.withAlpha(140), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.goldPrimary),
                ),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.goldPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? inst.nameAr : inst.nameEn,
                      style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'MSP: ${inst.orgMspId} • ${inst.domain}',
                      style: GoogleFonts.robotoMono(color: AppColors.goldLight, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.goldPrimary),
                ),
                child: Text(
                  isArabic ? 'بانتظار الاعتماد' : 'PENDING APPROVAL',
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 9, fontWeight: FontWeight.bold),
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
                Text(
                  '• ${isArabic ? "مسؤول المؤسسة:" : "Admin:"} ${isArabic ? inst.adminNameAr : inst.adminNameEn} (${inst.adminEmail})',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text('• Admin DID: ${inst.adminDid}', style: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 9.5)),
                const SizedBox(height: 3),
                Text(
                  '• ${isArabic ? "الغرض:" : "Purpose:"} ${isArabic ? inst.reasonAr : inst.reasonEn}',
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  '• Endpoints: Peer (${inst.peerEndpoint}) • CA (${inst.caEndpoint})',
                  style: GoogleFonts.robotoMono(color: AppColors.textSubtle, fontSize: 9.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _handleApproveAndDeploy(inst),
                  icon: const Icon(Icons.cloud_done_rounded, size: 18),
                  label: Text(
                    isArabic ? 'اعتماد ونشر المؤسسة على البلوكشين' : 'Approve & Deploy to Blockchain',
                    style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusActive,
                    foregroundColor: AppColors.obsidianBlack,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    _govService.rejectInstitutionRequest(inst.id, 'Orderer Administrative Rejection');
                    setState(() {});
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusRevoked,
                    side: const BorderSide(color: AppColors.statusRevoked),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isArabic ? 'رفض' : 'Reject', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 2: ACTIVE ONBOARDED INSTITUTIONS ---
  Widget _buildActiveInstitutionsTab() {
    final isArabic = AppLocalizations.isArabic;

    return ValueListenableBuilder<List<Institution>>(
      valueListenable: _govService.institutions,
      builder: (context, allInst, _) {
        final active = allInst.where((i) => i.isActive).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isArabic ? 'المؤسسات الأعضاء المعتمدة على البلوكشين:' : 'Active Enrolled Organizations on Fabric Channel:',
                style: GoogleFonts.cairo(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              const SizedBox(height: 12),

              ...active.map((inst) {
                final isOrderer = inst.id == 'INST-NUVTE-001';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.slateCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.statusActive.withAlpha(120)),
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
                              color: isOrderer ? AppColors.navyPrimary : AppColors.charcoalDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.statusActive),
                            ),
                            child: Icon(
                              isOrderer ? Icons.hub_rounded : Icons.account_balance_rounded,
                              color: AppColors.statusActive,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? inst.nameAr : inst.nameEn,
                                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13.5, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'MSP: ${inst.orgMspId} • ${inst.domain}',
                                  style: GoogleFonts.robotoMono(color: AppColors.goldLight, fontSize: 10.5),
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
                              isOrderer ? (isArabic ? 'أوردرير القناة' : 'ORDERER NODE') : (isArabic ? 'عضو نشط' : 'ACTIVE ORG'),
                              style: const TextStyle(color: AppColors.statusActive, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('• Channel: ${inst.channelName} | Tx: ${inst.txId}', style: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 10)),
                      Text('• Admin DID: ${inst.adminDid}', style: GoogleFonts.robotoMono(color: AppColors.textSubtle, fontSize: 9)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InstitutionPortalScreen(institution: inst),
                            ),
                          );
                        },
                        icon: const Icon(Icons.dashboard_customize_rounded, size: 16),
                        label: Text(
                          isArabic ? 'الدخول لبوابة إدارة المؤسسة والعقود الذكية' : 'Enter Institution & Smart Contract Portal',
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyPrimary,
                          foregroundColor: AppColors.goldLight,
                          side: const BorderSide(color: AppColors.goldPrimary, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
      },
    );
  }

  // --- TAB 3: APPLY FOR ONBOARDING ---
  Widget _buildApplyOnboardingTab() {
    final isArabic = AppLocalizations.isArabic;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isArabic ? 'تقديم طلب انضمام مؤسسة جديدة للبلوكشين:' : 'Submit New Institution Blockchain Onboarding Application:',
            style: GoogleFonts.cairo(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 14),

          // Institution Type Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.slateCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slateCardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<InstitutionType>(
                value: _selectedType,
                isExpanded: true,
                dropdownColor: AppColors.slateCard,
                items: InstitutionType.values.map((t) {
                  String label = t == InstitutionType.university
                      ? (isArabic ? 'جامعة / مؤسسة أكاديمية' : 'University / Academic Institution')
                      : (t == InstitutionType.ministry
                          ? (isArabic ? 'وزارة / هيئة حكومية' : 'Ministry / Government Body')
                          : (t == InstitutionType.bank
                              ? (isArabic ? 'بنك / قطاع مصرفي' : 'Bank / Financial Sector')
                              : (isArabic ? 'سلطة عامة سيادية' : 'Public Sovereign Authority')));
                  return DropdownMenuItem(
                    value: t,
                    child: Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _nameEnController,
            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
            decoration: InputDecoration(
              labelText: isArabic ? 'اسم المؤسسة بالإنجليزية (English Name)' : 'Institution English Name',
              hintText: 'e.g. Palestine Polytechnic University',
              filled: true,
              fillColor: AppColors.slateCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _nameArController,
            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
            decoration: InputDecoration(
              labelText: isArabic ? 'اسم المؤسسة بالعربية (Arabic Name)' : 'Institution Arabic Name',
              hintText: 'مثال: جامعة بوليتكنك فلسطين',
              filled: true,
              fillColor: AppColors.slateCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mspController,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'MSP ID (e.g. PPUMSP)',
                    filled: true,
                    fillColor: AppColors.slateCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _domainController,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Domain (e.g. ppu.edu)',
                    filled: true,
                    fillColor: AppColors.slateCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _adminNameController,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: isArabic ? 'اسم المسؤول' : 'Admin Name',
                    filled: true,
                    fillColor: AppColors.slateCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _adminEmailController,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Admin Email',
                    filled: true,
                    fillColor: AppColors.slateCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _reasonController,
            maxLines: 2,
            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
            decoration: InputDecoration(
              labelText: isArabic ? 'الغرض من الانضمام للبلوكشين' : 'Purpose for Blockchain Onboarding',
              filled: true,
              fillColor: AppColors.slateCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: _handleSubmitNewApplication,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(
              isArabic ? 'إرسال طلب الانضمام للأوردرير' : 'Submit Onboarding Application',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
              foregroundColor: AppColors.obsidianBlack,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 20),
          const BrandFooter(),
        ],
      ),
    );
  }
}
