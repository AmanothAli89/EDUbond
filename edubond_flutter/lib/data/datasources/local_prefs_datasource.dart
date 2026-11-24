import '../../core/services/local_storage_service.dart';
import '../../models/quiz_question_model.dart';

class LocalPrefsDataSource {
  LocalPrefsDataSource(this._localStorage);

  final LocalStorageService _localStorage;

  Future<void> setCurrentUser(String email) =>
      _localStorage.setCurrentUser(email);

  String getCurrentUser() => _localStorage.getCurrentUser();

  Future<void> logout() => _localStorage.logout();

  Future<List<List<QuizQuestionModel>>> getQuizSets(String subject) =>
      _localStorage.getQuizSets(subject);

  Future<void> saveQuizSets(
    String subject,
    List<List<QuizQuestionModel>> sets,
  ) =>
      _localStorage.saveQuizSets(subject, sets);
}
