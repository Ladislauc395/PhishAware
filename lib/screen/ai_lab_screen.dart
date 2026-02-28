import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_models.dart';
import 'api_service.dart';
import 'groq_service.dart';

class AiLabScreen extends StatefulWidget {
  const AiLabScreen({super.key});

  @override
  State<AiLabScreen> createState() => _AiLabScreenState();
}

class _AiLabScreenState extends State<AiLabScreen>
    with TickerProviderStateMixin {
  int _sessionCorrect = 0;
  int _sessionTotal = 0;
  late AnimationController _bgCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;

  @override
  void initState() {
    super.initState();
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _openChallenge({String? type, String? difficulty}) async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<_ChallengeResult>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) =>
            AiChallengeScreen(type: type, difficulty: difficulty),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _sessionTotal++;
        if (result.correct) _sessionCorrect++;
      });
      ApiService.addXp(
        result.xpEarned,
        result.correct,
        result.scenario?.type ?? 'email',
        scenario: result.scenario?.subject ?? '',
      ).ignore();
    }
  }

  void _openForensic(ForensicCase fc) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => ForensicDetailScreen(fc: fc),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A10),
      body: Stack(
        children: [
          _GridBackground(controller: _bgCtrl),
          SafeArea(
            child: FadeTransition(
              opacity: _entryFade,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(),
                  if (_sessionTotal > 0) _buildSessionStats(),
                  _buildLabSection(),
                  _buildForensicSection(),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FF88), Color(0xFF00C4F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF00FF88).withAlpha(60),
                        blurRadius: 20,
                        spreadRadius: -4)
                  ],
                ),
                child: const Text('🧠', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Phishing Lab',
                          style: GoogleFonts.syne(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                      Text('Simulações ultra-realistas geradas por IA',
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 12)),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: const Color(0xFF00FF88).withAlpha(60)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFF00FF88)),
                  ),
                  const SizedBox(width: 6),
                  Text('Groq',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: const Color(0xFF00FF88))),
                ]),
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStats() {
    final pct = _sessionTotal > 0 ? _sessionCorrect / _sessionTotal : 0.0;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1520),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00FF88).withAlpha(40)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip('$_sessionTotal', 'Jogadas', const Color(0xFF3B82F6)),
              _StatChip('$_sessionCorrect', 'Acertos', const Color(0xFF00FF88)),
              _StatChip('${_sessionTotal - _sessionCorrect}', 'Erros',
                  const Color(0xFFFF4444)),
              _StatChip(
                  '${(pct * 100).round()}%',
                  'Taxa',
                  pct >= 0.7
                      ? const Color(0xFF00FF88)
                      : const Color(0xFFFFCC00)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
                icon: '⚡', title: 'Gerar Simulação IA', subtitle: 'Groq AI'),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => _openChallenge(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A1A0F), Color(0xFF0D1F1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFF00FF88).withAlpha(60)),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF00FF88).withAlpha(15),
                        blurRadius: 20,
                        spreadRadius: -5)
                  ],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88).withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('🎲', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Simulação Aleatória',
                              style: GoogleFonts.syne(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          Text('Tipo e dificuldade gerados pela IA',
                              style: GoogleFonts.inter(
                                  color: Colors.white38, fontSize: 12)),
                        ]),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('JOGAR',
                        style: GoogleFonts.jetBrainsMono(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: [
                _TypeCard(
                    icon: '📧',
                    label: 'Email',
                    type: 'email',
                    color: const Color(0xFF00FF88),
                    onTap: () => _openChallenge(type: 'email')),
                _TypeCard(
                    icon: '💬',
                    label: 'SMS',
                    type: 'sms',
                    color: const Color(0xFFFFCC00),
                    onTap: () => _openChallenge(type: 'sms')),
                _TypeCard(
                    icon: '🟢',
                    label: 'WhatsApp',
                    type: 'whatsapp',
                    color: const Color(0xFF25D366),
                    onTap: () => _openChallenge(type: 'whatsapp')),
                _TypeCard(
                    icon: '🔐',
                    label: 'Página Login',
                    type: 'login_page',
                    color: const Color(0xFFFF6B35),
                    onTap: () => _openChallenge(type: 'login_page')),
                _TypeCard(
                    icon: '🔗',
                    label: 'URL / Link',
                    type: 'url',
                    color: const Color(0xFF3B82F6),
                    onTap: () => _openChallenge(type: 'url')),
                _TypeCard(
                    icon: '🎲',
                    label: 'Surpresa',
                    type: '',
                    color: const Color(0xFFB06EFF),
                    onTap: () => _openChallenge()),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [
              _DiffChip(
                  label: 'Fácil',
                  emoji: '🟢',
                  onTap: () => _openChallenge(difficulty: 'easy')),
              const SizedBox(width: 8),
              _DiffChip(
                  label: 'Médio',
                  emoji: '🟡',
                  onTap: () => _openChallenge(difficulty: 'medium')),
              const SizedBox(width: 8),
              _DiffChip(
                  label: 'Difícil',
                  emoji: '🔴',
                  onTap: () => _openChallenge(difficulty: 'hard')),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildForensicSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
                icon: '🔬', title: 'Análise Forense', subtitle: 'Casos Reais'),
            const SizedBox(height: 4),
            Text('Ataques documentados que mudaram a cibersegurança',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 16),
            ...kForensicCases.asMap().entries.map((e) => _ForensicCard(
                  fc: e.value,
                  onTap: () => _openForensic(e.value),
                )),
          ],
        ),
      ),
    );
  }
}

class _ChallengeResult {
  final bool correct;
  final int xpEarned;
  final AiScenario? scenario;
  _ChallengeResult(
      {required this.correct, required this.xpEarned, this.scenario});
}

class AiChallengeScreen extends StatefulWidget {
  final String? type;
  final String? difficulty;
  const AiChallengeScreen({super.key, this.type, this.difficulty});

  @override
  State<AiChallengeScreen> createState() => _AiChallengeScreenState();
}

class _AiChallengeScreenState extends State<AiChallengeScreen>
    with TickerProviderStateMixin {
  AiScenario? _scenario;
  bool _loading = true;
  String? _error;
  bool? _userAnswer;
  bool _revealed = false;

  final Set<String> _tappedElements = {};
  bool _inspectMode = false;

  late AnimationController _revealCtrl;
  late Animation<double> _revealAnim;
  late AnimationController _shakeCtrl;
  late Animation<Offset> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _revealAnim = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0.02, 0))
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeCtrl);
    _generate();
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _scenario = null;
      _userAnswer = null;
      _revealed = false;
      _tappedElements.clear();
      _inspectMode = false;
    });
    try {
      final s = await GroqService.generateScenario(
          type: widget.type, difficulty: widget.difficulty);
      if (mounted)
        setState(() {
          _scenario = s;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  void _onElementTapped(SuspiciousElement el) {
    if (_revealed) return;
    HapticFeedback.selectionClick();
    setState(() => _tappedElements.add(el.id));
    _showElementHint(el);
  }

  void _showElementHint(SuspiciousElement el) {
    final color =
        el.isSuspicious ? const Color(0xFFFF4444) : const Color(0xFF00FF88);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0D1520),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color.withAlpha(80))),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 4),
        content: Row(children: [
          Icon(
            el.isSuspicious
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    el.isSuspicious
                        ? '⚠️ Elemento Suspeito'
                        : '✅ Elemento Normal',
                    style: GoogleFonts.syne(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(el.hint,
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 11, height: 1.4)),
                ]),
          ),
        ]),
      ),
    );
  }

  void _answer(bool isPhishing) {
    if (_revealed) return;
    HapticFeedback.mediumImpact();
    final correct = isPhishing == (_scenario?.isPhishing ?? true);
    setState(() {
      _userAnswer = isPhishing;
      _revealed = true;
    });
    _revealCtrl.forward();
    if (!correct) {
      _shakeCtrl.forward().then((_) => _shakeCtrl.reset());
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
      Future.delayed(
          const Duration(milliseconds: 100), HapticFeedback.lightImpact);
    }
  }

  void _nextRound() {
    Navigator.pop(
        context,
        _ChallengeResult(
          correct: _userAnswer == (_scenario?.isPhishing ?? true),
          xpEarned: _calcXp(),
          scenario: _scenario,
        ));
  }

  int _calcXp() {
    if (_scenario == null || _userAnswer == null) return 0;
    if (_userAnswer != _scenario!.isPhishing) return 0;
    final baseXp = switch (_scenario!.difficulty) {
      'hard' => 30,
      'medium' => 20,
      _ => 10,
    };
    final inspectBonus = (_tappedElements.length * 2).clamp(0, 10);
    return baseXp + inspectBonus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A10),
      body: SafeArea(
        child: _loading
            ? _LoadingView(type: widget.type)
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _generate)
                : _buildChallenge(),
      ),
    );
  }

  Widget _buildChallenge() {
    final s = _scenario!;
    return Column(children: [
      _ChallengeHeader(
        scenario: s,
        revealed: _revealed,
        inspectMode: _inspectMode,
        tappedCount: _tappedElements.length,
        onClose: _revealed ? _nextRound : () => Navigator.pop(context),
        onToggleInspect: () => setState(() => _inspectMode = !_inspectMode),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(children: [
            const SizedBox(height: 16),
            if (_inspectMode && !_revealed)
              _InspectBanner(elementCount: s.suspiciousElements.length),
            const SizedBox(height: 8),
            SlideTransition(
              position: _shakeAnim,
              child: _buildVisualRenderer(s),
            ),
            const SizedBox(height: 20),
            if (!_revealed)
              _buildDecisionSection(s)
            else
              FadeTransition(
                opacity: _revealAnim,
                child: _buildAnalysisPanel(s),
              ),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildVisualRenderer(AiScenario s) {
    switch (s.type) {
      case 'sms':
        return _SmsRenderer(
            scenario: s,
            revealed: _revealed,
            inspectMode: _inspectMode,
            tappedElements: _tappedElements,
            onElementTap: _onElementTapped);
      case 'whatsapp':
        return _WhatsAppRenderer(
            scenario: s,
            revealed: _revealed,
            inspectMode: _inspectMode,
            tappedElements: _tappedElements,
            onElementTap: _onElementTapped);
      case 'login_page':
        return _LoginPageRenderer(
            scenario: s,
            revealed: _revealed,
            inspectMode: _inspectMode,
            tappedElements: _tappedElements,
            onElementTap: _onElementTapped);
      case 'url':
        return _UrlRenderer(
            scenario: s,
            revealed: _revealed,
            inspectMode: _inspectMode,
            tappedElements: _tappedElements,
            onElementTap: _onElementTapped);
      default:
        return _EmailRenderer(
            scenario: s,
            revealed: _revealed,
            inspectMode: _inspectMode,
            tappedElements: _tappedElements,
            onElementTap: _onElementTapped);
    }
  }

  Widget _buildDecisionSection(AiScenario s) {
    return Column(children: [
      if (_tappedElements.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCC00).withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFCC00).withAlpha(40)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔍', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              '${_tappedElements.length} elemento(s) inspecionado(s)',
              style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFFFFCC00), fontSize: 10),
            ),
          ]),
        ),
        const SizedBox(height: 16),
      ],
      Text('O que achas?',
          style: GoogleFonts.syne(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('Toca nos elementos suspeitos • Depois decide',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(
          child: _DecisionButton(
            label: '🎣 É Phishing',
            color: const Color(0xFFFF4444),
            onTap: () => _answer(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DecisionButton(
            label: '✅ É Legítimo',
            color: const Color(0xFF00FF88),
            onTap: () => _answer(false),
          ),
        ),
      ]),
    ]);
  }

  Widget _buildAnalysisPanel(AiScenario s) {
    final userWasCorrect = _userAnswer == s.isPhishing;
    final xp = _calcXp();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: userWasCorrect
              ? const Color(0xFF00FF88).withAlpha(15)
              : const Color(0xFFFF4444).withAlpha(15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: userWasCorrect
                  ? const Color(0xFF00FF88).withAlpha(60)
                  : const Color(0xFFFF4444).withAlpha(60)),
        ),
        child: Row(children: [
          Text(userWasCorrect ? '🎯' : '😔',
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(userWasCorrect ? 'Correto!' : 'Não desta vez',
                  style: GoogleFonts.syne(
                      color: userWasCorrect
                          ? const Color(0xFF00FF88)
                          : const Color(0xFFFF4444),
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Text(
                s.isPhishing
                    ? 'Era um ataque de phishing'
                    : 'Era uma mensagem legítima',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ]),
          ),
          if (userWasCorrect && xp > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC00).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFFFFCC00).withAlpha(60)),
              ),
              child: Text('+$xp XP',
                  style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFFFCC00),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
      const SizedBox(height: 16),
      if (s.suspiciousElements.isNotEmpty) ...[
        _ElementsRevealCard(
          elements: s.suspiciousElements,
          tapped: _tappedElements,
          isPhishing: s.isPhishing,
        ),
        const SizedBox(height: 12),
      ],
      if (s.isPhishing && s.redFlags.isNotEmpty) ...[
        _AnalysisCard(
            title: '🚩 Sinais de Phishing',
            items: s.redFlags,
            color: const Color(0xFFFF4444)),
        const SizedBox(height: 12),
      ],
      if (!s.isPhishing && s.greenFlags.isNotEmpty) ...[
        _AnalysisCard(
            title: '✅ Indicadores de Confiança',
            items: s.greenFlags,
            color: const Color(0xFF00FF88)),
        const SizedBox(height: 12),
      ],
      _InfoBlock(
          icon: '🔍',
          title: 'Análise Técnica',
          content: s.explanation,
          color: const Color(0xFF3B82F6)),
      const SizedBox(height: 12),
      if (s.isPhishing &&
          s.attackTechnique.isNotEmpty &&
          s.attackTechnique != 'N/A') ...[
        _InfoBlock(
            icon: '⚔️',
            title: 'Técnica de Ataque',
            content: s.attackTechnique,
            color: const Color(0xFFFF6B35)),
        const SizedBox(height: 12),
      ],
      if (s.isPhishing &&
          s.potentialDamage.isNotEmpty &&
          s.potentialDamage != 'Não aplicável') ...[
        _InfoBlock(
            icon: '💀',
            title: 'Impacto Potencial',
            content: s.potentialDamage,
            color: const Color(0xFFFF4444)),
        const SizedBox(height: 12),
      ],
      if (s.realWorldReference.isNotEmpty) ...[
        _InfoBlock(
            icon: '📰',
            title: 'Caso Real Similar',
            content: s.realWorldReference,
            color: const Color(0xFFFFCC00)),
        const SizedBox(height: 12),
      ],
      if (s.forensicTip.isNotEmpty) ...[
        _InfoBlock(
            icon: '🛡️',
            title: 'Dica Forense',
            content: s.forensicTip,
            color: const Color(0xFF00FF88)),
        const SizedBox(height: 20),
      ],
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _nextRound,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FF88),
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text('Próxima Simulação',
              style:
                  GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }
}

class _InspectBanner extends StatelessWidget {
  final int elementCount;
  const _InspectBanner({required this.elementCount});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFCC00).withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCC00).withAlpha(50)),
        ),
        child: Row(children: [
          const Text('👆', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modo inspeção ativo — toca nos elementos destacados ($elementCount disponíveis)',
              style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFFFFCC00), fontSize: 10),
            ),
          ),
        ]),
      );
}

class _ElementsRevealCard extends StatelessWidget {
  final List<SuspiciousElement> elements;
  final Set<String> tapped;
  final bool isPhishing;
  const _ElementsRevealCard(
      {required this.elements, required this.tapped, required this.isPhishing});

  @override
  Widget build(BuildContext context) {
    final suspicious = elements.where((e) => e.isSuspicious).toList();
    if (suspicious.isEmpty) return const SizedBox.shrink();

    final found = suspicious.where((e) => tapped.contains(e.id)).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCC00).withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCC00).withAlpha(40)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🔍 Elementos Suspeitos',
              style: GoogleFonts.syne(
                  color: const Color(0xFFFFCC00),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: found == suspicious.length
                  ? const Color(0xFF00FF88).withAlpha(20)
                  : const Color(0xFFFFCC00).withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$found/${suspicious.length} encontrados',
              style: GoogleFonts.jetBrainsMono(
                  color: found == suspicious.length
                      ? const Color(0xFF00FF88)
                      : const Color(0xFFFFCC00),
                  fontSize: 9,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        ...suspicious.map((el) {
          final wasTapped = tapped.contains(el.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(
                wasTapped ? Icons.check_circle : Icons.radio_button_unchecked,
                color: wasTapped
                    ? const Color(0xFF00FF88)
                    : const Color(0xFFFF4444),
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(el.label,
                          style: GoogleFonts.jetBrainsMono(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                      Text(el.hint,
                          style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 10,
                              height: 1.4)),
                    ]),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final AiScenario scenario;
  final double size;
  final bool inspectMode;
  final bool isTapped;
  final VoidCallback? onTap;

  const _BrandLogo({
    required this.scenario,
    this.size = 40,
    this.inspectMode = false,
    this.isTapped = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final logoEl = scenario.suspiciousElements
        .where((e) => e.elementType == 'logo')
        .firstOrNull;
    final isInteractive = inspectMode && logoEl != null;

    Widget logoWidget = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: scenario.logoUrl.isNotEmpty
          ? Image.network(
              scenario.logoUrl,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  _FallbackLogo(scenario: scenario, size: size),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : _FallbackLogo(scenario: scenario, size: size),
            )
          : _FallbackLogo(scenario: scenario, size: size),
    );

    if (isInteractive) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.22 + 3),
            border: Border.all(
              color: isTapped
                  ? const Color(0xFFFFCC00)
                  : const Color(0xFFFFCC00).withAlpha(100),
              width: isTapped ? 2.5 : 1.5,
            ),
          ),
          child: logoWidget,
        ),
      );
    }
    return logoWidget;
  }
}

class _FallbackLogo extends StatelessWidget {
  final AiScenario scenario;
  final double size;
  const _FallbackLogo({required this.scenario, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: scenario.brandColorParsed.withAlpha(40),
      child: Center(
        child: Text(
          scenario.logoAltText.isNotEmpty
              ? scenario.logoAltText[0].toUpperCase()
              : '?',
          style: GoogleFonts.syne(
              color: scenario.brandColorParsed,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _TappableSpan extends StatelessWidget {
  final SuspiciousElement element;
  final bool inspectMode;
  final bool isTapped;
  final bool revealed;
  final VoidCallback onTap;
  final Widget child;

  const _TappableSpan({
    required this.element,
    required this.inspectMode,
    required this.isTapped,
    required this.revealed,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!inspectMode && !revealed) return child;

    Color borderColor;
    if (revealed) {
      borderColor = element.isSuspicious
          ? const Color(0xFFFF4444)
          : const Color(0xFF00FF88);
    } else if (isTapped) {
      borderColor = const Color(0xFFFFCC00);
    } else {
      borderColor = const Color(0xFFFFCC00).withAlpha(120);
    }

    return GestureDetector(
      onTap: revealed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: revealed
              ? (element.isSuspicious
                  ? const Color(0xFFFF4444).withAlpha(25)
                  : const Color(0xFF00FF88).withAlpha(25))
              : (isTapped
                  ? const Color(0xFFFFCC00).withAlpha(25)
                  : const Color(0xFFFFCC00).withAlpha(10)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: child,
      ),
    );
  }
}

class _EmailRenderer extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final Set<String> tappedElements;
  final ValueChanged<SuspiciousElement> onElementTap;

  const _EmailRenderer({
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedElements,
    required this.onElementTap,
  });

  SuspiciousElement? _el(String id) =>
      scenario.suspiciousElements.where((e) => e.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    final borderColor = !revealed
        ? Colors.white.withAlpha(20)
        : s.isPhishing
            ? const Color(0xFFFF4444).withAlpha(100)
            : const Color(0xFF00FF88).withAlpha(100);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: revealed
            ? [
                BoxShadow(
                    color: (s.isPhishing
                            ? const Color(0xFFFF4444)
                            : const Color(0xFF00FF88))
                        .withAlpha(30),
                    blurRadius: 30,
                    spreadRadius: -5)
              ]
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161E2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border:
                Border(bottom: BorderSide(color: Colors.white.withAlpha(15))),
          ),
          child: Row(children: [
            _dot(const Color(0xFFFF5F57)),
            const SizedBox(width: 5),
            _dot(const Color(0xFFFFBD2E)),
            const SizedBox(width: 5),
            _dot(const Color(0xFF27C93F)),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('📧 Caixa de Entrada',
                    style: GoogleFonts.jetBrainsMono(
                        color: Colors.white38, fontSize: 10)),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _BrandLogo(
                scenario: s,
                size: 42,
                inspectMode: inspectMode,
                isTapped: tappedElements.contains('logo'),
                onTap: () {
                  final el = _el('logo');
                  if (el != null) onElementTap(el);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.senderName,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Builder(builder: (_) {
                        final el = _el('sender');
                        final widget = Text(
                          s.senderAddress,
                          style: GoogleFonts.jetBrainsMono(
                              color: revealed && s.isPhishing
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.white54,
                              fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        );
                        if (el != null) {
                          return _TappableSpan(
                            element: el,
                            inspectMode: inspectMode,
                            isTapped: tappedElements.contains(el.id),
                            revealed: revealed,
                            onTap: () => onElementTap(el),
                            child: widget,
                          );
                        }
                        return widget;
                      }),
                    ]),
              ),
              Text(s.timestamp,
                  style:
                      GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
            ]),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withAlpha(15)),
            const SizedBox(height: 10),
            Text(s.subject,
                style: GoogleFonts.syne(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(s.body,
                style: GoogleFonts.inter(
                    color: Colors.white70, fontSize: 13, height: 1.6)),
            const SizedBox(height: 16),
            if (s.ctaText.isNotEmpty)
              Builder(builder: (_) {
                final el = _el('cta_url') ?? _el('cta');
                final btn = Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: revealed && s.isPhishing
                        ? const Color(0xFFFF4444).withAlpha(30)
                        : s.brandColorParsed.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: revealed && s.isPhishing
                            ? const Color(0xFFFF4444).withAlpha(80)
                            : s.brandColorParsed.withAlpha(80)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(s.ctaText,
                        style: GoogleFonts.inter(
                            color: revealed && s.isPhishing
                                ? const Color(0xFFFF6B6B)
                                : s.brandColorParsed,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Icon(Icons.open_in_new,
                        size: 13,
                        color: revealed && s.isPhishing
                            ? const Color(0xFFFF6B6B)
                            : s.brandColorParsed),
                  ]),
                );
                if (el != null) {
                  return _TappableSpan(
                    element: el,
                    inspectMode: inspectMode,
                    isTapped: tappedElements.contains(el.id),
                    revealed: revealed,
                    onTap: () => onElementTap(el),
                    child: btn,
                  );
                }
                return btn;
              }),
            if (s.ctaUrl.isNotEmpty && revealed) ...[
              const SizedBox(height: 8),
              Row(children: [
                if (s.isPhishing)
                  const Icon(Icons.warning_amber_rounded,
                      size: 12, color: Color(0xFFFF4444)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(s.ctaUrl,
                      style: GoogleFonts.jetBrainsMono(
                          color: s.isPhishing
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFF00FF88),
                          fontSize: 10),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _dot(Color c) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c));
}

class _SmsRenderer extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final Set<String> tappedElements;
  final ValueChanged<SuspiciousElement> onElementTap;

  const _SmsRenderer({
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedElements,
    required this.onElementTap,
  });

  SuspiciousElement? _el(String id) =>
      scenario.suspiciousElements.where((e) => e.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: revealed
                ? s.isPhishing
                    ? const Color(0xFFFF4444).withAlpha(100)
                    : const Color(0xFF00FF88).withAlpha(100)
                : Colors.white.withAlpha(20)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF161E2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border:
                Border(bottom: BorderSide(color: Colors.white.withAlpha(15))),
          ),
          child: Row(children: [
            const Icon(Icons.signal_cellular_alt,
                color: Colors.white38, size: 14),
            const SizedBox(width: 6),
            Text('Mensagens',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('🔋 87%',
                style: GoogleFonts.jetBrainsMono(
                    color: Colors.white38, fontSize: 10)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            _BrandLogo(scenario: s, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.senderName,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Builder(builder: (_) {
                      final el = _el('sender');
                      final w = Text(
                        s.phoneNumber ?? s.senderAddress,
                        style: GoogleFonts.jetBrainsMono(
                            color: revealed && s.isPhishing
                                ? const Color(0xFFFF6B6B)
                                : Colors.white38,
                            fontSize: 10),
                      );
                      if (el != null) {
                        return _TappableSpan(
                          element: el,
                          inspectMode: inspectMode,
                          isTapped: tappedElements.contains(el.id),
                          revealed: revealed,
                          onTap: () => onElementTap(el),
                          child: w,
                        );
                      }
                      return w;
                    }),
                  ]),
            ),
            Text(s.timestamp,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
          ]),
        ),
        Divider(color: Colors.white.withAlpha(10), height: 1),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 290),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2A3A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: Colors.white.withAlpha(15)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.body,
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 13, height: 1.5)),
                    if (s.ctaUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Builder(builder: (_) {
                        final el = _el('cta_url');
                        final w = Text(
                          s.ctaUrl,
                          style: GoogleFonts.jetBrainsMono(
                              color: revealed && s.isPhishing
                                  ? const Color(0xFFFF6B6B)
                                  : const Color(0xFF60A5FA),
                              fontSize: 11),
                        );
                        if (el != null) {
                          return _TappableSpan(
                            element: el,
                            inspectMode: inspectMode,
                            isTapped: tappedElements.contains(el.id),
                            revealed: revealed,
                            onTap: () => onElementTap(el),
                            child: w,
                          );
                        }
                        return w;
                      }),
                    ],
                  ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _WhatsAppRenderer extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final Set<String> tappedElements;
  final ValueChanged<SuspiciousElement> onElementTap;

  const _WhatsAppRenderer({
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedElements,
    required this.onElementTap,
  });

  SuspiciousElement? _el(String id) =>
      scenario.suspiciousElements.where((e) => e.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    const waGreen = Color(0xFF25D366);
    const waDark = Color(0xFF111B21);
    const waBubble = Color(0xFF1F2C34);

    return Container(
      decoration: BoxDecoration(
        color: waDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: revealed
                ? s.isPhishing
                    ? const Color(0xFFFF4444).withAlpha(100)
                    : waGreen.withAlpha(100)
                : Colors.white.withAlpha(20)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: const BoxDecoration(
            color: Color(0xFF1F2C34),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            const Icon(Icons.arrow_back, color: waGreen, size: 18),
            const SizedBox(width: 8),
            _BrandLogo(
              scenario: s,
              size: 36,
              inspectMode: inspectMode,
              isTapped: tappedElements.contains('logo'),
              onTap: () {
                final el = _el('logo');
                if (el != null) onElementTap(el);
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.senderName,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Builder(builder: (_) {
                      final el = _el('sender');
                      final w = Text(
                        s.phoneNumber ?? s.senderAddress,
                        style: GoogleFonts.inter(
                            color: revealed && s.isPhishing
                                ? const Color(0xFFFF6B6B)
                                : Colors.white54,
                            fontSize: 11),
                      );
                      if (el != null) {
                        return _TappableSpan(
                          element: el,
                          inspectMode: inspectMode,
                          isTapped: tappedElements.contains(el.id),
                          revealed: revealed,
                          onTap: () => onElementTap(el),
                          child: w,
                        );
                      }
                      return w;
                    }),
                  ]),
            ),
            const Icon(Icons.videocam, color: waGreen, size: 20),
            const SizedBox(width: 16),
            const Icon(Icons.call, color: waGreen, size: 18),
          ]),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B141A),
            image: const DecorationImage(
              image: AssetImage('assets/wa_pattern.png'),
              repeat: ImageRepeat.repeat,
              opacity: 0.03,
            ),
          ),
          child: Column(children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF182229),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('HOJE',
                    style:
                        GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                decoration: BoxDecoration(
                  color: waBubble,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.senderName,
                          style: GoogleFonts.inter(
                              color: waGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(s.body,
                          style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5)),
                      if (s.ctaUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Builder(builder: (_) {
                          final el = _el('cta_url');
                          final preview = Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF182229),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: revealed && s.isPhishing
                                      ? const Color(0xFFFF4444).withAlpha(80)
                                      : waGreen.withAlpha(40)),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.link,
                                        size: 12,
                                        color: revealed && s.isPhishing
                                            ? const Color(0xFFFF4444)
                                            : waGreen),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        s.ctaText.isNotEmpty
                                            ? s.ctaText
                                            : 'Ver link',
                                        style: GoogleFonts.inter(
                                            color: revealed && s.isPhishing
                                                ? const Color(0xFFFF6B6B)
                                                : waGreen,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(s.ctaUrl,
                                      style: GoogleFonts.jetBrainsMono(
                                          color: revealed && s.isPhishing
                                              ? const Color(0xFFFF6B6B)
                                              : Colors.white38,
                                          fontSize: 9),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1),
                                ]),
                          );
                          if (el != null) {
                            return _TappableSpan(
                              element: el,
                              inspectMode: inspectMode,
                              isTapped: tappedElements.contains(el.id),
                              revealed: revealed,
                              onTap: () => onElementTap(el),
                              child: preview,
                            );
                          }
                          return preview;
                        }),
                      ],
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(s.timestamp,
                              style: GoogleFonts.inter(
                                  color: Colors.white38, fontSize: 10)),
                          const SizedBox(width: 4),
                          const Icon(Icons.done_all, size: 14, color: waGreen),
                        ]),
                      ),
                    ]),
              ),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1F2C34),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3942),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Mensagem',
                    style:
                        GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration:
                  const BoxDecoration(shape: BoxShape.circle, color: waGreen),
              child: const Icon(Icons.mic, color: Colors.white, size: 18),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _LoginPageRenderer extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final Set<String> tappedElements;
  final ValueChanged<SuspiciousElement> onElementTap;

  const _LoginPageRenderer({
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedElements,
    required this.onElementTap,
  });

  SuspiciousElement? _el(String id) =>
      scenario.suspiciousElements.where((e) => e.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    final brandColor = s.brandColorParsed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: revealed
                ? s.isPhishing
                    ? const Color(0xFFFF4444).withAlpha(150)
                    : const Color(0xFF00FF88).withAlpha(150)
                : Colors.white.withAlpha(20),
            width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 20,
              spreadRadius: -4)
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Icon(
              revealed && s.isPhishing ? Icons.lock_open : Icons.lock,
              size: 13,
              color: revealed && s.isPhishing
                  ? const Color(0xFFFF4444)
                  : const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Builder(builder: (_) {
                final el = _el('cta_url') ?? _el('page_url');
                final w = Text(
                  s.ctaUrl,
                  style: GoogleFonts.jetBrainsMono(
                      color: revealed && s.isPhishing
                          ? const Color(0xFFFF4444)
                          : const Color(0xFF333333),
                      fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                );
                if (el != null) {
                  return _TappableSpan(
                    element: el,
                    inspectMode: inspectMode,
                    isTapped: tappedElements.contains(el.id),
                    revealed: revealed,
                    onTap: () => onElementTap(el),
                    child: w,
                  );
                }
                return w;
              }),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(children: [
            _BrandLogo(
              scenario: s,
              size: 56,
              inspectMode: inspectMode,
              isTapped: tappedElements.contains('logo'),
              onTap: () {
                final el = _el('logo');
                if (el != null) onElementTap(el);
              },
            ),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final el = _el('logo') ?? _el('header');
              final w = Text(
                s.logoAltText,
                style: GoogleFonts.syne(
                    color: brandColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              );
              if (el != null) {
                return _TappableSpan(
                  element: el,
                  inspectMode: inspectMode,
                  isTapped: tappedElements.contains(el.id),
                  revealed: revealed,
                  onTap: () => onElementTap(el),
                  child: w,
                );
              }
              return w;
            }),
            const SizedBox(height: 4),
            Text(
              s.pageTitle ?? '${s.brand} — Iniciar Sessão',
              style: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ...s.formFields.map((field) {
              final isPasswordField = field.toLowerCase().contains('senha') ||
                  field.toLowerCase().contains('password') ||
                  field.toLowerCase().contains('confirmar');
              final isSuspect = s.formFields.length > 2;
              final el = _el('form_field');
              Widget fieldWidget = Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: revealed && s.isPhishing && isSuspect
                          ? const Color(0xFFFF4444).withAlpha(100)
                          : const Color(0xFFDDDDDD)),
                ),
                child: Row(children: [
                  Icon(
                    isPasswordField ? Icons.lock_outline : Icons.person_outline,
                    size: 16,
                    color: Colors.black38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(field,
                        style: GoogleFonts.inter(
                            color: Colors.black38, fontSize: 13)),
                  ),
                ]),
              );
              if (el != null && inspectMode) {
                return _TappableSpan(
                  element: el,
                  inspectMode: inspectMode,
                  isTapped: tappedElements.contains(el.id),
                  revealed: revealed,
                  onTap: () => onElementTap(el),
                  child: fieldWidget,
                );
              }
              return fieldWidget;
            }),
            Builder(builder: (_) {
              final el = _el('cta');
              final btn = Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: revealed && s.isPhishing
                      ? const Color(0xFFFF4444)
                      : brandColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    s.ctaText.isNotEmpty ? s.ctaText : 'Iniciar Sessão',
                    style: GoogleFonts.syne(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              );
              if (el != null) {
                return _TappableSpan(
                  element: el,
                  inspectMode: inspectMode,
                  isTapped: tappedElements.contains(el.id),
                  revealed: revealed,
                  onTap: () => onElementTap(el),
                  child: btn,
                );
              }
              return btn;
            }),
            if (s.isPhishing && revealed) ...[
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: Color(0xFFFF4444)),
                const SizedBox(width: 6),
                Text(
                  'Página FALSA — dados seriam roubados',
                  style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFFF4444), fontSize: 10),
                ),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _UrlRenderer extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final Set<String> tappedElements;
  final ValueChanged<SuspiciousElement> onElementTap;

  const _UrlRenderer({
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedElements,
    required this.onElementTap,
  });

  SuspiciousElement? _el(String id) =>
      scenario.suspiciousElements.where((e) => e.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    final urlColor = revealed
        ? s.isPhishing
            ? const Color(0xFFFF4444)
            : const Color(0xFF00FF88)
        : const Color(0xFF60A5FA);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: revealed && s.isPhishing
                ? const Color(0xFFFF4444).withAlpha(100)
                : Colors.white.withAlpha(20)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF161E2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border:
                Border(bottom: BorderSide(color: Colors.white.withAlpha(15))),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1520),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(children: [
                  Text('🔐 ',
                      style: TextStyle(
                          fontSize: 10,
                          color: revealed && s.isPhishing
                              ? const Color(0xFFFF4444)
                              : Colors.white38)),
                  Text(s.brand,
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 10)),
                  const SizedBox(width: 6),
                  const Icon(Icons.close, size: 10, color: Colors.white38),
                ]),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.add, size: 14, color: Colors.white38),
            ]),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final el = _el('cta_url');
              final urlBar = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: revealed && s.isPhishing
                          ? const Color(0xFFFF4444).withAlpha(80)
                          : Colors.white.withAlpha(15)),
                ),
                child: Row(children: [
                  Icon(
                    revealed && s.isPhishing ? Icons.lock_open : Icons.lock,
                    size: 12,
                    color: urlColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(s.ctaUrl,
                        style: GoogleFonts.jetBrainsMono(
                            color: urlColor, fontSize: 10),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.refresh, size: 12, color: Colors.white38),
                ]),
              );
              if (el != null) {
                return _TappableSpan(
                  element: el,
                  inspectMode: inspectMode,
                  isTapped: tappedElements.contains(el.id),
                  revealed: revealed,
                  onTap: () => onElementTap(el),
                  child: urlBar,
                );
              }
              return urlBar;
            }),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _BrandLogo(scenario: s, size: 32),
              const SizedBox(width: 10),
              Text(s.brand,
                  style: GoogleFonts.syne(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),
            Text(s.subject,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(s.body,
                style: GoogleFonts.inter(
                    color: Colors.white60, fontSize: 12, height: 1.5)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: revealed && s.isPhishing
                    ? const Color(0xFFFF4444).withAlpha(20)
                    : s.brandColorParsed.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: revealed && s.isPhishing
                        ? const Color(0xFFFF4444).withAlpha(60)
                        : s.brandColorParsed.withAlpha(60)),
              ),
              child: Text(s.ctaText,
                  style: GoogleFonts.inter(
                      color: revealed && s.isPhishing
                          ? const Color(0xFFFF6B6B)
                          : s.brandColorParsed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class ForensicDetailScreen extends StatelessWidget {
  final ForensicCase fc;
  const ForensicDetailScreen({super.key, required this.fc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A10),
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1520),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.white.withAlpha(20)),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4444).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFFF4444).withAlpha(60)),
                        ),
                        child: Text('🔬 ANÁLISE FORENSE',
                            style: GoogleFonts.jetBrainsMono(
                                color: const Color(0xFFFF4444),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF161E2E), Color(0xFF0D1520)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: const Color(0xFFFF4444).withAlpha(40)),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(fc.emoji,
                                  style: const TextStyle(fontSize: 36)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(fc.title,
                                          style: GoogleFonts.syne(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800)),
                                      Text('${fc.year} • ${fc.country}',
                                          style: GoogleFonts.inter(
                                              color: Colors.white38,
                                              fontSize: 12)),
                                    ]),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            Text(fc.summary,
                                style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.6)),
                            const SizedBox(height: 14),
                            Wrap(spacing: 8, runSpacing: 6, children: [
                              _Tag(fc.attackType, const Color(0xFFFF4444)),
                              _Tag(fc.target.split(' ')[0],
                                  const Color(0xFF3B82F6)),
                              _Tag(fc.year, const Color(0xFFFFCC00)),
                            ]),
                          ]),
                    ),
                    const SizedBox(height: 20),
                    _InfoBlock(
                        icon: '🎭',
                        title: 'Ator da Ameaça',
                        content: fc.threat_actor,
                        color: const Color(0xFFFF6B35)),
                    const SizedBox(height: 12),
                    _InfoBlock(
                        icon: '🎯',
                        title: 'Vetor de Ataque',
                        content: '${fc.attackVector}\n\n${fc.howItWorked}',
                        color: const Color(0xFFFF4444)),
                    const SizedBox(height: 12),
                    _AnalysisCard(
                        title: '🚩 Sinais que Deveriam ter Alertado',
                        items: fc.redFlags,
                        color: const Color(0xFFFFCC00)),
                    const SizedBox(height: 12),
                    _InfoBlock(
                        icon: '⚡',
                        title: 'Resultado e Impacto',
                        content:
                            '${fc.outcome}\n\n💰 Impacto financeiro: ${fc.financialImpact}',
                        color: const Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                    _AnalysisCard(
                        title: '📚 Lições Aprendidas',
                        items: fc.lessons,
                        color: const Color(0xFF00FF88)),
                    const SizedBox(height: 40),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _GridBackground extends StatelessWidget {
  final AnimationController controller;
  const _GridBackground({required this.controller});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (_, __) => CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _GridPainter(controller.value),
        ),
      );
}

class _GridPainter extends CustomPainter {
  final double t;
  _GridPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF060A10));
    final p = Paint()..color = const Color(0xFF00FF88).withAlpha(8);
    const sp = 40.0;
    final ox = (t * sp) % sp;
    final oy = (t * sp * 0.6) % sp;
    for (var x = -sp + ox; x < size.width + sp; x += sp) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = -sp + oy; y < size.height + sp; y += sp) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) => o.t != t;
}

class _SectionHeader extends StatelessWidget {
  final String icon, title, subtitle;
  const _SectionHeader(
      {required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.syne(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF00FF88).withAlpha(15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF00FF88).withAlpha(40)),
          ),
          child: Text(subtitle,
              style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF00FF88),
                  fontSize: 9,
                  letterSpacing: 0.5)),
        ),
      ]);
}

class _TypeCard extends StatelessWidget {
  final String icon, label, type;
  final Color color;
  final VoidCallback onTap;
  const _TypeCard({
    required this.icon,
    required this.label,
    required this.type,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.syne(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.play_arrow, color: color, size: 16),
          ]),
        ),
      );
}

class _DiffChip extends StatelessWidget {
  final String label, emoji;
  final VoidCallback onTap;
  const _DiffChip(
      {required this.label, required this.emoji, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1520),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 2),
              Text(label,
                  style:
                      GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
            ]),
          ),
        ),
      );
}

class _ForensicCard extends StatelessWidget {
  final ForensicCase fc;
  final VoidCallback onTap;
  const _ForensicCard({required this.fc, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1520),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4444).withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(fc.emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fc.title,
                        style: GoogleFonts.syne(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${fc.year} • ${fc.attackType}',
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(fc.financialImpact,
                        style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFFFF4444), fontSize: 10)),
                  ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ]),
        ),
      );
}

class _ChallengeHeader extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final int tappedCount;
  final VoidCallback onClose;
  final VoidCallback onToggleInspect;

  const _ChallengeHeader({
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedCount,
    required this.onClose,
    required this.onToggleInspect,
  });

  String get _diffEmoji => scenario.difficulty == 'hard'
      ? '🔴'
      : scenario.difficulty == 'medium'
          ? '🟡'
          : '🟢';

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E14),
          border: Border(bottom: BorderSide(color: Colors.white.withAlpha(15))),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1520),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Icon(revealed ? Icons.check : Icons.close,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${scenario.typeIcon} ${scenario.typeLabel}',
                style: GoogleFonts.syne(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                '${scenario.brand} • $_diffEmoji ${scenario.difficultyLabel}',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
            ]),
          ),
          if (!revealed)
            GestureDetector(
              onTap: onToggleInspect,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: inspectMode
                      ? const Color(0xFFFFCC00).withAlpha(25)
                      : const Color(0xFF0D1520),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: inspectMode
                          ? const Color(0xFFFFCC00).withAlpha(80)
                          : Colors.white.withAlpha(20)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    inspectMode ? '🔍' : '👁️',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    inspectMode
                        ? (tappedCount > 0 ? '$tappedCount' : 'ON')
                        : 'Inspecionar',
                    style: GoogleFonts.jetBrainsMono(
                        color: inspectMode
                            ? const Color(0xFFFFCC00)
                            : Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ),
        ]),
      );
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DecisionButton(
      {required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.syne(
                    color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  const _AnalysisCard(
      {required this.title, required this.items, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.syne(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...items.map((flag) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 5, right: 8),
                        decoration:
                            BoxDecoration(shape: BoxShape.circle, color: color),
                      ),
                      Expanded(
                        child: Text(flag,
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.4)),
                      ),
                    ]),
              )),
        ]),
      );
}

class _InfoBlock extends StatelessWidget {
  final String icon, title, content;
  final Color color;
  const _InfoBlock(
      {required this.icon,
      required this.title,
      required this.content,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1520),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(title,
                style: GoogleFonts.syne(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3)),
          ]),
          const SizedBox(height: 8),
          Text(content,
              style: GoogleFonts.inter(
                  color: Colors.white60, fontSize: 12, height: 1.5)),
        ]),
      );
}

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatChip(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.syne(
                  color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
        ],
      );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(label,
            style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
      );
}

class _LoadingView extends StatelessWidget {
  final String? type;
  const _LoadingView({this.type});

  static const _msgs = [
    'A criar cenário ultra-realista com IA...',
    'A gerar táticas de engenharia social...',
    'A inserir sinais forenses...',
    'A calibrar nível de dificuldade...',
    'A construir layout visual...',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withAlpha(15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00FF88).withAlpha(60)),
            ),
            child: const Center(
                child: CircularProgressIndicator(
              color: Color(0xFF00FF88),
              strokeWidth: 2,
            )),
          ),
          const SizedBox(height: 24),
          Text('Groq AI a trabalhar...',
              style: GoogleFonts.syne(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(_msgs[DateTime.now().second % _msgs.length],
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Erro ao gerar simulação',
                style: GoogleFonts.syne(
                    color: const Color(0xFFFF4444),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(error,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: BorderSide(color: Colors.white.withAlpha(30)),
                  ),
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF88),
                    foregroundColor: Colors.black,
                  ),
                  child: Text('Tentar',
                      style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      );
}
