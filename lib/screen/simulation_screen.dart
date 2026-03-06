import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import 'api_service.dart';
import 'ai_lab_screen.dart';

class SoundManager {
  static bool _enabled = true;
  static void setEnabled(bool v) => _enabled = v;

  static Future<void> playCorrect() async {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
  }

  static Future<void> playWrong() async {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  static Future<void> playStart() async {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  static Future<void> playComplete() async {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.lightImpact();
  }

  static Future<void> playTick() async {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }
}

class SimulationsScreen extends StatelessWidget {
  final List<PhishSimulation> simulations;
  final ValueChanged<String> onStart;

  const SimulationsScreen({
    super.key,
    required this.simulations,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return const AiLabScreen();
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _BgPainter(progress: controller.value),
        );
      },
    );
  }
}

class _BgPainter extends CustomPainter {
  final double progress;
  _BgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF080C14), Color(0xFF0D1520), Color(0xFF080C14)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.047);
    const spacing = 30.0;
    final offsetX = (progress * spacing) % spacing;
    final offsetY = (progress * spacing * 0.7) % spacing;

    for (double x = -spacing + offsetX;
        x < size.width + spacing;
        x += spacing) {
      for (double y = -spacing + offsetY;
          y < size.height + spacing;
          y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }

    final scanY = size.height * ((progress * 1.3) % 1.0);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF00FF88).withValues(alpha: 0.078),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 40, size.width, 80));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 40, size.width, 80), scanPaint);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.progress != progress;
}

class _AiLabHeroCard extends StatelessWidget {
  const _AiLabHeroCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => const AiLabScreen(),
            transitionsBuilder: (_, a, __, child) => FadeTransition(
              opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A1F15), Color(0xFF091420)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFF00FF88).withValues(alpha: 0.392)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF00FF88).withValues(alpha: 0.118),
                blurRadius: 30,
                spreadRadius: -5)
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00FF88), Color(0xFF00C4F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.392),
                      blurRadius: 16,
                      spreadRadius: -4)
                ],
              ),
              child: const Center(
                  child: Text('🧠', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('AI Phishing Lab',
                        style: GoogleFonts.syne(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.157),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: const Color(0xFF00FF88)
                                .withValues(alpha: 0.392)),
                      ),
                      child: Text('NOVO',
                          style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFF00FF88),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      'Simulações geradas por IA em tempo real + Análise Forense',
                      style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.392),
                          fontSize: 11,
                          height: 1.3)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, children: [
                    _MiniTag('📧 Email'),
                    _MiniTag('💬 SMS'),
                    _MiniTag('🔗 URL'),
                    _MiniTag('🔬 Forense'),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: Color(0xFF00FF88), size: 16),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  const _MiniTag(this.label);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.039),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.078)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.392), fontSize: 9)),
      );
}

class _Header extends StatelessWidget {
  final int completed, total;
  const _Header({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520).withValues(alpha: 0.784),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.157)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withValues(alpha: 0.059),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.078),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color:
                            const Color(0xFF00FF88).withValues(alpha: 0.235)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Color(0xFF00FF88), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'MODO TREINO ACTIVO',
                          style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFF00FF88),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$completed/$total',
                  style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF00FF88),
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Simulações\nde Ataque',
              style: GoogleFonts.syne(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.1)),
          const SizedBox(height: 4),
          Text('Treina contra ataques reais documentados',
              style: GoogleFonts.jetBrainsMono(
                  color: Colors.white.withValues(alpha: 0.196), fontSize: 11)),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.039),
                    borderRadius: BorderRadius.circular(3)),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => FractionallySizedBox(
                  widthFactor: val,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF00FF88), Color(0xFF00BFFF)]),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF00FF88)
                                .withValues(alpha: 0.314),
                            blurRadius: 8)
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimCard extends StatefulWidget {
  final PhishSimulation sim;
  final int index;
  final VoidCallback onTap;
  const _SimCard({required this.sim, required this.index, required this.onTap});

  @override
  State<_SimCard> createState() => _SimCardState();
}

class _SimCardState extends State<_SimCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _hovered = false;

  static const _categoryData = {
    'email': (
      icon: '📧',
      label: 'PHISHING POR EMAIL',
      color: Color(0xFF00FF88),
      threat: 'Credenciais / Malware'
    ),
    'sms': (
      icon: '💬',
      label: 'SMISHING',
      color: Color(0xFFFF6B35),
      threat: 'Roubo de identidade'
    ),
    'url': (
      icon: '🔗',
      label: 'URL FALSO',
      color: Color(0xFF00BFFF),
      threat: 'Dados bancários'
    ),
    'app': (
      icon: '📱',
      label: 'APP / QR CODE',
      color: Color(0xFFB06EFF),
      threat: 'Acesso ao dispositivo'
    ),
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 100 + widget.index * 120), () {
      if (mounted) {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sim = widget.sim;
    final String category = sim.category;
    final data = _categoryData[category] ?? _categoryData['email']!;
    final color = sim.completed ? const Color(0xFF00FF88) : data.color;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _hovered
                    ? const Color(0xFF0D1520).withValues(alpha: 0.941)
                    : const Color(0xFF0D1520).withValues(alpha: 0.784),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sim.completed
                      ? color.withValues(alpha: 0.392)
                      : _hovered
                          ? color.withValues(alpha: 0.314)
                          : Colors.white.withValues(alpha: 0.059),
                  width: sim.completed ? 1.5 : 1,
                ),
                boxShadow: [
                  if (sim.completed || _hovered)
                    BoxShadow(
                        color: color.withValues(alpha: 0.078),
                        blurRadius: 20,
                        spreadRadius: -4),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.059),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.157))),
                          child: Center(
                              child: Text(data.icon,
                                  style: const TextStyle(fontSize: 22))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.label,
                                  style: GoogleFonts.jetBrainsMono(
                                      color: color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(sim.title,
                                  style: GoogleFonts.syne(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(sim.description,
                                  style: GoogleFonts.jetBrainsMono(
                                      color:
                                          Colors.white.withValues(alpha: 0.196),
                                      fontSize: 10),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        sim.completed
                            ? Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF00FF88)
                                        .withValues(alpha: 0.078),
                                    border: Border.all(
                                        color: const Color(0xFF00FF88)
                                            .withValues(alpha: 0.235))),
                                child: const Icon(Icons.check,
                                    color: Color(0xFF00FF88), size: 16),
                              )
                            : Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.02),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.059))),
                                child: const Icon(Icons.play_arrow,
                                    color: Colors.white, size: 16),
                              ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                            icon: '⚡',
                            label: sim.difficulty,
                            color: sim.difficultyColor),
                        _InfoChip(
                            icon: '🎯',
                            label: '${sim.xp} XP',
                            color: const Color(0xFFFFCC00)),
                        _InfoChip(icon: '⚠️', label: data.threat, color: color),
                        if (sim.progress > 0 && !sim.completed)
                          _InfoChip(
                              icon: '▶',
                              label: '${sim.progress}%',
                              color: const Color(0xFF00BFFF)),
                      ],
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
}

class _InfoChip extends StatelessWidget {
  final String icon, label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.039),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.118)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  style: GoogleFonts.jetBrainsMono(
                      color: color, fontSize: 9, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📡', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('SEM SINAL',
                style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF00FF88),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3)),
            const SizedBox(height: 8),
            Text('Sem ligação ao servidor',
                style: GoogleFonts.jetBrainsMono(
                    color: Colors.white.withValues(alpha: 0.157),
                    fontSize: 11)),
          ],
        ),
      );
}

class _AssistantFab extends StatefulWidget {
  @override
  State<_AssistantFab> createState() => _AssistantFabState();
}

class _AssistantFabState extends State<_AssistantFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 60 + _pulse.value * 10,
            height: 60 + _pulse.value * 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00FF88)
                  .withValues(alpha: (20 * (1 - _pulse.value)) / 255.0),
            ),
          ),
          child!,
        ],
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, Routes.assistant);
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF00FF88), Color(0xFF00BFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.314),
                  blurRadius: 20,
                  spreadRadius: -4),
            ],
          ),
          child: const Icon(Icons.smart_toy_outlined,
              color: Colors.black, size: 24),
        ),
      ),
    );
  }
}

class SimulationDetailScreen extends StatefulWidget {
  final PhishSimulation sim;
  const SimulationDetailScreen({super.key, required this.sim});

  @override
  State<SimulationDetailScreen> createState() => _SimulationDetailScreenState();
}

class _SimulationDetailScreenState extends State<SimulationDetailScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  bool _answered = false;
  bool? _correct;
  int _score = 0;
  int _streak = 0;
  int _maxStreak = 0;
  bool _showResult = false;
  int _selectedIndex = -1;

  static const _timerSeconds = 30;
  int _timeLeft = _timerSeconds;
  Timer? _countdownTimer;
  bool _timerExpired = false;

  Set<int> _highlightedWords = {};

  late AnimationController _typewriter;
  late AnimationController _shakeController;
  late AnimationController _successController;
  late AnimationController _timerPulse;
  String _displayedText = '';
  Timer? _typeTimer;

  late List<_SimStep> _steps;

  @override
  void initState() {
    super.initState();
    _typewriter =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _successController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _timerPulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);

    _steps = _buildSteps(widget.sim);
    _startTypewriter(_steps[0].content);
    _startTimer();
    SoundManager.playStart();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _countdownTimer?.cancel();
    _typewriter.dispose();
    _shakeController.dispose();
    _successController.dispose();
    _timerPulse.dispose();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _timeLeft = _timerSeconds;
    _timerExpired = false;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _timeLeft--);
      if (_timeLeft <= 5 && _timeLeft > 0) SoundManager.playTick();
      if (_timeLeft <= 0) {
        timer.cancel();
        if (!_answered) _onTimerExpired();
      }
    });
  }

  void _onTimerExpired() {
    setState(() {
      _timerExpired = true;
      _answered = true;
      _correct = false;
      _streak = 0;
    });
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
    SoundManager.playWrong();
    _safeAddXp(0, false, widget.sim.category, '${widget.sim.title}: TIMEOUT');
  }

  Future<void> _safeAddXp(
      int xp, bool correct, String? category, String scenario) async {
    try {
      await ApiService.addXp(xp, correct, category ?? 'email',
          scenario: scenario);
    } catch (e) {
      debugPrint('[SimDetail] addXp erro: \$e');
    }
  }

  Future<void> _safeUpdateProgress(
      String id, int progress, bool completed) async {
    try {
      await ApiService.updateSimulationProgress(id, progress, completed);
    } catch (e) {
      debugPrint('[SimDetail] updateProgress erro: \$e');
    }
  }

  List<_SimStep> _buildSteps(PhishSimulation sim) {
    final String category = sim.category;
    final variant = sim.id.hashCode % 3;
    switch (category) {
      case 'email':
        return variant == 0
            ? _emailSteps(sim)
            : variant == 1
                ? _emailSteps2(sim)
                : _emailSteps3(sim);
      case 'sms':
        return variant == 0 ? _smsSteps(sim) : _smsSteps2(sim);
      case 'url':
        return variant == 0 ? _urlSteps(sim) : _urlSteps2(sim);
      default:
        return variant == 0 ? _appSteps(sim) : _appSteps2(sim);
    }
  }

  List<_SimStep> _emailSteps(PhishSimulation sim) => [
        _SimStep(
          type: StepType.email,
          title: '📧 Email Recebido',
          subtitle: 'Analisa este email — toca nas partes suspeitas',
          content: '''De: seguranca@bankportugal-alerta.com
Para: tu@email.com
Assunto: ⚠️ URGENTE: A tua conta foi suspensa

Caro Cliente,

Detectámos actividade suspeita na tua conta. Por motivos de segurança, a tua conta foi TEMPORARIAMENTE SUSPENSA.

Para reactivar o acesso, clica no link abaixo e confirma os teus dados IMEDIATAMENTE:

👉 http://bankportugal-secure-login.xyz/reactivar

Este processo deve ser concluído nas próximas 2 HORAS ou a tua conta será ENCERRADA permanentemente.

Serviço de Segurança
Banco de Portugal''',
          suspiciousWords: [
            'bankportugal-alerta.com',
            'URGENTE',
            'IMEDIATAMENTE',
            '.xyz/reactivar',
            '2 HORAS',
            'ENCERRADA'
          ],
          question: 'Este email é legítimo ou phishing?',
          options: ['✅ É legítimo, vou clicar', '🚨 É phishing, não clico'],
          correctIndex: 1,
          explanation:
              'PHISHING DETECTADO! Pistas: domínio falso "bankportugal-alerta.com", urgência artificial, ameaças de encerramento, URL suspeito ".xyz". O Banco de Portugal nunca pede dados por email.',
          audioCorrect:
              '🎵 Excelente análise! Identificaste os sinais de phishing.',
          audioWrong: '⚠️ Atenção! Nunca cliques em links de emails suspeitos.',
        ),
        _SimStep(
          type: StepType.analysis,
          title: '🔍 Análise do URL',
          subtitle: 'Examina o link com atenção',
          content: 'http://bankportugal-secure-login.xyz/reactivar?token=a7f2k',
          suspiciousWords: ['.xyz', 'http://', 'bankportugal-secure-login'],
          question: 'O que é mais suspeito neste URL?',
          options: [
            'O protocolo http://',
            'O domínio .xyz e "bankportugal" junto',
            'O parâmetro token=',
            'Tudo parece normal'
          ],
          correctIndex: 1,
          explanation:
              'Correcto! ".xyz" é um domínio barato frequentemente usado em phishing. O banco verdadeiro seria "bancoportugal.pt". O http:// sem "s" também é suspeito.',
          audioCorrect:
              '🎵 Bem visto! Domínios falsos são uma técnica clássica.',
          audioWrong:
              '⚠️ O domínio .xyz combinado com nome de banco é sinal vermelho.',
        ),
        _SimStep(
          type: StepType.decision,
          title: '🎯 Decisão Final',
          subtitle: 'O que fazes agora?',
          content:
              'Recebeste este email. A tua conta aparentemente está suspensa. Tens 2 horas para agir.',
          suspiciousWords: [],
          question: 'Qual é a acção mais segura?',
          options: [
            'Clicar no link e verificar rapidamente',
            'Ignorar o email completamente',
            'Ir directamente ao site do banco pelo browser',
            'Reencaminhar para amigos para eles verem'
          ],
          correctIndex: 2,
          explanation:
              'Perfeito! Nunca cliques em links de emails. Vai sempre directamente ao site oficial digitando o endereço.',
          audioCorrect:
              '🎵 Atitude correcta! Acessa sempre os serviços directamente.',
          audioWrong:
              '⚠️ Nunca uses links de emails para aceder a contas bancárias.',
        ),
      ];

  List<_SimStep> _smsSteps(PhishSimulation sim) => [
        _SimStep(
          type: StepType.sms,
          title: '💬 SMS Recebido',
          subtitle: 'Mensagem no teu telemóvel',
          content:
              'CTT: O teu pacote #PT7823 está retido. Taxa aduaneira: 2.99€. Paga aqui: ctt-entrega.online/pagar ou o pacote será devolvido.',
          suspiciousWords: ['ctt-entrega.online', '2.99€', 'Paga aqui'],
          question: 'Esta mensagem é legítima?',
          options: ['✅ Parece real, vou pagar', '🚨 É smishing, não pago'],
          correctIndex: 1,
          explanation:
              'SMISHING! Os CTT nunca pedem pagamentos por SMS. O domínio "ctt-entrega.online" é falso. O site oficial é ctt.pt.',
          audioCorrect:
              '🎵 Bem detectado! SMS de cobrança são quase sempre fraude.',
          audioWrong: '⚠️ Nunca pages por SMS. Vai ao site oficial verificar.',
        ),
        _SimStep(
          type: StepType.analysis,
          title: '🔍 Inspecionar o Link',
          subtitle: 'Analisa o domínio',
          content:
              'ctt-entrega.online  vs  ctt.pt\n\n⚠️ O domínio à esquerda tem hífen e TLD .online — não é oficial.',
          suspiciousWords: ['ctt-entrega.online', '.online'],
          question: 'Qual é o domínio oficial dos CTT?',
          options: [
            'ctt-entrega.online',
            'ctt.pt',
            'ctt-portugal.com',
            'entrega-ctt.pt'
          ],
          correctIndex: 1,
          explanation:
              'Os CTT usam sempre "ctt.pt". Qualquer variação é falsa. Empresas legítimas têm domínios simples e reconhecíveis.',
          audioCorrect:
              '🎵 Correcto! Domínios oficiais são sempre simples e directos.',
          audioWrong: '⚠️ Verifica sempre o domínio antes de clicar.',
        ),
      ];

  List<_SimStep> _urlSteps(PhishSimulation sim) => [
        _SimStep(
          type: StepType.browser,
          title: '🌐 Página Suspeita',
          subtitle: 'Examina esta URL com atenção',
          content:
              'https://paypa1.com/signin\n\n🔎 Dica: Compara cada carácter com "paypal.com".\nO número "1" e a letra "l" são visualmente semelhantes.',
          suspiciousWords: ['paypa1', '1'],
          question: 'O que está errado nesta URL?',
          options: [
            'Nada, parece o PayPal',
            'O "1" em vez de "l" em paypa1',
            'O https://',
            'O /signin'
          ],
          correctIndex: 1,
          explanation:
              'Typosquatting! "paypa1.com" usa o número "1" em vez da letra "l". O site real é paypal.com.',
          audioCorrect:
              '🎵 Excelente! Atenção aos caracteres substituídos nos URLs.',
          audioWrong:
              '⚠️ "paypa1" com número 1 é diferente de "paypal" com letra l.',
        ),
        _SimStep(
          type: StepType.decision,
          title: '🔐 Certificado SSL',
          subtitle: 'O https:// garante segurança?',
          content:
              'O site paypa1.com tem cadeado verde 🔒 e https://.\nMuitos pensam que isso significa que o site é legítimo.',
          suspiciousWords: ['paypa1.com'],
          question: 'O https:// significa que o site é legítimo?',
          options: [
            'Sim, https:// garante que é seguro',
            'Não, apenas encripta a ligação',
            'Só sites do governo têm https://',
            'Sim, o cadeado prova autenticidade'
          ],
          correctIndex: 1,
          explanation:
              'MITO COMUM! https:// apenas encripta a comunicação. Sites falsos também podem ter certificado SSL.',
          audioCorrect:
              '🎵 Correcto! https:// não garante que o site seja legítimo.',
          audioWrong:
              '⚠️ Sites falsos também têm https://. Verifica sempre o domínio!',
        ),
      ];

  List<_SimStep> _appSteps(PhishSimulation sim) => [
        _SimStep(
          type: StepType.qr,
          title: '📱 QR Code Suspeito',
          subtitle: 'Encontraste este QR em local público',
          content:
              'QR Code colado sobre o menu de um restaurante.\n\nURL detectado:\nhttp://menu-restaurante-lisboa.xyz/cardapio\n\n⚠️ Toca nos elementos suspeitos antes de decidir.',
          suspiciousWords: ['.xyz', 'http://', 'menu-restaurante-lisboa'],
          question: 'O que fazes com este QR Code?',
          options: [
            'Acedo normalmente, parece o menu',
            'Verifico o URL antes de abrir qualquer página',
            'Introduzo os meus dados para ver o menu',
            'Partilho com amigos para verem'
          ],
          correctIndex: 1,
          explanation:
              'QR Jacking! QR codes falsos são colados sobre os originais em locais públicos. Verifica sempre o URL.',
          audioCorrect:
              '🎵 Prudente! Verifica sempre URLs de QR codes desconhecidos.',
          audioWrong:
              '⚠️ QR codes em locais públicos podem ser substituídos por falsos.',
        ),
      ];

  List<_SimStep> _emailSteps2(PhishSimulation sim) => [
        _SimStep(
          type: StepType.email,
          title: '📧 Email Corporativo Falso',
          subtitle: 'Email no teu trabalho',
          content: '''De: ti-suporte@empresa-helpdesk.net
Para: colaborador@empresa.pt
Assunto: 🔧 Actualização obrigatória da senha – Acção imediata

Prezado colaborador,

O nosso sistema detectou que a tua senha expirou há 3 dias. Para evitar o bloqueio da conta, actualiza a senha clicando abaixo:

👉 https://empresa-helpdesk.net/reset-password?id=EMP7823

Se não actualizares nas próximas 24H, o acesso será bloqueado.

Departamento de TI''',
          suspiciousWords: ['empresa-helpdesk.net', '24H', 'bloqueado'],
          question: 'Deves clicar no link para actualizar a senha?',
          options: [
            '✅ Sim, o IT enviou o email',
            '🚨 Não, contacto o IT directamente'
          ],
          correctIndex: 1,
          explanation:
              'BEC (Business Email Compromise)! O domínio "empresa-helpdesk.net" não é o domínio da empresa. O IT nunca pede reset de senha por email com link externo.',
          audioCorrect:
              '🎵 Correcto! Sempre verifica com o IT por canal oficial.',
          audioWrong:
              '⚠️ Nunca cliques em links de reset de senha sem confirmar com o IT.',
        ),
        _SimStep(
          type: StepType.analysis,
          title: '🔍 Cabeçalho do Email',
          subtitle: 'Analisa os metadados',
          content:
              'De: ti-suporte@empresa-helpdesk.net\nReply-To: scammer2024@protonmail.com\nServidor: mail.digitalocean.xyz',
          suspiciousWords: [
            'empresa-helpdesk.net',
            'scammer2024',
            'protonmail.com',
            'digitalocean.xyz'
          ],
          question: 'Qual pista revela que este email é falso?',
          options: [
            'O Reply-To diferente do remetente',
            'O servidor DigitalOcean',
            'O endereço Protonmail',
            'Todas as opções acima'
          ],
          correctIndex: 3,
          explanation:
              'Correcto! Um Reply-To diferente, servidor desconhecido e email anónimo são todos red flags.',
          audioCorrect: '🎵 Análise completa! Identificaste todos os sinais.',
          audioWrong: '⚠️ Cada um destes elementos é suspeito individualmente.',
        ),
        _SimStep(
          type: StepType.decision,
          title: '🎯 Protocolo de Resposta',
          subtitle: 'Qual é o procedimento correcto?',
          content:
              'Recebeste este email suspeito no trabalho. O que deves fazer?',
          suspiciousWords: [],
          question: 'Qual é a melhor acção?',
          options: [
            'Apagar o email e ignorar',
            'Reportar ao departamento de segurança',
            'Abrir o link em modo privado para verificar',
            'Perguntar a um colega se recebeu o mesmo'
          ],
          correctIndex: 1,
          explanation:
              'Reportar é crucial! O departamento de segurança pode alertar outros colaboradores e investigar.',
          audioCorrect:
              '🎵 Perfeito! Reportar phishing ajuda a proteger toda a empresa.',
          audioWrong:
              '⚠️ Reportar ao departamento de IT é sempre a melhor opção.',
        ),
      ];

  List<_SimStep> _emailSteps3(PhishSimulation sim) => [
        _SimStep(
          type: StepType.email,
          title: '📧 Falso Prémio / Sorteio',
          subtitle: 'Email sobre uma suposta vitória',
          content: '''De: premios@mbway-oficial-sorteio.com
Para: tu@email.com
Assunto: 🏆 PARABÉNS! Ganhaste 500€ no sorteio MB WAY!

Olá,

Foste seleccionado aleatoriamente para receber 500€ da promoção MB WAY Verão 2024!

Para receber o teu prémio, segue estes passos:
1. Clica no link: http://mbway-premios.xyz/receber
2. Confirma o teu número MB WAY
3. Introduz o código de segurança recebido por SMS

O prémio expira em 48H!

MB WAY Premiações''',
          suspiciousWords: [
            'mbway-oficial-sorteio.com',
            '500€',
            '.xyz/receber',
            'código de segurança',
            '48H'
          ],
          question: 'Este email de prémio é legítimo?',
          options: [
            '✅ Sim, o MB WAY faz sorteios',
            '🚨 É uma fraude de engenharia social'
          ],
          correctIndex: 1,
          explanation:
              'Fraude clássica! O MB WAY nunca faz sorteios por email. Pedir o código SMS é tentar roubar acesso à tua conta.',
          audioCorrect:
              '🎵 Bem identificado! Ofertas não solicitadas são quase sempre fraude.',
          audioWrong:
              '⚠️ Nunca existe prémio real sem participação prévia num sorteio.',
        ),
        _SimStep(
          type: StepType.analysis,
          title: '🔍 A Armadilha do Código SMS',
          subtitle: 'Percebe a técnica de roubo',
          content:
              'O atacante pede o código SMS que recebes.\nEste código é o OTP (One-Time Password) da tua conta MB WAY.\n\n⚠️ Nunca partilhes este código com ninguém.',
          suspiciousWords: ['OTP', 'código SMS', 'One-Time Password'],
          question: 'Para que serve o código SMS neste contexto?',
          options: [
            'Para verificar a tua identidade',
            'Para o atacante aceder à tua conta',
            'Para confirmar o endereço de entrega',
            'Para activar o prémio'
          ],
          correctIndex: 1,
          explanation:
              'O código OTP é a chave da tua conta! O atacante iniciou login na tua conta real e precisa do código SMS.',
          audioCorrect: '🎵 Exacto! Nunca partilhes códigos SMS com ninguém.',
          audioWrong:
              '⚠️ Códigos SMS são senhas temporárias — nunca os partilhes.',
        ),
      ];

  List<_SimStep> _smsSteps2(PhishSimulation sim) => [
        _SimStep(
          type: StepType.sms,
          title: '💬 SMS Bancário Falso',
          subtitle: 'Mensagem urgente do banco',
          content:
              'CGDPT: Detectámos acesso nao autorizado. Bloqueamos o cartao. Clica para desbloquear: cgd-seguranca.online/desbloquear | Codigo: 4821',
          suspiciousWords: [
            'cgd-seguranca.online',
            'Codigo: 4821',
            'nao autorizado'
          ],
          question: 'O que está suspeito nesta mensagem?',
          options: [
            'O código 4821 no final',
            'O domínio cgd-seguranca.online e a urgência',
            'A palavra "bloqueamos"',
            'Nada, a CGD envia mensagens assim'
          ],
          correctIndex: 1,
          explanation:
              'Smishing bancário! A CGD usa "cgd.pt" não "cgd-seguranca.online". Bancos nunca incluem links de desbloqueio por SMS.',
          audioCorrect: '🎵 Correcto! Domínio falso + urgência = smishing.',
          audioWrong:
              '⚠️ Nenhum banco real envia links de desbloqueio por SMS.',
        ),
        _SimStep(
          type: StepType.decision,
          title: '🎯 Acção Imediata',
          subtitle: 'O teu cartão pode estar em risco',
          content:
              'Recebes este SMS. Ficas preocupado com o teu cartão. O que fazes?',
          suspiciousWords: [],
          question: 'Qual é a resposta mais segura?',
          options: [
            'Clico no link para verificar a situação',
            'Ligo para o número no verso do cartão',
            'Respondo ao SMS para saber mais',
            'Envio o código 4821 para verificar'
          ],
          correctIndex: 1,
          explanation:
              'Liga sempre para o número oficial no verso do cartão! Nunca cliques em links de SMS bancários.',
          audioCorrect:
              '🎵 Excelente! O verso do cartão tem o número oficial do banco.',
          audioWrong:
              '⚠️ O número no verso do cartão é o canal correcto para o banco.',
        ),
      ];

  List<_SimStep> _urlSteps2(PhishSimulation sim) => [
        _SimStep(
          type: StepType.browser,
          title: '🌐 Homograph Attack',
          subtitle: 'URL com caracteres internacionais',
          content:
              'https://аpple.com/account\n\n⚠️ Aviso: O "а" no início é o Cirílico А (U+0430), não o latino "a".\nVisualmente idêntico, mas domínio completamente diferente.',
          suspiciousWords: ['аpple', 'Cirílico'],
          question: 'Este URL é o site oficial da Apple?',
          options: [
            'Sim, tem https:// e parece correcto',
            'Não, usa caracteres Cirílicos invisíveis',
            'Só é suspeito se não tiver cadeado',
            'Sim, o domínio apple.com é oficial'
          ],
          correctIndex: 1,
          explanation:
              'Homograph Attack! Caracteres de outros alfabetos parecem idênticos ao olho humano mas são domínios completamente diferentes.',
          audioCorrect:
              '🎵 Impressionante! Homograph attacks são muito difíceis de detectar.',
          audioWrong:
              '⚠️ Caracteres visualmente idênticos de outros alfabetos são uma técnica avançada de phishing.',
        ),
        _SimStep(
          type: StepType.analysis,
          title: '🔍 URL Shortener',
          subtitle: 'Link encurtado suspeito',
          content:
              'Recebes: bit.ly/3xK9mPq\n\nNão consegues ver o destino real sem clicar.\n🔒 Usa ferramentas de expansão de links antes de abrir.',
          suspiciousWords: ['bit.ly/3xK9mPq'],
          question: 'Como verificas um link encurtado com segurança?',
          options: [
            'Clico directamente para ver',
            'Uso um serviço como checkshorturl.com para expandir',
            'Se o remetente é de confiança, clico',
            'Espero que o antivírus bloqueie se for mau'
          ],
          correctIndex: 1,
          explanation:
              'Links encurtados escondem o destino real. Usa ferramentas como checkshorturl.com ou unshorten.it antes de clicar.',
          audioCorrect:
              '🎵 Correcto! Sempre expande links encurtados antes de clicar.',
          audioWrong:
              '⚠️ Nunca cliques em links encurtados sem expandir primeiro.',
        ),
      ];

  List<_SimStep> _appSteps2(PhishSimulation sim) => [
        _SimStep(
          type: StepType.qr,
          title: '📱 App Store Falsa',
          subtitle: 'Aplicação suspeita na loja',
          content:
              'Vês um anúncio: "MB WAY PRO – Versão melhorada!"\n\nQR leva a:\nmbway-pro-download.xyz/app.apk\n\n⚠️ Ficheiros .apk fora da loja oficial são perigosos.',
          suspiciousWords: ['mbway-pro-download.xyz', '.apk', '.xyz'],
          question: 'O que está errado nesta situação?',
          options: [
            'Nada, as apps também existem fora das lojas',
            'O APK fora da loja oficial pode ser malware',
            'Só é suspeito se pedir dados bancários',
            'O QR code garante que é seguro'
          ],
          correctIndex: 1,
          explanation:
              'APK de fonte desconhecida! Apps legítimas estão na Google Play ou App Store. Instalar APKs externos pode instalar malware.',
          audioCorrect:
              '🎵 Correcto! Nunca instales APKs fora das lojas oficiais.',
          audioWrong:
              '⚠️ Aplicações de fontes externas são o principal vector de malware mobile.',
        ),
        _SimStep(
          type: StepType.decision,
          title: '🎯 Permissões Excessivas',
          subtitle: 'A app pede demasiado',
          content:
              'Instalas uma app de lanterna. Ela pede acesso a:\n• Contactos\n• SMS\n• Câmara\n• Microfone\n• Localização\n• Histórico de chamadas\n\n❓ Uma lanterna precisa de tudo isto?',
          suspiciousWords: [
            'Contactos',
            'SMS',
            'Microfone',
            'Localização',
            'Histórico de chamadas'
          ],
          question: 'O que deves fazer?',
          options: [
            'Aceitar tudo, as apps precisam de permissões',
            'Desinstalar — uma lanterna não precisa dessas permissões',
            'Aceitar só câmara e localização',
            'Perguntar ao amigo que recomendou'
          ],
          correctIndex: 1,
          explanation:
              'Malware disfarçado! Uma lanterna só precisa da câmara (flash). Permissões excessivas são sinal de app maliciosa.',
          audioCorrect:
              '🎵 Excelente! Permissões excessivas são sempre red flag.',
          audioWrong:
              '⚠️ Questiona sempre se as permissões fazem sentido para a função da app.',
        ),
      ];

  void _startTypewriter(String text) {
    _typeTimer?.cancel();
    _displayedText = '';
    int index = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (index < text.length) {
        if (mounted) {
          setState(() => _displayedText = text.substring(0, index + 1));
        }
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  void _answer(int selectedIndex) {
    if (_answered) return;
    _countdownTimer?.cancel();
    final step = _steps[_step];
    final isCorrect = selectedIndex == step.correctIndex;

    setState(() {
      _answered = true;
      _correct = isCorrect;
      _selectedIndex = selectedIndex;
      if (isCorrect) {
        _streak++;
        _score += 100 + (_streak > 1 ? (_streak - 1) * 10 : 0);
        if (_streak > _maxStreak) _maxStreak = _streak;
        _successController.forward(from: 0);
      } else {
        _streak = 0;
        _shakeController.forward(from: 0);
      }
    });

    if (isCorrect) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playWrong();
    }

    final scenario = '${widget.sim.title}: ${step.question}';
    _safeAddXp(isCorrect ? 100 : 0, isCorrect, widget.sim.category, scenario);
  }

  void _next() {
    if (_step < _steps.length - 1) {
      final progress = ((_step + 1) / _steps.length * 100).round();
      _safeUpdateProgress(widget.sim.id, progress, false);
      setState(() {
        _step++;
        _answered = false;
        _correct = null;
        _selectedIndex = -1;
        _timerExpired = false;
        _highlightedWords = {};
      });
      _successController.reset();
      _startTypewriter(_steps[_step].content);
      _startTimer();
    } else {
      _safeUpdateProgress(widget.sim.id, 100, true);
      SoundManager.playComplete();
      setState(() => _showResult = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return _ResultView(
          score: _score, total: _steps.length * 100, maxStreak: _maxStreak);
    }

    final step = _steps[_step];

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              current: _step + 1,
              total: _steps.length,
              score: _score,
              streak: _streak,
              timeLeft: _timeLeft,
              timerExpired: _timerExpired,
              timerPulse: _timerPulse,
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.title,
                        style: GoogleFonts.syne(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text(step.subtitle,
                        style: GoogleFonts.jetBrainsMono(
                            color: Colors.white.withValues(alpha: 0.196),
                            fontSize: 11)),
                    const SizedBox(height: 16),
                    _InteractiveContentCard(
                      step: step,
                      displayedText: _displayedText,
                      highlightedWords: _highlightedWords,
                      onWordTap: (word) {
                        setState(() => _highlightedWords.add(word.hashCode));
                        HapticFeedback.selectionClick();
                      },
                    ),
                    if (_highlightedWords.isNotEmpty && !_answered)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCC00)
                                .withValues(alpha: 0.059),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFFFCC00)
                                    .withValues(alpha: 0.157)),
                          ),
                          child: Row(children: [
                            const Text('🔍', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${_highlightedWords.length} elemento(s) suspeito(s) marcado(s)',
                                style: GoogleFonts.jetBrainsMono(
                                    color: const Color(0xFFFFCC00),
                                    fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1520),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.059)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('❓', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(step.question,
                                style: GoogleFonts.syne(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...step.options.asMap().entries.map((e) => _OptionButton(
                          label: e.value,
                          index: e.key,
                          answered: _answered,
                          isCorrect: e.key == step.correctIndex,
                          isSelected: e.key == _selectedIndex,
                          onTap: () => _answer(e.key),
                        )),
                    const SizedBox(height: 16),
                    if (_answered)
                      AnimatedBuilder(
                        animation:
                            _correct! ? _successController : _shakeController,
                        builder: (_, child) {
                          double dx = 0;
                          if (!_correct!) {
                            dx =
                                math.sin(_shakeController.value * math.pi * 6) *
                                    8;
                          }
                          return Transform.translate(
                              offset: Offset(dx, 0), child: child);
                        },
                        child: _FeedbackCard(
                          correct: _correct!,
                          timerExpired: _timerExpired,
                          step: step,
                          streak: _streak,
                          onNext: _next,
                          isLast: _step == _steps.length - 1,
                        ),
                      ),
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

class _TopBar extends StatelessWidget {
  final int current, total, score, streak, timeLeft;
  final bool timerExpired;
  final AnimationController timerPulse;
  final VoidCallback onClose;

  const _TopBar({
    required this.current,
    required this.total,
    required this.score,
    required this.streak,
    required this.timeLeft,
    required this.timerExpired,
    required this.timerPulse,
    required this.onClose,
  });

  Color get _timerColor {
    if (timerExpired || timeLeft <= 5) return const Color(0xFFFF4444);
    if (timeLeft <= 10) return const Color(0xFFFFCC00);
    return const Color(0xFF00FF88);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.039))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.039),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ETAPA $current/$total',
                        style: GoogleFonts.jetBrainsMono(
                            color: Colors.white.withValues(alpha: 0.235),
                            fontSize: 10,
                            letterSpacing: 1)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (streak >= 2) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35)
                                  .withValues(alpha: 0.118),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFFFF6B35)
                                      .withValues(alpha: 0.314)),
                            ),
                            child: Text('🔥 x$streak',
                                style: GoogleFonts.jetBrainsMono(
                                    color: const Color(0xFFFF6B35),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text('$score pts',
                            style: GoogleFonts.jetBrainsMono(
                                color: const Color(0xFF00FF88),
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: current / total,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.039),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00FF88)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: timerPulse,
            builder: (_, __) {
              final shouldPulse = timeLeft <= 10 && !timerExpired;
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _timerColor.withValues(
                      alpha: shouldPulse
                          ? (10 + timerPulse.value * 20) / 255.0
                          : 10 / 255.0),
                  border: Border.all(
                      color: _timerColor.withValues(
                          alpha: shouldPulse
                              ? (80 + timerPulse.value * 80) / 255.0
                              : 60 / 255.0),
                      width: 1.5),
                ),
                child: Center(
                  child: Text(
                    timerExpired ? '⏱' : '$timeLeft',
                    style: GoogleFonts.jetBrainsMono(
                        color: _timerColor,
                        fontSize: timerExpired ? 16 : 13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InteractiveContentCard extends StatelessWidget {
  final _SimStep step;
  final String displayedText;
  final Set<int> highlightedWords;
  final ValueChanged<String> onWordTap;

  const _InteractiveContentCard({
    required this.step,
    required this.displayedText,
    required this.highlightedWords,
    required this.onWordTap,
  });

  Color get _borderColor {
    switch (step.type) {
      case StepType.email:
        return const Color(0xFF00FF88);
      case StepType.sms:
        return const Color(0xFFFF6B35);
      case StepType.browser:
        return const Color(0xFF00BFFF);
      case StepType.qr:
        return const Color(0xFFB06EFF);
      case StepType.analysis:
        return const Color(0xFFFFCC00);
      default:
        return const Color(0xFF00FF88);
    }
  }

  String get _headerLabel {
    switch (step.type) {
      case StepType.email:
        return 'CAIXA DE ENTRADA';
      case StepType.sms:
        return 'MENSAGEM SMS';
      case StepType.browser:
        return 'NAVEGADOR WEB';
      case StepType.qr:
        return 'QR CODE DETECTADO';
      case StepType.analysis:
        return 'ANÁLISE FORENSE';
      default:
        return 'CENÁRIO';
    }
  }

  IconData get _headerIcon {
    switch (step.type) {
      case StepType.email:
        return Icons.email_outlined;
      case StepType.sms:
        return Icons.sms_outlined;
      case StepType.browser:
        return Icons.language_outlined;
      case StepType.qr:
        return Icons.qr_code_scanner_outlined;
      case StepType.analysis:
        return Icons.search_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _borderColor;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.235)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.059),
              blurRadius: 20,
              spreadRadius: -4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.059),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(
                  bottom: BorderSide(color: color.withValues(alpha: 0.157))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_headerIcon, color: color, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _headerLabel,
                        style: GoogleFonts.jetBrainsMono(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['red', 'yellow', 'green']
                          .map((c) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c == 'red'
                                      ? const Color(0xFFFF5F57)
                                      : c == 'yellow'
                                          ? const Color(0xFFFFBD2E)
                                          : const Color(0xFF28CA41),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
                if (step.suspiciousWords.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'toca nos elementos suspeitos',
                    style: GoogleFonts.jetBrainsMono(
                        color: color.withValues(alpha: 0.392),
                        fontSize: 9,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: step.suspiciousWords.isEmpty
                ? _buildTypewriterText(displayedText)
                : _buildInteractiveText(displayedText, color),
          ),
        ],
      ),
    );
  }

  Widget _buildTypewriterText(String text) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.jetBrainsMono(
            color: Colors.white.withValues(alpha: 0.784),
            fontSize: 12,
            height: 1.8),
        children: [
          TextSpan(text: text),
          WidgetSpan(child: _BlinkingCursor()),
        ],
      ),
    );
  }

  Widget _buildInteractiveText(String text, Color accentColor) {
    final spans = <InlineSpan>[];
    String remaining = text;

    while (remaining.isNotEmpty) {
      int earliestIndex = remaining.length;
      String? foundWord;

      for (final word in step.suspiciousWords) {
        final idx = remaining.indexOf(word);
        if (idx != -1 && idx < earliestIndex) {
          earliestIndex = idx;
          foundWord = word;
        }
      }

      if (foundWord == null) {
        spans.add(TextSpan(text: remaining));
        break;
      }

      if (earliestIndex > 0) {
        spans.add(TextSpan(text: remaining.substring(0, earliestIndex)));
      }

      final isHighlighted = highlightedWords.contains(foundWord.hashCode);
      spans.add(WidgetSpan(
        child: GestureDetector(
          onTap: () => onWordTap(foundWord!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? const Color(0xFFFFCC00).withValues(alpha: 0.157)
                  : accentColor.withValues(alpha: 0.039),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isHighlighted
                    ? const Color(0xFFFFCC00).withValues(alpha: 0.588)
                    : accentColor.withValues(alpha: 0.157),
              ),
            ),
            child: Text(
              foundWord,
              style: GoogleFonts.jetBrainsMono(
                color: isHighlighted ? const Color(0xFFFFCC00) : accentColor,
                fontSize: 12,
                height: 1.8,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ));

      remaining = remaining.substring(earliestIndex + foundWord.length);
    }

    spans.add(WidgetSpan(child: _BlinkingCursor()));

    return RichText(
      text: TextSpan(
        style: GoogleFonts.jetBrainsMono(
            color: Colors.white.withValues(alpha: 0.784),
            fontSize: 12,
            height: 1.8),
        children: spans,
      ),
    );
  }
}

class _OptionButton extends StatefulWidget {
  final String label;
  final int index;
  final bool answered, isCorrect, isSelected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.index,
    required this.answered,
    required this.isCorrect,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;

    if (!widget.answered) {
      bgColor = Colors.white.withValues(alpha: 0.059);
      borderColor = Colors.white.withValues(alpha: 0.078);
    } else if (widget.isCorrect) {
      bgColor = const Color(0xFF00FF88).withValues(alpha: 0.118);
      borderColor = const Color(0xFF00FF88).withValues(alpha: 0.392);
    } else if (widget.isSelected) {
      bgColor = const Color(0xFFFF4444).withValues(alpha: 0.078);
      borderColor = const Color(0xFFFF4444).withValues(alpha: 0.314);
    } else {
      bgColor = Colors.white.withValues(alpha: 0.02);
      borderColor = Colors.white.withValues(alpha: 0.039);
    }

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.answered) setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.answered) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        transform: Matrix4.diagonal3Values(
            _pressed ? 0.97 : 1.0, _pressed ? 0.97 : 1.0, 1.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.answered && widget.isCorrect
                    ? const Color(0xFF00FF88).withValues(alpha: 0.118)
                    : widget.answered && widget.isSelected
                        ? const Color(0xFFFF4444).withValues(alpha: 0.078)
                        : Colors.white.withValues(alpha: 0.039),
                border: Border.all(
                    color: widget.answered && widget.isCorrect
                        ? const Color(0xFF00FF88)
                        : widget.answered && widget.isSelected
                            ? const Color(0xFFFF4444)
                            : Colors.white.withValues(alpha: 0.118)),
              ),
              child: Center(
                child:
                    widget.answered && (widget.isCorrect || widget.isSelected)
                        ? Icon(widget.isCorrect ? Icons.check : Icons.close,
                            size: 14,
                            color: widget.isCorrect
                                ? const Color(0xFF00FF88)
                                : const Color(0xFFFF4444))
                        : Text(String.fromCharCode(65 + widget.index),
                            style: GoogleFonts.jetBrainsMono(
                                color: Colors.white.withValues(alpha: 0.235),
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.label,
                  style: GoogleFonts.syne(
                    color: widget.answered && widget.isCorrect
                        ? const Color(0xFF00FF88)
                        : widget.answered &&
                                widget.isSelected &&
                                !widget.isCorrect
                            ? const Color(0xFFFF4444)
                            : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatefulWidget {
  final bool correct, isLast, timerExpired;
  final _SimStep step;
  final int streak;
  final VoidCallback onNext;

  const _FeedbackCard({
    required this.correct,
    required this.step,
    required this.onNext,
    required this.isLast,
    required this.streak,
    required this.timerExpired,
  });

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.correct ? const Color(0xFF00FF88) : const Color(0xFFFF4444);

    String headerTitle;
    String headerEmoji;
    if (widget.timerExpired) {
      headerTitle = 'TEMPO ESGOTADO!';
      headerEmoji = '⏱️';
    } else if (widget.correct) {
      headerTitle = widget.streak >= 3
          ? 'SEQUÊNCIA x${widget.streak}! +${widget.streak * 10} BÓNUS'
          : 'CORRECTO! +100 pts';
      headerEmoji = widget.streak >= 3 ? '🔥' : '🎯';
    } else {
      headerTitle = 'ERRADO!';
      headerEmoji = '💀';
    }

    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.059),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.314)),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.078),
                  blurRadius: 20,
                  spreadRadius: -4)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headerEmoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(headerTitle,
                            style: GoogleFonts.jetBrainsMono(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1),
                            overflow: TextOverflow.ellipsis),
                        Text(
                            widget.correct
                                ? widget.step.audioCorrect
                                : widget.step.audioWrong,
                            style: GoogleFonts.jetBrainsMono(
                                color: color.withValues(alpha: 0.588),
                                fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: color.withValues(alpha: 0.157)),
              const SizedBox(height: 12),
              Text(widget.step.explanation,
                  style: GoogleFonts.jetBrainsMono(
                      color: Colors.white.withValues(alpha: 0.706),
                      fontSize: 11,
                      height: 1.7)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.isLast ? 'VER RESULTADO FINAL →' : 'PRÓXIMA ETAPA →',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatefulWidget {
  final int score, total, maxStreak;
  const _ResultView(
      {required this.score, required this.total, required this.maxStreak});

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView>
    with TickerProviderStateMixin {
  late AnimationController _ctrl, _countCtrl;
  late Animation<double> _fade, _scale;
  late Animation<int> _count;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _countCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _count = IntTween(begin: 0, end: widget.score).animate(
        CurvedAnimation(parent: _countCtrl, curve: Curves.easeOutCubic));
    _ctrl.forward().then((_) => _countCtrl.forward());
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  String get _grade {
    final p = widget.score / widget.total;
    if (p >= 0.8) return 'S';
    if (p >= 0.6) return 'A';
    if (p >= 0.4) return 'B';
    return 'C';
  }

  String get _gradeLabel {
    final p = widget.score / widget.total;
    if (p >= 0.8) return 'ESPECIALISTA EM SEGURANÇA';
    if (p >= 0.6) return 'BOM DESEMPENHO';
    if (p >= 0.4) return 'A MELHORAR';
    return 'PRECISA DE TREINO';
  }

  Color get _gradeColor {
    final p = widget.score / widget.total;
    if (p >= 0.8) return const Color(0xFF00FF88);
    if (p >= 0.6) return const Color(0xFF00BFFF);
    if (p >= 0.4) return const Color(0xFFFFCC00);
    return const Color(0xFFFF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _gradeColor.withValues(alpha: 0.078),
                        border: Border.all(
                            color: _gradeColor.withValues(alpha: 0.392),
                            width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: _gradeColor.withValues(alpha: 0.235),
                              blurRadius: 40,
                              spreadRadius: -5)
                        ],
                      ),
                      child: Center(
                        child: Text(_grade,
                            style: GoogleFonts.syne(
                                color: _gradeColor,
                                fontSize: 56,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('MISSÃO CONCLUÍDA',
                      style: GoogleFonts.jetBrainsMono(
                          color: Colors.white.withValues(alpha: 0.235),
                          fontSize: 11,
                          letterSpacing: 3)),
                  const SizedBox(height: 8),
                  Text(_gradeLabel,
                      style: GoogleFonts.syne(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _count,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1520),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _gradeColor.withValues(alpha: 0.235)),
                      ),
                      child: Column(children: [
                        Text('${_count.value}',
                            style: GoogleFonts.syne(
                                color: _gradeColor,
                                fontSize: 48,
                                fontWeight: FontWeight.w900)),
                        Text('de ${widget.total} pontos',
                            style: GoogleFonts.jetBrainsMono(
                                color: Colors.white.withValues(alpha: 0.235),
                                fontSize: 12)),
                        if (widget.maxStreak >= 2) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35)
                                  .withValues(alpha: 0.078),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFFF6B35)
                                      .withValues(alpha: 0.235)),
                            ),
                            child: Text(
                                '🔥 Melhor sequência: ${widget.maxStreak}x acertos',
                                style: GoogleFonts.jetBrainsMono(
                                    color: const Color(0xFFFF6B35),
                                    fontSize: 11)),
                          ),
                        ],
                      ]),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gradeColor,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('VOLTAR ÀS MISSÕES',
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
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
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: _ctrl.value,
          child: Container(
              width: 2,
              height: 14,
              margin: const EdgeInsets.only(left: 2),
              color: const Color(0xFF00FF88)),
        ),
      );
}

enum StepType { email, sms, browser, qr, analysis, decision }

class _SimStep {
  final StepType type;
  final String title,
      subtitle,
      content,
      question,
      explanation,
      audioCorrect,
      audioWrong;
  final List<String> options;
  final List<String> suspiciousWords;
  final int correctIndex;

  const _SimStep({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.audioCorrect,
    required this.audioWrong,
    this.suspiciousWords = const [],
  });
}
