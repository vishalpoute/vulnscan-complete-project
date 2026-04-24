import 'package:flutter/material.dart';
import 'package:vulnscan/presentation/screens/splash/splash_screen.dart';
import 'package:vulnscan/presentation/screens/auth/login_screen.dart';
import 'package:vulnscan/presentation/screens/auth/signup_screen.dart';
import 'package:vulnscan/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:vulnscan/presentation/screens/new_scan/new_scan_screen.dart';
import 'package:vulnscan/presentation/screens/scan_progress/scan_progress_screen.dart';
import 'package:vulnscan/presentation/screens/scan_report/scan_report_screen.dart';
import 'package:vulnscan/presentation/screens/settings/settings_screen.dart';
import 'package:vulnscan/presentation/screens/subscription/subscription_screen.dart';
import 'package:vulnscan/presentation/screens/admin/admin_panel_screen.dart';
import 'package:vulnscan/presentation/screens/backend_status/backend_status_screen.dart';

/// Route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String scans = '/scans';
  static const String newScan = '/new-scan';
  static const String scanProgress = '/scan-progress';
  static const String scanReport = '/scan-report';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  static const String admin = '/admin';
  static const String backendStatus = '/backend-status';
}

/// Navigation service
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void pushNamed(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  static void pushReplacementNamed(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  static void pushNamedAndRemoveUntil(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void pop({Object? result}) {
    navigatorKey.currentState?.pop(result);
  }

  static void popUntil(String routeName) {
    navigatorKey.currentState?.popUntil(ModalRoute.withName(routeName));
  }
}

/// Route generator
class AppRouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());

      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case AppRoutes.scans:
        return MaterialPageRoute(builder: (_) => const NewScanScreen());

      case AppRoutes.newScan:
        return MaterialPageRoute(builder: (_) => const NewScanScreen());

      case AppRoutes.scanProgress:
        final scanId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ScanProgressScreen(scanId: scanId),
        );

      case AppRoutes.scanReport:
        final scanId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ScanReportScreen(scanId: scanId),
        );

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case AppRoutes.subscription:
        return MaterialPageRoute(builder: (_) => const SubscriptionScreen());

      case AppRoutes.admin:
        return MaterialPageRoute(builder: (_) => const AdminPanelScreen());

      case AppRoutes.backendStatus:
        return MaterialPageRoute(builder: (_) => const BackendStatusScreen());

      // TODO: Add other routes as screens are implemented
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
