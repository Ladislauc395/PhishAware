// ============================================================
//  vishing_sim_screen.dart
//  Simulação de Vishing com Clonagem de Voz por IA
//
//  Dependências a adicionar ao pubspec.yaml:
//    record: ^5.1.2
//    audioplayers: ^6.1.0
//    permission_handler: ^11.3.1
//    lottie: ^3.1.2          (opcional – para animações)
//    path_provider: ^2.1.4
// ============================================================

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_models.dart';
import 'api_service.dart';

// ─── Phase Enum ──────────────────────────────────────────────────────────────

enum _VishPhase { intro, recording, processing, call, reveal }

// ─── Screen ──────────────────────────────────────────────────────────────────

class VishingSimScreen extends StatefulWidget {
  const VishingSimScreen({super.key});

  @override
  State<VishingSimScreen> createState() => _VishingSimScreenState();
}

class _VishingSimScreenState extends State<VishingSimScreen>
    with TickerProviderStateMixin {
  _VishPhase _phase = _VishPhase.intro;

  // ── Recording
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;
  bool _isRecording = false;
  int _recSeconds = 0;
  Timer? _recTimer;

  // ── Waveform animation
  late AnimationController _waveCtrl;
  final List<double> _waveBars = List.generate(24, (i) => 0.2);
  Timer? _waveTimer;

  // ── Processing animation
  late AnimationController _spinCtrl;
  int _processingStep = 0;
  Timer? _procTimer;

  // ── Call screen
  late AnimationController _callPulseCtrl;
  late AnimationController _callRingCtrl;
  bool _callAnswered = false;
  bool _showRedFlags = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _clonedAudioUrl;
  String? _phishingScript;
  List<String> _redFlags = [];
  String _explanation = '';

  // ── Reveal
  late AnimationController _revealCtrl;
  int _revealedFlags = 0;

  @override
  void initState() {
    super.initState();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _callPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _callRingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
    _waveCtrl.dispose();
    _spinCtrl.dispose();
    _callPulseCtrl.dispose();
    _callRingCtrl.dispose();
    _revealCtrl.dispose();
    _recTimer?.cancel();
    _waveTimer?.cancel();
    _procTimer?.cancel();
    super.dispose();
  }

  // ─── Recording Logic ────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showSnack('Permissão de microfone necessária');
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath =
        '${dir.path}/vishing_sample_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: _recordingPath!,
    );

    setState(() {
      _isRecording = true;
      _recSeconds = 0;
      _phase = _VishPhase.recording;
    });

    // Countdown timer
    _recTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _recSeconds++);
      if (_recSeconds >= 6) _stopAndProcess();
    });

    // Animate wave bars
    _waveTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _waveBars.length; i++) {
          _waveBars[i] = 0.15 + math.Random().nextDouble() * 0.85;
        }
      });
    });
  }

  Future<void> _stopAndProcess() async {
    _recTimer?.cancel();
    _waveTimer?.cancel();
    await _recorder.stop();

    setState(() {
      _isRecording = false;
      _phase = _VishPhase.processing;
      _processingStep = 0;
    });

    // Animated processing steps
    final steps = [
      'A analisar a tua voz…',
      'A extrair características vocais…',
      'A treinar modelo de clonagem…',
      'A gerar script de phishing…',
      'A sintetizar voz clonada…',
    ];

    _procTimer = Timer.periodic(const Duration(milliseconds: 1100), (t) {
      if (!mounted) return;
      setState(() => _processingStep = (_processingStep + 1) % steps.length);
    });

    try {
      final result = await ApiService.generateVishingClone(
        audioPath: _recordingPath!,
      );

      _procTimer?.cancel();

      _clonedAudioUrl = result['audio_url'] as String?;
      _phishingScript = result['script'] as String? ?? _fallbackScript;
      _redFlags = List<String>.from(result['red_flags'] ?? _fallbackRedFlags);
      _explanation = result['explanation'] as String? ?? _fallbackExplanation;
    } catch (_) {
      // Fallback for demo / backend unavailable
      _procTimer?.cancel();
      _phishingScript = _fallbackScript;
      _redFlags = _fallbackRedFlags;
      _explanation = _fallbackExplanation;
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _phase = _VishPhase.call);
  }

  // ─── Call Logic ─────────────────────────────────────────────────────────────

  Future<void> _answerCall() async {
    setState(() => _callAnswered = true);

    if (_clonedAudioUrl != null) {
      await _audioPlayer.play(UrlSource(_clonedAudioUrl!));
    }

    // Show red flags after 3s of call
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _showRedFlags = true);
  }

  void _hangUpAndReveal() {
    _audioPlayer.stop();
    setState(() {
      _phase = _VishPhase.reveal;
      _revealedFlags = 0;
    });
    _revealNextFlag();
  }

  void _revealNextFlag() {
    Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (!mounted || _revealedFlags >= _redFlags.length) {
        t.cancel();
        return;
      }
      setState(() => _revealedFlags++);
    });
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _reset() => setState(() {
    _phase = _VishPhase.intro;
    _callAnswered = false;
    _showRedFlags = false;
    _revealedFlags = 0;
    _recSeconds = 0;
  });

  // ─── Fallback content (usado quando backend indisponível) ───────────────────

  static const _fallbackScript =
      'Olá, sou eu! Esqueci-me da senha do banco e estou aqui com o gerente '
      'que precisa confirmar o teu NIF e os últimos quatro dígitos do cartão '
      'para desbloquear a conta. É urgente, tens de me dar agora!';

  static const List<String> _fallbackRedFlags = [
    'Urgência artificial — pressão para agir "agora"',
    'Pedido de dados bancários por telefone',
    'Voz familiar usada para baixar a guarda',
    'Nenhuma instituição real pede o NIF por chamada',
    'Tom emocional para bloquear o pensamento crítico',
  ];

  static const _fallbackExplanation =
      'Esta chamada usa a tua própria voz clonada por IA para simular um '
      'familiar em apuros. Os atacantes reais usam apenas 3–10 segundos de '
      'áudio (redes sociais, vídeos públicos) para criar um clone convincente. '
      'Estabelece sempre uma palavra-código segura com a tua família.';

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _buildPhase(),
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _VishPhase.intro:
        return _IntroView(
          key: const ValueKey('intro'),
          onStart: _startRecording,
        );
      case _VishPhase.recording:
        return _RecordingView(
          key: const ValueKey('recording'),
          seconds: _recSeconds,
          waveBars: _waveBars,
          onStop: _stopAndProcess,
        );
      case _VishPhase.processing:
        return _ProcessingView(
          key: const ValueKey('processing'),
          step: _processingStep,
          spinCtrl: _spinCtrl,
        );
      case _VishPhase.call:
        return _CallView(
          key: const ValueKey('call'),
          pulseCtrl: _callPulseCtrl,
          ringCtrl: _callRingCtrl,
          answered: _callAnswered,
          showRedFlags: _showRedFlags,
          redFlags: _redFlags,
          script: _phishingScript ?? _fallbackScript,
          onAnswer: _answerCall,
          onHangUp: _hangUpAndReveal,
        );
      case _VishPhase.reveal:
        return _RevealView(
          key: const ValueKey('reveal'),
          redFlags: _redFlags,
          revealedCount: _revealedFlags,
          explanation: _explanation,
          onReset: _reset,
        );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  PHASE 1 — INTRO
// ════════════════════════════════════════════════════════════════════════════

class _IntroView extends StatelessWidget {
  final VoidCallback onStart;
  const _IntroView({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(height: 32),

            // Hero badge
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withAlpha(80),
                      blurRadius: 32,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Center(
              child: Text(
                'Ataque de Vishing',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'A IA pode clonar a tua voz em segundos',
                style: GoogleFonts.dmSans(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // Stat cards
            _StatRow(
              icon: Icons.timer_outlined,
              color: AppColors.danger,
              stat: '3 segundos',
              label: 'de áudio são suficientes para clonar a tua voz',
            ),
            const SizedBox(height: 12),
            _StatRow(
              icon: Icons.trending_up,
              color: AppColors.warn,
              stat: '+1 200%',
              label: 'aumento de ataques de vishing com IA em 2024',
            ),
            const SizedBox(height: 12),
            _StatRow(
              icon: Icons.people_outline,
              color: AppColors.blue,
              stat: '77%',
              label: 'das vítimas acreditam ser um familiar a ligar-lhes',
            ),
            const SizedBox(height: 32),

            // How it works
            _SectionCard(
              title: 'Como funciona este ataque?',
              children: [
                _Step(
                  n: '1',
                  color: AppColors.danger,
                  text:
                      'O atacante recolhe alguns segundos da tua voz (redes sociais, vídeos)',
                ),
                _Step(
                  n: '2',
                  color: AppColors.warn,
                  text: 'Uma IA clona a tua voz e gera um script convincente',
                ),
                _Step(
                  n: '3',
                  color: AppColors.blue,
                  text:
                      'Liga para um familiar usando a tua voz, pedindo dinheiro ou dados',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // CTA
            _GradientButton(
              label: 'Experimenta — grava a tua voz',
              icon: Icons.mic,
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
              ),
              onTap: onStart,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Apenas 4-6 segundos de áudio · Dados não são guardados',
                style: GoogleFonts.dmSans(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  PHASE 2 — RECORDING
// ════════════════════════════════════════════════════════════════════════════

class _RecordingView extends StatelessWidget {
  final int seconds;
  final List<double> waveBars;
  final VoidCallback onStop;

  const _RecordingView({
    super.key,
    required this.seconds,
    required this.waveBars,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (6 - seconds).clamp(0, 6);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Prompt text
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.danger.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Text(
                  '"Olá! Estava a pensar em ti. '
                  'Tudo bem por aí? Hoje foi um dia longo…"',
                  style: GoogleFonts.dmSans(
                    color: AppColors.text,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lê o texto acima em voz alta',
                style: GoogleFonts.dmSans(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 48),

              // Waveform
              SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: waveBars
                      .map(
                        (h) => AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          width: 5,
                          height: 80 * h,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Red pulsing mic
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger.withAlpha(20),
                  border: Border.all(color: AppColors.danger, width: 2),
                ),
                child: Icon(Icons.mic, color: AppColors.danger, size: 44),
              ),
              const SizedBox(height: 24),

              Text(
                remaining > 0 ? 'Para em  $remaining s' : 'A processar…',
                style: GoogleFonts.dmSans(
                  color: AppColors.danger,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gravando… ${seconds}s / 6s',
                style: GoogleFonts.dmSans(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),

              // Manual stop
              GestureDetector(
                onTap: onStop,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text(
                    'Parar já',
                    style: GoogleFonts.dmSans(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
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

// ════════════════════════════════════════════════════════════════════════════
//  PHASE 3 — PROCESSING
// ════════════════════════════════════════════════════════════════════════════

class _ProcessingView extends StatelessWidget {
  final int step;
  final AnimationController spinCtrl;

  const _ProcessingView({
    super.key,
    required this.step,
    required this.spinCtrl,
  });

  static const _steps = [
    'A analisar a tua voz…',
    'A extrair características vocais…',
    'A treinar modelo de clonagem…',
    'A gerar script de phishing…',
    'A sintetizar voz clonada…',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spinning AI brain icon
              AnimatedBuilder(
                animation: spinCtrl,
                builder: (_, __) => Transform.rotate(
                  angle: spinCtrl.value * 2 * math.pi,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFFB91C1C),
                          Color(0xFF00E5A0),
                          Color(0xFFEF4444),
                        ],
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Text(
                'IA a clonar a tua voz',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _steps[step % _steps.length],
                  key: ValueKey(step),
                  style: GoogleFonts.dmSans(
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: i == step % _steps.length ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == step % _steps.length
                          ? AppColors.danger
                          : AppColors.surface2,
                      borderRadius: BorderRadius.circular(4),
                    ),
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

// ════════════════════════════════════════════════════════════════════════════
//  PHASE 4 — CALL (Incoming call UI)
// ════════════════════════════════════════════════════════════════════════════

class _CallView extends StatelessWidget {
  final AnimationController pulseCtrl;
  final AnimationController ringCtrl;
  final bool answered;
  final bool showRedFlags;
  final List<String> redFlags;
  final String script;
  final VoidCallback onAnswer;
  final VoidCallback onHangUp;

  const _CallView({
    super.key,
    required this.pulseCtrl,
    required this.ringCtrl,
    required this.answered,
    required this.showRedFlags,
    required this.redFlags,
    required this.script,
    required this.onAnswer,
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark blurred background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A0000), Color(0xFF0F1318)],
            ),
          ),
        ),

        // Ambient red glow
        AnimatedBuilder(
          animation: pulseCtrl,
          builder: (_, __) => Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.danger.withAlpha(
                      (40 + pulseCtrl.value * 20).toInt(),
                    ),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),

              // ── Avatar ────────────────────────────────────────────────────
              AnimatedBuilder(
                animation: pulseCtrl,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse rings
                    if (!answered) ...[
                      _PulseRing(
                        scale: 1.0 + pulseCtrl.value * 0.4,
                        opacity: 0.15,
                      ),
                      _PulseRing(
                        scale: 1.0 + pulseCtrl.value * 0.6,
                        opacity: 0.08,
                      ),
                    ],
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface2,
                        border: Border.all(
                          color: answered
                              ? AppColors.danger.withAlpha(200)
                              : Colors.white.withAlpha(50),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          UserSession.avatarLetter,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Caller info ───────────────────────────────────────────────
              Text(
                UserSession.userName,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedBuilder(
                animation: ringCtrl,
                builder: (_, __) => Text(
                  answered ? '● A falar…' : 'Chamada de voz a entrar…',
                  style: GoogleFonts.dmSans(
                    color: answered ? AppColors.danger : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // ── Script bubble (when answered) ─────────────────────────────
              if (answered) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withAlpha(200),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.danger.withAlpha(60),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '"$script"',
                      style: GoogleFonts.dmSans(
                        color: AppColors.text,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],

              // ── Red flags overlay (after 3s in call) ─────────────────────
              if (showRedFlags && redFlags.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: redFlags
                        .take(2)
                        .map(
                          (f) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.danger.withAlpha(80),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  color: AppColors.danger,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.danger,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],

              const Spacer(),

              // ── Call buttons ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Hang up (always visible)
                    _CallBtn(
                      icon: Icons.call_end,
                      color: AppColors.danger,
                      label: answered ? 'Desligar' : 'Rejeitar',
                      onTap: answered ? onHangUp : onHangUp,
                    ),

                    // Answer (only when not yet answered)
                    if (!answered)
                      _CallBtn(
                        icon: Icons.call,
                        color: const Color(0xFF22C55E),
                        label: 'Atender',
                        onTap: onAnswer,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevealView extends StatelessWidget {
  final List<String> redFlags;
  final int revealedCount;
  final String explanation;
  final VoidCallback onReset;

  const _RevealView({
    super.key,
    required this.redFlags,
    required this.revealedCount,
    required this.explanation,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.gpp_bad, color: AppColors.danger, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Era phishing!',
                        style: GoogleFonts.dmSans(
                          color: AppColors.danger,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'A tua voz foi clonada por IA',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Explanation
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Text(
                explanation,
                style: GoogleFonts.dmSans(
                  color: AppColors.text,
                  fontSize: 14,
                  height: 1.65,
                ),
              ),
            ),
            const SizedBox(height: 28),

            Text(
              '🚩 Sinais de alerta detetados',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            // Animated red flags
            ...List.generate(
              redFlags.length,
              (i) => AnimatedOpacity(
                opacity: i < revealedCount ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: AnimatedSlide(
                  offset: i < revealedCount
                      ? Offset.zero
                      : const Offset(-0.1, 0),
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withAlpha(12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.danger.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}.',
                          style: GoogleFonts.dmSans(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            redFlags[i],
                            style: GoogleFonts.dmSans(
                              color: AppColors.text,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Protection tips
            _SectionCard(
              title: '🛡️ Como te proteger',
              children: [
                _Step(
                  n: '✓',
                  color: AppColors.accent,
                  text: 'Cria uma palavra-código secreta com a família',
                ),
                _Step(
                  n: '✓',
                  color: AppColors.accent,
                  text: 'Liga de volta pelo número que conheces antes de agir',
                ),
                _Step(
                  n: '✓',
                  color: AppColors.accent,
                  text: 'Nunca dês dados bancários numa chamada não solicitada',
                ),
                _Step(
                  n: '✓',
                  color: AppColors.accent,
                  text:
                      'Desconfia de urgência extrema — é sempre uma técnica de pressão',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Buttons
            _GradientButton(
              label: 'Tentar novamente',
              icon: Icons.refresh,
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.accentAlt],
              ),
              onTap: onReset,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Voltar ao início',
                  style: GoogleFonts.dmSans(color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String stat;
  final String label;

  const _StatRow({
    required this.icon,
    required this.color,
    required this.stat,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat,
                  style: GoogleFonts.dmSans(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textMuted,
                    fontSize: 12,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n;
  final Color color;
  final String text;

  const _Step({required this.n, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                n,
                style: GoogleFonts.dmSans(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                color: AppColors.text,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CallBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
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
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final double scale;
  final double opacity;

  const _PulseRing({required this.scale, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.danger, width: 1.5),
          ),
        ),
      ),
    );
  }
}
