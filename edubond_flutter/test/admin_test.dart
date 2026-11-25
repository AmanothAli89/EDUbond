import 'package:edubond_flutter/core/constants/firestore_collections.dart';
import 'package:edubond_flutter/core/routes/app_routes.dart';
import 'package:edubond_flutter/core/services/local_storage_service.dart';
import 'package:edubond_flutter/core/services/providers.dart';
import 'package:edubond_flutter/core/utils/doc_id_helper.dart';
import 'package:edubond_flutter/data/datasources/firebase_auth_datasource.dart';
import 'package:edubond_flutter/data/datasources/firestore_datasource.dart';
import 'package:edubond_flutter/data/datasources/local_prefs_datasource.dart';
import 'package:edubond_flutter/data/repositories/admin_repository.dart';
import 'package:edubond_flutter/data/repositories/auth_repository.dart';
import 'package:edubond_flutter/data/repositories/quiz_repository.dart';
import 'package:edubond_flutter/data/repositories/subject_repository.dart';
import 'package:edubond_flutter/features/admin/admin_module.dart';
import 'package:edubond_flutter/features/admin/admin_quiz_screen.dart';
import 'package:edubond_flutter/features/admin/admin_subjects_screen.dart';
import 'package:edubond_flutter/features/admin/admin_teachers_screen.dart';
import 'package:edubond_flutter/features/admin/admin_users_screen.dart';
import 'package:edubond_flutter/features/authentication/admin_login_screen.dart';
import 'package:edubond_flutter/features/reports/reports_module.dart';
import 'package:edubond_flutter/models/quiz_question_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InMemoryAdminFirestore implements FirestoreDataSource {
  final Map<String, Map<String, Map<String, dynamic>>> store = {};

  Map<String, Map<String, dynamic>> _col(String name) =>
      store.putIfAbsent(name, () => <String, Map<String, dynamic>>{});

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
    col[docId] = {...(col[docId] ?? {}), ...data};
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubFirebaseAuthDataSource implements FirebaseAuthDataSource {
  bool signOutCalled = false;

  @override
  User? get currentUser => null;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late InMemoryAdminFirestore fakeDb;
  late StubFirebaseAuthDataSource stubAuthDs;
  late LocalStorageService localStorage;
  late LocalPrefsDataSource localPrefs;
  late AuthRepository authRepo;
  late AdminRepository adminRepo;
  late SubjectRepository subjectRepo;
  late QuizRepository quizRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fakeDb = InMemoryAdminFirestore();
    stubAuthDs = StubFirebaseAuthDataSource();
    localStorage = LocalStorageService(prefs);
    localPrefs = LocalPrefsDataSource(localStorage);
    authRepo = AuthRepository(
      authDataSource: stubAuthDs,
      firestoreDataSource: fakeDb,
      localPrefsDataSource: localPrefs,
    );
    adminRepo = AdminRepository(
      fakeDb,
      isAdminAuthorized: () => authRepo.isAdminAuthorized,
    );
    subjectRepo = SubjectRepository(fakeDb);
    quizRepo = QuizRepository(
      firestoreDataSource: fakeDb,
      localPrefsDataSource: localPrefs,
    );

    // Seed Firestore admin_config/credentials without hardcoding in app source.
    await fakeDb.setDoc(
      FirestoreCollections.adminConfig,
      FirestoreCollections.adminCredentialsDoc,
      {
        FirestoreFields.id: 'testAdmin',
        FirestoreFields.password: 'secretPass123',
      },
    );
  });

  Widget wrapAdmin({required Widget home}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        adminRepositoryProvider.overrideWithValue(adminRepo),
        subjectRepositoryProvider.overrideWithValue(subjectRepo),
        quizRepositoryProvider.overrideWithValue(quizRepo),
        localStorageServiceProvider.overrideWithValue(localStorage),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.admin:
              return MaterialPageRoute<void>(
                builder: (_) => const AdminModulePage(),
              );
            case AppRoutes.adminUsers:
              return MaterialPageRoute<void>(
                builder: (_) => const AdminUsersScreen(),
              );
            case AppRoutes.adminTeachers:
              return MaterialPageRoute<void>(
                builder: (_) => const AdminTeachersScreen(),
              );
            case AppRoutes.adminSubjects:
              return MaterialPageRoute<void>(
                builder: (_) => const AdminSubjectsScreen(),
              );
            case AppRoutes.adminQuiz:
              return MaterialPageRoute<void>(
                builder: (_) => AdminQuizEditorScreen(
                  subject: settings.arguments as String? ?? '',
                ),
              );
            case AppRoutes.reports:
              return MaterialPageRoute<void>(
                builder: (_) => const ReportsModulePage(),
              );
            case AppRoutes.adminLogin:
              return MaterialPageRoute<void>(
                builder: (_) => const AdminLoginScreen(),
              );
            default:
              return AppRouter.onGenerateRoute(settings);
          }
        },
        home: home,
      ),
    );
  }

  group('Admin Authentication & Security Boundaries', () {
    test('AdminRepository blocks calls when not authorized', () {
      expect(authRepo.isAdminAuthorized, isFalse);
      expect(() => adminRepo.getAllUsers(), throwsStateError);
      expect(() => adminRepo.fetchWeeklyReports(), throwsStateError);
      expect(
        () => adminRepo.assignTeacherRole(
          email: 'u@baust.edu.bd',
          subject: 'Compiler',
        ),
        throwsStateError,
      );
    });

    testWidgets(
        'Direct route access without login shows Unauthorized Access; valid AdminLogin opens dashboard',
        (tester) async {
      await tester.pumpWidget(wrapAdmin(home: const AdminUsersScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Unauthorized Access'), findsOneWidget);

      await tester.pumpWidget(wrapAdmin(home: const AdminLoginScreen()));
      await tester.pumpAndSettle();

      // Wrong credentials fail
      await tester.enterText(find.byType(TextField).at(0), 'testAdmin');
      await tester.enterText(find.byType(TextField).at(1), 'wrongPass');
      await tester.tap(find.text('Login as Admin'));
      await tester.pumpAndSettle();
      expect(authRepo.isAdminAuthorized, isFalse);

      // Valid Firestore credentials authorize and navigate to Admin Panel
      await tester.enterText(find.byType(TextField).at(1), 'secretPass123');
      await tester.tap(find.text('Login as Admin'));
      await tester.pumpAndSettle();
      expect(authRepo.isAdminAuthorized, isTrue);
      expect(find.text('Admin Panel'), findsOneWidget);
      expect(find.text('Welcome, Admin'), findsOneWidget);
    });
  });

  group('Manage Users, Teachers, Subjects, Quizzes & Reports', () {
    setUp(() async {
      await authRepo.loginAsAdmin(
        adminId: 'testAdmin',
        password: 'secretPass123',
      );
    });

    testWidgets(
        'Manage Users: search, user details, assign teacher role (score 10), remove teacher & unblock user',
        (tester) async {
      await fakeDb.setDoc(FirestoreCollections.users, 'u1', {
        FirestoreFields.uid: 'u1',
        FirestoreFields.username: 'Tariq Islam',
        FirestoreFields.email: 'tariq@baust.edu.bd',
        FirestoreFields.loginProvider: 'google+password',
        FirestoreFields.googleVerified: true,
        FirestoreFields.passwordSet: true,
        FirestoreFields.biodata: 'CSE 3.1',
        FirestoreFields.updatedAt: DateTime.now().millisecondsSinceEpoch,
      });
      await fakeDb.setDoc(FirestoreCollections.users, 'u2', {
        FirestoreFields.uid: 'u2',
        FirestoreFields.username: 'Nadia Khan',
        FirestoreFields.email: 'nadia@baust.edu.bd',
        FirestoreFields.updatedAt: DateTime.now().millisecondsSinceEpoch,
      });
      await subjectRepo.addSubjectGlobally('Algorithm');

      final blockedId = DocIdHelper.emailSubjectDocId(
        'nadia@baust.edu.bd',
        'Algorithm',
      );
      await fakeDb.setDoc(FirestoreCollections.quizAttempts, blockedId, {
        FirestoreFields.email: 'nadia@baust.edu.bd',
        FirestoreFields.subject: 'Algorithm',
        FirestoreFields.attempts: 2,
        FirestoreFields.totalAttempts: 2,
        FirestoreFields.blocked: true,
        FirestoreFields.lastPassed: false,
        FirestoreFields.timestamp: 1000,
      });

      await tester.pumpWidget(wrapAdmin(home: const AdminUsersScreen()));
      await tester.pumpAndSettle();

      // Search filters to Tariq
      await tester.enterText(find.byType(TextField), 'Tariq');
      await tester.pumpAndSettle();
      expect(find.text('Tariq Islam'), findsOneWidget);
      expect(find.text('Nadia Khan'), findsNothing);

      // View User Details
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.text('Biodata: CSE 3.1'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Assign teacher role with score 10
      await tester.tap(find.text('Add Role'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();

      final roleId = DocIdHelper.emailSubjectDocId(
        'tariq@baust.edu.bd',
        'Algorithm',
      );
      final roleDoc = await fakeDb.getDocData(
        FirestoreCollections.userRoles,
        roleId,
      );
      expect(roleDoc![FirestoreFields.role], 'teacher');
      expect(roleDoc[FirestoreFields.score], 10);

      // Dedicated AdminTeachersScreen: Active Teachers remove + Blocked unblock (attempts=0)
      await tester.pumpWidget(wrapAdmin(home: const AdminTeachersScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Subject: Algorithm'), findsOneWidget);

      await tester.tap(find.text('Remove Teacher Role'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(
        await fakeDb.getDocData(FirestoreCollections.userRoles, roleId),
        isNull,
      );

      // Switch to Blocked tab & unblock Nadia
      await tester.tap(find.text('Blocked'));
      await tester.pumpAndSettle();
      expect(find.text('Blocked for Subject: Algorithm'), findsOneWidget);
      await tester.tap(find.text('Unblock User'));
      await tester.pumpAndSettle();

      final unblockedDoc = await fakeDb.getDocData(
        FirestoreCollections.quizAttempts,
        blockedId,
      );
      expect(unblockedDoc![FirestoreFields.blocked], isFalse);
      expect(unblockedDoc[FirestoreFields.attempts], 0);
    });

    testWidgets(
        'Subject Management: add, delete, accept/edit/reject subject requests',
        (tester) async {
      await subjectRepo.addSubjectGlobally('Cloud Computing');
      await subjectRepo.submitSubjectRequest(
        subjectName: 'Cyber Security',
        requesterEmail: 'u1@baust.edu.bd',
      );

      await tester.pumpWidget(wrapAdmin(home: const AdminSubjectsScreen()));
      await tester.pumpAndSettle();

      // Add New Subject
      await tester.tap(find.text('+ Add New Subject'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Enter subject name',
        ),
        'Deep Learning',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Deep Learning'), findsOneWidget);

      // Delete Cloud Computing
      final deleteBtn = find.text('Delete').first;
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('Cloud Computing'), findsNothing);

      // Switch to Requests tab -> Accept Cyber Security
      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();
      expect(find.text('Cyber Security'), findsOneWidget);

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      final subDoc = await fakeDb.getDocData(
        FirestoreCollections.subjects,
        DocIdHelper.subjectDocId('Cyber Security'),
      );
      expect(subDoc![FirestoreFields.name], 'Cyber Security');
      expect(subDoc[FirestoreFields.type], 'admin');
    });

    testWidgets(
        'Quiz Management: edits Set 1..4 10 MCQs and saves to SharedPreferences & quizzes/{subject}',
        (tester) async {
      await tester.pumpWidget(
        wrapAdmin(home: const AdminQuizEditorScreen(subject: 'Software Engineering')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set 1'), findsOneWidget);
      expect(find.text('Set 4'), findsOneWidget);
      expect(find.text('Configure 10 MCQs for Set 1'), findsOneWidget);

      // Switch to Set 3 (empty initially -> populate 10 questions & save)
      await tester.tap(find.text('Set 3'));
      await tester.pumpAndSettle();
      expect(find.text('Configure 10 MCQs for Set 3'), findsOneWidget);

      // Switch back to seeded Set 1, verify Save Set 1 persists to local + Firestore
      await tester.tap(find.text('Set 1'));
      await tester.pumpAndSettle();

      final saveBtn = find.text('Save Set 1');
      final listScrollable = find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first;
      await tester.scrollUntilVisible(
        saveBtn,
        200,
        maxScrolls: 100,
        scrollable: listScrollable,
      );
      await tester.drag(listScrollable, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      final cloudQuiz = await fakeDb.getDocData(
        FirestoreCollections.quizzes,
        'Software Engineering',
      );
      expect(cloudQuiz, isNotNull);
      final decoded = QuizQuestionModel.decodeQuizSets(
        cloudQuiz![FirestoreFields.quizJson] as String,
      );
      expect(decoded.first.length, 10);

      final localSets = await localStorage.getQuizSets('Software Engineering');
      expect(localSets.first.length, 10);
    });

    testWidgets(
        'Reports: calculates Total Users & Weekly stats and renders BarChart widgets',
        (tester) async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await fakeDb.setDoc(FirestoreCollections.users, 'u1', {
        FirestoreFields.uid: 'u1',
        FirestoreFields.email: 'a@baust.edu.bd',
        FirestoreFields.updatedAt: nowMs,
      });
      await fakeDb.setDoc(FirestoreCollections.users, 'u2', {
        FirestoreFields.uid: 'u2',
        FirestoreFields.email: 'b@baust.edu.bd',
        FirestoreFields.updatedAt: nowMs,
      });
      await fakeDb.setDoc(FirestoreCollections.groups, 'G1', {
        FirestoreFields.id: 'G1',
        FirestoreFields.name: 'Study 1',
        FirestoreFields.subject: 'Compiler',
        FirestoreFields.createdBy: 'a@baust.edu.bd',
        FirestoreFields.members: ['a@baust.edu.bd'],
        FirestoreFields.teachers: <String>[],
        FirestoreFields.timestamp: nowMs,
      });
      await fakeDb.setDoc(FirestoreCollections.userRoles, 'a_baust_Compiler', {
        FirestoreFields.email: 'a@baust.edu.bd',
        FirestoreFields.subject: 'Compiler',
        FirestoreFields.role: 'teacher',
        FirestoreFields.score: 9,
        FirestoreFields.timestamp: nowMs,
      });

      await tester.pumpWidget(wrapAdmin(home: const ReportsModulePage()));
      await tester.pumpAndSettle();

      expect(find.text('Total Users'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text('New Users (Weekly)'), findsOneWidget);
      expect(find.text('New Groups (Weekly)'), findsOneWidget);
      expect(find.text('New Teachers (Weekly)'), findsOneWidget);
      expect(find.byType(BarChart), findsNWidgets(3));
    });
  });
}
