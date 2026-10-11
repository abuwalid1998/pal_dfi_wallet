import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/institution.dart';
import '../core/models/smart_contract_definition.dart';
import '../core/models/verifiable_credential.dart';
import '../core/services/id_plus_auth_service.dart';
import '../core/services/institution_governance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_footer.dart';

class InstitutionPortalScreen extends StatefulWidget {
  final Institution institution;

  const InstitutionPortalScreen({
    super.key,
    required this.institution,
  });

  @override
  State<InstitutionPortalScreen> createState() => _InstitutionPortalScreenState();
}

class _InstitutionPortalScreenState extends State<InstitutionPortalScreen>
    with SingleTickerProviderStateMixin {
  final InstitutionGovernanceService _govService =
      InstitutionGovernanceService();

  late TabController _tabController;
  bool _isProcessing = false;

  // Smart Contract Creation Form State
  final _contractNameEnController = TextEditingController();
  final _contractNameArController = TextEditingController();
  final _contractDescEnController = TextEditingController();
  final _contractDescArController = TextEditingController();
  final _contractVersionController = TextEditingController(text: '1.0.0');
  final Set<String> _selectedAttributes = {
    'studentId',
    'nationalId',
    'fullName',
    'degreeTitle',
    'major',
    'gpa',
    'issueDate',
    'honors',
  };

  // Document Issuance Form State
  String _selectedCitizenId = 'STU-2024098';
  String? _selectedContractId;
  final _docTitleEnController = TextEditingController();
  final _docTitleArController = TextEditingController();
  final _majorController = TextEditingController();
  final _gpaController = TextEditingController(text: '3.90');
  final _honorsController = TextEditingController();
  AcademicDocumentType _selectedDocType = AcademicDocumentType.graduationCertificate;

  final List<Map<String, dynamic>> _issuedHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contractNameEnController.dispose();
    _contractNameArController.dispose();
    _contractDescEnController.dispose();
    _contractDescArController.dispose();
    _contractVersionController.dispose();
    _docTitleEnController.dispose();
    _docTitleArController.dispose();
    _majorController.dispose();
    _gpaController.dispose();
    _honorsController.dispose();
    super.dispose();
  }

  // --- ACTION 1: DEPLOY SMART CONTRACT TO FABRIC ---
  Future<void> _handleDeploySmartContract() async {
    final isArabic = AppLocalizations.isArabic;
    if (_contractNameEnController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'يرجى إدخال اسم العقد الذكي' : 'Please enter smart contract name.'),
          backgroundColor: AppColors.statusRevoked,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final res = await _govService.deploySmartContractOnChain(
      institutionId: widget.institution.id,
      nameEn: _contractNameEnController.text.trim(),
      nameAr: _contractNameArController.text.trim().isEmpty ? _contractNameEnController.text.trim() : _contractNameArController.text.trim(),
      descriptionEn: _contractDescEnController.text.trim().isEmpty ? 'Verifiable credential smart contract deployed on Fabric' : _contractDescEnController.text.trim(),
      descriptionAr: _contractDescArController.text.trim().isEmpty ? 'عقد ذكي لتوثيق الشهادات على البلوكشين' : _contractDescArController.text.trim(),
      version: _contractVersionController.text.trim().isEmpty ? '1.0.0' : _contractVersionController.text.trim(),
      schemaAttributes: _selectedAttributes.toList(),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (res['success'] == true) {
      _contractNameEnController.clear();
      _contractNameArController.clear();
      _contractDescEnController.clear();
      _contractDescArController.clear();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.charcoalDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.statusActive, width: 1.4),
          ),
          title: Row(
            children: [
              const Icon(Icons.code_rounded, color: AppColors.statusActive, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? 'تم نشر العقد الذكي على البلوكشين' : 'Smart Contract Deployed on Fabric',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 15, fontWeight: FontWeight.bold),
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
                    ? 'تم نشر العقد الذكي بنجاح على القناة (${widget.institution.channelName}) وأصبح جاهزاً لإصدار الوثائق للمواطنين.'
                    : 'Smart contract deployed to channel (${widget.institution.channelName}) and ready for citizen document issuance.',
                style: const TextStyle(color: AppColors.textLight, fontSize: 12),
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
                    Text('Contract ID: ${res["contract"].contractId}', style: GoogleFonts.robotoMono(color: AppColors.goldLight, fontSize: 10.5)),
                    const SizedBox(height: 3),
                    Text('Fabric Tx: ${res["txId"]}', style: GoogleFonts.robotoMono(color: AppColors.statusActive, fontSize: 10)),
                    const SizedBox(height: 3),
                    Text('Block: #${res["blockNumber"]}', style: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 10)),
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

  // --- ACTION 2: ISSUE DOCUMENT TO CITIZEN & ANCHOR ON FABRIC ---
  Future<void> _handleIssueDocument() async {
    final isArabic = AppLocalizations.isArabic;
    final contracts = _govService.getContractsForInstitution(widget.institution.id);
    if (contracts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'يرجى نشر عقد ذكي أولاً في التبويب الأول' : 'Please deploy a smart contract in Tab 1 first.'),
          backgroundColor: AppColors.statusRevoked,
        ),
      );
      return;
    }

    final contractId = _selectedContractId ?? contracts.first.contractId;
    final targetProfile = IdPlusAuthService.studentProfiles.firstWhere(
      (p) => p['studentId'] == _selectedCitizenId,
      orElse: () => IdPlusAuthService.studentProfiles.first,
    );

    setState(() => _isProcessing = true);

    final docTitleEn = _docTitleEnController.text.trim().isEmpty
        ? 'Official Certificate of ${widget.institution.nameEn}'
        : _docTitleEnController.text.trim();
    final docTitleAr = _docTitleArController.text.trim().isEmpty
        ? 'شهادة معتمدة من ${widget.institution.nameAr}'
        : _docTitleArController.text.trim();

    final res = await _govService.issueDocumentFromInstitution(
      institutionId: widget.institution.id,
      contractId: contractId,
      studentId: targetProfile['studentId']!,
      documentTitleEn: docTitleEn,
      documentTitleAr: docTitleAr,
      documentType: _selectedDocType,
      attributes: {
        'major': _majorController.text.trim().isEmpty ? targetProfile['programEn']! : _majorController.text.trim(),
        'gpa': _gpaController.text.trim().isEmpty ? '3.85' : _gpaController.text.trim(),
        'honors': _honorsController.text.trim().isEmpty ? 'Honors of Excellence' : _honorsController.text.trim(),
        'institutionMsp': widget.institution.orgMspId,
      },
      employeeId: '${widget.institution.orgMspId}-EMP-01',
    );

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      if (res['success'] == true) {
        _issuedHistory.insert(0, {
          'docId': res['docId'],
          'txId': res['txId'],
          'citizenName': isArabic ? targetProfile['fullNameAr']! : targetProfile['fullNameEn']!,
          'citizenId': targetProfile['studentId']!,
          'docTitle': isArabic ? docTitleAr : docTitleEn,
          'timestamp': DateTime.now(),
        });
      }
    });

    if (res['success'] == true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.charcoalDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.goldPrimary, width: 1.4),
          ),
          title: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppColors.statusActive, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? 'تم الإصدار والتثبيت في محفظة المواطن' : 'Document Issued & Anchored on Chain',
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 15, fontWeight: FontWeight.bold),
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
                    ? 'تم توثيق الوثيقة بنجاح على البلوكشين وكتابتها مباشرة في المحفظة السيادية للمواطن (${targetProfile["fullNameAr"]}).'
                    : 'Document successfully anchored on Fabric and ingested into citizen (${targetProfile["fullNameEn"]})\'s sovereign wallet.',
                style: const TextStyle(color: AppColors.textLight, fontSize: 12),
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
                    Text('Doc ID: ${res["docId"]}', style: GoogleFonts.robotoMono(color: AppColors.goldLight, fontSize: 10.5)),
                    const SizedBox(height: 3),
                    Text('Fabric Tx: ${res["txId"]}', style: GoogleFonts.robotoMono(color: AppColors.statusActive, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary, foregroundColor: AppColors.obsidianBlack),
              child: Text(isArabic ? 'تم' : 'Done'),
            ),
          ],
        ),
      );
    }
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
                child: const Icon(Icons.account_balance_rounded, color: AppColors.goldPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? widget.institution.nameAr : widget.institution.nameEn,
                      style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'MSP: ${widget.institution.orgMspId} • ${widget.institution.adminNameEn}',
                      style: GoogleFonts.robotoMono(fontSize: 9.5, color: AppColors.goldLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.goldPrimary,
            labelColor: AppColors.goldPrimary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(
                icon: const Icon(Icons.code_rounded, size: 18),
                text: isArabic ? '١. العقود الذكية والمخططات' : '1. Smart Contracts',
              ),
              Tab(
                icon: const Icon(Icons.post_add_rounded, size: 18),
                text: isArabic ? '٢. إصدار الوثائق للمواطنين' : '2. Issue Documents',
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
                      'Executing Smart Contract & Fabric Transaction...',
                      style: TextStyle(color: AppColors.goldLight, fontSize: 12),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildSmartContractsTab(),
                  _buildDocumentIssuanceTab(),
                ],
              ),
      ),
    );
  }

  // --- TAB 1: SMART CONTRACTS & CHAINCODE DEPLOYMENT ---
  Widget _buildSmartContractsTab() {
    final isArabic = AppLocalizations.isArabic;

    return ValueListenableBuilder<List<SmartContractDefinition>>(
      valueListenable: _govService.smartContracts,
      builder: (context, allContracts, _) {
        final myContracts = allContracts
            .where((c) => c.institutionId == widget.institution.id || c.institutionId == 'INST-NUVTE-001')
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Guidance banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withAlpha(120),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.goldPrimary.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.goldPrimary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'إنشاء ونشر العقود الذكية: قم بتعريف مخطط الوثيقة الخاصة بمؤسستك ونشرها تلقائياً على قناة البلوكشين.'
                            : 'Define custom credential schemas and deploy smart contracts automatically to the Hyperledger Fabric channel.',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Deployed Contracts List
              Text(
                isArabic ? 'العقود الذكية النشطة على القناة:' : 'Active Smart Contracts on Channel:',
                style: GoogleFonts.cairo(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),

              ...myContracts.map((c) => _buildContractCard(c)),

              const SizedBox(height: 18),

              // Deploy New Smart Contract Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slateCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.goldPrimary.withAlpha(140), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, color: AppColors.goldPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'إنشاء ونشر عقد ذكي جديد (Smart Contract Deployer):' : 'Deploy New Smart Contract:',
                          style: GoogleFonts.cairo(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _contractNameEnController,
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: isArabic ? 'اسم العقد بالإنجليزية' : 'Contract Name (English)',
                        hintText: 'e.g. Master of Science in Cybersecurity Degree Contract',
                        filled: true,
                        fillColor: AppColors.charcoalDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _contractNameArController,
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: isArabic ? 'اسم العقد بالعربية' : 'Contract Name (Arabic)',
                        hintText: 'مثال: عقد درجة الماجستير في الأمن السيبراني والذكاء الاصطناعي',
                        filled: true,
                        fillColor: AppColors.charcoalDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _contractVersionController,
                            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Version',
                              filled: true,
                              fillColor: AppColors.charcoalDark,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.charcoalDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.slateCardBorder),
                            ),
                            child: Text(
                              'Endorsement: OR(\'${widget.institution.orgMspId}.peer\')',
                              style: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      isArabic ? 'الحقول والبيانات المعتمدة في المخطط (Schema Attributes):' : 'Schema Attributes Included in Proof:',
                      style: const TextStyle(color: AppColors.goldLight, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        'studentId',
                        'nationalId',
                        'fullName',
                        'degreeTitle',
                        'faculty',
                        'major',
                        'gpa',
                        'issueDate',
                        'honors',
                        'deanDecree',
                        'accreditationNumber',
                      ].map((attr) {
                        final isSelected = _selectedAttributes.contains(attr);
                        return FilterChip(
                          label: Text(attr, style: TextStyle(color: isSelected ? AppColors.obsidianBlack : AppColors.textLight, fontSize: 10.5)),
                          selected: isSelected,
                          selectedColor: AppColors.goldPrimary,
                          backgroundColor: AppColors.charcoalDark,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedAttributes.add(attr);
                              } else {
                                _selectedAttributes.remove(attr);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _handleDeploySmartContract,
                      icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                      label: Text(
                        isArabic ? 'نشر العقد الذكي تلقائياً على البلوكشين' : 'Deploy Smart Contract to Blockchain',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary,
                        foregroundColor: AppColors.obsidianBlack,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const BrandFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContractCard(SmartContractDefinition c) {
    final isArabic = AppLocalizations.isArabic;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.charcoalDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusActive.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code_rounded, color: AppColors.statusActive, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? c.nameAr : c.nameEn,
                  style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.statusActive.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.statusActive),
                ),
                child: Text(
                  'v${c.version} • DEPLOYED',
                  style: const TextStyle(color: AppColors.statusActive, fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '• Contract ID: ${c.contractId} | Channel: ${c.channel}',
            style: GoogleFonts.robotoMono(color: AppColors.goldLight, fontSize: 9.5),
          ),
          Text(
            '• Endorsement: ${c.endorsementPolicy}',
            style: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 9.5),
          ),
          if (c.deployTxId != null)
            Text(
              '• Fabric Tx: ${c.deployTxId}',
              style: GoogleFonts.robotoMono(color: AppColors.statusActive, fontSize: 9),
            ),
        ],
      ),
    );
  }

  // --- TAB 2: CITIZEN DOCUMENT ISSUANCE ---
  Widget _buildDocumentIssuanceTab() {
    final isArabic = AppLocalizations.isArabic;
    final contracts = _govService.getContractsForInstitution(widget.institution.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.slateCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.goldPrimary, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'إصدار وتوثيق وثيقة رسمية لمواطن على البلوكشين:' : 'Issue & Anchor Official Credential for Citizen:',
                  style: GoogleFonts.cairo(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 14),

                // Select Target Citizen
                Text(isArabic ? 'اختر المواطن/الطالب:' : 'Select Target Citizen:', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.charcoalDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slateCardBorder),
                  ),
                  child: Builder(
                    builder: (context) {
                      final profiles = IdPlusAuthService.studentProfiles;
                      final effectiveValue = profiles.any((p) => p['studentId'] == _selectedCitizenId)
                          ? _selectedCitizenId
                          : (profiles.isNotEmpty ? profiles.first['studentId'] : null);

                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: effectiveValue,
                          isExpanded: true,
                          dropdownColor: AppColors.charcoalDark,
                          items: profiles.map((p) {
                            return DropdownMenuItem<String>(
                              value: p['studentId'],
                              child: Text(
                                '${isArabic ? p["fullNameAr"] : p["fullNameEn"]} (${p["studentId"]})',
                                style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCitizenId = val);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Select Deployed Smart Contract Schema
                Text(isArabic ? 'اختر العقد الذكي المعتمد للإصدار:' : 'Select Deployed Smart Contract Schema:', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.charcoalDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slateCardBorder),
                  ),
                  child: Builder(
                    builder: (context) {
                      final effectiveContract = contracts.any((c) => c.contractId == _selectedContractId)
                          ? _selectedContractId
                          : (contracts.isNotEmpty ? contracts.first.contractId : null);

                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: effectiveContract,
                          isExpanded: true,
                          dropdownColor: AppColors.charcoalDark,
                          items: contracts.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.contractId,
                              child: Text(
                                isArabic ? c.nameAr : c.nameEn,
                                style: const TextStyle(color: AppColors.textLight, fontSize: 12.5),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedContractId = val);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _docTitleEnController,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: isArabic ? 'عنوان الوثيقة بالإنجليزية' : 'Document Title (English)',
                    hintText: 'e.g. Master of Science in Artificial Intelligence Degree',
                    filled: true,
                    fillColor: AppColors.charcoalDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _docTitleArController,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: isArabic ? 'عنوان الوثيقة بالعربية' : 'Document Title (Arabic)',
                    hintText: 'مثال: شهادة درجة الماجستير في الذكاء الاصطناعي والأمن السيبراني',
                    filled: true,
                    fillColor: AppColors.charcoalDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _majorController,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: isArabic ? 'التخصص / البرنامج' : 'Major / Program',
                          filled: true,
                          fillColor: AppColors.charcoalDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _gpaController,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'GPA / Grade',
                          filled: true,
                          fillColor: AppColors.charcoalDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _handleIssueDocument,
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: Text(
                    isArabic ? 'إصدار وتوثيق الوثيقة على البلوكشين والمحفظة' : 'Issue & Anchor to Blockchain & Citizen Wallet',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusActive,
                    foregroundColor: AppColors.obsidianBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Issued Documents History
          if (_issuedHistory.isNotEmpty) ...[
            Text(
              isArabic ? 'سجل الوثائق الصادرة مؤخراً من المؤسسة:' : 'Recently Issued Documents on Fabric:',
              style: GoogleFonts.cairo(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),

            ..._issuedHistory.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.charcoalDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.statusActive.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.statusActive, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item["citizenName"]} • ${item["docTitle"]}',
                            style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            'Doc ID: ${item["docId"]} • Tx: ${item["txId"]}',
                            style: GoogleFonts.robotoMono(color: AppColors.goldLight, fontSize: 9.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 20),
          const BrandFooter(),
        ],
      ),
    );
  }
}
