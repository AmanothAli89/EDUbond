import 'dart:convert';

class QuizQuestionModel {
  const QuizQuestionModel({
    required this.question,
    required this.options,
    required this.answer,
  });

  final String question;
  final List<String> options;
  final String answer;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const <dynamic>[];
    return QuizQuestionModel(
      question: (json['question'] as String?) ?? '',
      options: rawOptions.map((e) => e.toString()).toList(),
      answer: (json['answer'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'question': question,
      'options': options,
      'answer': answer,
    };
  }

  static List<List<QuizQuestionModel>> decodeQuizSets(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List<dynamic>) return const <List<QuizQuestionModel>>[];
    return decoded.map((setItem) {
      if (setItem is! List<dynamic>) return const <QuizQuestionModel>[];
      return setItem
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestionModel.fromJson)
          .toList();
    }).toList();
  }

  static String encodeQuizSets(List<List<QuizQuestionModel>> sets) {
    return jsonEncode(
      sets
          .map((set) => set.map((q) => q.toJson()).toList())
          .toList(),
    );
  }
}
