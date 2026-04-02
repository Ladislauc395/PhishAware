import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/app_models.dart';
import 'api_service.dart';
import 'groq_service.dart' hide ForensicCase, AiScenario, SuspiciousElement;
import 'realistic_sim_renderer.dart';
import 'avatar_call_sim_screen.dart';

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
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
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
        transitionDuration: const Duration(milliseconds: 300),
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
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  void _openAdvancedSim(String simType) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => AdvancedSimScreen(simType: simType),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
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
                  _buildHeroCard(),
                  _buildTypeSection(),
                  _buildDiffSection(),
                  _buildAdvancedSimsSection(),
                  _buildAvatarCallSection(),
                  _buildForensicSection(),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pct = _sessionTotal > 0
        ? (_sessionCorrect / _sessionTotal * 100).round()
        : 0;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1520),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(18)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF00FF88),
                        size: 28,
                      ),
                      Positioned(
                        bottom: 10,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00FF88),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF060A10),
                            size: 7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PhishAware',
                        style: GoogleFonts.syne(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF00FF88),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Simulações por IA · Groq',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_sessionTotal > 0) ...[
              const SizedBox(height: 20),
              _buildSessionBar(pct),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionBar(int pct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _MiniStat('$_sessionTotal', 'Jogadas', const Color(0xFF3B82F6)),
            _divider(),
            _MiniStat('$_sessionCorrect', 'Acertos', const Color(0xFF00FF88)),
            _divider(),
            _MiniStat(
              '${_sessionTotal - _sessionCorrect}',
              'Erros',
              const Color(0xFFFF4444),
            ),
            _divider(),
            _MiniStat(
              '$pct%',
              'Taxa',
              pct >= 70 ? const Color(0xFF00FF88) : const Color(0xFFFFCC00),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 28,
    color: Colors.white.withAlpha(12),
    margin: const EdgeInsets.symmetric(horizontal: 12),
  );

  Widget _buildHeroCard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: GestureDetector(
          onTap: () => _openChallenge(),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1520),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withAlpha(14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withAlpha(12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00FF88).withAlpha(35),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF00FF88),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulação Aleatória',
                        style: GoogleFonts.syne(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A IA gera um cenário único',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withAlpha(15)),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSection() {
    final types = [
      _SimTypeData(
        Icons.email_outlined,
        'Email',
        const Color(0xFF00FF88),
        'email',
      ),
      _SimTypeData(Icons.sms_outlined, 'SMS', const Color(0xFFFFCC00), 'sms'),
      _SimTypeData(
        Icons.chat_outlined,
        'WhatsApp',
        const Color(0xFF25D366),
        'whatsapp',
      ),
      _SimTypeData(
        Icons.lock_outline,
        'Login',
        const Color(0xFFFF6B35),
        'login_page',
      ),
      _SimTypeData(Icons.link_rounded, 'URL', const Color(0xFF3B82F6), 'url'),
      _SimTypeData(
        Icons.shuffle_rounded,
        'Aleatório',
        const Color(0xFFB06EFF),
        '',
      ),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(Icons.tune_rounded, 'Por Tipo'),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: types.length,
              itemBuilder: (_, i) {
                final t = types[i];
                return GestureDetector(
                  onTap: () =>
                      _openChallenge(type: t.type.isEmpty ? null : t.type),
                  child: _TypePill(data: t),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(Icons.signal_cellular_alt, 'Por Dificuldade'),
            const SizedBox(height: 14),
            Row(
              children: [
                _DiffPill(
                  icon: Icons.signal_cellular_0_bar,
                  label: 'Fácil',
                  color: const Color(0xFF00FF88),
                  onTap: () => _openChallenge(difficulty: 'easy'),
                ),
                const SizedBox(width: 10),
                _DiffPill(
                  icon: Icons.signal_cellular_alt_2_bar,
                  label: 'Médio',
                  color: const Color(0xFFFFCC00),
                  onTap: () => _openChallenge(difficulty: 'medium'),
                ),
                const SizedBox(width: 10),
                _DiffPill(
                  icon: Icons.signal_cellular_alt,
                  label: 'Difícil',
                  color: const Color(0xFFFF4444),
                  onTap: () => _openChallenge(difficulty: 'hard'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSimsSection() {
    final sims = [
      _AdvancedSimData(
        icon: Icons.phone_in_talk_outlined,
        label: 'Vishing',
        subtitle: 'Chamada com voz clonada',
        color: const Color(0xFFFF4444),
        type: 'vishing',
      ),
      _AdvancedSimData(
        icon: Icons.search_rounded,
        label: 'Search Phishing',
        subtitle: 'Resultados falsos',
        color: const Color(0xFF3B82F6),
        type: 'search',
      ),
      _AdvancedSimData(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Quishing',
        subtitle: 'QR Code malicioso',
        color: const Color(0xFFFFCC00),
        type: 'quishing',
      ),
      _AdvancedSimData(
        icon: Icons.dns_outlined,
        label: 'Pharming',
        subtitle: 'DNS envenenado',
        color: const Color(0xFFB06EFF),
        type: 'pharming',
      ),
      _AdvancedSimData(
        icon: Icons.support_agent_outlined,
        label: 'Angler',
        subtitle: 'Suporte falso',
        color: const Color(0xFF25D366),
        type: 'angler',
      ),
      _AdvancedSimData(
        icon: Icons.account_balance_outlined,
        label: 'Whaling',
        subtitle: 'Ataque a executivos',
        color: const Color(0xFFFF6B35),
        type: 'whaling',
      ),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SectionLabel(Icons.hub_outlined, 'Simulações Avançadas'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withAlpha(18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withAlpha(50),
                    ),
                  ),
                  child: Text(
                    'Novos vetores',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF3B82F6),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Ataques sofisticados além do e‑mail',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
              ),
              itemCount: sims.length,
              itemBuilder: (_, i) => _AdvancedSimCard(
                data: sims[i],
                onTap: () => _openAdvancedSim(sims[i].type),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCallSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(Icons.phone_in_talk_outlined, 'Chamada Suspeita'),
            const SizedBox(height: 6),
            Text(
              'Treina a resistência a ataques de vishing ao vivo',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 14),
            AvatarCallSimCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildForensicSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(Icons.biotech_outlined, 'Análise Forense'),
            const SizedBox(height: 6),
            Text(
              'Ataques documentados que mudaram a cibersegurança',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ...kForensicCases.map(
              (fc) => _ForensicCard(fc: fc, onTap: () => _openForensic(fc)),
            ),
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
  _ChallengeResult({
    required this.correct,
    required this.xpEarned,
    this.scenario,
  });
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
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _revealAnim = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.02, 0),
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeCtrl);
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
      final data = await ApiService.generateAiSimulation(
        type: widget.type,
        difficulty: widget.difficulty,
      );
      final s = AiScenario.fromJson(data);
      if (mounted)
        setState(() {
          _scenario = s;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
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
    final color = el.isSuspicious
        ? const Color(0xFFFF4444)
        : const Color(0xFF00FF88);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0D1520),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withAlpha(80)),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
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
                    el.isSuspicious ? 'Elemento Suspeito' : 'Elemento Normal',
                    style: GoogleFonts.syne(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    el.hint,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        const Duration(milliseconds: 100),
        HapticFeedback.lightImpact,
      );
    }
  }

  void _nextRound() => Navigator.pop(
    context,
    _ChallengeResult(
      correct: _userAnswer == (_scenario?.isPhishing ?? true),
      xpEarned: _calcXp(),
      scenario: _scenario,
    ),
  );

  int _calcXp() {
    if (_scenario == null || _userAnswer == null) return 0;
    if (_userAnswer != _scenario!.isPhishing) return 0;
    final baseXp = switch (_scenario!.difficulty) {
      'hard' => 30,
      'medium' => 20,
      _ => 10,
    };
    return baseXp + (_tappedElements.length * 2).clamp(0, 10);
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
    return Column(
      children: [
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualRenderer(AiScenario s) => RealisticSimRenderer(
    scenario: s,
    revealed: _revealed,
    inspectMode: _inspectMode,
    tappedElements: _tappedElements,
    onElementTap: _onElementTapped,
  );

  Widget _buildDecisionSection(AiScenario s) {
    return Column(
      children: [
        if (_tappedElements.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC00).withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFCC00).withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFFFCC00),
                  size: 13,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_tappedElements.length} elemento(s) inspecionado(s)',
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFFFFCC00),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'O que achas?',
          style: GoogleFonts.syne(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Toca nos elementos suspeitos • Depois decide',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _DecisionButton(
                label: 'É Phishing',
                icon: Icons.phishing_rounded,
                color: const Color(0xFFFF4444),
                onTap: () => _answer(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DecisionButton(
                label: 'É Legítimo',
                icon: Icons.verified_outlined,
                color: const Color(0xFF00FF88),
                onTap: () => _answer(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisPanel(AiScenario s) {
    final userWasCorrect = _userAnswer == s.isPhishing;
    final xp = _calcXp();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  : const Color(0xFFFF4444).withAlpha(60),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: userWasCorrect
                      ? const Color(0xFF00FF88).withAlpha(20)
                      : const Color(0xFFFF4444).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  userWasCorrect ? Icons.check_rounded : Icons.close_rounded,
                  color: userWasCorrect
                      ? const Color(0xFF00FF88)
                      : const Color(0xFFFF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userWasCorrect ? 'Correto!' : 'Não desta vez',
                      style: GoogleFonts.syne(
                        color: userWasCorrect
                            ? const Color(0xFF00FF88)
                            : const Color(0xFFFF4444),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      s.isPhishing
                          ? 'Era um ataque de phishing'
                          : 'Era uma mensagem legítima',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (userWasCorrect && xp > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC00).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFCC00).withAlpha(60),
                    ),
                  ),
                  child: Text(
                    '+$xp XP',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFFFCC00),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
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
            title: 'Sinais de Phishing',
            icon: Icons.flag_rounded,
            items: s.redFlags,
            color: const Color(0xFFFF4444),
          ),
          const SizedBox(height: 12),
        ],
        if (!s.isPhishing && s.greenFlags.isNotEmpty) ...[
          _AnalysisCard(
            title: 'Indicadores de Confiança',
            icon: Icons.verified_outlined,
            items: s.greenFlags,
            color: const Color(0xFF00FF88),
          ),
          const SizedBox(height: 12),
        ],
        _InfoBlock(
          icon: Icons.manage_search_rounded,
          title: 'Análise Técnica',
          content: s.explanation,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 12),
        if (s.isPhishing &&
            s.attackTechnique.isNotEmpty &&
            s.attackTechnique != 'N/A') ...[
          _InfoBlock(
            icon: Icons.bolt_rounded,
            title: 'Técnica de Ataque',
            content: s.attackTechnique,
            color: const Color(0xFFFF6B35),
          ),
          const SizedBox(height: 12),
        ],
        if (s.isPhishing &&
            s.potentialDamage.isNotEmpty &&
            s.potentialDamage != 'Não aplicável') ...[
          _InfoBlock(
            icon: Icons.warning_amber_rounded,
            title: 'Impacto Potencial',
            content: s.potentialDamage,
            color: const Color(0xFFFF4444),
          ),
          const SizedBox(height: 12),
        ],
        if (s.realWorldReference.isNotEmpty) ...[
          _InfoBlock(
            icon: Icons.newspaper_rounded,
            title: 'Caso Real Similar',
            content: s.realWorldReference,
            color: const Color(0xFFFFCC00),
          ),
          const SizedBox(height: 12),
        ],
        if (s.forensicTip.isNotEmpty) ...[
          _InfoBlock(
            icon: Icons.shield_outlined,
            title: 'Dica Forense',
            content: s.forensicTip,
            color: const Color(0xFF00FF88),
          ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Próxima Simulação',
              style: GoogleFonts.syne(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
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
    child: Row(
      children: [
        const Icon(
          Icons.touch_app_outlined,
          color: Color(0xFFFFCC00),
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Modo inspeção ativo — toca nos elementos ($elementCount disponíveis)',
            style: GoogleFonts.jetBrainsMono(
              color: const Color(0xFFFFCC00),
              fontSize: 10,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ElementsRevealCard extends StatelessWidget {
  final List<SuspiciousElement> elements;
  final Set<String> tapped;
  final bool isPhishing;
  const _ElementsRevealCard({
    required this.elements,
    required this.tapped,
    required this.isPhishing,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.manage_search_rounded,
                color: Color(0xFFFFCC00),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Elementos Suspeitos',
                style: GoogleFonts.syne(
                  color: const Color(0xFFFFCC00),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...suspicious.map((el) {
            final wasTapped = tapped.contains(el.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    wasTapped
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
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
                        Text(
                          el.label,
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          el.hint,
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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
  Widget build(BuildContext context) => Container(
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
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
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
                  color:
                      (s.isPhishing
                              ? const Color(0xFFFF4444)
                              : const Color(0xFF00FF88))
                          .withAlpha(30),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161E2E),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withAlpha(15)),
              ),
            ),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F57)),
                const SizedBox(width: 5),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 5),
                _dot(const Color(0xFF27C93F)),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Caixa de Entrada',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          Text(
                            s.senderName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Builder(
                            builder: (_) {
                              final el = _el('sender');
                              final widget = Text(
                                s.senderAddress,
                                style: GoogleFonts.jetBrainsMono(
                                  color: revealed && s.isPhishing
                                      ? const Color(0xFFFF6B6B)
                                      : Colors.white54,
                                  fontSize: 10,
                                ),
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
                            },
                          ),
                        ],
                      ),
                    ),
                    Text(
                      s.timestamp,
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withAlpha(15)),
                const SizedBox(height: 10),
                Text(
                  s.subject,
                  style: GoogleFonts.syne(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.body,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                if (s.ctaText.isNotEmpty)
                  Builder(
                    builder: (_) {
                      final el = _el('cta_url') ?? _el('cta');
                      final btn = Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: revealed && s.isPhishing
                              ? const Color(0xFFFF4444).withAlpha(30)
                              : s.brandColorParsed.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: revealed && s.isPhishing
                                ? const Color(0xFFFF4444).withAlpha(80)
                                : s.brandColorParsed.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                s.ctaText,
                                style: GoogleFonts.inter(
                                  color: revealed && s.isPhishing
                                      ? const Color(0xFFFF6B6B)
                                      : s.brandColorParsed,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.open_in_new,
                              size: 13,
                              color: revealed && s.isPhishing
                                  ? const Color(0xFFFF6B6B)
                                  : s.brandColorParsed,
                            ),
                          ],
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
                    },
                  ),
                if (s.ctaUrl.isNotEmpty && revealed) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (s.isPhishing)
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: Color(0xFFFF4444),
                        ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s.ctaUrl,
                          style: GoogleFonts.jetBrainsMono(
                            color: s.isPhishing
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF00FF88),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
  );
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
              : Colors.white.withAlpha(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF161E2E),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withAlpha(15)),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.signal_cellular_alt,
                  color: Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Mensagens',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '87%',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                _BrandLogo(scenario: s, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.senderName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Builder(
                        builder: (_) {
                          final el = _el('sender');
                          final w = Text(
                            s.phoneNumber ?? s.senderAddress,
                            style: GoogleFonts.jetBrainsMono(
                              color: revealed && s.isPhishing
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.white38,
                              fontSize: 10,
                            ),
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
                        },
                      ),
                    ],
                  ),
                ),
                Text(
                  s.timestamp,
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
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
                    Text(
                      s.body,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    if (s.ctaUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (_) {
                          final el = _el('cta_url');
                          final w = Text(
                            s.ctaUrl,
                            style: GoogleFonts.jetBrainsMono(
                              color: revealed && s.isPhishing
                                  ? const Color(0xFFFF6B6B)
                                  : const Color(0xFF60A5FA),
                              fontSize: 11,
                            ),
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
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
              : Colors.white.withAlpha(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2C34),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
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
                      Text(
                        s.senderName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Builder(
                        builder: (_) {
                          final el = _el('sender');
                          final w = Text(
                            s.phoneNumber ?? s.senderAddress,
                            style: GoogleFonts.inter(
                              color: revealed && s.isPhishing
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.white54,
                              fontSize: 11,
                            ),
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
                        },
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.videocam, color: waGreen, size: 20),
                const SizedBox(width: 16),
                const Icon(Icons.call, color: waGreen, size: 18),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0B141A),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF182229),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'HOJE',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    decoration: const BoxDecoration(
                      color: waBubble,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(2),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.senderName,
                          style: GoogleFonts.inter(
                            color: waGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.body,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        if (s.ctaUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Builder(
                            builder: (_) {
                              final el = _el('cta_url');
                              final preview = Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF182229),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: revealed && s.isPhishing
                                        ? const Color(0xFFFF4444).withAlpha(80)
                                        : waGreen.withAlpha(40),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.link,
                                          size: 12,
                                          color: revealed && s.isPhishing
                                              ? const Color(0xFFFF4444)
                                              : waGreen,
                                        ),
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
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      s.ctaUrl,
                                      style: GoogleFonts.jetBrainsMono(
                                        color: revealed && s.isPhishing
                                            ? const Color(0xFFFF6B6B)
                                            : Colors.white38,
                                        fontSize: 9,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
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
                            },
                          ),
                        ],
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                s.timestamp,
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.done_all,
                                size: 14,
                                color: waGreen,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2C34),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3942),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Mensagem',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: waGreen,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
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
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  revealed && s.isPhishing ? Icons.lock_open : Icons.lock,
                  size: 13,
                  color: revealed && s.isPhishing
                      ? const Color(0xFFFF4444)
                      : const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Builder(
                    builder: (_) {
                      final el = _el('cta_url') ?? _el('page_url');
                      final w = Text(
                        s.ctaUrl,
                        style: GoogleFonts.jetBrainsMono(
                          color: revealed && s.isPhishing
                              ? const Color(0xFFFF4444)
                              : const Color(0xFF333333),
                          fontSize: 10,
                        ),
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
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
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
                Builder(
                  builder: (_) {
                    final el = _el('logo') ?? _el('header');
                    final w = Text(
                      s.logoAltText,
                      style: GoogleFonts.syne(
                        color: brandColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
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
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  s.pageTitle ?? '${s.brand} — Iniciar Sessão',
                  style: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ...s.formFields.map((field) {
                  final isPasswordField =
                      field.toLowerCase().contains('senha') ||
                      field.toLowerCase().contains('password') ||
                      field.toLowerCase().contains('confirmar');
                  final isSuspect = s.formFields.length > 2;
                  final el = _el('form_field');
                  Widget fieldWidget = Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: revealed && s.isPhishing && isSuspect
                            ? const Color(0xFFFF4444).withAlpha(100)
                            : const Color(0xFFDDDDDD),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPasswordField
                              ? Icons.lock_outline
                              : Icons.person_outline,
                          size: 16,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            field,
                            style: GoogleFonts.inter(
                              color: Colors.black38,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                Builder(
                  builder: (_) {
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
                            fontWeight: FontWeight.w700,
                          ),
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
                  },
                ),
                if (s.isPhishing && revealed) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Color(0xFFFF4444),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Página FALSA — dados seriam roubados',
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFFFF4444),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
              : Colors.white.withAlpha(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF161E2E),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withAlpha(15)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1520),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 10,
                            color: revealed && s.isPhishing
                                ? const Color(0xFFFF4444)
                                : Colors.white38,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              s.brand,
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.close,
                            size: 10,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.add, size: 14, color: Colors.white38),
                  ],
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (_) {
                    final el = _el('cta_url');
                    final urlBar = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0E14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: revealed && s.isPhishing
                              ? const Color(0xFFFF4444).withAlpha(80)
                              : Colors.white.withAlpha(15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            revealed && s.isPhishing
                                ? Icons.lock_open
                                : Icons.lock,
                            size: 12,
                            color: urlColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s.ctaUrl,
                              style: GoogleFonts.jetBrainsMono(
                                color: urlColor,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.refresh,
                            size: 12,
                            color: Colors.white38,
                          ),
                        ],
                      ),
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
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _BrandLogo(scenario: s, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.brand,
                        style: GoogleFonts.syne(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  s.subject,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  s.body,
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: revealed && s.isPhishing
                        ? const Color(0xFFFF4444).withAlpha(20)
                        : s.brandColorParsed.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: revealed && s.isPhishing
                          ? const Color(0xFFFF4444).withAlpha(60)
                          : s.brandColorParsed.withAlpha(60),
                    ),
                  ),
                  child: Text(
                    s.ctaText,
                    style: GoogleFonts.inter(
                      color: revealed && s.isPhishing
                          ? const Color(0xFFFF6B6B)
                          : s.brandColorParsed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class ForensicDetailScreen extends StatelessWidget {
  final ForensicCase fc;
  const ForensicDetailScreen({super.key, required this.fc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A10),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1520),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withAlpha(20),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4444).withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFF4444).withAlpha(60),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.biotech_outlined,
                                color: Color(0xFFFF4444),
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'ANÁLISE FORENSE',
                                style: GoogleFonts.jetBrainsMono(
                                  color: const Color(0xFFFF4444),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                          color: const Color(0xFFFF4444).withAlpha(40),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4444).withAlpha(15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFF4444,
                                    ).withAlpha(50),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.policy_outlined,
                                  color: Color(0xFFFF4444),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fc.title,
                                      style: GoogleFonts.syne(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '${fc.year} • ${fc.country}',
                                      style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fc.summary,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _Tag(fc.attackType, const Color(0xFFFF4444)),
                              _Tag(
                                fc.target.split(' ')[0],
                                const Color(0xFF3B82F6),
                              ),
                              _Tag(fc.year, const Color(0xFFFFCC00)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _InfoBlock(
                      icon: Icons.groups_outlined,
                      title: 'Ator da Ameaça',
                      content: fc.threat_actor,
                      color: const Color(0xFFFF6B35),
                    ),
                    const SizedBox(height: 12),
                    _InfoBlock(
                      icon: Icons.track_changes_rounded,
                      title: 'Vetor de Ataque',
                      content: '${fc.attackVector}\n\n${fc.howItWorked}',
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 12),
                    _AnalysisCard(
                      title: 'Sinais que Deveriam ter Alertado',
                      icon: Icons.flag_rounded,
                      items: fc.redFlags,
                      color: const Color(0xFFFFCC00),
                    ),
                    const SizedBox(height: 12),
                    _InfoBlock(
                      icon: Icons.bolt_rounded,
                      title: 'Resultado e Impacto',
                      content:
                          '${fc.outcome}\n\nImpacto financeiro: ${fc.financialImpact}',
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 12),
                    _AnalysisCard(
                      title: 'Lições Aprendidas',
                      icon: Icons.school_outlined,
                      items: fc.lessons,
                      color: const Color(0xFF00FF88),
                    ),
                    const SizedBox(height: 40),
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF060A10),
    );
    final p = Paint()..color = const Color(0xFF00FF88).withAlpha(6);
    const sp = 44.0;
    final ox = (t * sp) % sp;
    final oy = (t * sp * 0.5) % sp;
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

class _SectionLabel extends StatelessWidget {
  final IconData iconData;
  final String title;
  const _SectionLabel(this.iconData, this.title);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(iconData, color: const Color(0xFF00FF88), size: 16),
      const SizedBox(width: 8),
      Text(
        title,
        style: GoogleFonts.syne(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _SimTypeData {
  final IconData icon;
  final String label, type;
  final Color color;
  const _SimTypeData(this.icon, this.label, this.color, this.type);
}

class _TypePill extends StatelessWidget {
  final _SimTypeData data;
  const _TypePill({required this.data});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1520),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withAlpha(12)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: data.color.withAlpha(15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(data.icon, color: data.color, size: 17),
        ),
        const SizedBox(height: 5),
        Text(
          data.label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class _DiffPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DiffPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4444).withAlpha(12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.policy_outlined,
              color: Color(0xFFFF4444),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fc.title,
                  style: GoogleFonts.syne(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${fc.year} • ${fc.attackType}',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  fc.financialImpact,
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFFFF4444),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
        ],
      ),
    ),
  );
}

class _GroqBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF00FF88).withAlpha(15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF00FF88).withAlpha(50)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF00FF88),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'Groq',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: const Color(0xFF00FF88),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MiniStat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.syne(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
        ),
      ],
    ),
  );
}

class _ChallengeHeader extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed, inspectMode;
  final int tappedCount;
  final VoidCallback onClose, onToggleInspect;

  const _ChallengeHeader({
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedCount,
    required this.onClose,
    required this.onToggleInspect,
  });

  Color get _diffColor => scenario.difficulty == 'hard'
      ? const Color(0xFFFF4444)
      : scenario.difficulty == 'medium'
      ? const Color(0xFFFFCC00)
      : const Color(0xFF00FF88);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0E14),
      border: Border(bottom: BorderSide(color: Colors.white.withAlpha(15))),
    ),
    child: Row(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1520),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Icon(
              revealed ? Icons.check : Icons.close,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scenario.typeLabel,
                style: GoogleFonts.syne(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Text(
                    scenario.brand,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                  const Text(
                    ' • ',
                    style: TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _diffColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    scenario.difficultyLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!revealed)
          GestureDetector(
            onTap: onToggleInspect,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: inspectMode
                    ? const Color(0xFFFFCC00).withAlpha(25)
                    : const Color(0xFF0D1520),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: inspectMode
                      ? const Color(0xFFFFCC00).withAlpha(80)
                      : Colors.white.withAlpha(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    inspectMode
                        ? Icons.search_rounded
                        : Icons.visibility_outlined,
                    color: inspectMode
                        ? const Color(0xFFFFCC00)
                        : Colors.white54,
                    size: 13,
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _DecisionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.syne(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Color color;
  const _AnalysisCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withAlpha(10),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withAlpha(40)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.syne(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map(
          (flag) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 5, right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                Expanded(
                  child: Text(
                    flag,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String title, content;
  final Color color;
  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1520),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withAlpha(15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.syne(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.inter(
            color: Colors.white60,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    ),
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
    child: Text(
      label,
      style: GoogleFonts.jetBrainsMono(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Groq AI a trabalhar...',
            style: GoogleFonts.syne(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _msgs[DateTime.now().second % _msgs.length],
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4444).withAlpha(15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF4444).withAlpha(60)),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF4444),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao gerar simulação',
            style: GoogleFonts.syne(
              color: const Color(0xFFFF4444),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
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
                  child: Text(
                    'Tentar',
                    style: GoogleFonts.syne(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AdvancedSimData {
  final IconData icon;
  final String label, subtitle, type;
  final Color color;
  const _AdvancedSimData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.type,
  });
}

class _AdvancedSimCard extends StatefulWidget {
  final _AdvancedSimData data;
  final VoidCallback onTap;
  const _AdvancedSimCard({required this.data, required this.onTap});
  @override
  State<_AdvancedSimCard> createState() => _AdvancedSimCardState();
}

class _AdvancedSimCardState extends State<_AdvancedSimCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: d.color.withAlpha(10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: d.color.withAlpha(55)),
            boxShadow: [
              BoxShadow(
                color: d.color.withAlpha(18),
                blurRadius: 14,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: d.color.withAlpha(22),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: d.color.withAlpha(70)),
                    ),
                    child: Icon(d.icon, color: d.color, size: 18),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: d.color.withAlpha(18),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'NOVO',
                      style: GoogleFonts.jetBrainsMono(
                        color: d.color,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                d.label,
                style: GoogleFonts.syne(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                d.subtitle,
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 10,
                  height: 1.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdvancedSimScreen extends StatefulWidget {
  final String simType;
  const AdvancedSimScreen({super.key, required this.simType});
  @override
  State<AdvancedSimScreen> createState() => _AdvancedSimScreenState();
}

class _AdvancedSimScreenState extends State<AdvancedSimScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _scenario;
  bool? _userAnswer;
  bool _revealed = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _revealCtrl;
  late Animation<double> _revealAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _revealAnim = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _scenario = null;
      _userAnswer = null;
      _revealed = false;
    });
    try {
      final data = await ApiService.getAdvancedSim(widget.simType);
      if (mounted) {
        setState(() {
          _scenario = data;
          _loading = false;
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  void _answer(bool isPhishing) {
    if (_revealed) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _userAnswer = isPhishing;
      _revealed = true;
    });
    _revealCtrl.forward();
    final correct = isPhishing == (_scenario?['is_phishing'] as bool? ?? true);
    if (!correct) HapticFeedback.heavyImpact();
    final xpMap = {'easy': 10, 'medium': 20, 'hard': 35};
    final diff = _scenario?['difficulty'] as String? ?? 'medium';
    final xp = correct ? (xpMap[diff] ?? 15) : 0;
    if (xp > 0) ApiService.addXp(xp, correct, widget.simType).ignore();
  }

  String get _title {
    const map = {
      'vishing': 'Vishing',
      'search': 'Search Phishing',
      'quishing': 'Quishing',
      'pharming': 'Pharming',
      'angler': 'Angler',
      'whaling': 'Whaling',
    };
    return map[widget.simType] ?? 'Simulação';
  }

  Color get _typeColor {
    const map = {
      'vishing': Color(0xFFFF4444),
      'search': Color(0xFF3B82F6),
      'quishing': Color(0xFFFFCC00),
      'pharming': Color(0xFFB06EFF),
      'angler': Color(0xFF25D366),
      'whaling': Color(0xFFFF6B35),
    };
    return map[widget.simType] ?? const Color(0xFF00FF88);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A10),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                  ? _LoadingView(type: widget.simType)
                  : _error != null
                  ? _ErrorView(error: _error!, onRetry: _load)
                  : FadeTransition(opacity: _fadeAnim, child: _buildContent()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _typeColor.withAlpha(40), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _title,
              style: GoogleFonts.syne(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _revealed ? _load : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _typeColor.withAlpha(_revealed ? 30 : 10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _typeColor.withAlpha(_revealed ? 80 : 30),
                ),
              ),
              child: Text(
                'Próximo',
                style: GoogleFonts.jetBrainsMono(
                  color: _revealed ? _typeColor : Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final s = _scenario!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          _buildScenarioCard(s),
          const SizedBox(height: 20),
          if (!_revealed)
            _buildDecision()
          else
            FadeTransition(opacity: _revealAnim, child: _buildReveal(s)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(Map<String, dynamic> s) {
    switch (widget.simType) {
      case 'vishing':
        return _VishingCard(
          scenario: s,
          revealed: _revealed,
          color: _typeColor,
          onAnswer: _answer,
        );
      case 'search':
        return _SearchCard(scenario: s, revealed: _revealed, color: _typeColor);
      case 'quishing':
        return _QuishingCard(
          scenario: s,
          revealed: _revealed,
          color: _typeColor,
        );
      case 'pharming':
        return _PharmingCard(
          scenario: s,
          revealed: _revealed,
          color: _typeColor,
        );
      case 'angler':
        return _AnglerCard(scenario: s, revealed: _revealed, color: _typeColor);
      case 'whaling':
        return _WhalingCard(
          scenario: s,
          revealed: _revealed,
          color: _typeColor,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDecision() {
    if (widget.simType == 'vishing') return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1520),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Column(
            children: [
              Text(
                'O que achas?',
                style: GoogleFonts.syne(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Analisa cuidadosamente antes de decidir',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DecisionButton(
                      label: 'É Phishing',
                      icon: Icons.phishing_rounded,
                      color: const Color(0xFFFF4444),
                      onTap: () => _answer(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DecisionButton(
                      label: 'É Legítimo',
                      icon: Icons.verified_outlined,
                      color: const Color(0xFF00FF88),
                      onTap: () => _answer(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReveal(Map<String, dynamic> s) {
    final isPhishing = s['is_phishing'] as bool? ?? true;
    final correct = _userAnswer == isPhishing;
    final redFlags = (s['red_flags'] as List?)?.cast<String>() ?? [];
    final greenFlags = (s['green_flags'] as List?)?.cast<String>() ?? [];
    final explanation = s['explanation'] as String? ?? '';
    final attackTechnique = s['attack_technique'] as String? ?? '';
    final difficulty = s['difficulty'] as String? ?? 'medium';
    final xpMap = {'easy': 10, 'medium': 20, 'hard': 35};
    final xp = correct ? (xpMap[difficulty] ?? 15) : 0;
    final userSaidPhishing = _userAnswer == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: correct
                ? const Color(0xFF00FF88).withAlpha(15)
                : const Color(0xFFFF4444).withAlpha(15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: correct
                  ? const Color(0xFF00FF88).withAlpha(60)
                  : const Color(0xFFFF4444).withAlpha(60),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: correct
                      ? const Color(0xFF00FF88).withAlpha(20)
                      : const Color(0xFFFF4444).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  correct ? Icons.check_rounded : Icons.close_rounded,
                  color: correct
                      ? const Color(0xFF00FF88)
                      : const Color(0xFFFF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      correct ? 'Correto!' : 'Não desta vez',
                      style: GoogleFonts.syne(
                        color: correct
                            ? const Color(0xFF00FF88)
                            : const Color(0xFFFF4444),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      isPhishing
                          ? 'Era um ataque de phishing'
                          : 'Era uma comunicação legítima',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (correct && xp > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC00).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFCC00).withAlpha(60),
                    ),
                  ),
                  child: Text(
                    '+$xp XP',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFFFCC00),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isPhishing
                ? const Color(0xFFFF4444).withAlpha(8)
                : const Color(0xFF00FF88).withAlpha(8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPhishing
                  ? const Color(0xFFFF4444).withAlpha(35)
                  : const Color(0xFF00FF88).withAlpha(35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isPhishing
                        ? Icons.warning_amber_rounded
                        : Icons.verified_outlined,
                    color: isPhishing
                        ? const Color(0xFFFF4444)
                        : const Color(0xFF00FF88),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPhishing
                          ? 'Porque é um ataque de phishing'
                          : 'Porque é legítimo',
                      style: GoogleFonts.syne(
                        color: isPhishing
                            ? const Color(0xFFFF4444)
                            : const Color(0xFF00FF88),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                explanation,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isPhishing && redFlags.isNotEmpty) ...[
          _AnalysisCard(
            title: 'Sinais de Alerta',
            icon: Icons.flag_rounded,
            items: redFlags,
            color: const Color(0xFFFF4444),
          ),
          const SizedBox(height: 12),
        ],
        if (!isPhishing && greenFlags.isNotEmpty) ...[
          _AnalysisCard(
            title: 'Indicadores de Confiança',
            icon: Icons.verified_outlined,
            items: greenFlags,
            color: const Color(0xFF00FF88),
          ),
          const SizedBox(height: 12),
        ],
        if (!correct) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC00).withAlpha(10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFCC00).withAlpha(40)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFFFFCC00),
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    userSaidPhishing
                        ? 'Identificaste como phishing, mas era legítimo. Nem toda a comunicação urgente é golpe — verifica sempre os indicadores de confiança.'
                        : 'Identificaste como legítimo, mas era phishing. Atenção aos sinais de alerta listados acima.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFCC00),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (isPhishing &&
            attackTechnique.isNotEmpty &&
            attackTechnique != 'N/A') ...[
          _InfoBlock(
            icon: Icons.bolt_rounded,
            title: 'Técnica Usada',
            content: attackTechnique,
            color: const Color(0xFFFF6B35),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: _typeColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Próxima Simulação',
              style: GoogleFonts.syne(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _VishCallPhase { incoming, connected, safeEnded, silentWin, exposed }

class _VishingCard extends StatefulWidget {
  final Map<String, dynamic> scenario;
  final bool revealed;
  final Color color;
  final void Function(bool isPhishing)? onAnswer;

  const _VishingCard({
    required this.scenario,
    required this.revealed,
    required this.color,
    this.onAnswer,
  });

  @override
  State<_VishingCard> createState() => _VishingCardState();
}

class _VishingCardState extends State<_VishingCard>
    with TickerProviderStateMixin {
  _VishCallPhase _phase = _VishCallPhase.incoming;
  bool _wasRejected = false;
  bool _hungUpEarly = false;

  late AnimationController _pulseCtrl;
  late AnimationController _timerCtrl;
  late AnimationController _fadeScriptCtrl;

  Timer? _exposedTimer;
  Timer? _scriptTimer;
  Timer? _micMonitorTimer;
  int _scriptLine = 0;
  bool _callerSpeaking = true;

  AudioRecorder? _audioRecorder;
  String? _recordPath;
  bool _micActive = false;
  double _voiceLevel = 0.0;
  bool _voiceDetected = false;
  int _voiceFrames = 0;
  static const int _kVoiceConfirm = 3;

  // ── Áudio ─────────────────────────────────────────────────────────────────
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _ringPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _timerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _fadeScriptCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Inicia o toque do telefone assim que o widget estiver montado
    WidgetsBinding.instance.addPostFrameCallback((_) => _playRing());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _timerCtrl.dispose();
    _fadeScriptCtrl.dispose();
    _exposedTimer?.cancel();
    _scriptTimer?.cancel();
    _stopRealMicMonitoring();
    _sfxPlayer.dispose();
    _ringPlayer.dispose();
    super.dispose();
  }

  static const double _kSpeechFloor = -32.0;
  static const double _kMinVariance = 1.8;
  static const int _kWindowSize = 6;
  final List<double> _ampWindow = [];

  // ── Métodos de áudio ───────────────────────────────────────────────────────

  Future<void> _playRing() async {
    try {
      await _ringPlayer.setReleaseMode(ReleaseMode.loop);
      await _ringPlayer.play(AssetSource('sounds/phone_ring.mp3'), volume: 0.6);
    } catch (_) {}
  }

  Future<void> _stopRing() async {
    try {
      await _ringPlayer.stop();
    } catch (_) {}
  }

  Future<void> _playSfx(String asset) async {
    try {
      await _sfxPlayer.play(AssetSource('sounds/$asset'), volume: 0.85);
    } catch (_) {}
  }

  Future<void> _startRealMicMonitoring() async {
    _audioRecorder = AudioRecorder();

    bool hasPermission = false;
    try {
      hasPermission = await _audioRecorder!.hasPermission();
    } catch (_) {}

    if (!hasPermission || !mounted) {
      _audioRecorder?.dispose();
      _audioRecorder = null;
      return;
    }

    try {
      final tmp = await getTemporaryDirectory();
      _recordPath =
          '${tmp.path}/vish_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 32000,
        ),
        path: _recordPath!,
      );
      if (mounted) setState(() => _micActive = true);
      _ampWindow.clear();
    } catch (_) {
      try {
        final tmp = await getTemporaryDirectory();
        _recordPath =
            '${tmp.path}/vish_${DateTime.now().millisecondsSinceEpoch}.pcm';
        await _audioRecorder!.start(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: _recordPath!,
        );
        if (mounted) setState(() => _micActive = true);
        _ampWindow.clear();
      } catch (_) {
        _audioRecorder?.dispose();
        _audioRecorder = null;
        return;
      }
    }

    _micMonitorTimer = Timer.periodic(const Duration(milliseconds: 150), (
      _,
    ) async {
      if (!mounted || _phase != _VishCallPhase.connected) return;
      try {
        final amp = await _audioRecorder?.getAmplitude();
        if (amp == null) return;

        final db = amp.current.clamp(-160.0, 0.0);
        final normalised = ((db + 160) / 160).clamp(0.0, 1.0);
        if (mounted) setState(() => _voiceLevel = normalised);

        _ampWindow.add(db);
        if (_ampWindow.length > _kWindowSize) _ampWindow.removeAt(0);

        if (_ampWindow.length < _kWindowSize) return;

        final aboveFloor = _ampWindow.where((v) => v > _kSpeechFloor).length;
        if (aboveFloor < (_kWindowSize - 1)) {
          _voiceFrames = 0;
          return;
        }

        final mean = _ampWindow.reduce((a, b) => a + b) / _ampWindow.length;
        final variance =
            _ampWindow
                .map((v) => (v - mean) * (v - mean))
                .reduce((a, b) => a + b) /
            _ampWindow.length;
        final stdDev = variance > 0 ? variance : 0.0;
        if (stdDev < (_kMinVariance * _kMinVariance)) {
          _voiceFrames = 0;
          return;
        }

        _voiceFrames++;
        if (_voiceFrames >= _kVoiceConfirm && !_voiceDetected) {
          _voiceDetected = true;
          _exposeVoice();
        }
      } catch (_) {}
    });
  }

  Future<void> _stopRealMicMonitoring() async {
    _micMonitorTimer?.cancel();
    _micMonitorTimer = null;
    _voiceFrames = 0;
    _ampWindow.clear();
    try {
      await _audioRecorder?.stop();
    } catch (_) {}
    if (_recordPath != null) {
      try {
        File(_recordPath!).deleteSync();
      } catch (_) {}
      _recordPath = null;
    }
    _audioRecorder?.dispose();
    _audioRecorder = null;
    if (mounted)
      setState(() {
        _micActive = false;
        _voiceLevel = 0.0;
      });
  }

  void _exposeVoice() {
    if (_phase != _VishCallPhase.connected) return;
    HapticFeedback.heavyImpact();
    _exposedTimer?.cancel();
    _scriptTimer?.cancel();
    _timerCtrl.stop();
    _stopRealMicMonitoring();
    setState(() => _phase = _VishCallPhase.exposed);
    widget.onAnswer?.call(true);
  }

  void _rejectCall() {
    HapticFeedback.mediumImpact();
    _stopRing();
    _playSfx('success.mp3');
    setState(() {
      _wasRejected = true;
      _phase = _VishCallPhase.safeEnded;
    });
    widget.onAnswer?.call(true);
  }

  void _answerCall() {
    HapticFeedback.mediumImpact();
    _stopRing();
    _playSfx('call_connect.mp3');
    setState(() {
      _phase = _VishCallPhase.connected;
      _callerSpeaking = true;
    });
    _timerCtrl.forward();
    _startRealMicMonitoring();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && _phase == _VishCallPhase.connected) {
        setState(() => _callerSpeaking = false);
        _fadeScriptCtrl.forward();
        _advanceScript();
      }
    });

    _exposedTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _phase == _VishCallPhase.connected) {
        HapticFeedback.mediumImpact();
        _stopRealMicMonitoring();
        setState(() => _phase = _VishCallPhase.silentWin);
        widget.onAnswer?.call(true);
      }
    });
  }

  void _hangUp() {
    HapticFeedback.mediumImpact();
    _stopRing();
    _playSfx('success.mp3');
    _exposedTimer?.cancel();
    _scriptTimer?.cancel();
    _timerCtrl.stop();
    _stopRealMicMonitoring();
    setState(() {
      _hungUpEarly = true;
      _phase = _VishCallPhase.safeEnded;
    });
    widget.onAnswer?.call(true);
  }

  void _advanceScript() {
    final lines =
        (widget.scenario['script_lines'] as List?)?.cast<String>() ?? [];
    if (!mounted || _phase != _VishCallPhase.connected) return;
    if (_scriptLine < lines.length) {
      setState(() => _scriptLine++);
      _scriptTimer = Timer(const Duration(milliseconds: 1600), _advanceScript);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _VishCallPhase.incoming:
        return _buildIncomingUI();
      case _VishCallPhase.connected:
        return _buildConnectedUI();
      case _VishCallPhase.safeEnded:
        return _buildSafeEndedUI();
      case _VishCallPhase.silentWin:
        return _buildSilentWinUI();
      case _VishCallPhase.exposed:
        return _buildExposedUI();
    }
  }

  Widget _buildIncomingUI() {
    final s = widget.scenario;
    final callerName = s['caller_name'] as String? ?? 'Desconhecido';
    final callerRole = s['caller_role'] as String? ?? '';
    final phone = s['phone_number'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1A12), Color(0xFF060A10), Color(0xFF0A0D18)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: widget.color.withAlpha(40)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: widget.color.withAlpha(18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.color.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withOpacity(
                        0.5 + _pulseCtrl.value * 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Chamada recebida',
                  style: GoogleFonts.inter(
                    color: widget.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) => Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110 + _pulseCtrl.value * 18,
                  height: 110 + _pulseCtrl.value * 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity(
                        0.08 * (1 - _pulseCtrl.value),
                      ),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 90 + _pulseCtrl.value * 10,
                  height: 90 + _pulseCtrl.value * 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity(
                        0.15 * (1 - _pulseCtrl.value),
                      ),
                      width: 1.5,
                    ),
                  ),
                ),
                child!,
              ],
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withAlpha(22),
                border: Border.all(color: widget.color.withAlpha(90), width: 2),
              ),
              child: Center(
                child: Text(
                  callerName.isNotEmpty ? callerName[0].toUpperCase() : '?',
                  style: GoogleFonts.syne(
                    color: widget.color,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            callerName,
            style: GoogleFonts.syne(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          if (callerRole.isNotEmpty)
            Text(
              callerRole,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              phone,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PhoneActionButton(
                icon: Icons.call_end,
                label: 'Rejeitar',
                color: const Color(0xFFFF4444),
                onTap: _rejectCall,
              ),
              _PhoneActionButton(
                icon: Icons.call,
                label: 'Atender',
                color: const Color(0xFF00C853),
                onTap: _answerCall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 12, color: Colors.white24),
              const SizedBox(width: 5),
              Text(
                'Pensas que é seguro atender?',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedUI() {
    final s = widget.scenario;
    final callerName = s['caller_name'] as String? ?? 'Desconhecido';
    final callerRole = s['caller_role'] as String? ?? '';
    final scriptLines = (s['script_lines'] as List?)?.cast<String>() ?? [];
    final audioCues = (s['audio_cues'] as List?)?.cast<String>() ?? [];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060A10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFF4444).withAlpha(60)),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _timerCtrl,
              builder: (_, __) {
                final remaining = ((1 - _timerCtrl.value) * 10).ceil();
                final danger = _timerCtrl.value > 0.7;
                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: danger
                        ? const Color(0xFFFF4444).withAlpha(12)
                        : const Color(0xFF0D1520),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: danger
                            ? const Color(0xFFFF4444).withAlpha(40)
                            : Colors.white.withAlpha(12),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF00C853),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Em chamada',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '00:${remaining.toString().padLeft(2, '0')}',
                            style: GoogleFonts.jetBrainsMono(
                              color: danger
                                  ? const Color(0xFFFF4444)
                                  : Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 1 - _timerCtrl.value,
                          backgroundColor: Colors.white.withAlpha(12),
                          valueColor: AlwaysStoppedAnimation(
                            danger
                                ? const Color(0xFFFF4444)
                                : const Color(0xFF00C853),
                          ),
                          minHeight: 4,
                        ),
                      ),
                      if (danger) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Não respondas — o silêncio protege a tua voz!',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF4444),
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withAlpha(20),
                      border: Border.all(
                        color: widget.color.withAlpha(80),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        callerName.isNotEmpty
                            ? callerName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.syne(
                          color: widget.color,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          callerName,
                          style: GoogleFonts.syne(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (callerRole.isNotEmpty)
                          Text(
                            callerRole,
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4444).withAlpha(18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF4444).withAlpha(50),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(
                                0xFFFF4444,
                              ).withOpacity(0.5 + _pulseCtrl.value * 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Voz IA',
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFFFF4444),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              padding: const EdgeInsets.all(14),
              constraints: const BoxConstraints(minHeight: 100),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(10)),
              ),
              child: _callerSpeaking
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        _TypingDots(color: widget.color),
                      ],
                    )
                  : FadeTransition(
                      opacity: _fadeScriptCtrl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.mic_rounded,
                                size: 11,
                                color: Color(0xFFFF4444),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Transcrição — Voz Clonada por IA',
                                style: GoogleFonts.jetBrainsMono(
                                  color: widget.color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...scriptLines
                              .take(_scriptLine)
                              .map(
                                (line) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: widget.color.withAlpha(10),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: widget.color.withAlpha(35),
                                    ),
                                  ),
                                  child: Text(
                                    '"$line"',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      height: 1.4,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                          if (_scriptLine < scriptLines.length)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: widget.color.withAlpha(120),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'a falar...',
                                    style: GoogleFonts.inter(
                                      color: Colors.white30,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (audioCues.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: audioCues
                                  .map(
                                    (cue) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(8),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        cue,
                                        style: GoogleFonts.inter(
                                          color: Colors.white30,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _micActive
                          ? const Color(0xFFFF4444).withAlpha(12)
                          : const Color(0xFFFFCC00).withAlpha(12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _micActive
                            ? const Color(0xFFFF4444).withAlpha(40)
                            : const Color(0xFFFFCC00).withAlpha(40),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_micActive)
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (i) {
                                final h =
                                    4.0 +
                                    (_voiceLevel * 20) * (0.5 + (i % 3) * 0.25);
                                return Container(
                                  width: 3,
                                  height: h.clamp(4.0, 24.0),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF4444,
                                    ).withAlpha(180),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          )
                        else
                          const Icon(
                            Icons.volume_off_outlined,
                            color: Color(0xFFFFCC00),
                            size: 14,
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _micActive
                                ? 'Microfone ativo!'
                                : 'A aguardar permissão do microfone…',
                            style: GoogleFonts.inter(
                              color: _micActive
                                  ? const Color(0xFFFF4444)
                                  : const Color(0xFFFFCC00),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '🔇 Devo ou não ficar em silencio ?',
                    style: GoogleFonts.inter(
                      color: Colors.white24,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: _PhoneActionButton(
                      icon: Icons.call_end,
                      label: 'Desligar',
                      color: const Color(0xFFFF4444),
                      onTap: _hangUp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeEndedUI() {
    final s = widget.scenario;
    final callerName = s['caller_name'] as String? ?? 'Desconhecido';
    final msg = _wasRejected
        ? 'Não atendeste a chamada suspeita. Excelente instinto!'
        : 'Desligaste antes de seres manipulado. Reação perfeita!';
    final reason = _wasRejected
        ? 'Ao não atender, o atacante não conseguiu iniciar o script de engenharia social nem registar a tua voz. Chamadas de números desconhecidos a pedir dados pessoais são sempre suspeitas.'
        : 'Ao desligar rapidamente, cortaste o ataque antes de o agente conseguir gravar fragmentos da tua voz para clonagem por IA. Cada segundo conta.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF071410),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF00C853).withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withAlpha(20),
            blurRadius: 24,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C853).withAlpha(20),
              border: Border.all(
                color: const Color(0xFF00C853).withAlpha(80),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.shield_rounded,
                color: Color(0xFF00C853),
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bom Trabalho! 🛡️',
            style: GoogleFonts.syne(
              color: const Color(0xFF00C853),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            msg,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withAlpha(8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00C853).withAlpha(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.psychology_outlined,
                      color: Color(0xFF00C853),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Por que agiste bem?',
                      style: GoogleFonts.syne(
                        color: const Color(0xFF00C853),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  reason,
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1520),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(12)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: Colors.white38,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        callerName,
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        s['phone_number'] as String? ?? '',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white30,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withAlpha(18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'BLOQUEADO',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF00C853),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSilentWinUI() {
    final s = widget.scenario;
    final callerName = s['caller_name'] as String? ?? 'Desconhecido';
    final technique =
        s['voice_clone_technique'] as String? ??
        'clonagem de voz por IA com apenas 3 segundos de áudio';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF071B14), const Color(0xFF060A10)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF00FF88).withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withAlpha(25),
            blurRadius: 28,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00FF88), Color(0xFF00C853)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF88).withAlpha(70),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFF00FF88),
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Bom Trabalho!',
            style: GoogleFonts.syne(
              color: const Color(0xFF00FF88),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A tua voz não foi clonada',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withAlpha(8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF00FF88).withAlpha(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.psychology_outlined,
                      color: Color(0xFF00FF88),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Por que agiste bem?',
                      style: GoogleFonts.syne(
                        color: const Color(0xFF00FF88),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Ficaste 10 segundos em silêncio sem dizer nada. '
                  'Para que o vishing resulte, o atacante precisa de gravar a tua voz '
                  'e usar $technique. '
                  'Se não falas, não há voz para clonar — o ataque falha completamente!',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1520),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Como funciona o Vishing',
                  style: GoogleFonts.syne(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _VishStep(
                  '1',
                  'Atacante liga fingindo ser banco/empresa',
                  const Color(0xFFFF6B35),
                ),
                _VishStep(
                  '2',
                  'Tenta fazer-te falar para gravar a tua voz',
                  const Color(0xFFFFCC00),
                ),
                _VishStep(
                  '3',
                  'IA clona a tua voz em segundos',
                  const Color(0xFFFF4444),
                ),
                _VishStep(
                  '4',
                  'Usa a voz clonada para fraudes futuras',
                  const Color(0xFFB06EFF),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withAlpha(10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00FF88).withAlpha(40),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF00FF88),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tu não falaste → voz não gravada → ataque falhado',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF00FF88),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.phone_disabled, size: 13, color: Colors.white24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$callerName — Chamada terminada',
                  style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExposedUI() {
    final s = widget.scenario;
    final scriptLines = (s['script_lines'] as List?)?.cast<String>() ?? [];
    final callerName = s['caller_name'] as String? ?? 'Desconhecido';
    final callerRole = s['caller_role'] as String? ?? 'entidade desconhecida';
    final phoneNumber = s['phone_number'] as String? ?? 'N/D';
    final redFlags = (s['red_flags'] as List?)?.cast<String>() ?? [];
    final technique =
        s['voice_clone_technique'] as String? ??
        'clonagem de voz por IA com menos de 3 segundos de áudio';
    final explanation = s['explanation'] as String? ?? '';

    final autoFlags = [
      _VishFlag(
        '🎭',
        'Personificação',
        '$callerName fingiu ser $callerRole para criar confiança imediata',
        const Color(0xFFFF6B35),
      ),
      _VishFlag(
        '⏰',
        'Urgência artificial',
        'O script usa pressão temporal para impedir que o alvo pense criticamente',
        const Color(0xFFFFCC00),
      ),
      _VishFlag(
        '🎤',
        'Captura de voz',
        'O objetivo era gravar a tua voz para $technique',
        const Color(0xFFFF4444),
      ),
      _VishFlag(
        '📞',
        'Número potencialmente falsificado',
        'O número $phoneNumber pode estar spoofed — VoIP permite falsificar qualquer número',
        const Color(0xFFB06EFF),
      ),
    ];

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A0808),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFF4444).withAlpha(100)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4444).withAlpha(20),
              blurRadius: 24,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF4444).withAlpha(20),
                      border: Border.all(
                        color: const Color(0xFFFF4444).withAlpha(80),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFF4444),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ficaste exposto!',
                          style: GoogleFonts.syne(
                            color: const Color(0xFFFF4444),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'A tua voz foi capturada pelo atacante',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Banner IA ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4444).withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF4444).withAlpha(40),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.smart_toy_outlined,
                      color: Color(0xFF3B82F6),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$callerName usou voz clonada por IA para parecer legítimo',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFF6B6B),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── PORQUÊ É VISHING? ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1C0A0A), Color(0xFF0A0E14)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF4444).withAlpha(50),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.quiz_outlined,
                          color: Color(0xFFFF4444),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PORQUÊ É VISHING?',
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFFFF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sinais de alerta desta chamada',
                      style: GoogleFonts.inter(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Flags automáticas
                    ...autoFlags.map((f) => _VishFlagRow(flag: f)),

                    // Flags do backend (se existirem)
                    if (redFlags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 1,
                        color: const Color(0xFFFF4444).withAlpha(20),
                      ),
                      const SizedBox(height: 8),
                      ...redFlags.map(
                        (flag) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '⚠ ',
                                style: TextStyle(
                                  color: Color(0xFFFF4444),
                                  fontSize: 11,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  flag,
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Explicação do backend
                    if (explanation.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCC00).withAlpha(8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFFCC00).withAlpha(30),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFFFFCC00),
                              size: 13,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                explanation,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFFFCC00).withAlpha(200),
                                  fontSize: 11.5,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Como te protegeres ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1520),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF00FF88),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Como te protegeres',
                          style: GoogleFonts.syne(
                            color: const Color(0xFF00FF88),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ProtectStep(
                      '1',
                      'Desliga e liga tu para o número oficial da instituição',
                      const Color(0xFF00FF88),
                    ),
                    _ProtectStep(
                      '2',
                      'Nunca dês dados pessoais ao telefone — nenhum banco pede assim',
                      const Color(0xFF00C853),
                    ),
                    _ProtectStep(
                      '3',
                      'Denuncia à CNCS (cncs.gov.pt) ou à GNR/PSP',
                      const Color(0xFF00FF88),
                    ),
                    _ProtectStep(
                      '4',
                      'Bloqueia o número e partilha com contactos',
                      const Color(0xFF00C853),
                    ),
                  ],
                ),
              ),
            ),

            // ── Transcrição ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF4444).withAlpha(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.record_voice_over_outlined,
                          color: Color(0xFFFF4444),
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Transcrição do script',
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFFFF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...scriptLines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF4444),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '"$line"',
                                style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  height: 1.4,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _PhoneActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PhoneActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(80),
                blurRadius: 20,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
      ),
    ],
  );
}

class _VishStep extends StatelessWidget {
  final String step, label;
  final Color color;
  const _VishStep(this.step, this.label, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(25),
            border: Border.all(color: color.withAlpha(70)),
          ),
          child: Center(
            child: Text(
              step,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── _VishFlag data model ─────────────────────────────────────────────────────

class _VishFlag {
  final String emoji, title, desc;
  final Color color;
  const _VishFlag(this.emoji, this.title, this.desc, this.color);
}

// ─── _VishFlagRow ─────────────────────────────────────────────────────────────

class _VishFlagRow extends StatelessWidget {
  final _VishFlag flag;
  const _VishFlagRow({required this.flag});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(flag.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flag.title,
                  style: GoogleFonts.syne(
                    color: flag.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  flag.desc,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.4,
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

// ─── _ProtectStep ─────────────────────────────────────────────────────────────

class _ProtectStep extends StatelessWidget {
  final String step, label;
  final Color color;
  const _ProtectStep(this.step, this.label, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(25),
            border: Border.all(color: color.withAlpha(70)),
          ),
          child: Center(
            child: Text(
              step,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final delay = i / 3;
        final t = (_ctrl.value - delay).clamp(0.0, 1.0);
        final scale = 0.5 + 0.5 * sin(t * pi);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8 * scale,
          height: 8 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.4 + 0.6 * scale),
          ),
        );
      }),
    ),
  );
}

class _SearchCard extends StatefulWidget {
  final Map<String, dynamic> scenario;
  final bool revealed;
  final Color color;
  const _SearchCard({
    required this.scenario,
    required this.revealed,
    required this.color,
  });
  @override
  State<_SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<_SearchCard>
    with SingleTickerProviderStateMixin {
  int _tapped = -1;
  late AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    final query = s['search_query'] as String? ?? '';
    final results = (s['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final attackType = s['attack_type'] as String? ?? 'seo_poisoning';
    final totalHits =
        s['total_results'] as String? ?? 'Cerca de 4 230 000 resultados';
    final elapsed = s['search_time_ms'] as String? ?? '0,43 segundos';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF202124),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.revealed
                  ? widget.color.withAlpha(90)
                  : Colors.white.withAlpha(14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 18,
                spreadRadius: -4,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 34,
                color: const Color(0xFF292A2D),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 8),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 180),
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      decoration: const BoxDecoration(
                        color: Color(0xFF35363A),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.language,
                            size: 10,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              query.length > 20
                                  ? '${query.substring(0, 20)}…'
                                  : query,
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.close,
                            size: 9,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(2, 6, 0, 2),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 38,
                color: const Color(0xFF35363A),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _NavBtn(Icons.arrow_back, enabled: false),
                    _NavBtn(Icons.arrow_forward, enabled: false),
                    _NavBtn(Icons.refresh, enabled: true),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF202124),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock,
                              size: 10,
                              color: widget.revealed
                                  ? const Color(0xFF5CB85C)
                                  : Colors.white38,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'google.com/search?q=${Uri.encodeComponent(query)}',
                                style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white54,
                                  fontSize: 8.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.star_border,
                              size: 11,
                              color: Colors.white38,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _NavBtn(Icons.more_vert, enabled: true),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _GL('G', 0xFF4285F4),
                              _GL('o', 0xFFEA4335),
                              _GL('o', 0xFFFBBC05),
                              _GL('g', 0xFF4285F4),
                              _GL('l', 0xFF34A853),
                              _GL('e', 0xFFEA4335),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFDFE1E5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(14),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  color: Color(0xFF4285F4),
                                  size: 17,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    query,
                                    style: const TextStyle(
                                      color: Color(0xFF202124),
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.mic,
                                  color: Color(0xFF4285F4),
                                  size: 17,
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.image_search,
                                  color: Color(0xFF34A853),
                                  size: 17,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _STab('Todos', true),
                                _STab('Imagens', false),
                                _STab('Vídeos', false),
                                _STab('Notícias', false),
                                _STab('Shopping', false),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: const Color(0xFFDFE1E5),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$totalHits ($elapsed)',
                              style: const TextStyle(
                                color: Color(0xFF70757A),
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.revealed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4444).withAlpha(14),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFFF4444).withAlpha(60),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 9,
                                    color: Color(0xFFFF4444),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _attackLabel(attackType),
                                    style: const TextStyle(
                                      color: Color(0xFFFF4444),
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: results.asMap().entries.map((e) {
                          final i = e.key;
                          final r = e.value;
                          final malicious = r['is_malicious'] as bool? ?? false;
                          final isAd = r['is_ad'] as bool? ?? false;
                          final isSponsored =
                              r['is_sponsored'] as bool? ?? false;
                          final badge = r['badge'] as String?;
                          final rating = r['rating'] as double?;
                          final sitelinks =
                              (r['sitelinks'] as List?)?.cast<String>() ?? [];
                          final clues =
                              (r['threat_clues'] as List?)?.cast<String>() ??
                              [];
                          final showThreat = widget.revealed && malicious;
                          final tapped = _tapped == i;

                          return GestureDetector(
                            onTap: () =>
                                setState(() => _tapped = tapped ? -1 : i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: showThreat
                                  ? const EdgeInsets.all(9)
                                  : (tapped
                                        ? const EdgeInsets.all(6)
                                        : EdgeInsets.zero),
                              decoration: showThreat
                                  ? BoxDecoration(
                                      color: const Color(
                                        0xFFFF4444,
                                      ).withAlpha(8),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFFF4444,
                                        ).withAlpha(55),
                                      ),
                                    )
                                  : (tapped
                                        ? BoxDecoration(
                                            color: const Color(0xFFF8F9FA),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          )
                                        : null),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isAd || isSponsored || badge != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: showThreat
                                                ? const Color(0xFFFF4444)
                                                : const Color(0xFF70757A),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Text(
                                          isSponsored
                                              ? 'Patrocinado'
                                              : isAd
                                              ? 'Anúncio'
                                              : badge!,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: showThreat
                                                ? const Color(0xFFFF4444)
                                                : const Color(0xFF70757A),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        margin: const EdgeInsets.only(right: 5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: showThreat
                                              ? const Color(
                                                  0xFFFF4444,
                                                ).withAlpha(18)
                                              : const Color(0xFFE8F0FE),
                                        ),
                                        child: Icon(
                                          Icons.language,
                                          size: 8,
                                          color: showThreat
                                              ? const Color(0xFFFF4444)
                                              : const Color(0xFF4285F4),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          r['url'] as String? ?? '',
                                          style: TextStyle(
                                            color: showThreat
                                                ? const Color(0xFFCC3300)
                                                : const Color(0xFF202124),
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (showThreat)
                                        AnimatedBuilder(
                                          animation: _blink,
                                          builder: (_, __) => Icon(
                                            Icons.warning_amber_rounded,
                                            size: 12,
                                            color: Color.lerp(
                                              const Color(0xFFFF4444),
                                              const Color(0xFFFF8888),
                                              _blink.value,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    r['title'] as String? ?? '',
                                    style: TextStyle(
                                      color: showThreat
                                          ? const Color(0xFFCC0000)
                                          : const Color(0xFF1558D6),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      decoration: TextDecoration.underline,
                                      decorationColor: showThreat
                                          ? const Color(0xFFCC0000)
                                          : const Color(0xFF1558D6),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    r['description'] as String? ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFF4D5156),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (rating != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        ...List.generate(
                                          5,
                                          (s) => Icon(
                                            s < rating.floor()
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 11,
                                            color: const Color(0xFFFBBC05),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Color(0xFF70757A),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (sitelinks.isNotEmpty && !showThreat) ...[
                                    const SizedBox(height: 5),
                                    Wrap(
                                      spacing: 10,
                                      children: sitelinks
                                          .map(
                                            (sl) => Text(
                                              sl,
                                              style: const TextStyle(
                                                color: Color(0xFF1558D6),
                                                fontSize: 11,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                  if (showThreat) ...[
                                    const SizedBox(height: 6),
                                    if (clues.isEmpty)
                                      Row(
                                        children: const [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Color(0xFFFF4444),
                                            size: 11,
                                          ),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Domínio falso — dados em risco',
                                              style: TextStyle(
                                                color: Color(0xFFFF4444),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: clues
                                            .map(
                                              (c) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 2,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      '✗ ',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFFFF4444,
                                                        ),
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        c,
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFFFF4444,
                                                          ),
                                                          fontSize: 9,
                                                          height: 1.3,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _attackLabel(String t) {
    switch (t) {
      case 'malvertising':
        return '⚠ Malvertising — anúncio pago falso';
      case 'lookalike_domain':
        return '⚠ Lookalike — typosquatting';
      case 'sponsored_phishing':
        return '⚠ Google Ads abusado';
      default:
        return '⚠ SEO Poisoning — resultado envenenado';
    }
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  const _NavBtn(this.icon, {required this.enabled});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Icon(
      icon,
      size: 14,
      color: enabled ? Colors.white54 : Colors.white24,
    ),
  );
}

class _GL extends StatelessWidget {
  final String l;
  final int c;
  const _GL(this.l, this.c);
  @override
  Widget build(BuildContext context) => Text(
    l,
    style: TextStyle(
      color: Color(c),
      fontSize: 20,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _STab extends StatelessWidget {
  final String label;
  final bool active;
  const _STab(this.label, this.active);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: active
        ? const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF1A73E8), width: 3),
            ),
          )
        : null,
    child: Text(
      label,
      style: TextStyle(
        color: active ? const Color(0xFF1A73E8) : const Color(0xFF70757A),
        fontSize: 12,
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  );
}

class _AnglerCard extends StatefulWidget {
  final Map<String, dynamic> scenario;
  final bool revealed;
  final Color color;
  const _AnglerCard({
    required this.scenario,
    required this.revealed,
    required this.color,
  });
  @override
  State<_AnglerCard> createState() => _AnglerCardState();
}

class _AnglerCardState extends State<_AnglerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  static const _configs = <String, Map<String, dynamic>>{
    'twitter': {
      'bg': 0xFF15202B,
      'header': 0xFF1E2732,
      'bubble': 0xFF192734,
      'accent': 0xFF1D9BF0,
      'label': 'X (Twitter)',
      'sym': '𝕏',
      'reactions': ['favorite_border', 'repeat', 'chat_bubble_outline'],
    },
    'instagram': {
      'bg': 0xFF121212,
      'header': 0xFF1C1C1C,
      'bubble': 0xFF262626,
      'accent': 0xFFE1306C,
      'label': 'Instagram',
      'sym': '📷',
      'reactions': ['favorite_border', 'chat_bubble_outline', 'send'],
    },
    'facebook': {
      'bg': 0xFF18191A,
      'header': 0xFF242526,
      'bubble': 0xFF3A3B3C,
      'accent': 0xFF1877F2,
      'label': 'Facebook',
      'sym': 'f',
      'reactions': ['thumb_up_outlined', 'chat_bubble_outline', 'share'],
    },
    'linkedin': {
      'bg': 0xFF1B1F23,
      'header': 0xFF283040,
      'bubble': 0xFF1E2A3B,
      'accent': 0xFF0A66C2,
      'label': 'LinkedIn',
      'sym': 'in',
      'reactions': ['thumb_up_outlined', 'comment', 'share'],
    },
    'reddit': {
      'bg': 0xFF1A1A1B,
      'header': 0xFF272729,
      'bubble': 0xFF1A1A1B,
      'accent': 0xFFFF4500,
      'label': 'Reddit',
      'sym': '👽',
      'reactions': ['arrow_upward', 'arrow_downward', 'chat_bubble_outline'],
    },
    'telegram': {
      'bg': 0xFF17212B,
      'header': 0xFF232E3C,
      'bubble': 0xFF2B5278,
      'accent': 0xFF2AABEE,
      'label': 'Telegram',
      'sym': '✈',
      'reactions': ['reply', 'forward', 'bookmark_border'],
    },
    'tiktok': {
      'bg': 0xFF010101,
      'header': 0xFF121212,
      'bubble': 0xFF1C1C1C,
      'accent': 0xFFFF0050,
      'label': 'TikTok',
      'sym': '♪',
      'reactions': ['favorite_border', 'chat_bubble_outline', 'share'],
    },
  };

  static const _reactionIcons = <String, IconData>{
    'favorite_border': Icons.favorite_border,
    'repeat': Icons.repeat,
    'chat_bubble_outline': Icons.chat_bubble_outline,
    'send': Icons.send,
    'thumb_up_outlined': Icons.thumb_up_outlined,
    'share': Icons.share,
    'comment': Icons.comment,
    'arrow_upward': Icons.arrow_upward,
    'arrow_downward': Icons.arrow_downward,
    'reply': Icons.reply,
    'forward': Icons.forward,
    'bookmark_border': Icons.bookmark_border,
  };

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    final platformKey = (s['platform'] as String? ?? 'twitter').toLowerCase();
    final cfg = _configs[platformKey] ?? _configs['twitter']!;

    final bg = Color(cfg['bg'] as int);
    final header = Color(cfg['header'] as int);
    final bubble = Color(cfg['bubble'] as int);
    final accent = Color(cfg['accent'] as int);
    final label = cfg['label'] as String;
    final sym = cfg['sym'] as String;
    final rKeys = (cfg['reactions'] as List).cast<String>();
    final reactionIcons = rKeys.map((k) => _reactionIcons[k]!).toList();

    final complaint = s['original_complaint'] as String? ?? '';
    final fakeAcc = s['fake_account'] as Map<String, dynamic>? ?? {};
    final reply = s['reply_message'] as String? ?? '';
    final link = s['support_link'] as String? ?? '';
    final brand = s['brand'] as String? ?? 'Marca';
    final origUser = s['original_user'] as String? ?? '@user';
    final _followersRaw = fakeAcc['followers'];
    final followers = _followersRaw is int
        ? _followersRaw
        : int.tryParse(_followersRaw?.toString() ?? '') ?? 0;
    final isVerified = fakeAcc['verified'] as bool? ?? false;
    final created = fakeAcc['created'] as String? ?? '';
    final redFlags = (s['red_flags'] as List?)?.cast<String>() ?? [];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.revealed
              ? widget.color.withAlpha(100)
              : Colors.white.withAlpha(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: header,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text(
                  sym,
                  style: TextStyle(
                    color: accent,
                    fontSize: sym.length == 1 ? 20 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.10 + _pulse.value * 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withOpacity(
                              0.55 + _pulse.value * 0.45,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'ao vivo',
                          style: GoogleFonts.jetBrainsMono(
                            color: accent,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SocialPost(
                  avatarLetter: origUser.replaceAll('@', '').isNotEmpty
                      ? origUser.replaceAll('@', '')[0].toUpperCase()
                      : 'U',
                  handle: origUser,
                  name: origUser.replaceAll('@', '').replaceAll('_', ' '),
                  body: complaint,
                  bg: bubble,
                  accent: accent,
                  reactionIcons: reactionIcons,
                  isVerified: false,
                  revealed: widget.revealed,
                  isMalicious: false,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 18,
                        color: Colors.white.withAlpha(30),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'resposta de conta de suporte',
                        style: GoogleFonts.jetBrainsMono(
                          color: widget.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _SocialPost(
                  avatarLetter: brand.isNotEmpty ? brand[0].toUpperCase() : 'S',
                  handle: fakeAcc['handle'] as String? ?? '@${brand}Suporte',
                  name: fakeAcc['name'] as String? ?? '$brand Suporte',
                  body: reply,
                  link: link,
                  bg: widget.color.withAlpha(14),
                  accent: widget.color,
                  reactionIcons: reactionIcons,
                  isVerified: isVerified,
                  followers: followers,
                  createdDate: created,
                  revealed: widget.revealed,
                  isMalicious: true,
                ),
                if (widget.revealed) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4444).withAlpha(10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFF4444).withAlpha(50),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Angler Phishing — sinais',
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFFFF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...(_buildFlags(
                          redFlags,
                          followers,
                          isVerified,
                          created,
                        )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFlags(
    List<String> flags,
    int followers,
    bool verified,
    String created,
  ) {
    final list = flags.isNotEmpty
        ? flags
        : [
            if (!verified) 'Conta sem verificação oficial',
            if (followers < 1000) '$followers seguidores — conta suspeita',
            if (created.isNotEmpty) 'Criada em $created — muito recente',
            'Link não pertence ao domínio oficial da marca',
            'Suporte legítimo nunca envia links por DM',
          ];
    return list
        .map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✗ ',
                  style: TextStyle(color: Color(0xFFFF4444), fontSize: 10),
                ),
                Expanded(
                  child: Text(
                    c,
                    style: const TextStyle(
                      color: Color(0xFFFF4444),
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

class _SocialPost extends StatelessWidget {
  final String avatarLetter, handle, name, body;
  final String? link;
  final Color bg, accent;
  final List<IconData> reactionIcons;
  final bool isVerified, revealed, isMalicious;
  final int? followers;
  final String? createdDate;

  const _SocialPost({
    required this.avatarLetter,
    required this.handle,
    required this.name,
    required this.body,
    this.link,
    required this.bg,
    required this.accent,
    required this.reactionIcons,
    required this.isVerified,
    required this.revealed,
    required this.isMalicious,
    this.followers,
    this.createdDate,
  });

  @override
  Widget build(BuildContext context) {
    final showWarn = revealed && isMalicious;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: showWarn
              ? const Color(0xFFFF4444).withAlpha(80)
              : Colors.white.withAlpha(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withAlpha(30),
                  border: Border.all(color: accent.withAlpha(80)),
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: TextStyle(
                      color: accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 3),
                          Icon(Icons.verified, color: accent, size: 13),
                        ] else if (showWarn) ...[
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFF4444),
                            size: 12,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      handle,
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (followers != null)
                      Text(
                        '$followers seguidores',
                        style: GoogleFonts.inter(
                          color: Colors.white30,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (link != null && link!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              link!,
              style: TextStyle(
                color: showWarn ? const Color(0xFFFF4444) : accent,
                fontSize: 12,
                decoration: TextDecoration.underline,
                decorationColor: showWarn ? const Color(0xFFFF4444) : accent,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: reactionIcons
                .take(3)
                .map(
                  (icon) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(icon, color: Colors.white38, size: 14),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WhalingCard extends StatefulWidget {
  final Map<String, dynamic> scenario;
  final bool revealed;
  final Color color;
  const _WhalingCard({
    required this.scenario,
    required this.revealed,
    required this.color,
  });
  @override
  State<_WhalingCard> createState() => _WhalingCardState();
}

class _WhalingCardState extends State<_WhalingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final vector = (widget.scenario['attack_vector'] as String? ?? 'email')
        .toLowerCase();
    switch (vector) {
      case 'slack':
      case 'teams':
      case 'chat':
        return _buildChat();
      case 'invoice':
      case 'document':
        return _buildInvoice();
      case 'calendar':
        return _buildCalendar();
      default:
        return _buildEmail();
    }
  }

  BoxDecoration _outerBox(Color bg) => BoxDecoration(
    color: bg,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: widget.revealed
          ? widget.color.withAlpha(100)
          : Colors.white.withAlpha(20),
    ),
  );

  Widget _analysisPanel() {
    final s = widget.scenario;
    final clues =
        (s['red_flags'] as List?)?.cast<String>() ??
        (s['whaling_clues'] as List?)?.cast<String>() ??
        [
          'Pedido financeiro urgente fora dos canais normais',
          'Domínio do remetente ligeiramente diferente do oficial',
          'Pressão temporal para contornar verificações internas',
          'CEO/CFO nunca envia pedidos de pagamento por email',
        ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF6B35).withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análise Whaling',
            style: GoogleFonts.jetBrainsMono(
              color: const Color(0xFFFF6B35),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ...clues.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚡ ',
                    style: TextStyle(color: Color(0xFFFF6B35), fontSize: 10),
                  ),
                  Expanded(
                    child: Text(
                      c,
                      style: const TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmail() {
    final s = widget.scenario;
    final targetRole = s['target_role'] as String? ?? 'Diretor Financeiro';
    final senderName = s['sender_name'] as String? ?? '';
    final senderRole = s['sender_role'] as String? ?? '';
    final senderDomain =
        s['sender_domain'] as String? ?? s['sender_email'] as String? ?? '';
    final subject = s['subject'] as String? ?? '';
    final body = s['email_body'] as String? ?? '';
    final urgency = s['urgency_level'] as String? ?? 'URGENTE';
    final attachments = (s['attachments'] as List?)?.cast<String>() ?? [];
    final signature = s['signature'] as String? ?? '';
    final cc = (s['cc'] as List?)?.cast<String>() ?? [];

    return Container(
      decoration: _outerBox(const Color(0xFF0D1520)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF161E2E),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withAlpha(10)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      size: 14,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.archive_outlined,
                      size: 14,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: Colors.white38,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4444).withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFFF4444).withAlpha(80),
                        ),
                      ),
                      child: Text(
                        urgency,
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFFFF4444),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  subject,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _ERow(
                  'De',
                  '$senderName <$senderDomain>',
                  highlight: widget.revealed,
                ),
                _ERow('Para', targetRole),
                if (cc.isNotEmpty) _ERow('CC', cc.join(', ')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(senderName, widget.color, 42),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            senderRole,
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.revealed)
                            Text(
                              senderDomain,
                              style: GoogleFonts.jetBrainsMono(
                                color: const Color(0xFFFF6B6B),
                                fontSize: 9,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.white.withAlpha(12)),
                const SizedBox(height: 8),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 260),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Text(
                    body.length > 280 ? '${body.substring(0, 280)}…' : body,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  secondChild: Text(
                    body,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ),
                if (body.length > 280)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _expanded ? 'Mostrar menos ▲' : 'Ver mais ▼',
                        style: GoogleFonts.inter(
                          color: widget.color,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                if (signature.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Divider(color: Colors.white.withAlpha(10)),
                  Text(
                    signature,
                    style: GoogleFonts.inter(
                      color: Colors.white30,
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                ],
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: attachments
                        .map(
                          (a) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: widget.revealed
                                  ? const Color(0xFFFF4444).withAlpha(12)
                                  : Colors.white.withAlpha(8),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: widget.revealed
                                    ? const Color(0xFFFF4444).withAlpha(60)
                                    : Colors.white.withAlpha(20),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  a.endsWith('.pdf')
                                      ? Icons.picture_as_pdf
                                      : Icons.attach_file,
                                  size: 11,
                                  color: widget.revealed
                                      ? const Color(0xFFFF4444)
                                      : Colors.white54,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  a,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: widget.revealed
                                        ? const Color(0xFFFF4444)
                                        : Colors.white54,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (widget.revealed) ...[
                  const SizedBox(height: 12),
                  _analysisPanel(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    final s = widget.scenario;
    final isSlack =
        (s['attack_vector'] as String? ?? '').toLowerCase() == 'slack';
    final bg = isSlack ? const Color(0xFF1A1D21) : const Color(0xFF1B2838);
    final headerBg = isSlack
        ? const Color(0xFF4A154B)
        : const Color(0xFF6264A7);
    final senderName = s['sender_name'] as String? ?? 'CEO';
    final body = s['email_body'] as String? ?? s['message'] as String? ?? '';
    final channel = s['channel'] as String? ?? '#finanças';
    final urgency = s['urgency_level'] as String? ?? 'URGENTE';
    final platform = isSlack ? 'Slack' : 'Microsoft Teams';

    return Container(
      decoration: _outerBox(bg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text(
                  isSlack ? '#' : '⊞',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$platform — $channel',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4444).withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    urgency,
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFFF4444),
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(senderName, widget.color, 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                senderName,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (widget.revealed) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFFF4444),
                                  size: 12,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            'Hoje às ${TimeOfDay.now().format(context)}',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.revealed
                          ? const Color(0xFFFF4444).withAlpha(60)
                          : Colors.white.withAlpha(10),
                    ),
                  ),
                  child: Text(
                    body,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                if (widget.revealed) ...[
                  const SizedBox(height: 12),
                  _analysisPanel(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoice() {
    final s = widget.scenario;
    final sender = s['sender_name'] as String? ?? '';
    final subject = s['subject'] as String? ?? 'Fatura — Pagamento Urgente';
    final body = s['email_body'] as String? ?? '';
    final amount = s['amount'] as String? ?? '';
    final iban = s['iban'] as String? ?? '';
    final deadline = s['deadline'] as String? ?? '';

    return Container(
      decoration: _outerBox(const Color(0xFF0D1520)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161E2E),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: widget.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'De: $sender',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4444).withAlpha(20),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: const Color(0xFFFF4444).withAlpha(60),
                    ),
                  ),
                  child: Text(
                    'URGENTE',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFFF4444),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  body,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                if (amount.isNotEmpty || iban.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.revealed
                          ? const Color(0xFFFF4444).withAlpha(10)
                          : Colors.white.withAlpha(5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.revealed
                            ? const Color(0xFFFF4444).withAlpha(60)
                            : Colors.white.withAlpha(14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (amount.isNotEmpty)
                          _IRow('Valor', amount, widget.revealed),
                        if (iban.isNotEmpty)
                          _IRow('IBAN', iban, widget.revealed),
                        if (deadline.isNotEmpty)
                          _IRow('Prazo', deadline, false),
                      ],
                    ),
                  ),
                ],
                if (widget.revealed) ...[
                  const SizedBox(height: 12),
                  _analysisPanel(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final s = widget.scenario;
    final sender = s['sender_name'] as String? ?? '';
    final subject = s['subject'] as String? ?? 'Reunião Urgente';
    final body = s['email_body'] as String? ?? '';
    final link = s['meeting_link'] as String? ?? '';
    final time = s['meeting_time'] as String? ?? 'Hoje, 15:00';

    return Container(
      decoration: _outerBox(const Color(0xFF0D1520)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161E2E),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.color.withAlpha(60)),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: widget.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$sender · $time',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  body,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                if (link.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: widget.revealed
                          ? const Color(0xFFFF4444).withAlpha(10)
                          : widget.color.withAlpha(10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.revealed
                            ? const Color(0xFFFF4444).withAlpha(60)
                            : widget.color.withAlpha(40),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.videocam_outlined,
                          size: 14,
                          color: widget.revealed
                              ? const Color(0xFFFF4444)
                              : widget.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            link,
                            style: TextStyle(
                              color: widget.revealed
                                  ? const Color(0xFFFF6B6B)
                                  : widget.color,
                              fontSize: 11,
                              decoration: TextDecoration.underline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.revealed) ...[
                  const SizedBox(height: 12),
                  _analysisPanel(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  const _Avatar(this.name, this.color, this.size);
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withAlpha(25),
      border: Border.all(color: color.withAlpha(80), width: 1.5),
    ),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.syne(
          color: color,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _ERow extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _ERow(this.label, this.value, {this.highlight = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Text(
            '$label:',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: highlight ? const Color(0xFFFF6B6B) : Colors.white60,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _IRow extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _IRow(this.label, this.value, this.highlight);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: highlight ? const Color(0xFFFF6B6B) : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _QuishingCard extends StatefulWidget {
  final Map<String, dynamic> scenario;
  final bool revealed;
  final Color color;
  const _QuishingCard({
    required this.scenario,
    required this.revealed,
    required this.color,
  });
  @override
  State<_QuishingCard> createState() => _QuishingCardState();
}

class _QuishingCardState extends State<_QuishingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    final context_ =
        s['context'] as String? ??
        s['description'] as String? ??
        'Encontrou este código QR num local público.';
    final fakeUrl =
        s['fake_url'] as String? ??
        s['malicious_url'] as String? ??
        'hxxps://secure-verify.net/login';
    final legitimateDomain =
        s['legitimate_domain'] as String? ?? s['brand'] as String? ?? 'Banco';
    final placement =
        s['placement'] as String? ??
        s['location'] as String? ??
        'Cartaz público';
    final redFlags = (s['red_flags'] as List?)?.cast<String>() ?? <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1520),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.revealed
                  ? widget.color.withAlpha(100)
                  : Colors.white.withAlpha(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 18,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF161E2E),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withAlpha(10)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 16,
                      color: Color(0xFFFFCC00),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quishing – QR Code',
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFFFFCC00),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFCC00,
                          ).withOpacity(0.08 + _pulse.value * 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          placement,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFCC00),
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Context description
                    Text(
                      context_,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // QR code + tap-to-scan
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _scanned = true),
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, child) => Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: (_scanned || widget.revealed)
                                    ? widget.color.withOpacity(
                                        0.4 + _pulse.value * 0.3,
                                      )
                                    : const Color(
                                        0xFFFFCC00,
                                      ).withOpacity(0.2 + _pulse.value * 0.2),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_scanned || widget.revealed)
                                      ? widget.color.withOpacity(
                                          _pulse.value * 0.25,
                                        )
                                      : const Color(
                                          0xFFFFCC00,
                                        ).withOpacity(_pulse.value * 0.15),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: CustomPaint(
                                  size: const Size(140, 140),
                                  painter: _QrPainter(),
                                ),
                              ),
                              if (!_scanned)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(170),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Toca para escanear',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_scanned || widget.revealed)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4444).withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFF4444).withAlpha(60),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.link_rounded,
                                  size: 12,
                                  color: Color(0xFFFF4444),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'URL de destino',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: const Color(0xFFFF4444),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              fakeUrl,
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white70,
                                fontSize: 10,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.business_rounded,
                                  size: 10,
                                  color: Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Imita: $legitimateDomain',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    if (widget.revealed && redFlags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.color.withAlpha(12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: widget.color.withAlpha(50)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sinais de alerta',
                              style: GoogleFonts.jetBrainsMono(
                                color: widget.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...redFlags.map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '⚠ ',
                                      style: TextStyle(
                                        color: widget.color,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        f,
                                        style: TextStyle(
                                          color: widget.color,
                                          fontSize: 10,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PharmingCard extends StatefulWidget {
  final Map<String, dynamic> scenario;
  final bool revealed;
  final Color color;
  const _PharmingCard({
    required this.scenario,
    required this.revealed,
    required this.color,
  });
  @override
  State<_PharmingCard> createState() => _PharmingCardState();
}

class _PharmingCardState extends State<_PharmingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    final legitimateDomain =
        s['legitimate_domain'] as String? ??
        s['brand'] as String? ??
        'banco.pt';
    final spoofedUrl =
        s['spoofed_url'] as String? ??
        s['fake_url'] as String? ??
        'http://banco-seguro.net/login';
    final pageTitle =
        s['page_title'] as String? ?? '$legitimateDomain – Acesso';
    final formFields =
        (s['form_fields'] as List?)?.cast<String>() ??
        ['Utilizador', 'Palavra-passe', 'PIN'];
    final attackMethod =
        s['attack_method'] as String? ??
        s['method'] as String? ??
        'Envenenamento de cache DNS';
    final redFlags = (s['red_flags'] as List?)?.cast<String>() ?? <String>[];
    final hasHttps = s['has_https'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF202124),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.revealed
                  ? widget.color.withAlpha(90)
                  : Colors.white.withAlpha(14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 18,
                spreadRadius: -4,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 34,
                color: const Color(0xFF292A2D),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 8),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 200),
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      decoration: const BoxDecoration(
                        color: Color(0xFF35363A),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.language,
                            size: 10,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              pageTitle.length > 22
                                  ? '${pageTitle.substring(0, 22)}…'
                                  : pageTitle,
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.close,
                            size: 9,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 38,
                color: const Color(0xFF35363A),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _NavBtn(Icons.arrow_back, enabled: false),
                    _NavBtn(Icons.arrow_forward, enabled: false),
                    _NavBtn(Icons.refresh, enabled: true),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF202124),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            AnimatedBuilder(
                              animation: _blink,
                              builder: (_, __) => Icon(
                                hasHttps ? Icons.lock : Icons.lock_open_rounded,
                                size: 10,
                                color: hasHttps
                                    ? (widget.revealed
                                          ? const Color(0xFFFF6B6B)
                                          : const Color(0xFF5CB85C))
                                    : Color.lerp(
                                        const Color(0xFFFF6B6B),
                                        Colors.white38,
                                        _blink.value,
                                      )!,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                spoofedUrl,
                                style: GoogleFonts.jetBrainsMono(
                                  color: widget.revealed
                                      ? const Color(0xFFFF6B6B)
                                      : Colors.white54,
                                  fontSize: 8.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.star_border,
                              size: 11,
                              color: Colors.white38,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _NavBtn(Icons.more_vert, enabled: true),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB06EFF).withAlpha(18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        legitimateDomain.toUpperCase(),
                        style: GoogleFonts.syne(
                          color: const Color(0xFF333333),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Acesso à Conta',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF555555),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...formFields.map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFDDDDDD)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              field,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFAAAAAA),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB06EFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'Entrar',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.dns_outlined,
                size: 14,
                color: Color(0xFFB06EFF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Método de ataque',
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFFB06EFF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      attackMethod,
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.revealed && redFlags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.color.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.color.withAlpha(50)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sinais de alerta',
                  style: GoogleFonts.jetBrainsMono(
                    color: widget.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ...redFlags.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠ ',
                          style: TextStyle(color: widget.color, fontSize: 10),
                        ),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(
                              color: widget.color,
                              fontSize: 10,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;
    final blockSize = size.width / 10;
    void drawCorner(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, blockSize * 3, blockSize * 3), paint);
      canvas.drawRect(
        Rect.fromLTWH(
          x + blockSize * 0.5,
          y + blockSize * 0.5,
          blockSize * 2,
          blockSize * 2,
        ),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + blockSize, y + blockSize, blockSize, blockSize),
        paint,
      );
    }

    drawCorner(0, 0);
    drawCorner(size.width - blockSize * 3, 0);
    drawCorner(0, size.height - blockSize * 3);
    final positions = [
      [4, 1],
      [5, 1],
      [7, 1],
      [4, 2],
      [6, 2],
      [4, 3],
      [5, 3],
      [1, 4],
      [3, 4],
      [5, 4],
      [7, 4],
      [2, 5],
      [4, 5],
      [6, 5],
      [1, 6],
      [3, 6],
      [5, 6],
      [2, 7],
      [4, 7],
      [6, 7],
      [7, 7],
    ];
    for (final p in positions) {
      canvas.drawRect(
        Rect.fromLTWH(p[0] * blockSize, p[1] * blockSize, blockSize, blockSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_QrPainter _) => false;
}
