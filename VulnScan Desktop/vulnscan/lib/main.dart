import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme/app_theme.dart';
import 'config/routing/app_router.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/auth_provider.dart';

// Web detection constant
const bool kIsWeb = identical(0, 0.0);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env only on non-web platforms
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .env file not found - using defaults
      // This is normal in production
    }
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: VulnScanApp()));
}

class VulnScanApp extends ConsumerWidget {
  const VulnScanApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    return MaterialApp(
      title: 'VulnScan',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorKey: AppNavigator.navigatorKey,
      onGenerateRoute: AppRouteGenerator.generateRoute,
      home: const SplashRouteGuard(),
    );
  }
}

class SplashRouteGuard extends ConsumerWidget {
  const SplashRouteGuard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    return authState.when(
      data: (user) {
        if (user != null) {
          Future.microtask(
            () => AppNavigator.pushReplacementNamed(AppRoutes.dashboard),
          );
        } else {
          Future.microtask(
            () => AppNavigator.pushReplacementNamed(AppRoutes.login),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to initialize app'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(authNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
