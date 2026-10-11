import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../core/models/institution.dart';
import '../core/services/fabric_ledger_service.dart';
import '../core/services/face_recognition_service.dart';
import '../core/services/institution_governance_service.dart';
import '../core/services/wallet_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_footer.dart';
import 'institution_portal_screen.dart';
import 'orderer_governance_screen.dart';
import 'registrar_issuance_portal_screen.dart';

class AdminPortalScreen extends StatefulWidget {
  final VoidCallback? onSwitchToCitizenWallet;

  const AdminPortalScreen({
    super.key,
    this.onSwitchToCitizenWallet,
  });

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FabricLedgerService _ledgerService = FabricLedgerService();
  final InstitutionGovernanceService _govService = InstitutionGovernanceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleResetAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.midnightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.crimsonRevoked.withOpacity(0.5)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.crimsonRevoked),
            SizedBox(width: 8),
            Text('Reset Blockchain & Vector DB?', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          'This will clear all enrolled student vectors in the Vector Database and reset the local blockchain document registry to a 100% clean start.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimsonRevoked),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset Everything', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await WalletStorageService().resetAllStateToClean();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.emeraldGreen,
            content: Text('Blockchain & Vector DB successfully reset to scratch!'),
          ),
        );
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildAdminHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const OrdererGovernanceScreen(),
                  InstitutionPortalScreen(
                    institution: InstitutionGovernanceService().institutions.value.first,
                  ),
                  const RegistrarIssuancePortalScreen(),
                  _buildBlockchainExplorerTab(),
                ],
              ),
            ),
            const BrandFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.midnightCard,
        border: Border(bottom: BorderSide(color: AppColors.goldAccent.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.goldAccent.withOpacity(0.4)),
            ),
            child: const Icon(Icons.admin_panel_settings, color: AppColors.goldAccent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'PAL-DFI Consortium Admin Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '• بوابة الإدارة والحوكمة',
                      style: TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Orderer (Nablus University) • PMA Regulatory Sandbox • Hyperledger Fabric 2.5',
                  style: TextStyle(
                    color: AppColors.electricCyan.withOpacity(0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Reset Button
          IconButton(
            tooltip: 'Reset Blockchain & Vector DB to Scratch',
            icon: const Icon(Icons.restart_alt, color: AppColors.crimsonRevoked),
            onPressed: _handleResetAll,
          ),
          const SizedBox(width: 8),
          // Switch to Citizen Wallet Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricCyan.withOpacity(0.2),
              foregroundColor: AppColors.electricCyan,
              side: const BorderSide(color: AppColors.electricCyan),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.wallet, size: 16),
            label: const Text(
              'Citizen Wallet (/#/)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: widget.onSwitchToCitizenWallet ?? () {
              // Switch route
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF0F172A),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.goldAccent,
        indicatorWeight: 3,
        labelColor: AppColors.goldAccent,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(
            icon: Icon(Icons.gavel, size: 18),
            text: 'Orderer Governance',
          ),
          Tab(
            icon: Icon(Icons.code, size: 18),
            text: 'Smart Contract Factory',
          ),
          Tab(
            icon: Icon(Icons.verified_user, size: 18),
            text: 'Registrar & Documents',
          ),
          Tab(
            icon: Icon(Icons.hub, size: 18),
            text: 'Blockchain Telemetry',
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainExplorerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTelemetryCard(),
              const SizedBox(height: 20),
              _buildNodesStatusCard(),
              const SizedBox(height: 20),
              _buildVectorDbStatusCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.midnightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.terminal, color: AppColors.goldAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Hyperledger Fabric Channel Telemetry',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildExplorerRow('Channel Name', 'nuvte-academic-channel'),
          _buildExplorerRow('Contract Name', 'paldfi_academic_contract'),
          _buildExplorerRow('Consensus Type', 'Raft (Crash Fault Tolerant • Orderer PMA)'),
          _buildExplorerRow('Genesis Peer Endpoint', 'peer0.nuvte.edu.ps:7051 (TLS Mutual Auth)'),
          _buildExplorerRow('Orderer Endpoint', 'orderer.pma.gov.ps:7050 (TLS Enabled)'),
          _buildExplorerRow('Hyperledger Explorer (Network View)', 'http://localhost:8090/#/network', isLink: true),
        ],
      ),
    );
  }

  Widget _buildNodesStatusCard() {
    return ValueListenableBuilder<List<Institution>>(
      valueListenable: _govService.institutions,
      builder: (context, instList, _) {
        final approvedInsts = instList.where((i) => i.isActive && i.id != 'INST-NUVTE-001').toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.midnightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.electricCyan.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_done, color: AppColors.electricCyan, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Consortium Node Architecture & Network Peers',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.electricCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${2 + approvedInsts.length} Peers Online',
                      style: const TextStyle(color: AppColors.electricCyan, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildNodeItem('PMA Consensus Orderer Node', 'orderer.pma.gov.ps:7050', 'ONLINE • RAFT LEADER', AppColors.emeraldGreen),
              _buildNodeItem('NUVTE Genesis Peer Node', 'peer0.nuvte.edu.ps:7051', 'ONLINE • ENDORSER (NUVTEMSP)', AppColors.emeraldGreen),
              ...approvedInsts.map((inst) => _buildNodeItem(
                    '${inst.nameEn} Peer Node',
                    '${inst.peerEndpoint} (${inst.domain})',
                    'ACTIVE • ENROLLED (${inst.orgMspId})',
                    AppColors.emeraldGreen,
                  )),
              _buildNodeItem('Chaincode Server (CCaaS)', 'paldfi_academic_contract', 'ONLINE • GO CONTRACT', AppColors.emeraldGreen),
              _buildNodeItem('Biometric Face Microservice', 'localhost:5060', 'ONLINE • 128-D VECTOR DB', AppColors.emeraldGreen),
              _buildNodeItem('REST Gateway Bridge', 'localhost:5050', 'ONLINE • FABRIC BRIDGE', AppColors.emeraldGreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVectorDbStatusCard() {
    return ValueListenableBuilder<int>(
      valueListenable: FaceRecognitionService().enrolledCount,
      builder: (context, count, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.midnightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.goldAccent.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.scatter_plot, color: AppColors.goldAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PMA ID+ Biometric Vector Database',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildExplorerRow('Vector Embedding Size', '128 Dimensions (Unit L2 Normalized)'),
              _buildExplorerRow('Vector Search Engine', 'Exact Cosine Similarity & Euclidean Distance'),
              _buildExplorerRow('Total Enrolled Face Vectors', '$count Biometric Profiles'),
              _buildExplorerRow('Biometric DID Derivation', 'Ed25519-Biometric-HDKeyGen-PMA2024'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExplorerRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isLink ? AppColors.electricCyan : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeItem(String title, String endpoint, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: statusColor, size: 10),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(endpoint, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
