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
    final data = await _firestore.getDocData(FirestoreCollections.groups, groupId);
    if (data == null) return null;
    return GroupModel.fromMap(data, fallbackId: groupId);
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
    final records = await _firestore.queryRecords(
      FirestoreCollections.groups,
      isEqualTo: {FirestoreFields.subject: subject},
    );
    return records
        .map((r) => GroupModel.fromMap(r.data, fallbackId: r.id))
        .toList();
  }

  /// Returns all groups where `email` appears in `members`, `teachers`, or `createdBy`.
  Future<List<GroupModel>> getGroupsForUser(String email) async {
    final memberRecords = await _firestore.queryRecords(
      FirestoreCollections.groups,
      arrayContains: {FirestoreFields.members: email},
    );
    final teacherRecords = await _firestore.queryRecords(
      FirestoreCollections.groups,
      arrayContains: {FirestoreFields.teachers: email},
    );
    final creatorRecords = await _firestore.queryRecords(
      FirestoreCollections.groups,
      isEqualTo: {FirestoreFields.createdBy: email},
    );

    final byId = <String, GroupModel>{};
    for (final r in [...memberRecords, ...teacherRecords, ...creatorRecords]) {
      final group = GroupModel.fromMap(r.data, fallbackId: r.id);
      byId[group.id] = group;
    }
    return byId.values.toList();
  }

  /// Sends a join request unless a `pending` request already exists for this
  /// user and group. Returns `true` if created, `false` if duplicate pending.
  Future<bool> requestToJoinGroup({
    required String groupId,
    required String groupName,
    required String subject,
    required String requesterEmail,
  }) async {
    final existing = await _firestore.queryRecords(
      FirestoreCollections.groupJoinRequests,
      isEqualTo: {
        FirestoreFields.groupId: groupId,
        FirestoreFields.requester: requesterEmail,
        FirestoreFields.status: 'pending',
      },
    );
    if (existing.isNotEmpty) {
      return false;
    }

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
    await _firestore.setDoc(
      FirestoreCollections.groupJoinRequests,
      req.id,
      req.toMap(),
    );
    return true;
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
      final records = await _firestore.queryRecords(
        FirestoreCollections.groupJoinRequests,
        whereInField: FirestoreFields.groupId,
        whereInValues: chunk,
        isEqualTo: {FirestoreFields.status: 'pending'},
      );
      for (final r in records) {
        final req = GroupRequestModel.fromMap(r.data);
        if (req.requester.toLowerCase() != email.toLowerCase()) {
          results.add(req);
        }
      }
    }
    return results;
  }

  Future<List<GroupRequestModel>> getSentRequests(String email) async {
    final records = await _firestore.queryRecords(
      FirestoreCollections.groupJoinRequests,
      isEqualTo: {FirestoreFields.requester: email},
    );
    final list = records.map((r) => GroupRequestModel.fromMap(r.data)).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
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

  /// Sends a teacher invitation unless a `pending` invitation already exists
  /// for the same group and teacher. Returns `true` if created, `false` if duplicate.
  Future<bool> requestTeacherToJoin({
    required String groupId,
    required String groupName,
    required String subject,
    required String requesterEmail,
    required String teacherEmail,
  }) async {
    final existing = await _firestore.queryRecords(
      FirestoreCollections.teacherGroupRequests,
      isEqualTo: {
        FirestoreFields.groupId: groupId,
        FirestoreFields.teacher: teacherEmail,
        FirestoreFields.status: 'pending',
      },
    );
    if (existing.isNotEmpty) {
      return false;
    }

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
    await _firestore.setDoc(
      FirestoreCollections.teacherGroupRequests,
      req.id,
      req.toMap(),
    );
    return true;
  }

  Future<Set<String>> getPendingInvitedTeachersForGroup(String groupId) async {
    final records = await _firestore.queryRecords(
      FirestoreCollections.teacherGroupRequests,
      isEqualTo: {
        FirestoreFields.groupId: groupId,
        FirestoreFields.status: 'pending',
      },
    );
    return records
        .map((r) => (r.data[FirestoreFields.teacher] as String?) ?? '')
        .where((t) => t.isNotEmpty)
        .toSet();
  }

  Future<List<GroupRequestModel>> getIncomingTeacherRequests(
    String email,
  ) async {
    final records = await _firestore.queryRecords(
      FirestoreCollections.teacherGroupRequests,
      isEqualTo: {
        FirestoreFields.teacher: email,
        FirestoreFields.status: 'pending',
      },
    );
    return records.map((r) => GroupRequestModel.fromMap(r.data)).toList();
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
    final data = await _firestore.getDocData(FirestoreCollections.groups, groupId);
    if (data == null) {
      throw Exception('Group not found.');
    }
    final lower = email.toLowerCase();
    final members = (data[FirestoreFields.members] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.toLowerCase() != lower)
        .toList();
    final teachers = (data[FirestoreFields.teachers] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.toLowerCase() != lower)
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
