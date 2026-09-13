import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/admin/admin_home_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/doctor/doctor_home_shell.dart';
import 'screens/doctor/doctor_pending_screen.dart';
import 'screens/patient/patient_home_shell.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Never let a failed/slow Firebase init leave the app on a blank screen —
  // always call runApp, and fall back to a simple error screen if it fails.
  String? initError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    initError = e.toString();
  }

  runApp(initError == null ? const CareConnectApp() : _StartupErrorApp(error: initError));
}

/// Shown instead of a stuck blank/black screen if Firebase couldn't start
/// (e.g. no internet connection on first launch).
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "Couldn't connect to CareConnect",
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your internet connection and reopen the app.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CareConnectApp extends StatelessWidget {
  const CareConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppAuthProvider(),
      child: MaterialApp(
        title: 'CareConnect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Routes to Splash / Login / Home based on the current auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    switch (auth.status) {
      case AuthStatus.loading:
        return const SplashScreen();
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        // Profile hasn't loaded from Firestore yet — briefly show the splash
        // rather than guessing which shell to route to.
        if (auth.profile == null) return const SplashScreen();
        switch (auth.route) {
          case AppRoute.admin:
            return const AdminHomeShell();
          case AppRoute.doctor:
            return const DoctorHomeShell();
          case AppRoute.doctorPending:
            return const DoctorPendingScreen();
          case AppRoute.patient:
            return const PatientHomeShell();
        }
    }
  }
}
