import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edubond_flutter/core/constants/firestore_collections.dart';
import 'package:edubond_flutter/core/services/local_storage_service.dart';
import 'package:edubond_flutter/data/datasources/firebase_auth_datasource.dart';
import 'package:edubond_flutter/data/datasources/firestore_datasource.dart';
import 'package:edubond_flutter/data/datasources/local_prefs_datasource.dart';
import 'package:edubond_flutter/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUser implements User {
  MockUser({
    required this.uid,
    required this.email,
    this.displayName = 'Test User',
    this.photoURL = 'https://example.com/avatar.png',
  });

  @override
  final String uid;
  @override
  final String email;
  @override
  final String displayName;
  @override
  final String photoURL;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserCredential implements UserCredential {
  MockUserCredential(this._user);
  final User? _user;

  @override
  User? get user => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseAuthDataSource implements FirebaseAuthDataSource {
  User? _currentUser;
  bool throwOnEmailLogin = false;
  bool sendPasswordResetCalled = false;
  String? lastPasswordResetEmail;
  bool linkedEmailPassword = false;
  bool adminClaimGranted = false;

  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => Stream.value(_currentUser);

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (throwOnEmailLogin || password != 'validPass123') {
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'The password is invalid.',
      );
    }
    final user = MockUser(uid: 'uid_test', email: email);
    _currentUser = user;
    return MockUserCredential(user);
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    final user = MockUser(uid: 'google_uid_123', email: 'googleuser@gmail.com');
    _currentUser = user;
    return MockUserCredential(user);
  }

  @override
  Future<void> reloadCurrentUser() async {}

  @override
  Future<UserCredential> linkEmailPassword({
    required String email,
    required String password,
  }) async {
    linkedEmailPassword = true;
    final user = MockUser(uid: _currentUser?.uid ?? 'linked_uid', email: email);
    _currentUser = user;
    return MockUserCredential(user);
  }

  @override
  Future<void> reauthenticateAndUpdatePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    sendPasswordResetCalled = true;
    lastPasswordResetEmail = email;
  }

  @override
  Future<bool> hasAdminCustomClaim({bool forceRefresh = false}) async {
    return adminClaimGranted;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthFirestoreDataSource implements FirestoreDataSource {
  final Map<String, Map<String, Map<String, dynamic>>> _db = {};

  @override
  FirebaseFirestore get raw => throw UnimplementedError();

  @override
  Future<void> setDoc(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    _db.putIfAbsent(collection, () => {});
    if (merge && _db[collection]!.containsKey(docId)) {
      _db[collection]![docId]!.addAll(data);
    } else {
      _db[collection]![docId] = Map<String, dynamic>.from(data);
    }
  }

  @override
  Future<Map<String, dynamic>?> getDocData(
    String collection,
    String docId,
  ) async {
    return _db[collection]?[docId];
  }

  @override
  Future<void> deleteDoc(String collection, String docId) async {
    _db[collection]?.remove(docId);
  }

  @override
  Future<List<({String id, Map<String, dynamic> data})>> queryRecords(
    String collection, {
    Map<String, dynamic> isEqualTo = const {},
    Map<String, dynamic> arrayContains = const {},
    Map<String, dynamic> isGreaterThanOrEqualTo = const {},
    String? whereInField,
    List<dynamic>? whereInValues,
    String? orderByField,
    bool descending = false,
    int? limit,
  }) async {
    final col = _db[collection] ?? {};
    final list = col.entries.where((e) {
      for (final cond in isEqualTo.entries) {
        if (e.value[cond.key] != cond.value) return false;
      }
      return true;
    }).map((e) => (id: e.key, data: e.value)).toList();
    return list;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFirebaseAuthDataSource fakeAuth;
  late FakeAuthFirestoreDataSource fakeFirestore;
  late LocalStorageService localStorage;
  late LocalPrefsDataSource localPrefs;
  late AuthRepository authRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fakeAuth = FakeFirebaseAuthDataSource();
    fakeFirestore = FakeAuthFirestoreDataSource();
    localStorage = LocalStorageService(prefs);
    localPrefs = LocalPrefsDataSource(localStorage);
    authRepo = AuthRepository(
      authDataSource: fakeAuth,
      firestoreDataSource: fakeFirestore,
      localPrefsDataSource: localPrefs,
    );
  });

  group('Authentication Workflows & Session Safeguards', () {
    test('Email & Password Login: successful credential sets active session and user record', () async {
      await authRepo.loginWithEmailAndPassword(
        email: 'student@gmail.com',
        password: 'validPass123',
      );

      expect(authRepo.activeUserEmail, 'student@gmail.com');
      expect(localPrefs.getCurrentUser(), 'student@gmail.com');

      final userDoc = await fakeFirestore.getDocData(
        FirestoreCollections.users,
        'uid_test',
      );
      expect(userDoc, isNotNull);
      expect(userDoc![FirestoreFields.email], 'student@gmail.com');
      expect(userDoc[FirestoreFields.passwordSet], isTrue);
      expect(userDoc[FirestoreFields.googleVerified], isTrue);
    });

    test('Email & Password Login: invalid password throws FirebaseAuthException and denies session', () async {
      expect(
        () => authRepo.loginWithEmailAndPassword(
          email: 'student@gmail.com',
          password: 'wrongPassword',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );

      expect(authRepo.currentLocalEmail, isEmpty);
      expect(fakeAuth.currentUser, isNull);
    });

    test('Google Sign-In: first-time user without passwordSet triggers setAppPassword', () async {
      final outcome = await authRepo.authenticateWithGoogle();

      expect(outcome.uid, 'google_uid_123');
      expect(outcome.email, 'googleuser@gmail.com');
      expect(outcome.nextStep, GoogleAuthNextStep.setAppPassword);
    });

    test('Google App Password Creation: links credential and flags passwordSet: true', () async {
      await authRepo.setAppPasswordForGoogleUser(
        uid: 'google_uid_123',
        email: 'googleuser@gmail.com',
        username: 'Google Student',
        photoUrl: '',
        password: 'newAppPassword123',
      );

      expect(fakeAuth.linkedEmailPassword, isTrue);
      expect(localPrefs.getCurrentUser(), 'googleuser@gmail.com');

      final userDoc = await fakeFirestore.getDocData(
        FirestoreCollections.users,
        'google_uid_123',
      );
      expect(userDoc, isNotNull);
      expect(userDoc![FirestoreFields.passwordSet], isTrue);
    });

    test('Google Sign-In: returning user with passwordSet: true triggers verifyAppPassword', () async {
      // Seed existing user in Firestore
      await fakeFirestore.setDoc(
        FirestoreCollections.users,
        'google_uid_123',
        {
          FirestoreFields.uid: 'google_uid_123',
          FirestoreFields.email: 'googleuser@gmail.com',
          FirestoreFields.passwordSet: true,
        },
      );

      final outcome = await authRepo.authenticateWithGoogle();
      expect(outcome.nextStep, GoogleAuthNextStep.verifyAppPassword);
    });

    test('Forgot Password: sends password reset email to provider', () async {
      await authRepo.sendPasswordResetEmail('forgot@gmail.com');

      expect(fakeAuth.sendPasswordResetCalled, isTrue);
      expect(fakeAuth.lastPasswordResetEmail, 'forgot@gmail.com');
    });

    test('Admin Login: verifies Firestore credentials doc and enforces authorization flags', () async {
      // Seed admin credentials
      await fakeFirestore.setDoc(
        FirestoreCollections.adminConfig,
        FirestoreCollections.adminCredentialsDoc,
        {
          FirestoreFields.id: 'adminBoss',
          FirestoreFields.password: 'superSecret789',
        },
      );

      // Failed attempt with wrong password
      final failResult = await authRepo.loginAsAdmin(
        adminId: 'adminBoss',
        password: 'wrongPassword',
      );
      expect(failResult, isFalse);
      expect(authRepo.isAdminAuthorized, isFalse);

      // Successful attempt
      final successResult = await authRepo.loginAsAdmin(
        adminId: 'adminBoss',
        password: 'superSecret789',
      );
      expect(successResult, isTrue);
      expect(authRepo.isAdminAuthorized, isTrue);

      // Logout admin
      authRepo.logoutAdmin();
      expect(authRepo.isAdminAuthorized, isFalse);
    });

    test('Admin Login with Email & Custom Claim: authenticates via FirebaseAuth and requires admin claim', () async {
      // Student email without admin claim must fail and sign out
      fakeAuth.adminClaimGranted = false;
      final nonAdminOk = await authRepo.loginAsAdmin(
        adminId: 'student@gmail.com',
        password: 'validPass123',
      );
      expect(nonAdminOk, isFalse);
      expect(authRepo.isAdminAuthorized, isFalse);
      expect(fakeAuth.currentUser, isNull);

      // Admin email with { admin: true } claim succeeds and keeps FirebaseAuth signed in
      fakeAuth.adminClaimGranted = true;
      final adminOk = await authRepo.loginAsAdmin(
        adminId: 'admin@gmail.com',
        password: 'validPass123',
      );
      expect(adminOk, isTrue);
      expect(authRepo.isAdminAuthorized, isTrue);
      expect(fakeAuth.currentUser, isNotNull);
    });

    test('Logout & Session Restoration: hasValidSession requires both FirebaseAuth and SharedPreferences', () async {
      // Case 1: Neither logged in
      expect(await authRepo.hasValidSession(), isFalse);

      // Case 2: Only FirebaseAuth logged in, no local storage -> cleans up and returns false
      fakeAuth.setCurrentUser(MockUser(uid: 'u1', email: 'u1@gmail.com'));
      expect(await authRepo.hasValidSession(), isFalse);
      expect(fakeAuth.currentUser, isNull);

      // Case 3: Both valid
      fakeAuth.setCurrentUser(MockUser(uid: 'u2', email: 'u2@gmail.com'));
      await localPrefs.setCurrentUser('u2@gmail.com');
      expect(await authRepo.hasValidSession(), isTrue);

      // Case 4: Logout clears both
      await authRepo.logout();
      expect(await authRepo.hasValidSession(), isFalse);
      expect(localPrefs.getCurrentUser(), isEmpty);
      expect(fakeAuth.currentUser, isNull);
    });
  });
}
