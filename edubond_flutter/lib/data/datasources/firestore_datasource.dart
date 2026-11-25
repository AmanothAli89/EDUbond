import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_collections.dart';

class FirestoreDataSource {
  FirestoreDataSource(this._db);

  final FirebaseFirestore _db;

  FirebaseFirestore get raw => _db;

  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(
    String collection,
    String docId,
  ) {
    return _db.collection(collection).doc(docId).get();
  }

  Future<Map<String, dynamic>?> getDocData(
    String collection,
    String docId,
  ) async {
    final doc = await _db.collection(collection).doc(docId).get();
    return doc.data();
  }

  Future<void> setDoc(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    return _db
        .collection(collection)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
  }

  Future<void> updateDoc(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) {
    return _db.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDoc(String collection, String docId) {
    return _db.collection(collection).doc(docId).delete();
  }

  Future<DocumentReference<Map<String, dynamic>>> addDoc(
    String collection,
    Map<String, dynamic> data,
  ) {
    return _db.collection(collection).add(data);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(String collection) {
    return _db.collection(collection).get();
  }

  Future<List<({String id, Map<String, dynamic> data})>> getCollectionRecords(
    String collection,
  ) async {
    final snap = await _db.collection(collection).get();
    return snap.docs.map((doc) => (id: doc.id, data: doc.data())).toList();
  }

  Future<List<({String id, Map<String, dynamic> data})>> queryRecords(
    String collection, {
    Map<String, dynamic> isEqualTo = const <String, dynamic>{},
    Map<String, dynamic> arrayContains = const <String, dynamic>{},
    Map<String, dynamic> isGreaterThanOrEqualTo = const <String, dynamic>{},
    String? whereInField,
    List<dynamic>? whereInValues,
    String? orderByField,
    bool descending = false,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection(collection);
    for (final entry in isEqualTo.entries) {
      query = query.where(entry.key, isEqualTo: entry.value);
    }
    for (final entry in arrayContains.entries) {
      query = query.where(entry.key, arrayContains: entry.value);
    }
    for (final entry in isGreaterThanOrEqualTo.entries) {
      query = query.where(entry.key, isGreaterThanOrEqualTo: entry.value);
    }
    if (whereInField != null && whereInValues != null && whereInValues.isNotEmpty) {
      query = query.where(whereInField, whereIn: whereInValues);
    }
    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }
    final snap = await query.get();
    return snap.docs.map((doc) => (id: doc.id, data: doc.data())).toList();
  }

  Stream<List<({String id, Map<String, dynamic> data})>> watchSubcollection(
    String parentCollection,
    String parentDocId,
    String subcollection, {
    String? orderByField,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(parentCollection)
        .doc(parentDocId)
        .collection(subcollection);
    if (orderByField != null) {
      query = query.orderBy(orderByField);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map((d) => (id: d.id, data: d.data())).toList(),
        );
  }

  Future<String> addSubcollectionDoc(
    String parentCollection,
    String parentDocId,
    String subcollection,
    Map<String, dynamic> data,
  ) async {
    final ref = await _db
        .collection(parentCollection)
        .doc(parentDocId)
        .collection(subcollection)
        .add(data);
    return ref.id;
  }

  Future<void> arrayUnionSubcollectionField(
    String parentCollection,
    String parentDocId,
    String subcollection,
    String docId,
    String field,
    dynamic value,
  ) {
    return _db
        .collection(parentCollection)
        .doc(parentDocId)
        .collection(subcollection)
        .doc(docId)
        .update({
      field: FieldValue.arrayUnion([value]),
    });
  }

  Future<void> deleteSubcollectionDoc(
    String parentCollection,
    String parentDocId,
    String subcollection,
    String docId,
  ) {
    return _db
        .collection(parentCollection)
        .doc(parentDocId)
        .collection(subcollection)
        .doc(docId)
        .delete();
  }

  Future<void> logActivity(String email, String action) {
    return _db.collection(FirestoreCollections.activityLogs).add({
      FirestoreFields.email: email,
      FirestoreFields.action: action,
      FirestoreFields.timestamp: DateTime.now().millisecondsSinceEpoch,
    });
  }
}
