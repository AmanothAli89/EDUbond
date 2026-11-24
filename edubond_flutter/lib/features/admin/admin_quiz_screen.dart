import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/providers.dart';
import '../../core/widgets/edu_button.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../models/quiz_question_model.dart';

class AdminQuizEditorScreen extends ConsumerStatefulWidget {
  const AdminQuizEditorScreen({super.key, required this.subject});

  final String subject;

  @override
  ConsumerState<AdminQuizEditorScreen> createState() =>
      _AdminQuizEditorScreenState();
}

class _AdminQuizEditorScreenState extends ConsumerState<AdminQuizEditorScreen> {
  int _selectedSetIndex = 0;
  bool _loading = true;
  bool _saving = false;
  late List<List<QuizQuestionModel>> _allSets;
  late List<_QuestionControllers> _controllers;

  @override
  void initState() {
    super.initState();
    _allSets = List.generate(
      AppConstants.adminQuizSetCount,
      (_) => const <QuizQuestionModel>[],
    );
    _controllers = List.generate(
      AppConstants.quizTotalQuestions,
      (_) => _QuestionControllers(),
    );
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final sets =
          await ref.read(quizRepositoryProvider).getQuizSets(widget.subject);
      if (!mounted) return;
      final padded = List<List<QuizQuestionModel>>.from(sets);
      while (padded.length < AppConstants.adminQuizSetCount) {
        padded.add(const <QuizQuestionModel>[]);
      }
      setState(() {
        _allSets = padded;
        _loading = false;
      });
      _populateControllers();
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _populateControllers();
      }
    }
  }

  void _populateControllers() {
    final current = _allSets[_selectedSetIndex];
    for (var i = 0; i < AppConstants.quizTotalQuestions; i++) {
      final q = i < current.length ? current[i] : null;
      _controllers[i].setFrom(q);
    }
  }

  Future<void> _saveCurrentSet() async {
    final parsed = <QuizQuestionModel>[];
    for (final c in _controllers) {
      final q = c.toModelOrNull();
      if (q == null) {
        showEduSnackBar(context, 'Please fill all fields for 10 questions');
        return;
      }
      parsed.add(q);
    }

    _allSets[_selectedSetIndex] = parsed;
    setState(() => _saving = true);
    try {
      await ref.read(quizRepositoryProvider).saveQuizSetsToCloud(
            subject: widget.subject,
            sets: _allSets,
          );
      if (mounted) {
        showEduSnackBar(
          context,
          'Set ${_selectedSetIndex + 1} Saved to Cloud!',
        );
      }
    } catch (_) {
      if (mounted) {
        showEduSnackBar(
          context,
          'Saved locally, but failed to upload to cloud.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EduBackHeader(
                title: 'Quiz Sets: ${widget.subject}',
                fontSize: 20,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(AppConstants.adminQuizSetCount, (i) {
                    final active = _selectedSetIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedSetIndex = i);
                          _populateControllers();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: active
                                ? null
                                : Border.all(color: AppColors.borderSlate),
                          ),
                          child: Text(
                            'Set ${i + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  active ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: AppConstants.quizTotalQuestions + 2,
                        itemBuilder: (context, idx) {
                          if (idx == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Configure 10 MCQs for Set ${_selectedSetIndex + 1}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            );
                          }
                          if (idx == AppConstants.quizTotalQuestions + 1) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 20),
                              child: EduButton(
                                label: 'Save Set ${_selectedSetIndex + 1}',
                                backgroundColor: AppColors.emeraldBright,
                                borderRadius: 12,
                                isLoading: _saving,
                                onPressed: _saveCurrentSet,
                              ),
                            );
                          }

                          final qIndex = idx - 1;
                          final c = _controllers[qIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: EduCard(
                              padding: const EdgeInsets.all(16),
                              borderRadius: 16,
                              borderColor: AppColors.borderLight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Question ${qIndex + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _field(c.q, 'Question Text'),
                                  _field(c.o1, 'Option 1'),
                                  _field(c.o2, 'Option 2'),
                                  _field(c.o3, 'Option 3'),
                                  _field(c.o4, 'Option 4'),
                                  _field(
                                    c.ans,
                                    'Correct Answer (must match one option)',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

class _QuestionControllers {
  final q = TextEditingController();
  final o1 = TextEditingController();
  final o2 = TextEditingController();
  final o3 = TextEditingController();
  final o4 = TextEditingController();
  final ans = TextEditingController();

  void setFrom(QuizQuestionModel? model) {
    q.text = model?.question ?? '';
    o1.text = (model != null && model.options.isNotEmpty) ? model.options[0] : '';
    o2.text = (model != null && model.options.length > 1) ? model.options[1] : '';
    o3.text = (model != null && model.options.length > 2) ? model.options[2] : '';
    o4.text = (model != null && model.options.length > 3) ? model.options[3] : '';
    ans.text = model?.answer ?? '';
  }

  QuizQuestionModel? toModelOrNull() {
    final qText = q.text.trim();
    final op1 = o1.text.trim();
    final op2 = o2.text.trim();
    final op3 = o3.text.trim();
    final op4 = o4.text.trim();
    final answer = ans.text.trim();
    if (qText.isEmpty ||
        op1.isEmpty ||
        op2.isEmpty ||
        op3.isEmpty ||
        op4.isEmpty ||
        answer.isEmpty) {
      return null;
    }
    return QuizQuestionModel(
      question: qText,
      options: [op1, op2, op3, op4],
      answer: answer,
    );
  }

  void dispose() {
    q.dispose();
    o1.dispose();
    o2.dispose();
    o3.dispose();
    o4.dispose();
    ans.dispose();
  }
}
