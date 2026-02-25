import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_models.dart';
import 'api_service.dart';

class SimulationsScreen extends StatefulWidget {
  final List<PhishSimulation> simulations;
  final ValueChanged<String> onStart;

  const SimulationsScreen({
    super.key,
    required this.simulations,
    required this.onStart,
  });

  @override
  State<SimulationsScreen> createState() => _SimulationsScreenState();
}

class _SimulationsScreenState extends State<SimulationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerFade =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic));

    _headerController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  // ✅ CORRIGIDO: abre o detalhe e depois chama onStart para recarregar dados
  // O Navigator.push está AQUI (não no MainShell) para evitar duplicação
  void _openSimulation(PhishSimulation sim) async {
    HapticFeedback.mediumImpact();
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => SimulationDetailScreen(sim: sim),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    // ✅ Só chama onStart DEPOIS do pop — o MainShell recarrega stats + histórico
    widget.onStart(sim.id);
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.simulations.where((s) => s.completed).length;
    final total = widget.simulations.length;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: Stack(
        children: [
          _AnimatedBackground(controller: _bgController),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _Header(completed: completed, total: total),
                  ),
                ),
                Expanded(
                  child: widget.simulations.isEmpty
                      ? _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: widget.simulations.length,
                          itemBuilder: (_, i) {
                            return _SimCard(
                              sim: widget.simulations[i],
                              index: i,
                              onTap: () =>
                                  _openSimulation(widget.simulations[i]),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            right: 20,
            child: _AssistantFab(),
          ),
        ],
      ),
    );
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
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF080C14),
          const Color(0xFF0D1520),
          const Color(0xFF080C14),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final dotPaint = Paint()..color = const Color(0xFF00FF88).withAlpha(12);
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
          const Color(0xFF00FF88).withAlpha(20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 40, size.width, 80));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 40, size.width, 80), scanPaint);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.progress != progress;
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
        color: const Color(0xFF0D1520).withAlpha(200),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00FF88).withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withAlpha(15),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFF00FF88).withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00FF88),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MODO TREINO ACTIVO',
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFF00FF88),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '$completed/$total',
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF00FF88),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Simulações\nde Ataque',
            style: GoogleFonts.syne(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Treina contra ataques reais documentados',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white.withAlpha(50),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(3),
                ),
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
                        colors: [Color(0xFF00FF88), Color(0xFF00BFFF)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF88).withAlpha(80),
                          blurRadius: 8,
                        ),
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
      threat: 'Credenciais / Malware',
    ),
    'sms': (
      icon: '💬',
      label: 'SMISHING',
      color: Color(0xFFFF6B35),
      threat: 'Roubo de identidade',
    ),
    'url': (
      icon: '🔗',
      label: 'URL FALSO',
      color: Color(0xFF00BFFF),
      threat: 'Dados bancários',
    ),
    'app': (
      icon: '📱',
      label: 'APP / QR CODE',
      color: Color(0xFFB06EFF),
      threat: 'Acesso ao dispositivo',
    ),
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 100 + widget.index * 120), () {
      if (mounted) _ctrl.forward();
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
    final category = sim.category ?? 'email';
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
                    ? const Color(0xFF0D1520).withAlpha(240)
                    : const Color(0xFF0D1520).withAlpha(200),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sim.completed
                      ? color.withAlpha(100)
                      : _hovered
                          ? color.withAlpha(80)
                          : Colors.white.withAlpha(15),
                  width: sim.completed ? 1.5 : 1,
                ),
                boxShadow: [
                  if (sim.completed || _hovered)
                    BoxShadow(
                      color: color.withAlpha(20),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withAlpha(15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withAlpha(40)),
                          ),
                          child: Center(
                            child: Text(data.icon,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.label,
                                style: GoogleFonts.jetBrainsMono(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sim.title,
                                style: GoogleFonts.syne(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sim.description,
                                style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white.withAlpha(50),
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (sim.completed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF88).withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF00FF88).withAlpha(60)),
                            ),
                            child: Text(
                              '✓ OK',
                              style: GoogleFonts.jetBrainsMono(
                                color: const Color(0xFF00FF88),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withAlpha(40)),
                            ),
                            child: Text(
                              sim.progress > 0 ? 'EM CURSO' : 'NOVO',
                              style: GoogleFonts.jetBrainsMono(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withAlpha(8)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _InfoChip(
                                icon: '⚠️', label: data.threat, color: color),
                            const SizedBox(width: 8),
                            _InfoChip(
                                icon: '🎯',
                                label: sim.difficulty,
                                color: sim.difficultyColor),
                            const Spacer(),
                            Text(
                              '+${sim.xp} XP',
                              style: GoogleFonts.jetBrainsMono(
                                color: const Color(0xFF00FF88),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (!sim.completed) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(10),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: sim.progress / 100,
                                      child: Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withAlpha(100),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${sim.progress}%',
                                style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white.withAlpha(50),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton(
                              onPressed: widget.onTap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.withAlpha(20),
                                foregroundColor: color,
                                elevation: 0,
                                side: BorderSide(color: color.withAlpha(80)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    sim.progress > 0
                                        ? 'CONTINUAR MISSÃO'
                                        : 'INICIAR MISSÃO',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
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
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
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
            Text(
              'SEM SINAL',
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFF00FF88),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sem ligação ao servidor',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white.withAlpha(40),
                fontSize: 11,
              ),
            ),
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
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
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
                  .withAlpha((20 * (1 - _pulse.value)).toInt()),
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
                color: const Color(0xFF00FF88).withAlpha(80),
                blurRadius: 20,
                spreadRadius: -4,
              ),
            ],
          ),
          child: const Icon(Icons.smart_toy_outlined,
              color: Colors.black, size: 24),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIMULATION DETAIL SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

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
  bool _showResult = false;

  late AnimationController _typewriter;
  late AnimationController _shakeController;
  late AnimationController _successController;
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

    _steps = _buildSteps(widget.sim);
    _startTypewriter(_steps[0].content);
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _typewriter.dispose();
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }

  List<_SimStep> _buildSteps(PhishSimulation sim) {
    final category = sim.category ?? 'email';
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
          subtitle: 'Analisa este email com cuidado',
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
          question: 'O que é mais suspeito neste URL?',
          options: [
            'O protocolo http://',
            'O domínio .xyz e "bankportugal" junto',
            'O parâmetro token=',
            'Tudo parece normal',
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
          question: 'Qual é a acção mais segura?',
          options: [
            'Clicar no link e verificar rapidamente',
            'Ignorar o email completamente',
            'Ir directamente ao site do banco pelo browser',
            'Reencaminhar para amigos para eles verem',
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
          content: 'ctt-entrega.online vs ctt.pt',
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
          subtitle: 'Examina esta página web',
          content:
              'https://paypa1.com/signin\n\nPágina de login idêntica ao PayPal com logo e design oficial.',
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
              'O site paypa1.com tem cadeado verde e https://. Muitos pensam que isso significa segurança.',
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
              'QR Code colado sobre o menu de um restaurante. Ao ler: http://menu-restaurante-lisboa.xyz/cardapio',
          question: 'O que fazes com este QR Code?',
          options: [
            'Acedo normalmente, parece o menu',
            'Verifico o URL antes de abrir qualquer página',
            'Introduzo os meus dados para ver o menu',
            'Partilho com amigos para verem',
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
          question: 'Qual pista revela que este email é falso?',
          options: [
            'O Reply-To diferente do remetente',
            'O servidor DigitalOcean',
            'O endereço Protonmail',
            'Todas as opções acima',
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
          question: 'Qual é a melhor acção?',
          options: [
            'Apagar o email e ignorar',
            'Reportar ao departamento de segurança',
            'Abrir o link em modo privado para verificar',
            'Perguntar a um colega se recebeu o mesmo',
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
              'O atacante pede o código SMS que recebes. Este código é o OTP (One-Time Password) da tua conta MB WAY.',
          question: 'Para que serve o código SMS neste contexto?',
          options: [
            'Para verificar a tua identidade',
            'Para o atacante aceder à tua conta',
            'Para confirmar o endereço de entrega',
            'Para activar o prémio',
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
          question: 'O que está suspeito nesta mensagem?',
          options: [
            'O código 4821 no final',
            'O domínio cgd-seguranca.online e a urgência',
            'A palavra "bloqueamos"',
            'Nada, a CGD envia mensagens assim',
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
          question: 'Qual é a resposta mais segura?',
          options: [
            'Clico no link para verificar a situação',
            'Ligo para o número no verso do cartão',
            'Respondo ao SMS para saber mais',
            'Envio o código 4821 para verificar',
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
              'https://аpple.com/account\n\nAviso: O "а" no início é o Cirílico А (U+0430), não o latino "a".',
          question: 'Este URL é o site oficial da Apple?',
          options: [
            'Sim, tem https:// e parece correcto',
            'Não, usa caracteres Cirílicos invisíveis',
            'Só é suspeito se não tiver cadeado',
            'Sim, o domínio apple.com é oficial',
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
              'Recebes: bit.ly/3xK9mPq\n\nNão consegues ver o destino real sem clicar.',
          question: 'Como verificas um link encurtado com segurança?',
          options: [
            'Clico directamente para ver',
            'Uso um serviço como checkshorturl.com para expandir',
            'Se o remetente é de confiança, clico',
            'Espero que o antivírus bloqueie se for mau',
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
              'Vês um anúncio: "MB WAY PRO – Versão melhorada com mais funcionalidades! Descarrega aqui:" com um QR code que leva a: mbway-pro-download.xyz/app.apk',
          question: 'O que está errado nesta situação?',
          options: [
            'Nada, as apps também existem fora das lojas',
            'O APK fora da loja oficial pode ser malware',
            'Só é suspeito se pedir dados bancários',
            'O QR code garante que é seguro',
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
              'Instalas uma app de lanterna. Ela pede acesso a: Contactos, SMS, Câmara, Microfone, Localização e Histórico de chamadas.',
          question: 'O que deves fazer?',
          options: [
            'Aceitar tudo, as apps precisam de permissões',
            'Desinstalar — uma lanterna não precisa dessas permissões',
            'Aceitar só câmara e localização',
            'Perguntar ao amigo que recomendou',
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
        if (mounted)
          setState(() => _displayedText = text.substring(0, index + 1));
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  void _answer(int selectedIndex) {
    if (_answered) return;
    final step = _steps[_step];
    final isCorrect = selectedIndex == step.correctIndex;
    HapticFeedback.mediumImpact();
    setState(() {
      _answered = true;
      _correct = isCorrect;
    });
    if (isCorrect) {
      _score += 100;
      _successController.forward(from: 0);
    } else {
      _shakeController.forward(from: 0);
    }

    // ✅ CORRIGIDO: log de erro visível em vez de silenciar com catchError
    final scenario = '${widget.sim.title}: ${step.question}';
    ApiService.addXp(
      isCorrect ? 100 : 0,
      isCorrect,
      widget.sim.category,
      scenario: scenario,
    ).catchError((e) {
      debugPrint('[SimulationDetail] addXp erro: $e');
    });
  }

  void _next() {
    if (_step < _steps.length - 1) {
      final progress = ((_step + 1) / _steps.length * 100).round();
      ApiService.updateSimulationProgress(widget.sim.id, progress, false)
          .catchError((e) {
        debugPrint('[SimulationDetail] updateProgress erro: $e');
      });
      setState(() {
        _step++;
        _answered = false;
        _correct = null;
      });
      _successController.reset();
      _startTypewriter(_steps[_step].content);
    } else {
      ApiService.updateSimulationProgress(widget.sim.id, 100, true)
          .catchError((e) {
        debugPrint('[SimulationDetail] updateProgress (complete) erro: $e');
      });
      setState(() => _showResult = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult)
      return _ResultView(score: _score, total: _steps.length * 100);

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
                            color: Colors.white.withAlpha(50), fontSize: 11)),
                    const SizedBox(height: 16),
                    _ContentCard(step: step, displayedText: _displayedText),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1520),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(15)),
                      ),
                      child: Row(
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
                          step: step,
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
  final int current, total, score;
  final VoidCallback onClose;
  const _TopBar(
      {required this.current,
      required this.total,
      required this.score,
      required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(10))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ETAPA $current/$total',
                        style: GoogleFonts.jetBrainsMono(
                            color: Colors.white.withAlpha(60),
                            fontSize: 10,
                            letterSpacing: 1)),
                    Text('$score pts',
                        style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF00FF88),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: current / total,
                    minHeight: 4,
                    backgroundColor: Colors.white.withAlpha(10),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00FF88)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final _SimStep step;
  final String displayedText;
  const _ContentCard({required this.step, required this.displayedText});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    String headerLabel;
    IconData headerIcon;

    switch (step.type) {
      case StepType.email:
        borderColor = const Color(0xFF00FF88);
        headerLabel = 'CAIXA DE ENTRADA';
        headerIcon = Icons.email_outlined;
        break;
      case StepType.sms:
        borderColor = const Color(0xFFFF6B35);
        headerLabel = 'MENSAGEM SMS';
        headerIcon = Icons.sms_outlined;
        break;
      case StepType.browser:
        borderColor = const Color(0xFF00BFFF);
        headerLabel = 'NAVEGADOR WEB';
        headerIcon = Icons.language_outlined;
        break;
      case StepType.qr:
        borderColor = const Color(0xFFB06EFF);
        headerLabel = 'QR CODE DETECTADO';
        headerIcon = Icons.qr_code_scanner_outlined;
        break;
      case StepType.analysis:
        borderColor = const Color(0xFFFFCC00);
        headerLabel = 'ANÁLISE FORENSE';
        headerIcon = Icons.search_outlined;
        break;
      default:
        borderColor = const Color(0xFF00FF88);
        headerLabel = 'CENÁRIO';
        headerIcon = Icons.info_outline;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withAlpha(60)),
        boxShadow: [
          BoxShadow(
              color: borderColor.withAlpha(15),
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
              color: borderColor.withAlpha(15),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border:
                  Border(bottom: BorderSide(color: borderColor.withAlpha(40))),
            ),
            child: Row(
              children: [
                Icon(headerIcon, color: borderColor, size: 14),
                const SizedBox(width: 8),
                Text(headerLabel,
                    style: GoogleFonts.jetBrainsMono(
                        color: borderColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const Spacer(),
                ...['red', 'yellow', 'green'].map((c) => Container(
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
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.jetBrainsMono(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                    height: 1.8),
                children: [
                  TextSpan(text: displayedText),
                  WidgetSpan(child: _BlinkingCursor()),
                ],
              ),
            ),
          ),
        ],
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

class _OptionButton extends StatefulWidget {
  final String label;
  final int index;
  final bool answered, isCorrect;
  final VoidCallback onTap;

  const _OptionButton(
      {required this.label,
      required this.index,
      required this.answered,
      required this.isCorrect,
      required this.onTap});

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
    Color bgColor = !widget.answered
        ? Colors.white.withAlpha(15)
        : widget.isCorrect
            ? const Color(0xFF00FF88).withAlpha(30)
            : const Color(0xFFFF4444).withAlpha(20);
    Color borderColor = !widget.answered
        ? Colors.white.withAlpha(20)
        : widget.isCorrect
            ? const Color(0xFF00FF88).withAlpha(100)
            : const Color(0xFFFF4444).withAlpha(80);

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
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor)),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.answered && widget.isCorrect
                    ? const Color(0xFF00FF88).withAlpha(30)
                    : widget.answered
                        ? const Color(0xFFFF4444).withAlpha(20)
                        : Colors.white.withAlpha(10),
                border: Border.all(
                    color: widget.answered && widget.isCorrect
                        ? const Color(0xFF00FF88)
                        : widget.answered
                            ? const Color(0xFFFF4444)
                            : Colors.white.withAlpha(30)),
              ),
              child: Center(
                child: widget.answered
                    ? Icon(widget.isCorrect ? Icons.check : Icons.close,
                        size: 14,
                        color: widget.isCorrect
                            ? const Color(0xFF00FF88)
                            : const Color(0xFFFF4444))
                    : Text(String.fromCharCode(65 + widget.index),
                        style: GoogleFonts.jetBrainsMono(
                            color: Colors.white.withAlpha(60),
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
                        : widget.answered && !widget.isCorrect
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
  final bool correct, isLast;
  final _SimStep step;
  final VoidCallback onNext;

  const _FeedbackCard(
      {required this.correct,
      required this.step,
      required this.onNext,
      required this.isLast});

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
    final audio =
        widget.correct ? widget.step.audioCorrect : widget.step.audioWrong;

    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withAlpha(80)),
            boxShadow: [
              BoxShadow(
                  color: color.withAlpha(20), blurRadius: 20, spreadRadius: -4)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(widget.correct ? '🎯' : '💀',
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.correct ? 'CORRECTO! +100 pts' : 'ERRADO!',
                            style: GoogleFonts.jetBrainsMono(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                        Text(audio,
                            style: GoogleFonts.jetBrainsMono(
                                color: color.withAlpha(150), fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: color.withAlpha(40)),
              const SizedBox(height: 12),
              Text(widget.step.explanation,
                  style: GoogleFonts.jetBrainsMono(
                      color: Colors.white.withAlpha(180),
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

// ── Resultado Final ───────────────────────────────────────────────────────────
class _ResultView extends StatefulWidget {
  final int score, total;
  const _ResultView({required this.score, required this.total});

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
                        color: _gradeColor.withAlpha(20),
                        border: Border.all(
                            color: _gradeColor.withAlpha(100), width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: _gradeColor.withAlpha(60),
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
                          color: Colors.white.withAlpha(60),
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
                        border: Border.all(color: _gradeColor.withAlpha(60)),
                      ),
                      child: Column(
                        children: [
                          Text('${_count.value}',
                              style: GoogleFonts.syne(
                                  color: _gradeColor,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900)),
                          Text('de ${widget.total} pontos',
                              style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white.withAlpha(60),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      // ✅ CORRIGIDO: um único pop — o SimulationsScreen trata o resto
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

// ── Modelos internos ──────────────────────────────────────────────────────────
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
  });
}
