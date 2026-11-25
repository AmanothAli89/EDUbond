import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/app_constants.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource(this._auth);

  final FirebaseAuth _auth;
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: AppConstants.googleWebClientId,
      );
      _googleInitialized = true;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google Sign-In did not return an ID token.',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> linkEmailPassword({
    required String email,
    required String password,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user to link credential.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password.trim(),
    );
    return user.linkWithCredential(credential);
  }

  Future<void> reauthenticateAndUpdatePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'User session expired.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: currentPassword.trim(),
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword.trim());
  }

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  Future<bool> hasAdminCustomClaim({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final tokenResult = await user.getIdTokenResult(forceRefresh);
    return tokenResult.claims?['admin'] == true;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }
}
