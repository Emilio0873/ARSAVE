import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/crypto/crypto_service.dart';
import 'core/storage/session_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/ui_kit.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/backup/backup_service.dart';
import 'features/home/home_shell.dart';

String apiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  // Android emulator loopback to host machine
  return 'http://10.0.2.2:8080';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = SessionStore();
  final crypto = CryptoService();
  final api = ApiClient(
    baseUrl: apiBaseUrl(),
    getToken: store.getToken,
  );
  final auth = AuthState(api: api, crypto: crypto, store: store);
  final backup = BackupService(api: api, crypto: crypto, store: store);
  final theme = ThemeController();

  await Future.wait([auth.bootstrap(), theme.load()]);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        Provider.value(value: crypto),
        Provider.value(value: store),
        Provider.value(value: backup),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: theme),
      ],
      child: const ArsaveApp(),
    ),
  );
}

class ArsaveApp extends StatelessWidget {
  const ArsaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final theme = context.watch<ThemeController>();
    return MaterialApp(
      title: 'ARSAVE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.night(),
      key: ValueKey(theme.themeId),
      home: auth.bootstrapping
          ? AuraBackground(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandMark(compact: true),
                      const SizedBox(height: 28),
                      CircularProgressIndicator(color: AppColors.teal),
                    ],
                  ),
                ),
              ),
            )
          : auth.isAuthenticated
              ? const HomeShell()
              : const LoginScreen(),
    );
  }
}
