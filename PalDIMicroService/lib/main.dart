import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/id_plus_auth_service.dart';
import 'core/services/wallet_storage_service.dart';
import 'screens/admin_portal_screen.dart';
import 'screens/id_plus_login_screen.dart';
import 'screens/registrar_issuance_portal_screen.dart';
import 'screens/third_party_portal_screen.dart';
import 'screens/wallet_home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize hardware vault keys, dynamic students from Vector DB, and ledger anchors
  await WalletStorageService().initializeWallet();

  runApp(const PalDfiWalletApp());
}

class PalDfiWalletApp extends StatefulWidget {
  const PalDfiWalletApp({super.key});

  @override
  State<PalDfiWalletApp> createState() => _PalDfiWalletAppState();
}

class _PalDfiWalletAppState extends State<PalDfiWalletApp> {
  final IdPlusAuthService _idPlusAuth = IdPlusAuthService();
  bool _isAdminPortalMode = false;

  @override
  void initState() {
    super.initState();
    AppLocalizations.currentLanguage.addListener(_onLocaleChanged);
    _idPlusAuth.currentUser.addListener(_onAuthChanged);
    _checkUrlRoute();
  }

  void _checkUrlRoute() {
    if (kIsWeb) {
      final frag = Uri.base.fragment.toLowerCase();
      final path = Uri.base.path.toLowerCase();
      final query = Uri.base.queryParameters['portal']?.toLowerCase();
      if (frag.contains('admin') || frag.contains('orderer') || path.contains('admin') || query == 'admin') {
        _isAdminPortalMode = true;
      }
    }
  }

  @override
  void dispose() {
    AppLocalizations.currentLanguage.removeListener(_onLocaleChanged);
    _idPlusAuth.currentUser.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  void _onAuthChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAL-DFI Citizen & Academic Wallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Directionality(
        textDirection: AppLocalizations.textDirection,
        child: Builder(
          builder: (context) {
            if (_isAdminPortalMode) {
              return AdminPortalScreen(
                onSwitchToCitizenWallet: () {
                  setState(() {
                    _isAdminPortalMode = false;
                  });
                },
              );
            }

            return ValueListenableBuilder<IdPlusUserSession?>(
              valueListenable: _idPlusAuth.currentUser,
              builder: (context, userSession, _) {
                if (userSession == null) {
                  return Scaffold(
                    backgroundColor: AppColors.obsidianBlack,
                    body: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: IdPlusLoginScreen(
                          onRoleSelected: (role) {
                            setState(() {});
                          },
                          onOpenAdminPortal: () {
                            setState(() {
                              _isAdminPortalMode = true;
                            });
                          },
                        ),
                      ),
                    ),
                  );
                }

                switch (userSession.role) {
                  case IdPlusRole.student:
                    return Scaffold(
                      backgroundColor: AppColors.obsidianBlack,
                      body: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: WalletHomeScreen(
                            onLock: () {
                              _idPlusAuth.logout();
                            },
                          ),
                        ),
                      ),
                    );
                  case IdPlusRole.universityManagement:
                    return const RegistrarIssuancePortalScreen();
                  case IdPlusRole.thirdPartyVerifier:
                    return const ThirdPartyPortalScreen();
                }
              },
            );
          },
        ),
      ),
    );
  }
}
