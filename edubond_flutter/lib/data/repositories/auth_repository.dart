import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
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

  User? get currentFirebaseUser => _auth.currentUser;
  String get currentLocalEmail => _local.getCurrentUser();

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
    final doc = await _firestore.getDoc(FirestoreCollections.users, uid);
    final data = doc.data();
    if (data == null) return null;
    return UserModel.fromMap(data, fallbackUid: uid);
  }

  Future<String> getUserNameByEmail(String email) async {
    final snap = await _firestore.raw
        .collection(FirestoreCollections.users)
        .where(FirestoreFields.email, isEqualTo: email)
        .get();
    if (snap.docs.isEmpty) return email;
    final name = snap.docs.first.data()[FirestoreFields.username] as String?;
    return (name != null && name.isNotEmpty) ? name : email;
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
      final doc = await _firestore.getDoc(FirestoreCollections.users, uid);
      final passwordSet =
          (doc.data()?[FirestoreFields.passwordSet] as bool?) ?? false;
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
    final doc = await _firestore.getDoc(
      FirestoreCollections.adminConfig,
      FirestoreCollections.adminCredentialsDoc,
    );

    final bool matched;
    if (doc.exists) {
      final dbId = doc.data()?[FirestoreFields.id] as String?;
      final dbPass = doc.data()?[FirestoreFields.password] as String?;
      matched = adminId.trim() == dbId && password.trim() == dbPass;
    } else {
      matched = adminId.trim() == AppConstants.fallbackAdminId &&
          password.trim() == AppConstants.fallbackAdminPass;
    }

    if (matched) {
      await logout();
    }
    return matched;
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _local.logout();
  }
}
