// ============================================================
//  voice_clone_sim_screen.dart
//  Simulação: "A IA Clona a Tua Voz"
//
//  Fluxo:
//   1. INTRO        — contexto + regras de segurança
//   2. RECORDING    — utilizador fala 5 s (amostra de voz)
//   3. PROCESSING   — backend analisa + cria "clone"
//   4. INCOMING     — ecrã de chamada a tocar (número desconhecido)
//   5. ACTIVE CALL  — utilizador ouve a IA falar com a SUA voz,
//                     pode responder por microfone
//   6. REVEAL       — lições de segurança + score
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF060A10);
  static const surface = Color(0xFF0D1520);
  static const border = Color(0xFF1A2535);
  static const accent = Color(0xFF00FF88);
  static const red = Color(0xFFEF4444);
  static const warn = Color(0xFFFFCC00);
  static const blue = Color(0xFF3B82F6);
  static const purple = Color(0xFFB06EFF);
  static const text = Colors.white;
  static const muted = Colors.white38;
}

// ─── Phase ──────────────────────────────────────────────────────────────────
enum _Phase { intro, recording, processing, incoming, activeCall, reveal }

// ─── API layer ──────────────────────────────────────────────────────────────
class _VoiceCloneApi {
  static String get _base => ApiService.baseUrl;
  static Map<String, String> get _auth => {
    if (ApiService.authToken.isNotEmpty)
      'Authorization': 'Bearer ${ApiService.authToken}',
  };

  /// Envia a amostra de voz → backend devolve clone_id + primeiro texto
  static Future<Map<String, dynamic>> cloneVoice(String audioPath) async {
    final req =
        http.MultipartRequest('POST', Uri.parse('$_base/voice-clone/clone'))
          ..headers.addAll(_auth)
          ..files.add(await http.MultipartFile.fromPath('audio', audioPath));
    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) throw Exception('clone failed');
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// Obtém o áudio WAV do texto com a voz "clonada" → devolve path local
  static Future<String?> synthesize({
    required String cloneId,
    required String text,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/voice-clone/speak'),
            headers: {'Content-Type': 'application/json', ..._auth},
            body: jsonEncode({'clone_id': cloneId, 'text': text}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/vc_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      await file.writeAsBytes(res.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Transcreve resposta do utilizador
  static Future<String> transcribe(String audioPath) async {
    try {
      final req =
          http.MultipartRequest(
              'POST',
              Uri.parse('$_base/avatar-call/transcribe'),
            )
            ..headers.addAll(_auth)
            ..files.add(await http.MultipartFile.fromPath('audio', audioPath));
      final streamed = await req.send().timeout(const Duration(seconds: 20));
      final body = await streamed.stream.bytesToString();
      return (jsonDecode(body)['text'] ?? '').toString().trim();
    } catch (_) {
      return '';
    }
  }

  /// IA responde como "voz clonada" continuando a scam
  static Future<Map<String, dynamic>> respond({
    required String cloneId,
    required String userMessage,
    required List<Map<String, String>> history,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/voice-clone/respond'),
            headers: {'Content-Type': 'application/json', ..._auth},
            body: jsonEncode({
              'clone_id': cloneId,
              'user_id': ApiService.currentUserId,
              'user_message': userMessage,
              'history': history,
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) throw Exception('${res.statusCode}');
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'reply': 'Estou aqui, podes continuar.',
        'ended': false,
        'user_won': false,
        'danger_level': 0,
      };
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class VoiceCloneSimScreen extends StatefulWidget {
  const VoiceCloneSimScreen({super.key});

  @override
  State<VoiceCloneSimScreen> createState() => _VoiceCloneSimScreenState();
}

class _VoiceCloneSimScreenState extends State<VoiceCloneSimScreen>
    with TickerProviderStateMixin {
  _Phase _phase = _Phase.intro;

  // ── Recording
  final AudioRecorder _recorder = AudioRecorder();
  String? _samplePath;
  bool _isRecording = false;
  int _recSec = 0;
  Timer? _recTimer;
  final List<double> _waveBars = List.generate(28, (_) => 0.2);
  Timer? _waveTimer;

  // ── Processing
  late AnimationController _spinCtrl;
  int _procStep = 0;
  Timer? _procTimer;

  // ── Clone data
  String? _cloneId;
  String? _callerName; // e.g. "a tua própria voz"
  String? _openingText;

  // ── Incoming call ring
  late AnimationController _ringCtrl;
  int _ringCount = 0;
  Timer? _ringTimer;
  bool _declined = false;

  // ── Active call
  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _callRecorder = AudioRecorder();
  bool _aiSpeaking = false;
  bool _userSpeaking = false;
  String? _userSpeakPath;
  List<Map<String, String>> _history = [];
  List<_ChatBubble> _bubbles = [];
  bool _callEnded = false;
  bool _userWon = false;
  int _dangerScore = 0; // 0-100
  Timer? _userRecTimer;
  int _userRecSec = 0;
  ScrollController _scrollCtrl = ScrollController();

  // ── Reveal
  late AnimationController _revealCtrl;
  int _score = 0;

  // ── General animations
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _callRecorder.dispose();
    _player.dispose();
    _bgCtrl.dispose();
    _spinCtrl.dispose();
    _ringCtrl.dispose();
    _revealCtrl.dispose();
    _recTimer?.cancel();
    _waveTimer?.cancel();
    _procTimer?.cancel();
    _ringTimer?.cancel();
    _userRecTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ─── RECORDING ─────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _snack('Permissão de microfone necessária');
      return;
    }
    final dir = await getTemporaryDirectory();
    _samplePath =
        '${dir.path}/vc_sample_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: _samplePath!,
    );
    setState(() {
      _isRecording = true;
      _recSec = 0;
      _phase = _Phase.recording;
    });
    _recTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _recSec++);
      if (_recSec >= 5) _stopAndProcess();
    });
    _waveTimer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _waveBars.length; i++) {
          _waveBars[i] = 0.1 + math.Random().nextDouble() * 0.9;
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
      _phase = _Phase.processing;
      _procStep = 0;
    });

    final stepLabels = [
      'A analisar padrões vocais…',
      'A extrair frequências características…',
      'A construir modelo de voz…',
      'A gerar script de engenharia social…',
      'A sintetizar a voz clonada…',
      'A preparar chamada…',
    ];
    _procTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) return;
      setState(
        () => _procStep = (_procStep + 1).clamp(0, stepLabels.length - 1),
      );
    });

    try {
      final result = await _VoiceCloneApi.cloneVoice(_samplePath!);
      _cloneId = result['clone_id'] as String? ?? 'default';
      _callerName = result['caller_name'] as String? ?? 'Número Desconhecido';
      _openingText = result['opening_text'] as String? ?? _kFallbackOpening;
    } catch (_) {
      _cloneId = 'fallback';
      _callerName = 'Número Desconhecido';
      _openingText = _kFallbackOpening;
    }

    _procTimer?.cancel();
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _startIncomingCall();
  }

  // ─── INCOMING CALL ─────────────────────────────────────────────────────────

  void _startIncomingCall() {
    setState(() {
      _phase = _Phase.incoming;
      _ringCount = 0;
      _declined = false;
    });
    HapticFeedback.heavyImpact();
    _ringTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _ringCount++);
      // Auto-dismiss after 4 rings if not answered — counts as WIN
      if (_ringCount >= 4) {
        t.cancel();
        _declineCall();
      }
    });
  }

  void _declineCall() {
    _ringTimer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      _declined = true;
      _userWon = true;
      _score = 100;
      _phase = _Phase.reveal;
    });
    _revealCtrl.forward();
    ApiService.addXp(40, true, 'vishing').ignore();
  }

  Future<void> _answerCall() async {
    _ringTimer?.cancel();
    HapticFeedback.lightImpact();
    setState(() => _phase = _Phase.activeCall);
    await _aiSpeak(_openingText ?? _kFallbackOpening);
  }

  // ─── ACTIVE CALL ───────────────────────────────────────────────────────────

  Future<void> _aiSpeak(String text) async {
    setState(() => _aiSpeaking = true);
    _addBubble(_ChatBubble(text: text, isAi: true));

    final path = await _VoiceCloneApi.synthesize(
      cloneId: _cloneId ?? 'fallback',
      text: text,
    );
    if (path != null && mounted) {
      await _player.play(DeviceFileSource(path));
      await _player.onPlayerComplete.first;
    } else {
      // Fallback: just wait for reading time
      await Future.delayed(
        Duration(milliseconds: (text.length * 55).clamp(1500, 6000)),
      );
    }
    if (mounted) setState(() => _aiSpeaking = false);
  }

  Future<void> _startUserMic() async {
    if (_aiSpeaking || _userSpeaking || _callEnded) return;
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    final dir = await getTemporaryDirectory();
    _userSpeakPath =
        '${dir.path}/vc_user_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _callRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: _userSpeakPath!,
    );
    setState(() {
      _userSpeaking = true;
      _userRecSec = 0;
    });
    _userRecTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _userRecSec++);
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _stopUserMic() async {
    if (!_userSpeaking) return;
    _userRecTimer?.cancel();
    await _callRecorder.stop();
    setState(() => _userSpeaking = false);

    if (_userSpeakPath == null) return;

    // Transcribe
    final transcript = await _VoiceCloneApi.transcribe(_userSpeakPath!);
    final displayText = transcript.isEmpty ? '(silêncio)' : transcript;
    _addBubble(_ChatBubble(text: displayText, isAi: false));
    _history.add({'role': 'user', 'content': displayText});

    // Get AI reply
    final reply = await _VoiceCloneApi.respond(
      cloneId: _cloneId ?? 'fallback',
      userMessage: displayText,
      history: _history,
    );

    final replyText = reply['reply']?.toString() ?? '';
    final ended = reply['ended'] == true;
    final won = reply['user_won'] == true;
    _dangerScore = (reply['danger_level'] as num? ?? _dangerScore).toInt();

    _history.add({'role': 'assistant', 'content': replyText});

    if (ended) {
      _callEnded = true;
      _userWon = won;
      _score = _calcScore();
      if (replyText.isNotEmpty) await _aiSpeak(replyText);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() => _phase = _Phase.reveal);
        _revealCtrl.forward();
        ApiService.addXp(_score ~/ 5, won, 'vishing').ignore();
      }
    } else {
      await _aiSpeak(replyText);
    }
  }

  void _hangUpManually() {
    _userRecTimer?.cancel();
    _callRecorder.stop().ignore();
    _player.stop().ignore();
    _userWon = _dangerScore < 40;
    _score = _calcScore();
    setState(() {
      _callEnded = true;
      _phase = _Phase.reveal;
    });
    _revealCtrl.forward();
    ApiService.addXp(_score ~/ 5, _userWon, 'vishing').ignore();
  }

  int _calcScore() {
    if (_declined) return 100;
    if (_userWon && _dangerScore == 0) return 85;
    if (_userWon) return (85 - _dangerScore ~/ 2).clamp(40, 85);
    return (20 - _dangerScore ~/ 5).clamp(0, 20);
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  void _addBubble(_ChatBubble b) {
    if (!mounted) return;
    setState(() => _bubbles.add(b));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _reset() {
    setState(() {
      _phase = _Phase.intro;
      _bubbles.clear();
      _history.clear();
      _cloneId = null;
      _declined = false;
      _callEnded = false;
      _userWon = false;
      _dangerScore = 0;
      _score = 0;
      _recSec = 0;
    });
    _revealCtrl.reset();
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          _GridBg(controller: _bgCtrl),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _buildPhase(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _Phase.intro:
        return _IntroPhase(
          key: const ValueKey('intro'),
          onStart: _startRecording,
        );
      case _Phase.recording:
        return _RecordingPhase(
          key: const ValueKey('rec'),
          seconds: _recSec,
          bars: _waveBars,
          onStop: _stopAndProcess,
        );
      case _Phase.processing:
        return _ProcessingPhase(
          key: const ValueKey('proc'),
          step: _procStep,
          spinCtrl: _spinCtrl,
        );
      case _Phase.incoming:
        return _IncomingPhase(
          key: const ValueKey('incoming'),
          ringCtrl: _ringCtrl,
          ringCount: _ringCount,
          onAnswer: _answerCall,
          onDecline: _declineCall,
        );
      case _Phase.activeCall:
        return _ActiveCallPhase(
          key: const ValueKey('call'),
          bubbles: _bubbles,
          aiSpeaking: _aiSpeaking,
          userSpeaking: _userSpeaking,
          userRecSec: _userRecSec,
          dangerScore: _dangerScore,
          scrollCtrl: _scrollCtrl,
          onMicDown: _startUserMic,
          onMicUp: _stopUserMic,
          onHangUp: _hangUpManually,
        );
      case _Phase.reveal:
        return _RevealPhase(
          key: const ValueKey('reveal'),
          declined: _declined,
          userWon: _userWon,
          score: _score,
          dangerScore: _dangerScore,
          animation: _revealCtrl,
          onReset: _reset,
        );
    }
  }

  // ─── Fallback content ──────────────────────────────────────────────────────
  static const _kFallbackOpening =
      'Olá! Sou eu... Estou num apuro urgente. '
      'Precisava que me enviasses dinheiro agora, podes ajudar-me?';
}

// ═══════════════════════════════════════════════════════════════════════════
//  PHASE 1 — INTRO
// ═══════════════════════════════════════════════════════════════════════════

class _IntroPhase extends StatelessWidget {
  final VoidCallback onStart;
  const _IntroPhase({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: _C.muted,
                size: 20,
              ),
            ),
            const SizedBox(height: 28),

            // Hero icon
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFF7C1515)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _C.red.withAlpha(100),
                      blurRadius: 36,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.record_voice_over,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Text(
                'Clonagem de Voz por IA',
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                  color: _C.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'A IA usa a TUA voz para te atacar',
                style: GoogleFonts.inter(color: _C.muted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),

            // Warning banner
            _WarningBanner(
              icon: Icons.warning_amber_rounded,
              color: _C.warn,
              text:
                  'Esta simulação demonstra como um atacante pode clonar a tua voz com apenas 5 segundos de áudio e usá-la para enganar os teus familiares.',
            ),
            const SizedBox(height: 20),

            // Rules — the 3 golden rules
            _SectionTitle('As 3 regras de ouro das chamadas'),
            const SizedBox(height: 12),
            _RuleCard(
              n: '1',
              color: _C.red,
              icon: Icons.phone_missed,
              title: 'Nunca atendas números desconhecidos',
              body:
                  'Se não reconheces o número, deixa ir para o voicemail. Números desconhecidos são o principal vetor de vishing.',
            ),
            const SizedBox(height: 10),
            _RuleCard(
              n: '2',
              color: _C.warn,
              icon: Icons.hearing_disabled,
              title: 'Nunca fales primeiro na chamada',
              body:
                  'Se atenderes uma chamada suspeita, espera que o outro lado fale. Atacantes usam o teu silêncio para gravar e clonar a tua voz.',
            ),
            const SizedBox(height: 10),
            _RuleCard(
              n: '3',
              color: _C.blue,
              icon: Icons.lock_outline,
              title: 'Estabelece uma palavra-código familiar',
              body:
                  'Combina uma palavra secreta com a tua família. Se alguém ligar fingindo ser um familiar e não souber a palavra, é um clone de IA.',
            ),
            const SizedBox(height: 24),

            // Stats
            _StatGrid(
              items: const [
                _StatItem('3–5 s', 'de áudio para clonar uma voz', _C.red),
                _StatItem('+1200%', 'aumento de ataques em 2024', _C.warn),
                _StatItem('77%', 'das vítimas acredita ser familiar', _C.blue),
                _StatItem(
                  '\$25M',
                  'perdidos em fraudes de voz IA em 2023',
                  _C.purple,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // CTA
            _BigButton(
              label: 'Começar simulação',
              sublabel: 'Grava 5 segundos da tua voz',
              icon: Icons.mic_rounded,
              color: _C.red,
              onTap: onStart,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'O áudio não é guardado nem partilhado · Apenas para fins educativos',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: _C.muted, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PHASE 2 — RECORDING
// ═══════════════════════════════════════════════════════════════════════════

class _RecordingPhase extends StatelessWidget {
  final int seconds;
  final List<double> bars;
  final VoidCallback onStop;

  const _RecordingPhase({
    super.key,
    required this.seconds,
    required this.bars,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (5 - seconds).clamp(0, 5);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Instruction
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _C.red.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.red.withAlpha(60)),
              ),
              child: Text(
                '🎙️  Fala naturalmente — diz qualquer coisa',
                style: GoogleFonts.inter(color: _C.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),

            // Countdown circle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: seconds / 5,
                    strokeWidth: 6,
                    backgroundColor: _C.surface,
                    color: _C.red,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$remaining',
                      style: GoogleFonts.syne(
                        color: _C.text,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'segundos',
                      style: GoogleFonts.inter(color: _C.muted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Waveform
            SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: bars
                    .map(
                      (h) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 60),
                          width: 5,
                          height: 64 * h,
                          decoration: BoxDecoration(
                            color: _C.red.withAlpha((h * 255).toInt()),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 48),

            // Stop early
            GestureDetector(
              onTap: onStop,
              child: Text(
                'Parar agora',
                style: GoogleFonts.inter(
                  color: _C.muted,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: _C.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PHASE 3 — PROCESSING
// ═══════════════════════════════════════════════════════════════════════════

class _ProcessingPhase extends StatelessWidget {
  final int step;
  final AnimationController spinCtrl;

  const _ProcessingPhase({
    super.key,
    required this.step,
    required this.spinCtrl,
  });

  static const _steps = [
    'A analisar padrões vocais…',
    'A extrair frequências características…',
    'A construir modelo de voz…',
    'A gerar script de engenharia social…',
    'A sintetizar a voz clonada…',
    'A preparar a chamada…',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spinner
              AnimatedBuilder(
                animation: spinCtrl,
                builder: (_, __) => Transform.rotate(
                  angle: spinCtrl.value * 2 * math.pi,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _C.red.withAlpha(200),
                        width: 3,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Icon(
                      Icons.graphic_eq,
                      color: _C.red,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'A IA está a trabalhar…',
                style: GoogleFonts.syne(
                  color: _C.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // Steps
              ...List.generate(_steps.length, (i) {
                final done = i < step;
                final active = i == step;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(
                        done
                            ? Icons.check_circle
                            : active
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: done
                            ? _C.accent
                            : active
                            ? _C.red
                            : _C.muted,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _steps[i],
                        style: GoogleFonts.inter(
                          color: done
                              ? _C.accent
                              : active
                              ? _C.text
                              : _C.muted,
                          fontSize: 13,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PHASE 4 — INCOMING CALL
// ═══════════════════════════════════════════════════════════════════════════

class _IncomingPhase extends StatelessWidget {
  final AnimationController ringCtrl;
  final int ringCount;
  final VoidCallback onAnswer;
  final VoidCallback onDecline;

  const _IncomingPhase({
    super.key,
    required this.ringCtrl,
    required this.ringCount,
    required this.onAnswer,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),

          // Warning chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _C.warn.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.warn.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: _C.warn,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'NÚMERO DESCONHECIDO',
                  style: GoogleFonts.jetBrainsMono(
                    color: _C.warn,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pulse avatar
          AnimatedBuilder(
            animation: ringCtrl,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                // Outer rings
                ...List.generate(3, (i) {
                  final scale = 1.0 + (i + 1) * 0.25 + ringCtrl.value * 0.1;
                  final opacity = (0.15 - i * 0.04).clamp(0.0, 1.0);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _C.red.withAlpha((opacity * 255).toInt()),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                }),
                // Avatar
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A2535), Color(0xFF0D1520)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: _C.red.withAlpha(120), width: 2),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: _C.muted,
                    size: 48,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            '+351 9** *** ***',
            style: GoogleFonts.syne(
              color: _C.text,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chamada recebida',
            style: GoogleFonts.inter(color: _C.muted, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Já ${ringCount + 1} toque${ringCount > 0 ? 's' : ''}',
            style: GoogleFonts.jetBrainsMono(color: _C.muted, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // Tip box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: Text(
                '💡 Dica: Números desconhecidos são a principal fonte de vishing. O que fazes?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline
                _CallActionBtn(
                  icon: Icons.call_end_rounded,
                  color: _C.red,
                  label: 'Recusar',
                  onTap: onDecline,
                ),
                // Answer
                _CallActionBtn(
                  icon: Icons.call_rounded,
                  color: _C.accent,
                  label: 'Atender',
                  onTap: onAnswer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PHASE 5 — ACTIVE CALL
// ═══════════════════════════════════════════════════════════════════════════

class _ActiveCallPhase extends StatelessWidget {
  final List<_ChatBubble> bubbles;
  final bool aiSpeaking;
  final bool userSpeaking;
  final int userRecSec;
  final int dangerScore;
  final ScrollController scrollCtrl;
  final VoidCallback onMicDown;
  final VoidCallback onMicUp;
  final VoidCallback onHangUp;

  const _ActiveCallPhase({
    super.key,
    required this.bubbles,
    required this.aiSpeaking,
    required this.userSpeaking,
    required this.userRecSec,
    required this.dangerScore,
    required this.scrollCtrl,
    required this.onMicDown,
    required this.onMicUp,
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    final dangerColor = dangerScore < 30
        ? _C.accent
        : dangerScore < 60
        ? _C.warn
        : _C.red;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.mic_external_on_rounded,
                  color: _C.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Em chamada — voz clonada activa',
                  style: GoogleFonts.inter(color: _C.red, fontSize: 12),
                ),
                const Spacer(),
                // Danger meter
                Row(
                  children: [
                    Text(
                      'Risco: ',
                      style: GoogleFonts.inter(color: _C.muted, fontSize: 11),
                    ),
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (dangerScore / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: dangerColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$dangerScore%',
                      style: GoogleFonts.jetBrainsMono(
                        color: dangerColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: _C.border, height: 1),

          // Chat bubbles
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: bubbles.length + (aiSpeaking ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == bubbles.length) {
                  return _TypingBubble();
                }
                final b = bubbles[i];
                return _BubbleRow(bubble: b);
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: _C.surface,
              border: Border(top: BorderSide(color: _C.border)),
            ),
            child: Row(
              children: [
                // Hang up
                GestureDetector(
                  onTap: onHangUp,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.red.withAlpha(30),
                      border: Border.all(color: _C.red.withAlpha(80)),
                    ),
                    child: const Icon(
                      Icons.call_end_rounded,
                      color: _C.red,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Mic push-to-talk
                Expanded(
                  child: GestureDetector(
                    onTapDown: (_) => onMicDown(),
                    onTapUp: (_) => onMicUp(),
                    onTapCancel: () => onMicUp(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 52,
                      decoration: BoxDecoration(
                        color: userSpeaking
                            ? _C.red.withAlpha(30)
                            : _C.accent.withAlpha(15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: userSpeaking
                              ? _C.red.withAlpha(120)
                              : _C.accent.withAlpha(60),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            userSpeaking
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            color: userSpeaking ? _C.red : _C.accent,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            userSpeaking
                                ? 'A gravar… ${userRecSec}s'
                                : aiSpeaking
                                ? 'Aguarda…'
                                : 'Toca para responder',
                            style: GoogleFonts.inter(
                              color: userSpeaking ? _C.red : _C.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
}

// ═══════════════════════════════════════════════════════════════════════════
//  PHASE 6 — REVEAL
// ═══════════════════════════════════════════════════════════════════════════

class _RevealPhase extends StatelessWidget {
  final bool declined;
  final bool userWon;
  final int score;
  final int dangerScore;
  final AnimationController animation;
  final VoidCallback onReset;

  const _RevealPhase({
    super.key,
    required this.declined,
    required this.userWon,
    required this.score,
    required this.dangerScore,
    required this.animation,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final won = declined || userWon;
    final mainColor = won ? _C.accent : _C.red;

    return SafeArea(
      child: FadeTransition(
        opacity: animation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Result hero
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: mainColor.withAlpha(20),
                        border: Border.all(
                          color: mainColor.withAlpha(80),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        won
                            ? Icons.shield_rounded
                            : Icons.warning_amber_rounded,
                        color: mainColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      declined
                          ? '🏆 Perfeito! Número recusado'
                          : won
                          ? '✅ Boa resistência!'
                          : '⚠️ Caíste no ataque',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.syne(
                        color: _C.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      declined
                          ? 'Nunca atenderes foi a decisão certa'
                          : won
                          ? 'Resististe à engenharia social'
                          : 'A voz clonada enganou-te',
                      style: GoogleFonts.inter(color: _C.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Score
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ScoreStat('$score', 'Score', mainColor),
                    Container(width: 1, height: 40, color: _C.border),
                    _ScoreStat('${score ~/ 5} XP', 'XP ganhos', _C.accent),
                    Container(width: 1, height: 40, color: _C.border),
                    _ScoreStat(
                      won ? 'Baixo' : 'Alto',
                      'Perigo cedido',
                      won ? _C.accent : _C.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // What happened
              _SectionTitle('O que aconteceu'),
              const SizedBox(height: 10),
              _InfoCard(
                icon: Icons.info_outline,
                color: _C.blue,
                body: declined
                    ? 'Recusaste atender um número desconhecido — isto é a defesa mais eficaz. Mesmo que fosse uma chamada legítima, podes sempre ligar de volta.'
                    : won
                    ? 'Atendeste a chamada mas resististe à pressão da voz clonada. Bom trabalho! No entanto, nunca atender é ainda mais seguro.'
                    : 'A voz clonada da IA usou a TUA voz para te manipular. Cedeste informação a um atacante que usava a tua própria voz como arma.',
              ),
              const SizedBox(height: 20),

              // How cloning works
              _SectionTitle('Como funciona a clonagem de voz'),
              const SizedBox(height: 10),
              _StepCard(
                steps: const [
                  _StepItem(
                    '1',
                    _C.red,
                    'Recolha',
                    'O atacante obtém 3–10 s da tua voz (redes sociais, mensagens de voz, vídeos públicos)',
                  ),
                  _StepItem(
                    '2',
                    _C.warn,
                    'Clonagem',
                    'Ferramentas de IA gratuitas (ElevenLabs, RVC) criam um modelo da tua voz em segundos',
                  ),
                  _StepItem(
                    '3',
                    _C.blue,
                    'Ataque',
                    'Liga para um familiar usando a tua voz clonada, pedindo dinheiro urgente ou dados sensíveis',
                  ),
                  _StepItem(
                    '4',
                    _C.purple,
                    'Convicção',
                    'A vítima reconhece a "tua" voz e confia — taxa de sucesso muito alta',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Protection rules
              _SectionTitle('Como te proteger'),
              const SizedBox(height: 10),
              ..._kProtectionRules.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProtectionRow(rule: r),
                ),
              ),
              const SizedBox(height: 28),

              // Actions
              _BigButton(
                label: 'Tentar novamente',
                icon: Icons.refresh_rounded,
                color: mainColor,
                onTap: onReset,
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Voltar ao menu',
                    style: GoogleFonts.inter(color: _C.muted, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _kProtectionRules = [
    _Protection(
      Icons.phone_missed,
      _C.red,
      'Nunca atendas números desconhecidos',
    ),
    _Protection(
      Icons.hearing_disabled,
      _C.warn,
      'Nunca fales primeiro — espera que o outro lado fale',
    ),
    _Protection(
      Icons.key_outlined,
      _C.blue,
      'Cria uma palavra-código com a tua família',
    ),
    _Protection(
      Icons.call_end_rounded,
      _C.purple,
      'Em caso de dúvida, desliga e liga para o número oficial',
    ),
    _Protection(
      Icons.no_photography_outlined,
      _C.accent,
      'Limita o áudio da tua voz disponível publicamente',
    ),
    _Protection(
      Icons.report_gmailerrorred_outlined,
      _C.red,
      'Reporta chamadas suspeitas à operadora ou autoridades',
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _ChatBubble {
  final String text;
  final bool isAi;
  _ChatBubble({required this.text, required this.isAi});
}

class _BubbleRow extends StatelessWidget {
  final _ChatBubble bubble;
  const _BubbleRow({required this.bubble});

  @override
  Widget build(BuildContext context) {
    final isAi = bubble.isAi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isAi
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAi) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.red.withAlpha(25),
              ),
              child: const Icon(
                Icons.record_voice_over,
                color: _C.red,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAi ? _C.surface : _C.accent.withAlpha(20),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: isAi ? Radius.zero : const Radius.circular(14),
                  bottomRight: isAi ? const Radius.circular(14) : Radius.zero,
                ),
                border: Border.all(
                  color: isAi ? _C.red.withAlpha(50) : _C.accent.withAlpha(50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAi)
                    Text(
                      '🔴 Voz clonada',
                      style: GoogleFonts.jetBrainsMono(
                        color: _C.red,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (isAi) const SizedBox(height: 4),
                  Text(
                    bubble.text,
                    style: GoogleFonts.inter(
                      color: isAi ? _C.text : _C.accent,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isAi) ...[
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.accent.withAlpha(20),
              ),
              child: const Icon(Icons.person, color: _C.accent, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.red.withAlpha(25),
            ),
            child: const Icon(Icons.record_voice_over, color: _C.red, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: _C.red.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(3, (i) {
                  return Padding(
                    padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                    child: const _DotBlink(),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotBlink extends StatefulWidget {
  const _DotBlink();
  @override
  State<_DotBlink> createState() => _DotBlinkState();
}

class _DotBlinkState extends State<_DotBlink>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: const CircleAvatar(radius: 3, backgroundColor: _C.red),
    );
  }
}

class _CallActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CallActionBtn({
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(100),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(color: _C.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _GridBg extends StatelessWidget {
  final AnimationController controller;
  const _GridBg({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _GridPainter(controller.value),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double t;
  _GridPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2535).withAlpha(40)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) => false;
}

// ─── Small widgets ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.syne(
      color: _C.text,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _WarningBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _WarningBanner({
    required this.icon,
    required this.color,
    required this.text,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final String n;
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  const _RuleCard({
    required this.n,
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.syne(
                    color: _C.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
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

class _StatItem {
  final String value;
  final String label;
  final Color color;
  const _StatItem(this.value, this.label, this.color);
}

class _StatGrid extends StatelessWidget {
  final List<_StatItem> items;
  const _StatGrid({required this.items});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.7,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.value,
                style: GoogleFonts.syne(
                  color: item.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: GoogleFonts.inter(color: _C.muted, fontSize: 10),
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final String? sublabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _BigButton({
    required this.label,
    this.sublabel,
    required this.icon,
    required this.color,
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
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.black, 0.3)!],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.syne(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Text(
                sublabel!,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String body;
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.body,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              body,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepItem {
  final String n;
  final Color color;
  final String title;
  final String body;
  const _StepItem(this.n, this.color, this.title, this.body);
}

class _StepCard extends StatelessWidget {
  final List<_StepItem> steps;
  const _StepCard({required this.steps});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: steps
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: s.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          s.n,
                          style: GoogleFonts.syne(
                            color: s.color,
                            fontSize: 11,
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
                          Text(
                            s.title,
                            style: GoogleFonts.syne(
                              color: _C.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.body,
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
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Protection {
  final IconData icon;
  final Color color;
  final String text;
  const _Protection(this.icon, this.color, this.text);
}

class _ProtectionRow extends StatelessWidget {
  final _Protection rule;
  const _ProtectionRow({required this.rule});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: rule.color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(rule.icon, color: rule.color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rule.text,
              style: GoogleFonts.inter(color: _C.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _ScoreStat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.syne(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(color: _C.muted, fontSize: 11)),
      ],
    );
  }
}
