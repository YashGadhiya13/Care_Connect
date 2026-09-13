import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus { loading, signedOut, signedIn }

enum AppRoute { patient, doctorPending, doctor, admin }

/// Exposes current auth + profile state to the whole app via Provider,
/// so screens don't each need their own Firebase listeners.
class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthStatus status = AuthStatus.loading;
  User? firebaseUser;
  AppUser? profile;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  AppAuthProvider({AuthService? authService, FirestoreService? firestoreService})
      : _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService() {
    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  AuthService get authService => _authService;
  FirestoreService get firestoreService => _firestoreService;

  /// Where `_AuthGate` should route once a profile has loaded.
  AppRoute get route {
    if (profile == null) return AppRoute.patient; // shows a brief loading state
    switch (profile!.role) {
      case UserRole.admin:
        return AppRoute.admin;
      case UserRole.doctor:
        return profile!.isApprovedDoctor ? AppRoute.doctor : AppRoute.doctorPending;
      case UserRole.patient:
        return AppRoute.patient;
    }
  }

  void _onAuthChanged(User? user) {
    firebaseUser = user;
    _profileSub?.cancel();

    if (user == null) {
      profile = null;
      status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }

    status = AuthStatus.signedIn;
    notifyListeners();

    _profileSub = _firestoreService.watchUser(user.uid).listen((appUser) {
      profile = appUser;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
