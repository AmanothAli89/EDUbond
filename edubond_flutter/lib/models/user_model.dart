import '../core/constants/firestore_collections.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl = '',
    this.role = 'user',
    this.loginProvider = 'google+password',
    this.googleVerified = false,
    this.passwordSet = false,
    this.biodata = '',
    this.updatedAt,
  });

  final String uid;
  final String username;
  final String email;
  final String photoUrl;
  final String role;
  final String loginProvider;
  final bool googleVerified;
  final bool passwordSet;
  final String biodata;
  final dynamic updatedAt;

  factory UserModel.fromMap(Map<String, dynamic> map, {String fallbackUid = ''}) {
    return UserModel(
      uid: (map[FirestoreFields.uid] as String?) ?? fallbackUid,
      username: (map[FirestoreFields.username] as String?) ?? '',
      email: (map[FirestoreFields.email] as String?) ?? '',
      photoUrl: (map[FirestoreFields.photoUrl] as String?) ?? '',
      role: (map[FirestoreFields.role] as String?) ?? 'user',
      loginProvider:
          (map[FirestoreFields.loginProvider] as String?) ?? 'google+password',
      googleVerified: (map[FirestoreFields.googleVerified] as bool?) ?? false,
      passwordSet: (map[FirestoreFields.passwordSet] as bool?) ?? false,
      biodata: (map[FirestoreFields.biodata] as String?) ?? '',
      updatedAt: map[FirestoreFields.updatedAt],
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreFields.uid: uid,
      FirestoreFields.username: username,
      FirestoreFields.email: email,
      FirestoreFields.photoUrl: photoUrl,
      FirestoreFields.role: role,
      FirestoreFields.loginProvider: loginProvider,
      FirestoreFields.googleVerified: googleVerified,
      FirestoreFields.passwordSet: passwordSet,
      if (biodata.isNotEmpty) FirestoreFields.biodata: biodata,
      if (updatedAt != null) FirestoreFields.updatedAt: updatedAt,
    };
  }
}
