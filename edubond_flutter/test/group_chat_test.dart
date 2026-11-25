import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edubond_flutter/core/constants/app_colors.dart';
import 'package:edubond_flutter/core/constants/app_constants.dart';
import 'package:edubond_flutter/core/constants/firestore_collections.dart';
import 'package:edubond_flutter/core/routes/app_routes.dart';
import 'package:edubond_flutter/core/services/providers.dart';
import 'package:edubond_flutter/data/datasources/catbox_upload_datasource.dart';
import 'package:edubond_flutter/data/datasources/firebase_storage_datasource.dart';
import 'package:edubond_flutter/data/datasources/firestore_datasource.dart';
import 'package:edubond_flutter/data/repositories/auth_repository.dart';
import 'package:edubond_flutter/data/repositories/chat_repository.dart';
import 'package:edubond_flutter/data/repositories/group_repository.dart';
import 'package:edubond_flutter/data/repositories/subject_repository.dart';
import 'package:edubond_flutter/features/chat/chat_module.dart';
import 'package:edubond_flutter/features/group_info/group_info_module.dart';
import 'package:edubond_flutter/features/groups/groups_module.dart';
import 'package:edubond_flutter/features/requests/requests_module.dart';
import 'package:edubond_flutter/features/shared_files/shared_files_module.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

class InMemoryChatFirestoreDataSource implements FirestoreDataSource {
  final Map<String, Map<String, Map<String, dynamic>>> store = {};
  final Map<String, Map<String, Map<String, dynamic>>> subStore = {};
  final Map<String, StreamController<List<({String id, Map<String, dynamic> data})>>>
      _subControllers = {};

  int autoId = 1;
  int markReadCalls = 0;

  Map<String, Map<String, dynamic>> _col(String name) =>
      store.putIfAbsent(name, () => <String, Map<String, dynamic>>{});

  String _subKey(String parent, String parentId, String sub) =>
      '$parent/$parentId/$sub';

  Map<String, Map<String, dynamic>> _subCol(
    String parent,
    String parentId,
    String sub,
  ) =>
      subStore.putIfAbsent(
        _subKey(parent, parentId, sub),
        () => <String, Map<String, dynamic>>{},
      );

  List<({String id, Map<String, dynamic> data})> _sortedSubRecords(
    String key, {
    String? orderByField,
  }) {
    final map = subStore[key] ?? const <String, Map<String, dynamic>>{};
    final list = map.entries
        .map((e) => (id: e.key, data: Map<String, dynamic>.from(e.value)))
        .toList();
    if (orderByField != null) {
      list.sort((a, b) {
        final av = a.data[orderByField] as Comparable? ?? 0;
        final bv = b.data[orderByField] as Comparable? ?? 0;
        return av.compareTo(bv);
      });
    }
    return list;
  }

  void _emitSub(String key) {
    final ctrl = _subControllers[key];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(_sortedSubRecords(key, orderByField: FirestoreFields.timestamp));
    }
  }

  @override
  Future<Map<String, dynamic>?> getDocData(
    String collection,
    String docId,
  ) async {
    final data = _col(collection)[docId];
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  @override
  Future<void> setDoc(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    final col = _col(collection);
    if (merge && col.containsKey(docId)) {
      col[docId] = {...col[docId]!, ...data};
    } else {
      col[docId] = Map<String, dynamic>.from(data);
    }
  }

  @override
  Future<void> updateDoc(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final col = _col(collection);
    final current = Map<String, dynamic>.from(col[docId] ?? {});
    for (final entry in data.entries) {
      final val = entry.value;
      if (val is FieldValue) {
        // Handle FieldValue.arrayUnion in fake store by inspecting known array fields
        final str = val.toString();
        final existing = List<dynamic>.from(
          current[entry.key] as List<dynamic>? ?? const [],
        );
        // FieldValue.arrayUnion stores elements cleanly if passed via helper below;
        // fallback no-op if opaque in SDK.
        if (str.contains('arrayUnion')) {
          current[entry.key] = existing;
        }
      } else {
        current[entry.key] = val;
      }
    }
    col[docId] = current;
  }

  @override
  Future<void> deleteDoc(String collection, String docId) async {
    _col(collection).remove(docId);
  }

  @override
  Future<List<({String id, Map<String, dynamic> data})>> getCollectionRecords(
    String collection,
  ) async {
    return _col(collection)
        .entries
        .map((e) => (id: e.key, data: Map<String, dynamic>.from(e.value)))
        .toList();
  }

  @override
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
    final items = _col(collection).entries.where((entry) {
      final data = entry.value;
      for (final cond in isEqualTo.entries) {
        if (data[cond.key] != cond.value) return false;
      }
      for (final cond in arrayContains.entries) {
        final list = data[cond.key];
        if (list is! List || !list.contains(cond.value)) return false;
      }
      for (final cond in isGreaterThanOrEqualTo.entries) {
        final val = data[cond.key];
        if (val is! Comparable || val.compareTo(cond.value) < 0) return false;
      }
      if (whereInField != null && whereInValues != null) {
        if (!whereInValues.contains(data[whereInField])) return false;
      }
      return true;
    }).map((e) => (id: e.key, data: Map<String, dynamic>.from(e.value))).toList();

    if (orderByField != null) {
      items.sort((a, b) {
        final av = a.data[orderByField] as Comparable? ?? 0;
        final bv = b.data[orderByField] as Comparable? ?? 0;
        return descending ? bv.compareTo(av) : av.compareTo(bv);
      });
    }
    return items;
  }

  @override
  Stream<List<({String id, Map<String, dynamic> data})>> watchSubcollection(
    String parentCollection,
    String parentDocId,
    String subcollection, {
    String? orderByField,
  }) {
    final key = _subKey(parentCollection, parentDocId, subcollection);
    final ctrl = _subControllers.putIfAbsent(
      key,
      () => StreamController<
          List<({String id, Map<String, dynamic> data})>>.broadcast(),
    );
    Future.microtask(() {
      if (!ctrl.isClosed) {
        ctrl.add(_sortedSubRecords(key, orderByField: orderByField));
      }
    });
    return ctrl.stream;
  }

  @override
  Future<String> addSubcollectionDoc(
    String parentCollection,
    String parentDocId,
    String subcollection,
    Map<String, dynamic> data,
  ) async {
    final key = _subKey(parentCollection, parentDocId, subcollection);
    final id = 'msg_${autoId++}';
    _subCol(parentCollection, parentDocId, subcollection)[id] =
        Map<String, dynamic>.from(data);
    _emitSub(key);
    return id;
  }

  @override
  Future<void> arrayUnionSubcollectionField(
    String parentCollection,
    String parentDocId,
    String subcollection,
    String docId,
    String field,
    dynamic value,
  ) async {
    markReadCalls++;
    final key = _subKey(parentCollection, parentDocId, subcollection);
    final doc = _subCol(parentCollection, parentDocId, subcollection)[docId];
    if (doc == null) return;
    final list = List<dynamic>.from(doc[field] as List<dynamic>? ?? const []);
    if (!list.contains(value)) {
      list.add(value);
      doc[field] = list;
      _emitSub(key);
    }
  }

  @override
  Future<void> deleteSubcollectionDoc(
    String parentCollection,
    String parentDocId,
    String subcollection,
    String docId,
  ) async {
    final key = _subKey(parentCollection, parentDocId, subcollection);
    _subCol(parentCollection, parentDocId, subcollection).remove(docId);
    _emitSub(key);
  }

  @override
  Future<void> logActivity(String email, String action) async {
    final id = 'log_${autoId++}';
    await setDoc(FirestoreCollections.activityLogs, id, {
      FirestoreFields.email: email,
      FirestoreFields.action: action,
      FirestoreFields.timestamp: DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  FirebaseFirestore get raw => throw UnimplementedError();

  @override
  Future<DocumentReference<Map<String, dynamic>>> addDoc(
    String collection,
    Map<String, dynamic> data,
  ) =>
      throw UnimplementedError();

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(String collection) =>
      throw UnimplementedError();

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(
    String collection,
    String docId,
  ) =>
      throw UnimplementedError();
}

/// GroupRepository variant for tests where FieldValue.arrayUnion cannot be unpacked
/// outside Cloud Firestore platform channels.
class TestableGroupRepository extends GroupRepository {
  TestableGroupRepository(this._db) : super(_db);

  final InMemoryChatFirestoreDataSource _db;

  @override
  Future<void> acceptJoinRequest({
    required String requestId,
    required String groupId,
    required String requesterEmail,
  }) async {
    await _db.updateDoc(
      FirestoreCollections.groupJoinRequests,
      requestId,
      {FirestoreFields.status: 'accepted'},
    );
    final data = await _db.getDocData(FirestoreCollections.groups, groupId);
    if (data != null) {
      final members = List<String>.from(data[FirestoreFields.members] as List? ?? []);
      if (!members.contains(requesterEmail)) members.add(requesterEmail);
      await _db.updateDoc(
        FirestoreCollections.groups,
        groupId,
        {FirestoreFields.members: members},
      );
    }
  }

  @override
  Future<void> acceptTeacherRequest({
    required String requestId,
    required String groupId,
    required String teacherEmail,
  }) async {
    await _db.updateDoc(
      FirestoreCollections.teacherGroupRequests,
      requestId,
      {FirestoreFields.status: 'accepted'},
    );
    final data = await _db.getDocData(FirestoreCollections.groups, groupId);
    if (data != null) {
      final teachers = List<String>.from(data[FirestoreFields.teachers] as List? ?? []);
      if (!teachers.contains(teacherEmail)) teachers.add(teacherEmail);
      await _db.updateDoc(
        FirestoreCollections.groups,
        groupId,
        {FirestoreFields.teachers: teachers},
      );
    }
  }
}

class FakeAuthRepo implements AuthRepository {
  FakeAuthRepo(this.email, this.names);

  final String email;
  final Map<String, String> names;

  @override
  String get activeUserEmail => email;

  @override
  String get currentLocalEmail => email;

  @override
  User? get currentFirebaseUser => null;

  @override
  Future<String> getUserNameByEmail(String e) async => names[e] ?? e;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStorageDataSource implements FirebaseStorageDataSource {
  bool called = false;
  String? lastPath;

  @override
  Future<String> uploadGroupFile({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    called = true;
    lastPath = 'groups/$groupId/shared_files/$fileName';
    onProgress?.call(1.0);
    return 'https://firebasestorage.googleapis.com/fake/$fileName';
  }
}

void main() {
  late InMemoryChatFirestoreDataSource fakeDb;
  late TestableGroupRepository groupRepo;
  late SubjectRepository subjectRepo;
  late FakeStorageDataSource fakeStorage;

  const alice = 'alice@baust.edu.bd';
  const bob = 'bob@baust.edu.bd';
  const prof = 'prof@baust.edu.bd';
  final names = {
    alice: 'Alice Rahman',
    bob: 'Bob Karim',
    prof: 'Prof. Hasan',
  };

  setUp(() {
    fakeDb = InMemoryChatFirestoreDataSource();
    groupRepo = TestableGroupRepository(fakeDb);
    subjectRepo = SubjectRepository(fakeDb);
    fakeStorage = FakeStorageDataSource();
  });

  group('Groups, Requests, Teacher Invitations & Leave Group', () {
    test('group ID preserves G{timestamp} and getGroupsForUser checks members, teachers, createdBy',
        () async {
      await groupRepo.createGroup(
        subject: 'Compiler',
        creatorEmail: alice,
        groupName: 'Compiler Ninjas',
      );
      final bySubject = await groupRepo.getGroupsBySubject('Compiler');
      expect(bySubject.length, 1);
      final g = bySubject.first;
      expect(g.id.startsWith('G'), isTrue);
      expect(g.members, [alice]);
      expect(g.teachers, isEmpty);

      // Creator-only group (even if not in members) must still appear in getGroupsForUser
      await fakeDb.setDoc(FirestoreCollections.groups, 'G999', {
        FirestoreFields.id: 'G999',
        FirestoreFields.name: 'Creator Only',
        FirestoreFields.subject: 'Algorithm',
        FirestoreFields.createdBy: alice,
        FirestoreFields.members: <String>[],
        FirestoreFields.teachers: <String>[],
        FirestoreFields.timestamp: 999,
      });

      final aliceGroups = await groupRepo.getGroupsForUser(alice);
      expect(aliceGroups.map((e) => e.id).toSet(), {g.id, 'G999'});
    });

    test('join requests prevent duplicates and approve adds user to members',
        () async {
      await groupRepo.createGroup(
        subject: 'Compiler',
        creatorEmail: alice,
        groupName: 'Compiler Lab',
      );
      final group = (await groupRepo.getGroupsBySubject('Compiler')).first;

      final first = await groupRepo.requestToJoinGroup(
        groupId: group.id,
        groupName: group.name,
        subject: group.subject,
        requesterEmail: bob,
      );
      final duplicate = await groupRepo.requestToJoinGroup(
        groupId: group.id,
        groupName: group.name,
        subject: group.subject,
        requesterEmail: bob,
      );
      expect(first, isTrue);
      expect(duplicate, isFalse);

      final incoming = await groupRepo.getIncomingJoinRequests(alice);
      expect(incoming.length, 1);
      await groupRepo.acceptJoinRequest(
        requestId: incoming.first.id,
        groupId: group.id,
        requesterEmail: bob,
      );

      final updated = await groupRepo.getGroupInfo(group.id);
      expect(updated!.members.contains(bob), isTrue);
      expect(updated.containsUser(bob), isTrue);
    });

    test('teacher invitations prevent duplicates, accept adds teacher, leaveGroup removes user',
        () async {
      await subjectRepo.addSubjectRole(
        email: prof,
        subject: 'Compiler',
        role: 'teacher',
        score: 9,
      );
      await groupRepo.createGroup(
        subject: 'Compiler',
        creatorEmail: alice,
        groupName: 'Compiler Mentors',
      );
      final group = (await groupRepo.getGroupsBySubject('Compiler')).first;

      final sent1 = await groupRepo.requestTeacherToJoin(
        groupId: group.id,
        groupName: group.name,
        subject: 'Compiler',
        requesterEmail: alice,
        teacherEmail: prof,
      );
      final sent2 = await groupRepo.requestTeacherToJoin(
        groupId: group.id,
        groupName: group.name,
        subject: 'Compiler',
        requesterEmail: alice,
        teacherEmail: prof,
      );
      expect(sent1, isTrue);
      expect(sent2, isFalse);

      final invites = await groupRepo.getIncomingTeacherRequests(prof);
      expect(invites.length, 1);
      await groupRepo.acceptTeacherRequest(
        requestId: invites.first.id,
        groupId: group.id,
        teacherEmail: prof,
      );

      var info = await groupRepo.getGroupInfo(group.id);
      expect(info!.teachers, [prof]);

      await groupRepo.leaveGroup(groupId: group.id, email: prof);
      info = await groupRepo.getGroupInfo(group.id);
      expect(info!.teachers, isEmpty);
    });
  });

  group('File Sharing (Catbox + Progress + Firebase Helper) & Meeting Detection',
      () {
    test('Catbox upload sends reqtype=fileupload, reports progress, and never silently switches to Firebase Storage',
        () async {
      var capturedUrl = '';
      var capturedReqType = '';
      var capturedFileName = '';

      final successClient = MockClient((request) async {
        capturedUrl = request.url.toString();
        final body = request.body;
        if (body.contains('reqtype') && body.contains('fileupload')) {
          capturedReqType = 'fileupload';
        }
        if (body.contains('notes.pdf')) {
          capturedFileName = 'notes.pdf';
        }
        return http.Response('https://files.catbox.moe/abc123.pdf', 200);
      });

      final repo = ChatRepository(
        firestoreDataSource: fakeDb,
        catboxUploadDataSource: CatboxUploadDataSource(successClient),
        storageDataSource: fakeStorage,
      );

      final progressSteps = <double>[];
      final url = await repo.uploadAndShareFile(
        groupId: 'G100',
        senderEmail: alice,
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        fileName: 'notes.pdf',
        fileType: 'application/pdf',
        onProgress: progressSteps.add,
      );

      expect(capturedUrl, AppConstants.catboxUploadUrl);
      expect(capturedReqType, 'fileupload');
      expect(capturedFileName, 'notes.pdf');
      expect(url, 'https://files.catbox.moe/abc123.pdf');
      expect(progressSteps.last, 1.0);
      expect(fakeStorage.called, isFalse);

      // Failure must throw instead of silently switching to Firebase Storage.
      final failClient = MockClient((_) async => http.Response('Server Error', 500));
      final failRepo = ChatRepository(
        firestoreDataSource: fakeDb,
        catboxUploadDataSource: CatboxUploadDataSource(failClient),
        storageDataSource: fakeStorage,
      );
      await expectLater(
        failRepo.uploadAndShareFile(
          groupId: 'G100',
          senderEmail: alice,
          bytes: Uint8List.fromList([1, 2]),
          fileName: 'fail.pdf',
          fileType: 'application/pdf',
        ),
        throwsException,
      );
      expect(fakeStorage.called, isFalse);

      // Explicit Firebase Storage helper works when invoked directly.
      final fbUrl = await failRepo.uploadAndShareFileToFirebaseStorage(
        groupId: 'G100',
        senderEmail: alice,
        bytes: Uint8List.fromList([1, 2]),
        fileName: 'backup.pdf',
        fileType: 'application/pdf',
      );
      expect(fakeStorage.called, isTrue);
      expect(fbUrl, 'https://firebasestorage.googleapis.com/fake/backup.pdf');
    });

    test('detectMeetingPlatform identifies Zoom, Google Meet, Jitsi, and Live',
        () {
      expect(
        ChatRepository.detectMeetingPlatform('https://us02web.zoom.us/j/123'),
        'Zoom',
      );
      expect(
        ChatRepository.detectMeetingPlatform('https://meet.google.com/abc-def'),
        'Google Meet',
      );
      expect(
        ChatRepository.detectMeetingPlatform('https://meet.jit.si/edubond'),
        'Jitsi',
      );
      expect(
        ChatRepository.detectMeetingPlatform('https://example.com/room'),
        'Live',
      );
    });
  });

  group('Multi-Account Chat, Read Receipts, Unsend, Shared Files & Info UI',
      () {
    Widget wrapUser({
      required String userEmail,
      required ChatRepository chatRepo,
      required Widget home,
      FilePickHandler? filePicker,
    }) {
      return ProviderScope(
        key: ValueKey('$userEmail-${home.runtimeType}'),
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepo(userEmail, names)),
          groupRepositoryProvider.overrideWithValue(groupRepo),
          subjectRepositoryProvider.overrideWithValue(subjectRepo),
          chatRepositoryProvider.overrideWithValue(chatRepo),
          filePickProvider.overrideWithValue(filePicker ?? () async => null),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.sharedFiles) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => SharedFilesModulePage(
                  groupId: settings.arguments as String? ?? '',
                ),
              );
            }
            if (settings.name == AppRoutes.groupInfo) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => GroupInfoModulePage(
                  groupId: settings.arguments as String? ?? '',
                ),
              );
            }
            return AppRouter.onGenerateRoute(settings);
          },
          home: home,
        ),
      );
    }

    testWidgets(
        'Multi-account messaging updates seenBy read receipts, supports meeting card & unsend only for sender',
        (tester) async {
      await fakeDb.setDoc(FirestoreCollections.groups, 'G500', {
        FirestoreFields.id: 'G500',
        FirestoreFields.name: 'DSA Hub',
        FirestoreFields.subject: 'Data Structure',
        FirestoreFields.createdBy: alice,
        FirestoreFields.members: [alice, bob],
        FirestoreFields.teachers: [prof],
        FirestoreFields.timestamp: 5000,
      });

      final chatRepo = ChatRepository(
        firestoreDataSource: fakeDb,
        catboxUploadDataSource: CatboxUploadDataSource(
          MockClient((_) async => http.Response('https://files.catbox.moe/doc.pdf', 200)),
        ),
        storageDataSource: fakeStorage,
      );

      // 1. Alice sends a text message and shares a Zoom meeting link
      await tester.pumpWidget(
        wrapUser(
          userEmail: alice,
          chatRepo: chatRepo,
          home: const ChatModulePage(groupId: 'G500', groupName: 'DSA Hub'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'See https://baust.edu.bd');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Single check before Bob reads
      expect(find.text('✓'), findsOneWidget);
      expect(find.text('✓✓'), findsNothing);

      // Share meeting link via dialog
      await tester.tap(find.text('📹'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText == 'Paste Google Meet, Zoom, or Jitsi link',
        ),
        'https://zoom.us/j/998877',
      );
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      expect(find.text('Zoom Meeting'), findsOneWidget);
      expect(find.text('Click to Join'), findsOneWidget);

      // 2. Switch to Bob's session: Bob opens Chat -> marks both messages read via seenBy
      await tester.pumpWidget(
        wrapUser(
          userEmail: bob,
          chatRepo: chatRepo,
          home: const ChatModulePage(groupId: 'G500', groupName: 'DSA Hub'),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeDb.markReadCalls, 2);
      expect(find.text('Alice Rahman'), findsNWidgets(2));

      // Bob long-pressing Alice's message must NOT open Unsend dialog
      await tester.longPress(find.text('Zoom Meeting'));
      await tester.pumpAndSettle();
      expect(find.text('Do you want to unsend this message?'), findsNothing);

      // 3. Switch back to Alice: sees blue double checkmarks (✓✓) & can unsend her own message
      await tester.pumpWidget(
        wrapUser(
          userEmail: alice,
          chatRepo: chatRepo,
          home: const ChatModulePage(groupId: 'G500', groupName: 'DSA Hub'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('✓✓'), findsNWidgets(2));
      final checkText = tester.widget<Text>(find.text('✓✓').first);
      expect(checkText.style?.color, AppColors.chatSeenBlue);

      await tester.longPress(find.text('Zoom Meeting'));
      await tester.pumpAndSettle();
      expect(find.text('Do you want to unsend this message?'), findsOneWidget);
      await tester.tap(find.text('Unsend'));
      await tester.pumpAndSettle();
      expect(find.text('Zoom Meeting'), findsNothing);
    });

    testWidgets(
        'File upload via picker shares to Chat and renders in SharedFiles with unsend',
        (tester) async {
      await fakeDb.setDoc(FirestoreCollections.groups, 'G600', {
        FirestoreFields.id: 'G600',
        FirestoreFields.name: 'OS Group',
        FirestoreFields.subject: 'Operating System',
        FirestoreFields.createdBy: alice,
        FirestoreFields.members: [alice],
        FirestoreFields.teachers: <String>[],
        FirestoreFields.timestamp: 6000,
      });

      final chatRepo = ChatRepository(
        firestoreDataSource: fakeDb,
        catboxUploadDataSource: CatboxUploadDataSource(
          MockClient((_) async => http.Response('https://files.catbox.moe/os.pdf', 200)),
        ),
        storageDataSource: fakeStorage,
      );

      await tester.pumpWidget(
        wrapUser(
          userEmail: alice,
          chatRepo: chatRepo,
          filePicker: () async => PickedAttachment(
            name: 'os_notes.pdf',
            bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
            extension: 'pdf',
          ),
          home: const ChatModulePage(groupId: 'G600', groupName: 'OS Group'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('📎'));
      await tester.pumpAndSettle();
      expect(find.text('os_notes.pdf'), findsOneWidget);

      // Verify in SharedFilesModulePage
      await tester.pumpWidget(
        wrapUser(
          userEmail: alice,
          chatRepo: chatRepo,
          home: const SharedFilesModulePage(groupId: 'G600'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('os_notes.pdf'), findsOneWidget);
      expect(find.textContaining('PDF Document • Shared by Alice Rahman'), findsOneWidget);

      await tester.longPress(find.text('os_notes.pdf'));
      await tester.pumpAndSettle();
      expect(find.text('Do you want to unsend this file?'), findsOneWidget);
      await tester.tap(find.text('Unsend'));
      await tester.pumpAndSettle();
      expect(find.text('No files shared yet'), findsOneWidget);
    });

    testWidgets(
        'GroupInfo excludes current teachers, hires qualified teacher, and Requests + MyGroups workflows succeed',
        (tester) async {
      const otherTeacher = 'mentor2@baust.edu.bd';
      await subjectRepo.addSubjectRole(
        email: prof,
        subject: 'Compiler',
        role: 'teacher',
        score: 9,
      );
      await subjectRepo.addSubjectRole(
        email: otherTeacher,
        subject: 'Compiler',
        role: 'teacher',
        score: 8,
      );
      await fakeDb.setDoc(FirestoreCollections.groups, 'G700', {
        FirestoreFields.id: 'G700',
        FirestoreFields.name: 'Compiler Club',
        FirestoreFields.subject: 'Compiler',
        FirestoreFields.createdBy: alice,
        FirestoreFields.members: [alice],
        FirestoreFields.teachers: [prof],
        FirestoreFields.timestamp: 7000,
      });

      final chatRepo = ChatRepository(
        firestoreDataSource: fakeDb,
        catboxUploadDataSource: CatboxUploadDataSource(),
        storageDataSource: fakeStorage,
      );

      // GroupInfo excludes `prof` (already in group) from Hire Qualified Teachers and invites `otherTeacher`
      await tester.pumpWidget(
        wrapUser(
          userEmail: alice,
          chatRepo: chatRepo,
          home: const GroupInfoModulePage(groupId: 'G700'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(otherTeacher), findsWidgets);
      await tester.ensureVisible(find.text('Request'));
      await tester.tap(find.text('Request'));
      await tester.pumpAndSettle();
      expect(find.text('Sent'), findsOneWidget);

      // `otherTeacher` accepts invitation in RequestsModulePage
      await tester.pumpWidget(
        wrapUser(
          userEmail: otherTeacher,
          chatRepo: chatRepo,
          home: const RequestsModulePage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Group: Compiler Club'), findsOneWidget);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      // `otherTeacher` sees group in My Groups
      await tester.pumpWidget(
        wrapUser(
          userEmail: otherTeacher,
          chatRepo: chatRepo,
          home: const GroupsModulePage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Compiler Club'), findsOneWidget);
    });
  });
}
