import '../../core/constants/app_constants.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/utils/doc_id_helper.dart';
import '../../models/subject_model.dart';
import '../../models/subject_request_model.dart';
import '../../models/user_role_model.dart';
import '../datasources/firestore_datasource.dart';

class SubjectRepository {
  SubjectRepository(this._firestore);

  final FirestoreDataSource _firestore;

  Future<List<SubjectModel>> getGlobalSubjectItems() async {
    final records = await _firestore.getCollectionRecords(
      FirestoreCollections.subjects,
    );
    if (records.isEmpty) {
      final seeded = <SubjectModel>[];
      for (final name in AppConstants.coreSubjects) {
        final docId = DocIdHelper.subjectDocId(name);
        final model = SubjectModel(id: docId, name: name, type: 'core');
        await _firestore.setDoc(
          FirestoreCollections.subjects,
          docId,
          model.toMap(),
        );
        seeded.add(model);
      }
      seeded.sort((a, b) => a.name.compareTo(b.name));
      return seeded;
    }

    final list = records
        .map((r) => SubjectModel.fromMap(r.data, docId: r.id))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<List<String>> getGlobalSubjects() async {
    final items = await getGlobalSubjectItems();
    return items.map((s) => s.name).toList();
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
    final records = await _firestore.queryRecords(
      FirestoreCollections.subjectRequests,
      orderByField: FirestoreFields.timestamp,
      descending: true,
    );
    return records
        .map((r) => SubjectRequestModel.fromMap(r.data))
        .toList();
  }

  Future<List<SubjectRequestModel>> getUserSubjectRequests(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return const <SubjectRequestModel>[];
    final records = await _firestore.queryRecords(
      FirestoreCollections.subjectRequests,
      isEqualTo: {FirestoreFields.by: trimmed},
    );
    final list = records
        .map((r) => SubjectRequestModel.fromMap(r.data))
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
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
    final records = await _firestore.queryRecords(
      FirestoreCollections.userRoles,
      isEqualTo: {FirestoreFields.email: email},
    );
    return records
        .map((r) => UserRoleModel.fromMap(r.data, docId: r.id))
        .toList();
  }

  Future<List<String>> getQualifiedTeachers(String subject) async {
    final records = await _firestore.queryRecords(
      FirestoreCollections.userRoles,
      isEqualTo: {
        FirestoreFields.subject: subject,
        FirestoreFields.role: 'teacher',
      },
    );
    return records
        .map((r) => r.data[FirestoreFields.email] as String?)
        .whereType<String>()
        .toList();
  }
}
