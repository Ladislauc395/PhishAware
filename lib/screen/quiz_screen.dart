import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import 'api_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedOptionId;
  bool _answered = false;
  bool _isCorrect = false;
  String _explanation = '';
  String _correctOptionId = '';
  bool _loading = true;
  String? _error;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _loadQuestions();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await ApiService.getQuestions();
      setState(() {
        _questions = data
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
      _slideCtrl.forward();
      _progressCtrl.animateTo(1 / _questions.length);
    } catch (e) {
      setState(() {
        _loading = false;
        _error =
            'Não foi possível carregar as perguntas.\nVerifica se o servidor está a correr.';
      });
    }
  }

  Future<void> _selectOption(String optionId) async {
    if (_answered) return;
    setState(() {
      _selectedOptionId = optionId;
    });

    final result =
        await ApiService.submitAnswer(_questions[_currentIndex].id, optionId);
    await ApiService.addXp(
      result['points'] ?? 0,
      result['correct'] ?? false,
      _questions[_currentIndex].category,
    );

    setState(() {
      _answered = true;
      _isCorrect = result['correct'] ?? false;
      _explanation = result['explanation'] ?? '';
      _correctOptionId = result['correct_option_id'] ?? '';
      if (_isCorrect) _score += (result['points'] ?? 0) as int;
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedOptionId = null;
        _explanation = '';
        _correctOptionId = '';
      });
      _slideCtrl.forward(from: 0);
      _progressCtrl.animateTo((_currentIndex + 1) / _questions.length);
    } else {
      Navigator.pushReplacementNamed(context, Routes.result, arguments: {
        'score': _score,
        'total': _questions.length,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _LoadingView();
    if (_error != null)
      return _ErrorView(message: _error!, onRetry: _loadQuestions);
    if (_questions.isEmpty)
      return _ErrorView(
          message: 'Nenhuma pergunta disponível.', onRetry: _loadQuestions);

    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _QuizHeader(
              currentIndex: _currentIndex,
              total: _questions.length,
              score: _score,
              progressCtrl: _progressCtrl,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SlideTransition(
                position: _slideAnim,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _QuestionCard(question: q),
                    const SizedBox(height: 20),
                    ...q.options.map((opt) => _OptionTile(
                          option: opt,
                          isSelected: _selectedOptionId == opt.id,
                          isAnswered: _answered,
                          isCorrect: _correctOptionId == opt.id,
                          onTap: () => _selectOption(opt.id),
                        )),
                    if (_answered) ...[
                      const SizedBox(height: 16),
                      _ExplanationCard(
                          isCorrect: _isCorrect, explanation: _explanation),
                      const SizedBox(height: 16),
                      _NextBtn(
                        isLast: _currentIndex == _questions.length - 1,
                        onTap: _next,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizHeader extends StatelessWidget {
  final int currentIndex;
  final int total;
  final int score;
  final AnimationController progressCtrl;
  final VoidCallback onBack;

  const _QuizHeader({
    required this.currentIndex,
    required this.total,
    required this.score,
    required this.progressCtrl,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white, size: 28),
                  onPressed: onBack),
              Expanded(
                child: AnimatedBuilder(
                  animation: progressCtrl,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressCtrl.value,
                      minHeight: 6,
                      backgroundColor: AppColors.surface2,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${currentIndex + 1}/$total',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(15),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('$score XP',
                    style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QuizQuestion question;
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(question.categoryIcon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('${question.categoryLabel} · ${question.difficultyLabel}',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 12)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: question.difficultyColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('+${question.points} XP',
                    style: GoogleFonts.inter(
                        color: question.difficultyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(question.scenario,
              style: GoogleFonts.inter(
                  color: AppColors.text, fontSize: 14, height: 1.7)),
          if (question.clue.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warn.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warn.withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(question.clue,
                          style: GoogleFonts.inter(
                              color: AppColors.warn, fontSize: 12))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final QuizOption option;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.onTap,
  });

  Color get _bg {
    if (!isAnswered) return AppColors.surface;
    if (isCorrect) return AppColors.accent.withAlpha(20);
    if (isSelected) return AppColors.danger.withAlpha(20);
    return AppColors.surface;
  }

  Color get _border {
    if (!isAnswered) return isSelected ? AppColors.accent : AppColors.border;
    if (isCorrect) return AppColors.accent;
    if (isSelected) return AppColors.danger;
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _border,
              width: isAnswered && (isCorrect || isSelected) ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(option.text,
                  style: GoogleFonts.inter(
                    color: isAnswered && (isCorrect || isSelected)
                        ? Colors.white
                        : AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )),
            ),
            if (isAnswered && isCorrect)
              const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
            if (isAnswered && isSelected && !isCorrect)
              const Icon(Icons.cancel, color: AppColors.danger, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  const _ExplanationCard({required this.isCorrect, required this.explanation});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.accent : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: color, width: 3),
          right: const BorderSide(color: AppColors.border),
          top: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? '✅ Correto!' : '❌ Incorreto',
            style: GoogleFonts.spaceGrotesk(
                color: color, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(explanation,
              style: GoogleFonts.inter(
                  color: AppColors.text, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}

class _NextBtn extends StatelessWidget {
  final bool isLast;
  final VoidCallback onTap;
  const _NextBtn({required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.accentAlt]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.accent.withAlpha(60),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Center(
          child: Text(
            isLast ? 'Ver Resultado →' : 'Próxima →',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined,
                  color: AppColors.textMuted, size: 64),
              const SizedBox(height: 16),
              Text(message,
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
