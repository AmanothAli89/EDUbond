import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edubond_flutter/core/constants/app_colors.dart';
import 'package:edubond_flutter/core/constants/app_constants.dart';
import 'package:edubond_flutter/core/constants/firestore_collections.dart';
import 'package:edubond_flutter/core/constants/quiz_seed_data.dart';
import 'package:edubond_flutter/core/routes/app_routes.dart';
import 'package:edubond_flutter/core/services/local_storage_service.dart';
import 'package:edubond_flutter/core/services/providers.dart';
import 'package:edubond_flutter/core/utils/doc_id_helper.dart';
import 'package:edubond_flutter/data/datasources/firestore_datasource.dart';
import 'package:edubond_flutter/data/datasources/local_prefs_datasource.dart';
import 'package:edubond_flutter/data/repositories/auth_repository.dart';
import 'package:edubond_flutter/data/repositories/group_repository.dart';
import 'package:edubond_flutter/data/repositories/quiz_repository.dart';
import 'package:edubond_flutter/data/repositories/subject_repository.dart';
import 'package:edubond_flutter/features/quiz/quiz_module.dart';
import 'package:edubond_flutter/features/subjects/subject_detail_screen.dart';
import 'package:edubond_flutter/features/subjects/subjects_module.dart';
import 'package:edubond_flutter/models/quiz_question_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeFirestoreDataSource implements FirestoreDataSource {
  final Map<String, Map<String, Map<String, dynamic>>> store = {};
  bool failQuizReads = false;
  int autoIdCounter = 1;

  Map<String, Map<String, dynamic>> _col(String name) =>
      store.putIfAbsent(name, () => <String, Map<String, dynamic>>{});

  @override
  FirebaseFirestore get raw => throw UnimplementedError('Not used in unit tests');

  @override
  Future<Map<String, dynamic>?> getDocData(
    String collection,
    String docId,
  ) async {
    if (failQuizReads && collection == FirestoreCollections.quizzes) {
      throw Exception('Simulated offline / network error');
    }
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
    final existing = col[docId] ?? <String, dynamic>{};
    col[docId] = {...existing, ...data};
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
    var items = _col(collection).entries.where((entry) {
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
  Future<void> logActivity(String email, String action) async {
    final id = 'log_${autoIdCounter++}';
    await setDoc(FirestoreCollections.activityLogs, id, {
      FirestoreFields.email: email,
      FirestoreFields.action: action,
      FirestoreFields.timestamp: DateTime.now().millisecondsSinceEpoch,
    });
  }

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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._email);

  final String _email;

  @override
  String get activeUserEmail => _email;

  @override
  String get currentLocalEmail => _email;

  @override
  User? get currentFirebaseUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFirestoreDataSource fakeDb;
  late LocalStorageService localStorage;
  late LocalPrefsDataSource localPrefs;
  late SubjectRepository subjectRepo;
  late QuizRepository quizRepo;
  late GroupRepository groupRepo;
  const testEmail = 'student.one@baust.edu.bd';

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppConstants.currentUserPrefKey: testEmail,
    });
    final prefs = await SharedPreferences.getInstance();
    fakeDb = FakeFirestoreDataSource();
    localStorage = LocalStorageService(prefs);
    localPrefs = LocalPrefsDataSource(localStorage);
    subjectRepo = SubjectRepository(fakeDb);
    quizRepo = QuizRepository(
      firestoreDataSource: fakeDb,
      localPrefsDataSource: localPrefs,
    );
    groupRepo = GroupRepository(fakeDb);
  });

  group('Subject Management & Local Cache (AppStorage)', () {
    test('seeds 16 core subjects when empty and preserves core + admin types',
        () async {
      final seeded = await subjectRepo.getGlobalSubjectItems();
      expect(seeded.length, AppConstants.coreSubjects.length);
      expect(seeded.every((s) => s.isCore), isTrue);

      await subjectRepo.addSubjectGlobally('Machine Learning');
      final withAdmin = await subjectRepo.getGlobalSubjectItems();
      final ml = withAdmin.firstWhere((s) => s.name == 'Machine Learning');
      expect(ml.isAdmin, isTrue);
      expect(withAdmin.length, AppConstants.coreSubjects.length + 1);
    });

    test('AppStorage SharedPreferences preserves current_user & quiz_sets_{subject}',
        () async {
      expect(localStorage.getCurrentUser(), testEmail);

      final mathSets = await localStorage.getQuizSets('গনিত ৯-১০');
      expect(mathSets.length, 4);
      expect(mathSets.first.length, 10);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('${AppConstants.quizSetsPrefPrefix}গনিত ৯-১০'),
        isNotNull,
      );

      await localStorage.logout();
      expect(localStorage.getCurrentUser(), isEmpty);
    });
  });

  group('Quiz Loading, Cloud Sync & Offline Fallback', () {
    test('cloud synchronization caches cloud quizJson into SharedPreferences',
        () async {
      final customQuestions = List.generate(
        10,
        (i) => QuizQuestionModel(
          question: 'Cloud Question ${i + 1}?',
          options: const ['A', 'B', 'C', 'D'],
          answer: 'A',
        ),
      );
      await fakeDb.setDoc(
        FirestoreCollections.quizzes,
        'Software Engineering',
        {
          FirestoreFields.subject: 'Software Engineering',
          FirestoreFields.quizJson:
              QuizQuestionModel.encodeQuizSets([customQuestions]),
        },
      );

      final loadedOnline = await quizRepo.getQuizSets('Software Engineering');
      expect(loadedOnline.length, 1);
      expect(loadedOnline.first.first.question, 'Cloud Question 1?');

      // Now go offline: synced cache in SharedPreferences must serve cloud data.
      fakeDb.failQuizReads = true;
      final loadedOfflineAfterSync =
          await quizRepo.getQuizSets('Software Engineering');
      expect(
        loadedOfflineAfterSync.first.first.question,
        'Cloud Question 1?',
      );
    });

    test('offline fallback returns seeded Bengali & English quiz banks when cloud is unavailable',
        () async {
      fakeDb.failQuizReads = true;
      final banglaSets = await quizRepo.getQuizSets('পদার্থবিজ্ঞান ৯-১০');
      expect(banglaSets.length, 4);
      expect(banglaSets.first.length, 10);
      expect(banglaSets.first.first.answer, 'ত্বরণ');
    });

    test('totalAttempts % sets.length rotates quiz sets cleanly', () {
      expect(QuizRepository.selectSetIndex(totalAttempts: 0, setCount: 4), 0);
      expect(QuizRepository.selectSetIndex(totalAttempts: 1, setCount: 4), 1);
      expect(QuizRepository.selectSetIndex(totalAttempts: 4, setCount: 4), 0);
      expect(QuizRepository.selectSetIndex(totalAttempts: 5, setCount: 4), 1);
    });
  });

  group('Quiz Scoring, Attempts, Pass/Fail & Blocking', () {
    const subject = 'Software Engineering';

    List<QuizQuestionModel> firstSet() =>
        QuizSeedData.getDefaultSetsForSubject(subject)!.first;

    List<String?> answersWithCorrectCount(
      List<QuizQuestionModel> qs,
      int correctCount,
    ) {
      return List.generate(qs.length, (i) {
        if (i < correctCount) return qs[i].answer;
        return qs[i].options.firstWhere((o) => o != qs[i].answer);
      });
    }

    test('correct vs incorrect answers & passing score threshold (7/10)',
        () async {
      final qs = firstSet();
      expect(
        QuizRepository.calculateScore(qs, answersWithCorrectCount(qs, 10)),
        10,
      );
      expect(
        QuizRepository.calculateScore(qs, answersWithCorrectCount(qs, 6)),
        6,
      );

      // Score 7/10 passes, grants teacher role, stores score, resets attempts to 0.
      final passOutcome = await quizRepo.submitQuizAnswers(
        email: testEmail,
        subject: subject,
        questions: qs,
        selectedAnswers: answersWithCorrectCount(qs, 7),
      );
      expect(passOutcome.score, 7);
      expect(passOutcome.passed, isTrue);
      expect(passOutcome.blocked, isFalse);
      expect(passOutcome.attempts, 0);
      expect(passOutcome.totalAttempts, 1);

      final attempt = await quizRepo.getQuizStatus(
        email: testEmail,
        subject: subject,
      );
      expect(attempt, isNotNull);
      expect(attempt!.attempts, 0);
      expect(attempt.totalAttempts, 1);
      expect(attempt.blocked, isFalse);
      expect(attempt.lastPassed, isTrue);

      final roles = await subjectRepo.getUserSubjectRoles(testEmail);
      expect(roles.length, 1);
      expect(roles.first.role, 'teacher');
      expect(roles.first.score, 7);
    });

    test('failed first attempt allows retry; failed second attempt blocks user',
        () async {
      final qs = firstSet();

      // First failure (6/10)
      final firstFail = await quizRepo.submitQuizAnswers(
        email: testEmail,
        subject: subject,
        questions: qs,
        selectedAnswers: answersWithCorrectCount(qs, 6),
      );
      expect(firstFail.score, 6);
      expect(firstFail.passed, isFalse);
      expect(firstFail.blocked, isFalse);
      expect(firstFail.attempts, 1);
      expect(firstFail.totalAttempts, 1);

      // Second failure (4/10) -> blocked = true
      final secondFail = await quizRepo.submitQuizAnswers(
        email: testEmail,
        subject: subject,
        questions: qs,
        selectedAnswers: answersWithCorrectCount(qs, 4),
      );
      expect(secondFail.score, 4);
      expect(secondFail.passed, isFalse);
      expect(secondFail.blocked, isTrue);
      expect(secondFail.attempts, 2);
      expect(secondFail.totalAttempts, 2);

      final status = await quizRepo.getQuizStatus(
        email: testEmail,
        subject: subject,
      );
      expect(status!.blocked, isTrue);
      expect(status.attempts, 2);

      // No teacher role granted.
      final roles = await subjectRepo.getUserSubjectRoles(testEmail);
      expect(roles, isEmpty);
    });

    test('passing on second attempt after first failure resets attempts to 0',
        () async {
      final qs = firstSet();
      await quizRepo.submitQuizAnswers(
        email: testEmail,
        subject: subject,
        questions: qs,
        selectedAnswers: answersWithCorrectCount(qs, 5),
      );

      final secondPass = await quizRepo.submitQuizAnswers(
        email: testEmail,
        subject: subject,
        questions: qs,
        selectedAnswers: answersWithCorrectCount(qs, 8),
      );
      expect(secondPass.passed, isTrue);
      expect(secondPass.blocked, isFalse);
      expect(secondPass.attempts, 0);
      expect(secondPass.totalAttempts, 2);
    });
  });

  group('Widget Integration Workflows', () {
    Widget wrapApp({required Widget home}) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(testEmail),
          ),
          localStorageServiceProvider.overrideWithValue(localStorage),
          subjectRepositoryProvider.overrideWithValue(subjectRepo),
          quizRepositoryProvider.overrideWithValue(quizRepo),
          groupRepositoryProvider.overrideWithValue(groupRepo),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.quiz) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => QuizModulePage(
                  subject: settings.arguments as String? ?? '',
                ),
              );
            }
            if (settings.name == AppRoutes.subjectDetail) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => SubjectDetailScreen(
                  subject: settings.arguments as String? ?? '',
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
        'Subjects screen filters core/admin subjects, collapses list, submits & displays request status',
        (tester) async {
      await subjectRepo.getGlobalSubjectItems();
      await subjectRepo.addSubjectGlobally('Quantum Computing');

      await tester.pumpWidget(wrapApp(home: const SubjectsModulePage()));
      await tester.pumpAndSettle();

      expect(find.text('SOFTWARE ENGINEERING'), findsOneWidget);
      expect(find.text('QUANTUM COMPUTING'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);

      // Filter in real time via TextField
      await tester.enterText(find.byType(TextField), 'Quantum');
      await tester.pumpAndSettle();
      expect(find.text('QUANTUM COMPUTING'), findsOneWidget);
      expect(find.text('SOFTWARE ENGINEERING'), findsNothing);

      // Submit subject request and verify status renders
      await tester.enterText(find.byType(TextField), 'Linear Algebra');
      await tester.pumpAndSettle();
      await tester.tap(find.text('REQUEST NEW SUBJECT ADD'));
      await tester.pumpAndSettle();

      expect(find.text('My Subject Requests:'), findsOneWidget);
      expect(find.text('Linear Algebra'), findsNWidgets(2));
      expect(find.text('PENDING'), findsOneWidget);

      // Collapse Subject List
      await tester.tap(find.text('Subject List:'));
      await tester.pumpAndSettle();
      expect(find.text('(Click to show)'), findsOneWidget);
    });

    testWidgets(
        'Learner registration saves user_roles, displays groups, creates group & sends join request',
        (tester) async {
      const subject = 'Computer Architecture';
      await groupRepo.createGroup(
        subject: subject,
        creatorEmail: 'peer@baust.edu.bd',
        groupName: 'Peer Study Hub',
      );

      await tester.pumpWidget(
        wrapApp(home: const SubjectDetailScreen(subject: subject)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('I want to study this'));
      await tester.pumpAndSettle();

      final roles = await subjectRepo.getUserSubjectRoles(testEmail);
      expect(roles.length, 1);
      expect(roles.first.role, 'learner');
      expect(roles.first.subject, subject);

      expect(find.text('Peer Study Hub'), findsOneWidget);
      expect(find.text('Request to Join'), findsOneWidget);

      // Request to join peer group
      await tester.tap(find.text('Request to Join'));
      await tester.pumpAndSettle();
      expect(find.text('Request Pending'), findsOneWidget);

      // Create new group as learner
      await tester.enterText(find.byType(TextField), 'CA Warriors');
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();
      expect(find.text('CA Warriors'), findsOneWidget);
      expect(find.text('Open Group'), findsOneWidget);
    });

    testWidgets(
        'Teacher selection blocks already-teacher and blocked users, allows eligible user',
        (tester) async {
      const subject = 'Compiler';

      // Blocked user cannot start quiz
      final attemptId = DocIdHelper.emailSubjectDocId(testEmail, subject);
      await fakeDb.setDoc(FirestoreCollections.quizAttempts, attemptId, {
        FirestoreFields.email: testEmail,
        FirestoreFields.subject: subject,
        FirestoreFields.attempts: 2,
        FirestoreFields.totalAttempts: 2,
        FirestoreFields.blocked: true,
        FirestoreFields.lastPassed: false,
        FirestoreFields.timestamp: 1000,
      });

      await tester.pumpWidget(
        wrapApp(home: const SubjectDetailScreen(subject: subject)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('I want to teach this'));
      await tester.pumpAndSettle();
      expect(find.text('Examination Rules'), findsNothing);
      expect(
        find.textContaining('blocked from teaching $subject'),
        findsOneWidget,
      );

      // Unblock user -> launches Quiz rules screen
      await fakeDb.setDoc(FirestoreCollections.quizAttempts, attemptId, {
        FirestoreFields.email: testEmail,
        FirestoreFields.subject: subject,
        FirestoreFields.attempts: 0,
        FirestoreFields.totalAttempts: 2,
        FirestoreFields.blocked: false,
        FirestoreFields.lastPassed: false,
        FirestoreFields.timestamp: 2000,
      });
      await tester.tap(find.text('I want to teach this'));
      await tester.pumpAndSettle();
      expect(find.text('Examination Rules'), findsOneWidget);
    });

    testWidgets(
        'Quiz timer turns red under 60s and auto-submits once when time expires',
        (tester) async {
      const subject = 'Software Engineering';

      await tester.pumpWidget(
        wrapApp(
          home: const QuizModulePage(
            subject: subject,
            initialDurationSeconds: 61,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Examination Rules'), findsOneWidget);
      await tester.tap(find.text('Start Exam'));
      await tester.pump();

      // At 01:01 -> not red yet
      final initialTimer = tester.widget<Text>(find.text('01:01'));
      expect(initialTimer.style?.color, AppColors.textPrimary);

      // After 2 seconds -> 00:59 -> red warning color
      await tester.pump(const Duration(seconds: 2));
      final lowTimer = tester.widget<Text>(find.text('00:59'));
      expect(lowTimer.style?.color, AppColors.timerRed);

      // Advance remaining 59 seconds -> auto-submits once & shows Result screen
      await tester.pump(const Duration(seconds: 59));
      await tester.pumpAndSettle();

      expect(find.text('Quiz Failed'), findsOneWidget);
      expect(find.text('Score: 0 / 10'), findsOneWidget);

      final attempt = await quizRepo.getQuizStatus(
        email: testEmail,
        subject: subject,
      );
      expect(attempt!.totalAttempts, 1);
      expect(attempt.attempts, 1);
    });

    testWidgets(
        'Quiz UI accepts 10 answers, submits once, passes with 10/10 and grants teacher role',
        (tester) async {
      const subject = 'Software Engineering';
      final qs = QuizSeedData.getDefaultSetsForSubject(subject)!.first;

      await tester.pumpWidget(
        wrapApp(home: const QuizModulePage(subject: subject)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Exam'));
      await tester.pump();

      // Verify 5-minute countdown starts at 05:00
      expect(find.text('05:00'), findsOneWidget);

      // Select correct answer for each of the 10 questions
      for (var i = 0; i < qs.length; i++) {
        final optionFinder = find.text(qs[i].answer);
        await tester.ensureVisible(optionFinder.first);
        await tester.tap(optionFinder.first);
        await tester.pump();
      }

      final submitBtn = find.text('Submit Quiz');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Congratulations! You Passed!'), findsOneWidget);
      expect(find.text('Score: 10 / 10'), findsOneWidget);

      final roles = await subjectRepo.getUserSubjectRoles(testEmail);
      expect(roles.length, 1);
      expect(roles.first.role, 'teacher');
      expect(roles.first.score, 10);
    });
  });
}
