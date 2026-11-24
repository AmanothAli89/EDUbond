import 'package:shared_preferences/shared_preferences.dart';
import '../../models/quiz_question_model.dart';
import '../constants/app_constants.dart';
import '../constants/quiz_seed_data.dart';

/// Wraps SharedPreferences mirroring `AppStorage.kt` keys and seeding fallback.
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  Future<void> setCurrentUser(String email) async {
    await _prefs.setString(AppConstants.currentUserPrefKey, email.trim());
  }

  String getCurrentUser() {
    return _prefs.getString(AppConstants.currentUserPrefKey) ?? '';
  }

  Future<void> logout() async {
    await _prefs.remove(AppConstants.currentUserPrefKey);
  }

  Future<List<List<QuizQuestionModel>>> getQuizSets(String subject) async {
    final key = '${AppConstants.quizSetsPrefPrefix}$subject';
    var data = _prefs.getString(key);

    if (data == null) {
      final defaults = QuizSeedData.getDefaultSetsForSubject(subject);
      if (defaults != null) {
        await saveQuizSets(subject, defaults);
        data = _prefs.getString(key);
      }
    }

    if (data == null || data.isEmpty) {
      return const <List<QuizQuestionModel>>[];
    }
    try {
      return QuizQuestionModel.decodeQuizSets(data);
    } catch (_) {
      return const <List<QuizQuestionModel>>[];
    }
  }

  Future<void> saveQuizSets(
    String subject,
    List<List<QuizQuestionModel>> sets,
  ) async {
    final key = '${AppConstants.quizSetsPrefPrefix}$subject';
    await _prefs.setString(key, QuizQuestionModel.encodeQuizSets(sets));
  }
}
