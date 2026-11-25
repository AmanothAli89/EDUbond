import '../core/constants/firestore_collections.dart';

class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final String type; // 'core' or 'admin'

  bool get isCore => type == 'core';
  bool get isAdmin => type == 'admin';

  factory SubjectModel.fromMap(Map<String, dynamic> map, {String docId = ''}) {
    final rawName = (map[FirestoreFields.name] as String?)?.trim() ?? '';
    final rawType = (map[FirestoreFields.type] as String?)?.trim() ?? 'core';
    return SubjectModel(
      id: docId,
      name: rawName.isNotEmpty ? rawName : docId,
      type: rawType.isNotEmpty ? rawType : 'core',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      FirestoreFields.name: name,
      FirestoreFields.type: type,
    };
  }
}
