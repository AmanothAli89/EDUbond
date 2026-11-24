import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/utils/doc_id_helper.dart';
import '../../models/group_model.dart';
import '../../models/group_request_model.dart';
import '../datasources/firestore_datasource.dart';

class GroupRepository {
  GroupRepository(this._firestore);

  final FirestoreDataSource _firestore;

  Future<GroupModel?> getGroupInfo(String groupId) async {
    final doc = await _firestore.getDoc(FirestoreCollections.groups, groupId);
    final data = doc.data();
    if (data == null) return null;
    return GroupModel.fromMap(data, fallbackId: doc.id);
  }

  Future<void> createGroup({
    required String subject,
    required String creatorEmail,
    required String groupName,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final group = GroupModel(
      id: DocIdHelper.newGroupId(now),
      name: groupName.trim(),
      subject: subject.trim(),
      createdBy: creatorEmail,
      members: [creatorEmail],
      teachers: const [],
      timestamp: now,
    );
    await _firestore.setDoc(FirestoreCollections.groups, group.id, group.toMap());
    await _firestore.logActivity(creatorEmail, 'Created group: ${group.name}');
  }

  Future<List<GroupModel>> getGroupsBySubject(String subject) async {
    final snap = await _firestore.raw
        .collection(FirestoreCollections.groups)
        .where(FirestoreFields.subject, isEqualTo: subject)
        .get();
    return snap.docs
        .map((doc) => GroupModel.fromMap(doc.data(), fallbackId: doc.id))
        .toList();
  }

  Future<List<GroupModel>> getGroupsForUser(String email) async {
    final memberSnap = await _firestore.raw
        .collection(FirestoreCollections.groups)
        .where(FirestoreFields.members, arrayContains: email)
        .get();
    final teacherSnap = await _firestore.raw
        .collection(FirestoreCollections.groups)
        .where(FirestoreFields.teachers, arrayContains: email)
        .get();

    final byId = <String, GroupModel>{};
    for (final doc in [...memberSnap.docs, ...teacherSnap.docs]) {
      final group = GroupModel.fromMap(doc.data(), fallbackId: doc.id);
      byId[group.id] = group;
    }
    return byId.values.toList();
  }

  Future<void> requestToJoinGroup({
    required String groupId,
    required String groupName,
    required String subject,
    required String requesterEmail,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final req = GroupRequestModel(
      id: DocIdHelper.newTimestampId(now),
      groupId: groupId,
      groupName: groupName,
      subject: subject,
      requester: requesterEmail,
      status: 'pending',
      timestamp: now,
    );
    return _firestore.setDoc(
      FirestoreCollections.groupJoinRequests,
      req.id,
      req.toMap(),
    );
  }

  Future<List<GroupRequestModel>> getIncomingJoinRequests(String email) async {
    final groups = await getGroupsForUser(email);
    final groupIds = groups.map((g) => g.id).where((id) => id.isNotEmpty).toList();
    if (groupIds.isEmpty) return const [];

    // Chunk by 10 to stay safely within Firestore `whereIn` query limits.
    final results = <GroupRequestModel>[];
    for (var i = 0; i < groupIds.length; i += 10) {
      final chunk = groupIds.sublist(
        i,
        i + 10 > groupIds.length ? groupIds.length : i + 10,
      );
      final snap = await _firestore.raw
          .collection(FirestoreCollections.groupJoinRequests)
          .where(FirestoreFields.groupId, whereIn: chunk)
          .where(FirestoreFields.status, isEqualTo: 'pending')
          .get();
      for (final doc in snap.docs) {
        final req = GroupRequestModel.fromMap(doc.data());
        if (req.requester != email) {
          results.add(req);
        }
      }
    }
    return results;
  }

  Future<List<GroupRequestModel>> getSentRequests(String email) async {
    final snap = await _firestore.raw
        .collection(FirestoreCollections.groupJoinRequests)
        .where(FirestoreFields.requester, isEqualTo: email)
        .get();
    return snap.docs.map((doc) => GroupRequestModel.fromMap(doc.data())).toList();
  }

  Future<void> acceptJoinRequest({
    required String requestId,
    required String groupId,
    required String requesterEmail,
  }) async {
    await _firestore.updateDoc(
      FirestoreCollections.groupJoinRequests,
      requestId,
      {FirestoreFields.status: 'accepted'},
    );
    await _firestore.updateDoc(
      FirestoreCollections.groups,
      groupId,
      {FirestoreFields.members: FieldValue.arrayUnion([requesterEmail])},
    );
  }

  Future<void> rejectJoinRequest(String requestId) {
    return _firestore.updateDoc(
      FirestoreCollections.groupJoinRequests,
      requestId,
      {FirestoreFields.status: 'rejected'},
    );
  }

  Future<void> requestTeacherToJoin({
    required String groupId,
    required String groupName,
    required String subject,
    required String requesterEmail,
    required String teacherEmail,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final req = GroupRequestModel(
      id: DocIdHelper.newTimestampId(now),
      groupId: groupId,
      groupName: groupName,
      subject: subject,
      requester: requesterEmail,
      teacher: teacherEmail,
      status: 'pending',
      timestamp: now,
    );
    return _firestore.setDoc(
      FirestoreCollections.teacherGroupRequests,
      req.id,
      req.toMap(),
    );
  }

  Future<List<GroupRequestModel>> getIncomingTeacherRequests(
    String email,
  ) async {
    final snap = await _firestore.raw
        .collection(FirestoreCollections.teacherGroupRequests)
        .where(FirestoreFields.teacher, isEqualTo: email)
        .where(FirestoreFields.status, isEqualTo: 'pending')
        .get();
    return snap.docs.map((doc) => GroupRequestModel.fromMap(doc.data())).toList();
  }

  Future<void> acceptTeacherRequest({
    required String requestId,
    required String groupId,
    required String teacherEmail,
  }) async {
    await _firestore.updateDoc(
      FirestoreCollections.teacherGroupRequests,
      requestId,
      {FirestoreFields.status: 'accepted'},
    );
    await _firestore.updateDoc(
      FirestoreCollections.groups,
      groupId,
      {FirestoreFields.teachers: FieldValue.arrayUnion([teacherEmail])},
    );
  }

  Future<void> rejectTeacherRequest(String requestId) {
    return _firestore.updateDoc(
      FirestoreCollections.teacherGroupRequests,
      requestId,
      {FirestoreFields.status: 'rejected'},
    );
  }

  Future<void> leaveGroup({
    required String groupId,
    required String email,
  }) async {
    final doc = await _firestore.getDoc(FirestoreCollections.groups, groupId);
    if (!doc.exists) {
      throw Exception('Group not found.');
    }
    final data = doc.data() ?? const <String, dynamic>{};
    final members = (data[FirestoreFields.members] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e != email)
        .toList();
    final teachers = (data[FirestoreFields.teachers] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e != email)
        .toList();

    await _firestore.updateDoc(
      FirestoreCollections.groups,
      groupId,
      {
        FirestoreFields.members: members,
        FirestoreFields.teachers: teachers,
      },
    );
  }
}
