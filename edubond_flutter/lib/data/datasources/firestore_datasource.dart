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

  Future<void> logActivity(String email, String action) {
    return _db.collection(FirestoreCollections.activityLogs).add({
      FirestoreFields.email: email,
      FirestoreFields.action: action,
      FirestoreFields.timestamp: DateTime.now().millisecondsSinceEpoch,
    });
  }
}
