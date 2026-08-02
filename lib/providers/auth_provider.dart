import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/firebase/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // ------------------------------------------------------------
  // GETTERS
  // ------------------------------------------------------------

  User? get user => _user;

  bool get isLoading => _isLoading;

  bool get isLoggedIn => _user != null;

  String? get errorMessage => _errorMessage;

  String? get userId => _user?.uid;

  String? get email => _user?.email;

  // ------------------------------------------------------------
  // INITIALIZE AUTH STATE
  // ------------------------------------------------------------

  void initialize() {
    _user = _authService.currentUser;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // REGISTER USER
  // ------------------------------------------------------------

  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final UserCredential credential =
          await _authService.registerUser(
        email: email,
        password: password,
      );

      _user = credential.user;

      // Store display name in Firebase Authentication.
      if (_user != null) {
        await _authService.updateDisplayName(name);
        _user = _authService.currentUser;
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Unable to create account. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ------------------------------------------------------------
  // LOGIN USER
  // ------------------------------------------------------------

  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final UserCredential credential =
          await _authService.loginUser(
        email: email,
        password: password,
      );

      _user = credential.user;

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Unable to sign in. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ------------------------------------------------------------
  // ADMIN LOGIN
  // ------------------------------------------------------------

  Future<bool> loginAdmin({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final UserCredential credential =
          await _authService.loginUser(
        email: email,
        password: password,
      );

      _user = credential.user;

      /*
       * IMPORTANT:
       *
       * Firebase Authentication only confirms that the email
       * and password are valid.
       *
       * Later, when we implement the Database/Admin Module,
       * we will check the user's role in Firestore:
       *
       * role == "admin"
       *
       * Only then will the user be allowed into the Admin Home.
       */

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Unable to sign in. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
      _user = null;
      _clearError();
    } finally {
      _setLoading(false);
    }
  }

  // ------------------------------------------------------------
  // CLEAR ERROR
  // ------------------------------------------------------------

  void clearError() {
    _clearError();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // LOADING
  // ------------------------------------------------------------

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // FIREBASE ERROR HANDLING
  // ------------------------------------------------------------

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      // Registration errors
      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
        return 'The password is too weak.';

      // Login errors
      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      default:
        return 'Authentication failed. Please try again.';
    }
  }
}