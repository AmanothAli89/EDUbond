import '../../core/constants/app_constants.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/constants/quiz_seed_data.dart';
import '../../core/utils/doc_id_helper.dart';
import '../../models/quiz_attempt_model.dart';
import '../../models/quiz_question_model.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/local_prefs_datasource.dart';

class QuizSubmissionOutcome {
  const QuizSubmissionOutcome({
    required this.score,
    required this.passed,
    required this.blocked,
  });

  final int score;
  final bool passed;
  final bool blocked;
}

class QuizRepository {
  QuizRepository({
    required FirestoreDataSource firestoreDataSource,
    required LocalPrefsDataSource localPrefsDataSource,
  })  : _firestore = firestoreDataSource,
        _local = localPrefsDataSource;

  final FirestoreDataSource _firestore;
  final LocalPrefsDataSource _local;

  /// Mirrors `FirebaseHistoryManager.seedDefaultQuizzesToCloud()`.
  Future<void> seedDefaultQuizzesToCloud() async {
    for (final subject in AppConstants.seededQuizSubjects) {
      final quizDoc = await _firestore.getDoc(FirestoreCollections.quizzes, subject);
      if (!quizDoc.exists) {
        final defaultSets = QuizSeedData.getDefaultSetsForSubject(subject);
        if (defaultSets != null) {
          await saveQuizSetsToCloud(
            subject: subject,
            sets: defaultSets,
          );
        }
      }

      final subId = DocIdHelper.subjectDocId(subject);
      final subDoc = await _firestore.getDoc(FirestoreCollections.subjects, subId);
      if (!subDoc.exists) {
        await _firestore.setDoc(
          FirestoreCollections.subjects,
          subId,
          {
            FirestoreFields.name: subject,
            FirestoreFields.type: 'core',
          },
        );
      }
    }
  }

  Future<List<List<QuizQuestionModel>>> getQuizSets(String subject) async {
    var localSets = await _local.getQuizSets(subject);
    try {
      final doc = await _firestore.getDoc(FirestoreCollections.quizzes, subject);
      final rawJson = doc.data()?[FirestoreFields.quizJson] as String?;
      if (rawJson != null && rawJson.isNotEmpty) {
        final cloudSets = QuizQuestionModel.decodeQuizSets(rawJson);
        if (cloudSets.isNotEmpty) {
          localSets = cloudSets;
        }
      }
    } catch (_) {
      // Fallback gracefully to local quiz cache.
    }
    return localSets;
  }

  Future<void> saveQuizSetsToCloud({
    required String subject,
    required List<List<QuizQuestionModel>> sets,
  }) async {
    final jsonStr = QuizQuestionModel.encodeQuizSets(sets);
    await _local.saveQuizSets(subject, sets);
    await _firestore.setDoc(
      FirestoreCollections.quizzes,
      subject,
      {
        FirestoreFields.subject: subject,
        FirestoreFields.quizJson: jsonStr,
        FirestoreFields.lastUpdated: DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<QuizAttemptModel?> getQuizStatus({
    required String email,
    required String subject,
  }) async {
    final docId = DocIdHelper.emailSubjectDocId(email, subject);
    final doc = await _firestore.getDoc(FirestoreCollections.quizAttempts, docId);
    final data = doc.data();
    if (data == null) return null;
    return QuizAttemptModel.fromMap(data);
  }

  /// Mirrors `recordQuizResult` and teacher role granting on >= 7/10 score.
  Future<QuizSubmissionOutcome> submitQuizAnswers({
    required String email,
    required String subject,
    required List<QuizQuestionModel> questions,
    required List<String?> selectedAnswers,
  }) async {
    var score = 0;
    for (var i = 0; i < questions.length; i++) {
      final selected = i < selectedAnswers.length ? selectedAnswers[i] : null;
      if (selected != null && selected == questions[i].answer) {
        score++;
      }
    }

    final passed = score >= AppConstants.quizPassingScore;
    final attemptId = DocIdHelper.emailSubjectDocId(email, subject);
    final doc = await _firestore.getDoc(FirestoreCollections.quizAttempts, attemptId);
    final data = doc.data();

    var attempts = ((data?[FirestoreFields.attempts] as num?)?.toInt() ?? 0) + 1;
    final totalAttempts =
        ((data?[FirestoreFields.totalAttempts] as num?)?.toInt() ?? 0) + 1;
    if (passed) {
      attempts = 0;
    }

    var blocked = (data?[FirestoreFields.blocked] as bool?) ?? false;
    if (!passed && attempts >= AppConstants.quizMaxAttempts) {
      blocked = true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedAttempt = QuizAttemptModel(
      email: email,
      subject: subject,
      attempts: attempts,
      totalAttempts: totalAttempts,
      blocked: blocked,
      lastPassed: passed,
      timestamp: now,
    );

    await _firestore.setDoc(
      FirestoreCollections.quizAttempts,
      attemptId,
      updatedAttempt.toMap(),
      merge: true,
    );

    if (passed) {
      await _firestore.setDoc(
        FirestoreCollections.userRoles,
        attemptId,
        {
          FirestoreFields.email: email,
          FirestoreFields.subject: subject,
          FirestoreFields.role: 'teacher',
          FirestoreFields.score: score,
          FirestoreFields.timestamp: now,
        },
      );
    }

    return QuizSubmissionOutcome(
      score: score,
      passed: passed,
      blocked: blocked,
    );
  }
}
