import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around FirebaseAuth. Kept deliberately simple -- just
/// email/password sign up, sign in, sign out, and a stream of the current
/// user -- so the rest of the app never talks to FirebaseAuth directly.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUp({required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  Future<User?> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Converts FirebaseAuthException codes into short, user-facing
  /// messages instead of raw exception text.
  String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'network-request-failed':
          return 'No internet connection. Check your connection and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        default:
          return e.message ?? 'Authentication failed. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}