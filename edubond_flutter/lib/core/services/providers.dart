import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/catbox_upload_datasource.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/datasources/firebase_storage_datasource.dart';
import '../../data/datasources/firestore_datasource.dart';
import '../../data/datasources/local_prefs_datasource.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/subject_repository.dart';
import 'local_storage_service.dart';

/// Overridden at app startup in `main.dart` once `SharedPreferences` resolves.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService(ref.watch(sharedPreferencesProvider));
});

// Firebase Core Instances
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// DataSources
final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource(ref.watch(firebaseAuthProvider));
});

final firestoreDataSourceProvider = Provider<FirestoreDataSource>((ref) {
  return FirestoreDataSource(ref.watch(firebaseFirestoreProvider));
});

final firebaseStorageDataSourceProvider =
    Provider<FirebaseStorageDataSource>((ref) {
  return FirebaseStorageDataSource(ref.watch(firebaseStorageProvider));
});

final catboxUploadDataSourceProvider = Provider<CatboxUploadDataSource>((ref) {
  return CatboxUploadDataSource();
});

final localPrefsDataSourceProvider = Provider<LocalPrefsDataSource>((ref) {
  return LocalPrefsDataSource(ref.watch(localStorageServiceProvider));
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authDataSource: ref.watch(firebaseAuthDataSourceProvider),
    firestoreDataSource: ref.watch(firestoreDataSourceProvider),
    localPrefsDataSource: ref.watch(localPrefsDataSourceProvider),
  );
});

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepository(ref.watch(firestoreDataSourceProvider));
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(
    firestoreDataSource: ref.watch(firestoreDataSourceProvider),
    localPrefsDataSource: ref.watch(localPrefsDataSourceProvider),
  );
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(firestoreDataSourceProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    firestoreDataSource: ref.watch(firestoreDataSourceProvider),
    catboxUploadDataSource: ref.watch(catboxUploadDataSourceProvider),
    storageDataSource: ref.watch(firebaseStorageDataSourceProvider),
  );
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    ref.watch(firestoreDataSourceProvider),
    isAdminAuthorized: () => ref.read(authRepositoryProvider).isAdminAuthorized,
  );
});

class PickedAttachment {
  const PickedAttachment({
    required this.name,
    required this.bytes,
    this.extension,
  });

  final String name;
  final Uint8List bytes;
  final String? extension;
}

typedef FilePickHandler = Future<PickedAttachment?> Function();

final filePickProvider = Provider<FilePickHandler>((ref) {
  return () async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedAttachment(
      name: file.name,
      bytes: bytes,
      extension: file.extension,
    );
  };
});
