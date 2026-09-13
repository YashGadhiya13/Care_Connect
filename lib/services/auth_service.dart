import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Thin wrapper around FirebaseAuth + the `users` collection.
/// Keeping Firebase calls in one place makes the rest of the app easy to
/// read and, if needed later, easy to swap or mock in tests.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Registers a Patient or a Doctor. Admin accounts are never created
  /// through sign-up — see the README for how to promote a user to Admin.
  /// A Doctor account starts with `doctorStatus: pending` and is blocked
  /// from the doctor home screen until an Admin approves it.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String phone = '',
    String specialty = '',
    String department = '',
    String bio = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    await _db.collection('users').doc(uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': role.name,
      'specialty': specialty,
      'department': department,
      'bio': bio,
      'doctorStatus': DoctorStatus.pending.name,
      'ratingAvg': 0,
      'ratingCount': 0,
      'medications': [],
      'emergencyContacts': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await credential.user!.updateDisplayName(name.trim());
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() => _auth.signOut();

  String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'weak-password':
          return 'Please choose a stronger password (6+ characters).';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
