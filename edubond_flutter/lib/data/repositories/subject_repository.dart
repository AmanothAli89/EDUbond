import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/utils/doc_id_helper.dart';
import '../../models/subject_request_model.dart';
import '../../models/user_role_model.dart';
import '../datasources/firestore_datasource.dart';

class SubjectRepository {
  SubjectRepository(this._firestore);

  final FirestoreDataSource _firestore;

  Future<List<String>> getGlobalSubjects() async {
    final snap = await _firestore.getCollection(FirestoreCollections.subjects);
    final list = snap.docs.map((doc) {
      final name = doc.data()[FirestoreFields.name] as String?;
      return (name != null && name.isNotEmpty) ? name : doc.id;
    }).toList();

    if (list.isEmpty) {
      for (final name in AppConstants.coreSubjects) {
        await _firestore.setDoc(
          FirestoreCollections.subjects,
          DocIdHelper.subjectDocId(name),
          {
            FirestoreFields.name: name,
            FirestoreFields.type: 'core',
          },
        );
      }
      return List<String>.from(AppConstants.coreSubjects);
    }

    list.sort();
    return list;
  }

  Future<void> addSubjectGlobally(String name) {
    final trimmed = name.trim();
    return _firestore.setDoc(
      FirestoreCollections.subjects,
      DocIdHelper.subjectDocId(trimmed),
      {
        FirestoreFields.name: trimmed,
        FirestoreFields.type: 'admin',
      },
    );
  }

  Future<void> deleteSubjectGlobally(String name) {
    return _firestore.deleteDoc(
      FirestoreCollections.subjects,
      DocIdHelper.subjectDocId(name),
    );
  }

  Future<void> submitSubjectRequest({
    required String subjectName,
    required String requesterEmail,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final req = SubjectRequestModel(
      id: DocIdHelper.newTimestampId(now),
      subject: subjectName.trim(),
      by: requesterEmail.trim(),
      status: 'pending',
      timestamp: now,
    );
    return _firestore.setDoc(
      FirestoreCollections.subjectRequests,
      req.id,
      req.toMap(),
    );
  }

  Future<List<SubjectRequestModel>> getSubjectRequests() async {
    final snap = await _firestore.raw
        .collection(FirestoreCollections.subjectRequests)
        .orderBy(FirestoreFields.timestamp, descending: true)
        .get();
    return snap.docs
        .map((doc) => SubjectRequestModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateSubjectRequestStatus({
    required String requestId,
    required String status,
    String? updatedName,
  }) {
    final updates = <String, dynamic>{
      FirestoreFields.status: status,
      if (updatedName != null) FirestoreFields.subject: updatedName.trim(),
    };
    return _firestore.updateDoc(
      FirestoreCollections.subjectRequests,
      requestId,
      updates,
    );
  }

  Future<void> addSubjectRole({
    required String email,
    required String subject,
    required String role,
    int score = 0,
  }) {
    final roleModel = UserRoleModel(
      email: email,
      subject: subject,
      role: role,
      score: score,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    return _firestore.setDoc(
      FirestoreCollections.userRoles,
      DocIdHelper.emailSubjectDocId(email, subject),
      roleModel.toMap(),
    );
  }

  Future<List<UserRoleModel>> getUserSubjectRoles(String email) async {
    final snap = await _firestore.raw
        .collection(FirestoreCollections.userRoles)
        .where(FirestoreFields.email, isEqualTo: email)
        .get();
    return snap.docs
        .map((doc) => UserRoleModel.fromMap(doc.data(), docId: doc.id))
        .toList();
  }

  Future<List<String>> getQualifiedTeachers(String subject) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _firestore.raw
        .collection(FirestoreCollections.userRoles)
        .where(FirestoreFields.subject, isEqualTo: subject)
        .where(FirestoreFields.role, isEqualTo: 'teacher')
        .get();
    return snap.docs
        .map((doc) => doc.data()[FirestoreFields.email] as String?)
        .whereType<String>()
        .toList();
  }
}
