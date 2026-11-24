import '../core/constants/firestore_collections.dart';

class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.createdBy,
    required this.members,
    required this.teachers,
    required this.timestamp,
  });

  final String id;
  final String name;
  final String subject;
  final String createdBy;
  final List<String> members;
  final List<String> teachers;
  final int timestamp;

  bool containsUser(String email) {
    final lower = email.toLowerCase();
    return createdBy.toLowerCase() == lower ||
        members.any((m) => m.toLowerCase() == lower) ||
        teachers.any((t) => t.toLowerCase() == lower);
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, {String fallbackId = ''}) {
    final rawMembers = map[FirestoreFields.members] as List<dynamic>? ?? const [];
    final rawTeachers = map[FirestoreFields.teachers] as List<dynamic>? ?? const [];
    return GroupModel(
      id: (map[FirestoreFields.id] as String?) ?? fallbackId,
      name: (map[FirestoreFields.name] as String?) ?? '',
      subject: (map[FirestoreFields.subject] as String?) ?? '',
      createdBy: (map[FirestoreFields.createdBy] as String?) ?? '',
      members: rawMembers.map((e) => e.toString()).toList(),
      teachers: rawTeachers.map((e) => e.toString()).toList(),
      timestamp: (map[FirestoreFields.timestamp] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreFields.id: id,
      FirestoreFields.name: name,
      FirestoreFields.subject: subject,
      FirestoreFields.createdBy: createdBy,
      FirestoreFields.members: members,
      FirestoreFields.teachers: teachers,
      FirestoreFields.timestamp: timestamp,
    };
  }
}
