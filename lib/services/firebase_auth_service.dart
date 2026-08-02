import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  // Firebase Authentication instance
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // ------------------------------------------------------------
  // GET CURRENT USER
  // ------------------------------------------------------------

  User? get currentUser {
    return _firebaseAuth.currentUser;
  }

  // ------------------------------------------------------------
  // CHECK WHETHER USER IS LOGGED IN
  // ------------------------------------------------------------

  bool get isLoggedIn {
    return _firebaseAuth.currentUser != null;
  }

  // ------------------------------------------------------------
  // REGISTER USER
  // ------------------------------------------------------------

  Future<UserCredential> registerUser({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return credential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // LOGIN USER
  // ------------------------------------------------------------

  Future<UserCredential> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return credential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // ------------------------------------------------------------
  // UPDATE DISPLAY NAME
  // ------------------------------------------------------------

  Future<void> updateDisplayName(String name) async {
    final User? user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    await user.updateDisplayName(name.trim());

    // Reload user information after updating.
    await user.reload();
  }

  // ------------------------------------------------------------
  // GET USER ID
  // ------------------------------------------------------------

  String? get userId {
    return _firebaseAuth.currentUser?.uid;
  }

  // ------------------------------------------------------------
  // GET USER EMAIL
  // ------------------------------------------------------------

  String? get userEmail {
    return _firebaseAuth.currentUser?.email;
  }
}