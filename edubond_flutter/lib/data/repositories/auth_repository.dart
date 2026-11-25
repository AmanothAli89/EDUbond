import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/firestore_collections.dart';
import '../../models/user_model.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/local_prefs_datasource.dart';

enum GoogleAuthNextStep {
  setAppPassword,
  verifyAppPassword,
}

class GoogleSignInOutcome {
  const GoogleSignInOutcome({
    required this.nextStep,
    required this.uid,
    required this.email,
    required this.username,
    required this.photoUrl,
  });

  final GoogleAuthNextStep nextStep;
  final String uid;
  final String email;
  final String username;
  final String photoUrl;
}

class AuthRepository {
  AuthRepository({
    required FirebaseAuthDataSource authDataSource,
    required FirestoreDataSource firestoreDataSource,
    required LocalPrefsDataSource localPrefsDataSource,
  })  : _auth = authDataSource,
        _firestore = firestoreDataSource,
        _local = localPrefsDataSource;

  final FirebaseAuthDataSource _auth;
  final FirestoreDataSource _firestore;
  final LocalPrefsDataSource _local;
  bool _isAdminAuthorized = false;

  bool get isAdminAuthorized => _isAdminAuthorized;
  User? get currentFirebaseUser => _auth.currentUser;
  String get currentLocalEmail => _local.getCurrentUser();
  String get activeUserEmail {
    final local = _local.getCurrentUser();
    return local.isNotEmpty ? local : (_auth.currentUser?.email ?? '');
  }

  /// Mirrors MainActivity's dual session guard (FirebaseAuth + SharedPreferences).
  Future<bool> hasValidSession() async {
    final user = _auth.currentUser;
    final localEmail = _local.getCurrentUser();
    if (user != null && (user.email?.isNotEmpty ?? false) && localEmail.isNotEmpty) {
      return true;
    }
    if (user != null && localEmail.isEmpty) {
      await logout();
    }
    return false;
  }

  Future<UserModel?> fetchUserProfile(String uid) async {
    final data = await _firestore.getDocData(FirestoreCollections.users, uid);
    if (data == null) return null;
    return UserModel.fromMap(data, fallbackUid: uid);
  }

  Future<String> getUserNameByEmail(String email) async {
    try {
      final snap = await _firestore.raw
          .collection(FirestoreCollections.users)
          .where(FirestoreFields.email, isEqualTo: email)
          .get();
      if (snap.docs.isEmpty) return email;
      final name = snap.docs.first.data()[FirestoreFields.username] as String?;
      return (name != null && name.isNotEmpty) ? name : email;
    } catch (_) {
      return email;
    }
  }

  Future<void> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Authentication succeeded without a user object.',
      );
    }
    final userEmail = user.email ?? email.trim();
    await _local.setCurrentUser(userEmail);
    await saveUserToFirestore(
      uid: user.uid,
      username: user.displayName ?? userEmail,
      email: userEmail,
      provider: 'google+password',
      photoUrl: user.photoURL ?? '',
      googleVerified: true,
      passwordSet: true,
    );
  }

  Future<GoogleSignInOutcome> authenticateWithGoogle() async {
    final result = await _auth.signInWithGoogle();
    final user = result.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Google Sign-In did not return a Firebase user.',
      );
    }

    await _auth.reloadCurrentUser();
    final uid = user.uid;
    final email = user.email ?? '';
    final username = user.displayName ?? '';
    final photoUrl = user.photoURL ?? '';

    try {
      final data = await _firestore.getDocData(FirestoreCollections.users, uid);
      final passwordSet =
          (data?[FirestoreFields.passwordSet] as bool?) ?? false;
      return GoogleSignInOutcome(
        nextStep: passwordSet
            ? GoogleAuthNextStep.verifyAppPassword
            : GoogleAuthNextStep.setAppPassword,
        uid: uid,
        email: email,
        username: username,
        photoUrl: photoUrl,
      );
    } catch (_) {
      return GoogleSignInOutcome(
        nextStep: GoogleAuthNextStep.setAppPassword,
        uid: uid,
        email: email,
        username: username,
        photoUrl: photoUrl,
      );
    }
  }

  Future<void> setAppPasswordForGoogleUser({
    required String uid,
    required String email,
    required String username,
    required String photoUrl,
    required String password,
  }) async {
    try {
      await _auth.linkEmailPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (!(e.message?.contains('already') ?? false) &&
          e.code != 'provider-already-linked') {
        rethrow;
      }
    }
    await saveUserToFirestore(
      uid: uid,
      username: username,
      email: email,
      provider: 'google+password',
      photoUrl: photoUrl,
      googleVerified: true,
      passwordSet: true,
    );
    await _local.setCurrentUser(email);
  }

  Future<void> verifyAppPasswordAfterGoogle({
    required String uid,
    required String email,
    required String username,
    required String photoUrl,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _local.setCurrentUser(email);
    await saveUserToFirestore(
      uid: uid,
      username: username,
      email: email,
      provider: 'google+password',
      photoUrl: photoUrl,
      googleVerified: true,
      passwordSet: true,
    );
  }

  Future<void> saveUserToFirestore({
    required String uid,
    required String username,
    required String email,
    required String provider,
    required String photoUrl,
    required bool googleVerified,
    required bool passwordSet,
  }) {
    return _firestore.setDoc(
      FirestoreCollections.users,
      uid,
      {
        FirestoreFields.uid: uid,
        FirestoreFields.username: username,
        FirestoreFields.email: email,
        FirestoreFields.photoUrl: photoUrl,
        FirestoreFields.role: 'user',
        FirestoreFields.loginProvider: provider,
        FirestoreFields.googleVerified: googleVerified,
        FirestoreFields.passwordSet: passwordSet,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      },
      merge: true,
    );
  }

  Future<void> updateProfile({
    required String uid,
    required String username,
    required String biodata,
  }) {
    return _firestore.setDoc(
      FirestoreCollections.users,
      uid,
      {
        FirestoreFields.username: username.trim(),
        FirestoreFields.biodata: biodata.trim(),
      },
      merge: true,
    );
  }

  Future<void> changeAppPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'No user email found for re-authentication.',
      );
    }
    await _auth.reauthenticateAndUpdatePassword(
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email);
  }

  Future<bool> loginAsAdmin({
    required String adminId,
    required String password,
  }) async {
    final trimmedId = adminId.trim();
    final trimmedPass = password.trim();

    if (trimmedId.contains('@')) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: trimmedId,
          password: trimmedPass,
        );
        final isClaimAdmin = await _auth.hasAdminCustomClaim(forceRefresh: true);
        if (isClaimAdmin) {
          await _local.logout();
          _isAdminAuthorized = true;
          return true;
        }
        await _auth.signOut();
        _isAdminAuthorized = false;
        return false;
      } on FirebaseAuthException {
        _isAdminAuthorized = false;
        return false;
      }
    }

    final data = await _firestore.getDocData(
      FirestoreCollections.adminConfig,
      FirestoreCollections.adminCredentialsDoc,
    );

    if (data == null) {
      _isAdminAuthorized = false;
      return false;
    }

    final dbId = (data[FirestoreFields.id] as String?)?.trim();
    final dbPass = (data[FirestoreFields.password] as String?)?.trim();
    final matched = dbId != null &&
        dbId.isNotEmpty &&
        dbPass != null &&
        dbPass.isNotEmpty &&
        trimmedId == dbId &&
        trimmedPass == dbPass;

    if (matched) {
      await logout();
      _isAdminAuthorized = true;
    } else {
      _isAdminAuthorized = false;
    }
    return matched;
  }

  void logoutAdmin() {
    _isAdminAuthorized = false;
  }

  Future<void> logout() async {
    _isAdminAuthorized = false;
    await _auth.signOut();
    await _local.logout();
  }
}
