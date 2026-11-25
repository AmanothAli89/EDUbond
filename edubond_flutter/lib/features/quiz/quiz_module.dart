import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/providers.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/edu_button.dart';
import '../../core/widgets/edu_card.dart';
import '../../core/widgets/edu_header_and_tiles.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../models/quiz_question_model.dart';

enum _QuizStage { loading, rules, exam, result }

class QuizModulePage extends ConsumerStatefulWidget {
  const QuizModulePage({
    super.key,
    this.subject = '',
    this.initialDurationSeconds = AppConstants.quizDurationSeconds,
  });

  final String subject;
  final int initialDurationSeconds;

  @override
  ConsumerState<QuizModulePage> createState() => _QuizModulePageState();
}

class _QuizModulePageState extends ConsumerState<QuizModulePage>
    with WidgetsBindingObserver {
  _QuizStage _stage = _QuizStage.loading;
  List<QuizQuestionModel> _questions = [];
  List<String?> _selectedAnswers = [];
  Timer? _timer;
  late int _remainingSeconds;
  DateTime? _pausedAt;
  bool _submitting = false;
  bool _submitted = false;
  QuizSubmissionOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialDurationSeconds;
    WidgetsBinding.instance.addObserver(this);
    _prepareQuiz();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_stage != _QuizStage.exam || _submitted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
      _pausedAt = null;
      if (elapsed <= 0 || !mounted) return;
      final nextRemaining = _remainingSeconds - elapsed;
      if (nextRemaining <= 0) {
        _timer?.cancel();
        setState(() => _remainingSeconds = 0);
        showEduSnackBar(context, 'Time is up! Submitting automatically...');
        _submitQuiz(autoSubmit: true);
      } else {
        setState(() => _remainingSeconds = nextRemaining);
      }
    }
  }

  Future<void> _prepareQuiz() async {
    if (widget.subject.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final email = ref.read(authRepositoryProvider).activeUserEmail;
    final quizRepo = ref.read(quizRepositoryProvider);

    try {
      final status = await quizRepo.getQuizStatus(
        email: email,
        subject: widget.subject,
      );
      if (!mounted) return;

      if (status?.blocked == true) {
        showEduSnackBar(context, 'You are blocked from this subject.');
        Navigator.of(context).pop();
        return;
      }
      if ((status?.attempts ?? 0) >= AppConstants.quizMaxAttempts) {
        showEduSnackBar(context, 'No more attempts left.');
        Navigator.of(context).pop();
        return;
      }

      final sets = await quizRepo.getQuizSets(widget.subject);
      if (!mounted) return;

      final totalAttempts = status?.totalAttempts ?? 0;
      final hasFullSet = sets.any(
        (s) => s.length >= AppConstants.quizTotalQuestions,
      );
      if (sets.isEmpty || !hasFullSet) {
        showEduSnackBar(
          context,
          'Quiz questions are not set yet. Please contact admin.',
        );
        Navigator.of(context).pop();
        return;
      }

      final setIndex = QuizRepository.selectSetIndex(
        totalAttempts: totalAttempts,
        setCount: sets.length,
      );
      final selectedSet = sets[setIndex];
      if (selectedSet.length < AppConstants.quizTotalQuestions) {
        showEduSnackBar(
          context,
          'Selected question set is incomplete. Contact Admin.',
        );
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _questions = selectedSet;
        _selectedAnswers = List<String?>.filled(selectedSet.length, null);
        _stage = _QuizStage.rules;
      });
    } catch (e) {
      if (mounted) {
        showEduSnackBar(context, 'Failed to load quiz: $e');
        Navigator.of(context).pop();
      }
    }
  }

  void _startExam() {
    setState(() {
      _remainingSeconds = widget.initialDurationSeconds;
      _pausedAt = null;
      _submitting = false;
      _submitted = false;
      _stage = _QuizStage.exam;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        showEduSnackBar(context, 'Time is up! Submitting automatically...');
        _submitQuiz(autoSubmit: true);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _submitQuiz({bool autoSubmit = false}) async {
    if (_submitting || _submitted) return;
    if (!autoSubmit && _selectedAnswers.any((a) => a == null)) {
      showEduSnackBar(context, 'Please answer all questions before submitting');
      return;
    }

    _timer?.cancel();
    setState(() => _submitting = true);
    final email = ref.read(authRepositoryProvider).activeUserEmail;

    try {
      final outcome = await ref.read(quizRepositoryProvider).submitQuizAnswers(
            email: email,
            subject: widget.subject,
            questions: _questions,
            selectedAnswers: _selectedAnswers,
          );
      if (!mounted) return;
      setState(() {
        _outcome = outcome;
        _submitting = false;
        _submitted = true;
        _stage = _QuizStage.result;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        showEduSnackBar(context, 'Quiz submission failed: $e');
      }
    }
  }

  Future<void> _confirmLeaveExam() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Examination?'),
        content: const Text(
          'Your exam timer is running. Are you sure you want to leave without submitting?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (shouldLeave == true && mounted) {
      _timer?.cancel();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage != _QuizStage.exam,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stage == _QuizStage.exam) {
          _confirmLeaveExam();
        }
      },
      child: switch (_stage) {
        _QuizStage.loading => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        _QuizStage.rules => _buildRulesScreen(),
        _QuizStage.result when _outcome != null => _buildResultScreen(_outcome!),
        _ => _buildExamScreen(),
      },
    );
  }

  Widget _buildRulesScreen() {
    final rules = [
      '• Subject: ${widget.subject}',
      '• Time Limit: 5 Minutes',
      '• Minimum Score: 7 out of 10',
      '• Total Questions: 10',
      '• Max Attempts: 2',
      '• Quiz will auto-submit when time is up.',
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: EduCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Examination Rules',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...rules.map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        r,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  EduButton(
                    label: 'Start Exam',
                    backgroundColor: AppColors.emerald,
                    borderRadius: 12,
                    onPressed: _startExam,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamScreen() {
    final lowTime = _remainingSeconds < 60;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header with Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quiz: ${widget.subject}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: lowTime ? AppColors.timerBg : AppColors.softBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormatter.formatCountdown(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 17,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color:
                            lowTime ? AppColors.timerRed : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Questions List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                itemCount: _questions.length + 1,
                itemBuilder: (context, index) {
                  if (index == _questions.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: EduButton(
                        label: 'Submit Quiz',
                        backgroundColor: AppColors.primaryBlue,
                        borderRadius: 12,
                        isLoading: _submitting,
                        onPressed: () => _submitQuiz(autoSubmit: false),
                      ),
                    );
                  }

                  final q = _questions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: EduCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ${q.question}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Material(
                            type: MaterialType.transparency,
                            child: RadioGroup<String>(
                              groupValue: _selectedAnswers[index],
                              onChanged: (value) {
                                setState(() => _selectedAnswers[index] = value);
                              },
                              child: Column(
                                children: q.options
                                    .map(
                                      (opt) => RadioListTile<String>(
                                        value: opt,
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                        title: Text(
                                          opt,
                                          style: const TextStyle(
                                            color: AppColors.textSlate,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
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
    );
  }

  Widget _buildResultScreen(QuizSubmissionOutcome outcome) {
    final color = outcome.passed ? AppColors.emerald : AppColors.dangerRed;
    final remaining = (AppConstants.quizMaxAttempts - outcome.attempts).clamp(0, AppConstants.quizMaxAttempts);
    final title = outcome.passed
        ? 'Congratulations! You Passed!'
        : (outcome.blocked ? 'Subject Blocked' : 'Quiz Failed');
    final subtitle = outcome.passed
        ? 'You are now a verified teacher for ${widget.subject}.'
        : (outcome.blocked
            ? 'You have reached the maximum of 2 failed attempts for ${widget.subject}.'
            : 'Minimum passing score is 7/10. You have $remaining attempt left.');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EduCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    outcome.passed
                        ? Icons.verified_rounded
                        : Icons.cancel_rounded,
                    size: 64,
                    color: color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Score: ${outcome.score} / 10',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSlate,
                    ),
                  ),
                  const SizedBox(height: 24),
                  EduButton(
                    label: 'Done',
                    backgroundColor: AppColors.primaryBlue,
                    borderRadius: 12,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
