import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

/// App-facing auth state. Screens talk to this, never to AuthService or
/// FirebaseAuth directly. Listens to Firebase's own auth-state stream so
/// the UI stays correct even if the user signs out from another device
/// or their session expires.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSub;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _busy = false;
  String? _errorMessage;

  AuthProvider() {
    _authSub = _authService.authStateChanges.listen((user) {
      _user = user;
      _status = user == null ? AuthStatus.loggedOut : AuthStatus.loggedIn;
      notifyListeners();
    });
  }

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoggedIn => _status == AuthStatus.loggedIn;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  String? get email => _user?.email;
  String? get uid => _user?.uid;

  Future<bool> signUp({required String email, required String password}) async {
    return _run(() => _authService.signUp(email: email, password: password));
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _run(() => _authService.signIn(email: email, password: password));
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.sendPasswordResetEmail(email);
      _busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      _busy = false;
      _errorMessage = _authService.friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> _run(Future<User?> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      _busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      _busy = false;
      _errorMessage = _authService.friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}