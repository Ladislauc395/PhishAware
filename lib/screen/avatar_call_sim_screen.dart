import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// BACKEND API
// ═══════════════════════════════════════════════════════════════════════════

class _AvatarCallApi {
  static String get _base => ApiService.baseUrl;
  static Map<String, String> get _auth => {
    if (ApiService.authToken.isNotEmpty)
      'Authorization': 'Bearer ${ApiService.authToken}',
  };

  static Future<String> transcribe(String filePath) async {
    try {
      final req =
          http.MultipartRequest(
              'POST',
              Uri.parse('$_base/avatar-call/transcribe'),
            )
            ..headers.addAll(_auth)
            ..files.add(await http.MultipartFile.fromPath('audio', filePath));
      final res = await req.send().timeout(const Duration(seconds: 25));
      final body = await res.stream.bytesToString();
      return (jsonDecode(body)['text'] ?? '').toString().trim();
    } catch (_) {
      return '';
    }
  }

  /// Backend devolve:
  /// { reply, ended, user_won }
  /// - ended:false           → conversa continua
  /// - ended:true, user_won:true  → utilizador recusou → WIN
  /// - ended:true, user_won:false → utilizador cedeu dados → LOSE
  static Future<_AiReply> respond({
    required String scenarioId,
    required String userMessage,
    required List<Map<String, String>> history,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/avatar-call/respond'),
            headers: {'Content-Type': 'application/json', ..._auth},
            body: jsonEncode({
              'scenario_id': scenarioId,
              'user_id': ApiService.currentUserId,
              'user_message': userMessage,
              'history': history,
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) throw Exception('${res.statusCode}');
      final j = jsonDecode(res.body);
      return _AiReply(
        text: j['reply']?.toString() ?? '',
        ended: j['ended'] == true,
        userWon: j['user_won'] == true,
      );
    } catch (_) {
      return _AiReply(
        text: 'Pode repetir? Não percebi bem.',
        ended: false,
        userWon: false,
      );
    }
  }

  static Future<String?> speak(String text, {String scenarioId = ''}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/avatar-call/speak'),
            headers: {'Content-Type': 'application/json', ..._auth},
            body: jsonEncode({'text': text, 'scenario_id': scenarioId}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      await file.writeAsBytes(res.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}

class _AiReply {
  final String text;
  final bool ended;
  final bool userWon;
  _AiReply({required this.text, required this.ended, required this.userWon});
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════

class CallScenario {
  final String id;
  final String callerName;
  final String organization;
  final String roleLabel;
  final String callerEmoji;
  final Color avatarColor;
  final String attackType;
  final String openingLine;
  final List<String> allRedFlags;
  final String educationalTip;
  final int xpIfWin;
  final int xpIfLose;

  const CallScenario({
    required this.id,
    required this.callerName,
    required this.organization,
    required this.roleLabel,
    required this.callerEmoji,
    required this.avatarColor,
    required this.attackType,
    required this.openingLine,
    required this.allRedFlags,
    required this.educationalTip,
    this.xpIfWin = 200,
    this.xpIfLose = 25,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// CENÁRIOS
// ═══════════════════════════════════════════════════════════════════════════

final List<CallScenario> kAvatarCallScenarios = [
  const CallScenario(
    id: 'bank_vishing',
    callerName: 'Ana Ferreira',
    organization: 'BPI Banco',
    roleLabel: 'Segurança Bancária',
    callerEmoji: '👩‍💼',
    avatarColor: Color(0xFF003087),
    attackType: 'Vishing Bancário',
    openingLine:
        'Boa tarde, fala com a Ana Ferreira do BPI. Detetámos uma movimentação suspeita na sua conta. Consegue falar agora?',
    allRedFlags: [
      'Chamada não solicitada alegando ser do banco',
      'Urgência com ameaça de bloqueio imediato',
      'Pedido de PIN por telefone — bancos NUNCA pedem',
      'Pedido de NIF e dados pessoais por chamada',
      'Pressão para agir sem tempo de verificar',
    ],
    educationalTip:
        'O teu banco NUNCA pede o PIN, código de confirmação ou password por telefone. '
        'Se receberes esta chamada, desliga e liga para o número oficial no verso do cartão.',
    xpIfWin: 200,
    xpIfLose: 25,
  ),
  const CallScenario(
    id: 'microsoft_support',
    callerName: 'Carlos Mendes',
    organization: 'Microsoft Portugal',
    roleLabel: 'Suporte Técnico',
    callerEmoji: '👨‍💻',
    avatarColor: Color(0xFF00A4EF),
    attackType: 'Vishing Suporte TI',
    openingLine:
        'Olá, Carlos da Microsoft. Os nossos sistemas detetaram erros críticos no seu computador. Preciso de acesso remoto urgente para resolver.',
    allRedFlags: [
      'A Microsoft não monitoriza computadores individuais',
      'Chamada não solicitada sobre vírus',
      'Pedido de acesso remoto ao computador',
      'Cobrança de taxa de suporte técnico falsa',
      'Jargão técnico para intimidar',
    ],
    educationalTip:
        'A Microsoft nunca liga espontaneamente sobre vírus. '
        'Se precisares de suporte, és TU que contactas pelo número oficial em support.microsoft.com.',
    xpIfWin: 180,
    xpIfLose: 25,
  ),
  const CallScenario(
    id: 'ctt_parcel',
    callerName: 'Rui Santos',
    organization: 'CTT Expresso',
    roleLabel: 'Serviço ao Cliente',
    callerEmoji: '📦',
    avatarColor: Color(0xFFE2001A),
    attackType: 'Vishing CTT',
    openingLine:
        'Boa tarde, contacto dos CTT. A sua encomenda está retida na alfândega por falta de pagamento de €2,99. Será devolvida em 24h se não regularizar.',
    allRedFlags: [
      'CTT não cobram taxas por telefone',
      'Prazo de 24h criado para pressionar',
      'Pedido de dados bancários por chamada',
      'Valor pequeno para parecer inofensivo',
      'Número de encomenda genérico não verificável',
    ],
    educationalTip:
        'Os CTT notificam apenas por email ou SMS oficial. '
        'Para pagar taxas vai sempre a ctt.pt — nunca dês dados de pagamento por telefone.',
    xpIfWin: 160,
    xpIfLose: 25,
  ),
  const CallScenario(
    id: 'tax_authority',
    callerName: 'Inspector Gomes',
    organization: 'Autoridade Tributária',
    roleLabel: 'Inspeção Fiscal',
    callerEmoji: '🏛️',
    avatarColor: Color(0xFF00439C),
    attackType: 'Fraude Fiscal',
    openingLine:
        'Boa tarde, Inspector Gomes da AT. Existe uma irregularidade no seu IRS e foi iniciado um processo de penhora. Pode resolver ainda hoje se colaborar.',
    allRedFlags: [
      'AT não inicia penhoras por telefone',
      'Ameaça de penhora imediata para criar pânico',
      'Pedido de IBAN e NIF por chamada',
      'Deadline falso — hoje à meia-noite',
      'Linguagem jurídica para intimidar',
    ],
    educationalTip:
        'A AT comunica SEMPRE por carta registada ou Portal das Finanças. '
        'Qualquer dívida real pode ser verificada em portaldasfinancas.gov.pt.',
    xpIfWin: 220,
    xpIfLose: 25,
  ),
  const CallScenario(
    id: 'hr_internal',
    callerName: 'Sofia Leal',
    organization: 'Recursos Humanos',
    roleLabel: 'RH — Salários',
    callerEmoji: '👩‍💼',
    avatarColor: Color(0xFF7C3AED),
    attackType: 'Vishing Corporativo',
    openingLine:
        'Olá! Sofia dos RH. Estamos a atualizar dados bancários para o novo sistema salarial. Precisava de confirmar o seu IBAN para garantir o pagamento deste mês.',
    allRedFlags: [
      'RH nunca pede IBAN por telefone',
      'Atualização bancária deveria ser feita pelo portal',
      'Urgência com fim de mês como pretexto',
      'Recolha progressiva de dados sensíveis',
      'Social proof: "já falámos com todos os colegas"',
    ],
    educationalTip:
        'Atualizações de dados bancários fazem-se SEMPRE pelo portal self-service. '
        'RH nunca pede passwords por telefone — é sempre fraude.',
    xpIfWin: 250,
    xpIfLose: 25,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// ENTRY CARD
// ═══════════════════════════════════════════════════════════════════════════

class AvatarCallSimCard extends StatelessWidget {
  const AvatarCallSimCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => const AvatarCallSimLauncher(),
            transitionsBuilder: (_, a, __, child) => FadeTransition(
              opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF150A1F), Color(0xFF091420)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.40),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
              blurRadius: 28,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('📞', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Chamada Suspeita',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.syne(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0EA5E9,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(
                              0xFFB24BF3,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'NOVO',
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF0EA5E9),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chamada real com IA • Fala ou escreve • Vishing',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    runSpacing: 4,
                    spacing: 6,
                    children: [
                      _MiniTag('🏦 Banco', const Color(0xFF003087)),
                      _MiniTag('🖥 TI', const Color(0xFF00A4EF)),
                      _MiniTag('🏛 AT', const Color(0xFF00439C)),
                      _MiniTag('📦 CTT', const Color(0xFFE2001A)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: color.withValues(alpha: 0.9),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LAUNCHER
// ═══════════════════════════════════════════════════════════════════════════

class AvatarCallSimLauncher extends StatelessWidget {
  const AvatarCallSimLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1520),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chamada Suspeita',
                          style: GoogleFonts.syne(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Conversa real com IA • Identifica e desliga',
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
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFB24BF3).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A IA tenta manipular-te. Desliga quando identificares engenharia social — não precisa de dizer porquê.',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kAvatarCallScenarios.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final s = kAvatarCallScenarios[i];
                  return _ScenarioCard(
                    scenario: s,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        ctx,
                        PageRouteBuilder(
                          pageBuilder: (_, a, __) =>
                              AvatarCallSimScreen(scenario: s),
                          transitionsBuilder: (_, a, __, child) =>
                              FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: a,
                                  curve: Curves.easeOut,
                                ),
                                child: child,
                              ),
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final CallScenario scenario;
  final VoidCallback onTap;
  const _ScenarioCard({required this.scenario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1520),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scenario.avatarColor.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: scenario.avatarColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: scenario.avatarColor.withValues(alpha: 0.35),
                ),
              ),
              child: Center(
                child: Text(
                  scenario.callerEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario.organization,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.syne(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scenario.callerName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scenario.avatarColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: scenario.avatarColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      scenario.attackType,
                      style: GoogleFonts.jetBrainsMono(
                        color: scenario.avatarColor.withValues(alpha: 0.9),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${scenario.xpIfWin}',
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF00FF88),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'XP',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white30,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN SCREEN — UI DE CHAMADA REAL
// ═══════════════════════════════════════════════════════════════════════════

enum _SimPhase { incoming, active, result }

enum _ResultType { win, lose }

class AvatarCallSimScreen extends StatefulWidget {
  final CallScenario scenario;
  const AvatarCallSimScreen({super.key, required this.scenario});

  @override
  State<AvatarCallSimScreen> createState() => _AvatarCallSimScreenState();
}

class _AvatarCallSimScreenState extends State<AvatarCallSimScreen>
    with TickerProviderStateMixin {
  _SimPhase _phase = _SimPhase.incoming;
  _ResultType? _resultType;

  // Legenda atual (o que o avatar está a dizer)
  String _currentSubtitle = '';
  // O que o utilizador disse (aparece brevemente)
  String _userLastMsg = '';
  bool _showUserMsg = false;

  final List<Map<String, String>> _aiHistory = [];

  bool _avatarSpeaking = false;
  bool _userRecording = false;
  bool _loadingReply = false;
  bool _ttsEnabled = true;
  int _ttsFailCount = 0; // só desativa TTS depois de 3 falhas seguidas

  int _callSeconds = 0;
  Timer? _callTimer;
  Timer? _userMsgTimer;

  final TextEditingController _textCtrl = TextEditingController();
  bool _showTextInput = false;

  final AudioRecorder _recorder = AudioRecorder();
  late final AudioPlayer _player;

  late AnimationController _ringCtrl;
  late AnimationController _speakCtrl;
  late AnimationController _resultCtrl;
  late AnimationController _micPulseCtrl;
  late AnimationController _subtitleCtrl;

  CallScenario get _s => widget.scenario;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    // Configura o player para reprodução local
    _player.setReleaseMode(ReleaseMode.stop);

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _speakCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _micPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
    _subtitleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _speakCtrl.dispose();
    _resultCtrl.dispose();
    _micPulseCtrl.dispose();
    _subtitleCtrl.dispose();
    _callTimer?.cancel();
    _userMsgTimer?.cancel();
    _recorder.cancel();
    _player.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  // ── CALL CONTROL ────────────────────────────────────────────────────────

  void _acceptCall() {
    HapticFeedback.mediumImpact();
    _ringCtrl.stop();
    setState(() => _phase = _SimPhase.active);
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
    _avatarSpeak(_s.openingLine);
  }

  void _declineCall() {
    HapticFeedback.mediumImpact();
    _ringCtrl.stop();
    // Recusou antes de atender → vitória imediata
    _endWithResult(_ResultType.win);
  }

  /// O utilizador decide desligar → SEMPRE vitória
  void _hangUp() {
    HapticFeedback.heavyImpact();
    _callTimer?.cancel();
    _player.stop();
    _recorder.cancel();
    _endWithResult(_ResultType.win);
  }

  void _endWithResult(_ResultType type) {
    if (_phase == _SimPhase.result) return; // evita duplicados
    setState(() {
      _phase = _SimPhase.result;
      _resultType = type;
    });
    _resultCtrl.forward();
    ApiService.addXp(
      type == _ResultType.win ? _s.xpIfWin : _s.xpIfLose,
      type == _ResultType.win,
      'vishing',
      scenario: _s.id,
    ).ignore();
  }

  // ── AVATAR SPEAK ─────────────────────────────────────────────────────────

  Future<void> _avatarSpeak(String text) async {
    if (!mounted) return;
    setState(() {
      _avatarSpeaking = true;
      _currentSubtitle = text;
    });
    _aiHistory.add({'role': 'assistant', 'content': text});
    _speakCtrl.repeat(reverse: true);
    _subtitleCtrl.forward(from: 0);

    bool audioPlayed = false;

    if (_ttsEnabled) {
      try {
        final path = await _AvatarCallApi.speak(text, scenarioId: _s.id);
        if (path != null && mounted) {
          // Para qualquer áudio anterior
          await _player.stop();
          // Pequena pausa para garantir que o ficheiro está escrito
          await Future.delayed(const Duration(milliseconds: 100));
          // Reproduz o ficheiro local
          await _player.play(DeviceFileSource(path));
          // Aguarda o fim do áudio com timeout generoso
          await _player.onPlayerComplete.first.timeout(
            Duration(seconds: (text.length ~/ 6) + 8),
          );
          // Limpa o ficheiro temporário
          try {
            File(path).deleteSync();
          } catch (_) {}
          audioPlayed = true;
          _ttsFailCount = 0; // reset contador de falhas
        }
      } catch (e) {
        _ttsFailCount++;
        // Só desativa TTS depois de 3 falhas consecutivas
        if (_ttsFailCount >= 3) {
          _ttsEnabled = false;
        }
      }
    }

    // Fallback: espera tempo proporcional ao texto
    if (!audioPlayed) {
      await Future.delayed(
        Duration(milliseconds: 700 + (text.length * 38).clamp(0, 5000)),
      );
    }

    if (mounted) {
      _speakCtrl.stop();
      _speakCtrl.reset();
      setState(() {
        _avatarSpeaking = false;
        _currentSubtitle = '';
      });
    }
  }

  // ── USER INPUT ───────────────────────────────────────────────────────────

  Future<void> _sendText() async {
    final msg = _textCtrl.text.trim();
    if (msg.isEmpty || _loadingReply || _avatarSpeaking) return;
    _textCtrl.clear();
    setState(() => _showTextInput = false);
    _showUserSaid(msg);
    _aiHistory.add({'role': 'user', 'content': msg});
    await _fetchAiReply(msg);
  }

  Future<void> _toggleRecording() async {
    if (_userRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (_loadingReply || _avatarSpeaking || _userRecording) return;
    final ok = await _recorder.hasPermission();
    if (!ok) {
      _snack('Permissão de microfone necessária');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    if (mounted) {
      setState(() => _userRecording = true);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _stopRecording() async {
    if (!_userRecording) return;
    final path = await _recorder.stop();
    if (mounted) setState(() => _userRecording = false);
    if (path == null || !mounted) return;

    setState(() => _loadingReply = true);
    final transcript = await _AvatarCallApi.transcribe(path);
    try {
      File(path).deleteSync();
    } catch (_) {}
    if (!mounted) return;

    if (transcript.isNotEmpty) {
      setState(() => _loadingReply = false);
      _showUserSaid(transcript);
      _aiHistory.add({'role': 'user', 'content': transcript});
      await _fetchAiReply(transcript);
    } else {
      setState(() => _loadingReply = false);
      _snack('Não captei — escreve a resposta');
    }
  }

  /// Mostra brevemente o que o utilizador disse no ecrã
  void _showUserSaid(String text) {
    _userMsgTimer?.cancel();
    setState(() {
      _userLastMsg = text;
      _showUserMsg = true;
    });
    _userMsgTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showUserMsg = false);
    });
  }

  Future<void> _fetchAiReply(String userMsg) async {
    if (!mounted) return;
    setState(() => _loadingReply = true);

    final reply = await _AvatarCallApi.respond(
      scenarioId: _s.id,
      userMessage: userMsg,
      history: List.from(_aiHistory),
    );

    if (!mounted) return;
    setState(() => _loadingReply = false);

    if (reply.ended) {
      // Fala a última frase e só depois mostra resultado
      await _avatarSpeak(reply.text);
      if (mounted) {
        // user_won:true → utilizador recusou → WIN
        // user_won:false → utilizador cedeu → LOSE
        _endWithResult(reply.userWon ? _ResultType.win : _ResultType.lose);
      }
      return;
    }

    await _avatarSpeak(reply.text);
  }

  String get _duration {
    final m = _callSeconds ~/ 60;
    final s = _callSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF1A2535),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        child: switch (_phase) {
          _SimPhase.incoming => _buildIncoming(),
          _SimPhase.active => _buildActive(),
          _SimPhase.result => _buildResult(),
        },
      ),
    );
  }

  // ── INCOMING CALL ─────────────────────────────────────────────────────────
  Widget _buildIncoming() {
    return Stack(
      key: const ValueKey('incoming'),
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _ringCtrl,
          builder: (_, __) => CustomPaint(
            painter: _CallBgPainter(
              color: _s.avatarColor,
              intensity: 0.18 + _ringCtrl.value * 0.08,
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 56),
              Text(
                'Chamada Recebida',
                style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _s.organization,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 48),
              // Pulsing avatar
              AnimatedBuilder(
                animation: _ringCtrl,
                builder: (_, __) => SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: (1 - _ringCtrl.value) * 0.25,
                        child: Transform.scale(
                          scale: 1.0 + _ringCtrl.value * 0.7,
                          child: _ring(_s.avatarColor, 140),
                        ),
                      ),
                      Opacity(
                        opacity: (1 - _ringCtrl.value) * 0.12,
                        child: Transform.scale(
                          scale: 1.0 + _ringCtrl.value * 1.3,
                          child: _ring(_s.avatarColor, 140),
                        ),
                      ),
                      _AvatarCircle(
                        scenario: _s,
                        size: 140,
                        isSpeaking: false,
                        ctrl: _ringCtrl,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _s.callerName,
                style: GoogleFonts.syne(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _s.roleLabel,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 52),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CallActionBtn(
                      icon: Icons.call_end_rounded,
                      color: const Color(0xFFFF4444),
                      label: 'Recusar',
                      onTap: _declineCall,
                    ),
                    _CallActionBtn(
                      icon: Icons.call_rounded,
                      color: const Color(0xFF00D68F),
                      iconColor: Colors.black,
                      label: 'Atender',
                      onTap: _acceptCall,
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

  // ── ACTIVE CALL ───────────────────────────────────────────────────────────
  Widget _buildActive() {
    return Stack(
      key: const ValueKey('active'),
      fit: StackFit.expand,
      children: [
        // Background com cor do avatar
        AnimatedBuilder(
          animation: _speakCtrl,
          builder: (_, __) => CustomPaint(
            painter: _CallBgPainter(
              color: _s.avatarColor,
              intensity: _avatarSpeaking
                  ? 0.12 + _speakCtrl.value * 0.06
                  : 0.08,
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // ── Top bar: nome + tempo
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _s.callerName,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.syne(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _avatarSpeaking
                                      ? const Color(0xFF00D68F)
                                      : _loadingReply
                                      ? const Color(0xFFFFCC00)
                                      : Colors.white38,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _avatarSpeaking
                                    ? 'A falar…'
                                    : _loadingReply
                                    ? 'A pensar…'
                                    : _userRecording
                                    ? 'A ouvir-te…'
                                    : 'Em linha',
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
                    // Timer
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _duration,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Avatar central (ocupa a maior parte do ecrã)
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _speakCtrl,
                    builder: (_, __) {
                      final pulse = _avatarSpeaking ? _speakCtrl.value : 0.0;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Avatar com anéis de fala
                          SizedBox(
                            width: 220,
                            height: 220,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_avatarSpeaking) ...[
                                  Opacity(
                                    opacity: pulse * 0.35,
                                    child: Transform.scale(
                                      scale: 1.0 + pulse * 0.35,
                                      child: _ring(_s.avatarColor, 160),
                                    ),
                                  ),
                                  Opacity(
                                    opacity: pulse * 0.15,
                                    child: Transform.scale(
                                      scale: 1.0 + pulse * 0.65,
                                      child: _ring(_s.avatarColor, 160),
                                    ),
                                  ),
                                ],
                                _AvatarCircle(
                                  scenario: _s,
                                  size: 160,
                                  isSpeaking: _avatarSpeaking,
                                  ctrl: _speakCtrl,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Sound wave quando fala
                          if (_avatarSpeaking)
                            _SoundWave(color: _s.avatarColor, ctrl: _speakCtrl)
                          else
                            const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ── Subtítulos (o que o avatar está a dizer)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentSubtitle.isNotEmpty
                    ? Padding(
                        key: ValueKey(_currentSubtitle),
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            _currentSubtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.90),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      )
                    : _showUserMsg
                    ? Padding(
                        key: ValueKey('user_$_userLastMsg'),
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF00D68F,
                            ).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(
                                0xFF00D68F,
                              ).withValues(alpha: 0.20),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                color: Color(0xFF00D68F),
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _userLastMsg,
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(height: 52, key: ValueKey('empty')),
              ),

              const SizedBox(height: 16),

              // ── Input de texto (aparece quando ativado)
              if (_showTextInput)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1520),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            autofocus: true,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Escreve a resposta…',
                              hintStyle: GoogleFonts.inter(
                                color: Colors.white30,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: (_) => _sendText(),
                          ),
                        ),
                        GestureDetector(
                          onTap: _sendText,
                          child: Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF00D68F,
                              ).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Color(0xFF00D68F),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // ── Controlos da chamada
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 36),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Teclado / texto
                    _SmallCallBtn(
                      icon: _showTextInput
                          ? Icons.keyboard_hide_rounded
                          : Icons.keyboard_rounded,
                      label: 'Teclado',
                      color: Colors.white30,
                      onTap: () {
                        if (_avatarSpeaking || _loadingReply) return;
                        setState(() => _showTextInput = !_showTextInput);
                      },
                    ),

                    // Microfone — botão central grande
                    GestureDetector(
                      onTap: (_avatarSpeaking || _loadingReply)
                          ? null
                          : _toggleRecording,
                      child: AnimatedBuilder(
                        animation: _micPulseCtrl,
                        builder: (_, __) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _userRecording ? 76 : 68,
                          height: _userRecording ? 76 : 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _userRecording
                                ? const Color(0xFFFF4444)
                                : (_avatarSpeaking || _loadingReply)
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white.withValues(alpha: 0.12),
                            border: Border.all(
                              color: _userRecording
                                  ? const Color(0xFFFF4444).withValues(
                                      alpha: 0.5 + _micPulseCtrl.value * 0.45,
                                    )
                                  : Colors.white.withValues(alpha: 0.20),
                              width: _userRecording ? 2.5 : 1.5,
                            ),
                            boxShadow: _userRecording
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF4444).withValues(
                                        alpha: 0.35 + _micPulseCtrl.value * 0.2,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: -2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            _userRecording
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: _userRecording
                                ? Colors.white
                                : (_avatarSpeaking || _loadingReply)
                                ? Colors.white24
                                : Colors.white,
                            size: _userRecording ? 30 : 26,
                          ),
                        ),
                      ),
                    ),

                    // Desligar
                    _SmallCallBtn(
                      icon: Icons.call_end_rounded,
                      label: 'Desligar',
                      color: const Color(0xFFFF4444),
                      large: true,
                      onTap: _hangUp,
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

  // ── RESULT ────────────────────────────────────────────────────────────────
  Widget _buildResult() {
    final won = _resultType == _ResultType.win;
    final accent = won ? const Color(0xFF00D68F) : const Color(0xFFFF4444);

    return FadeTransition(
      key: const ValueKey('result'),
      opacity: CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut),
      child: Scaffold(
        backgroundColor: const Color(0xFF080C14),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Badge
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.09),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.45),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.22),
                        blurRadius: 36,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      won ? '🛡️' : '😬',
                      style: const TextStyle(fontSize: 46),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  won ? 'CHAMADA TERMINADA' : 'ATAQUE BEM SUCEDIDO',
                  style: GoogleFonts.jetBrainsMono(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  won
                      ? 'Resististe à manipulação!'
                      : 'A IA obteve os teus dados',
                  style: GoogleFonts.syne(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  won
                      ? 'Identificaste a tentativa de engenharia social e não cedeste informação.'
                      : 'Foram fornecidos dados sensíveis a um atacante. Vê o que aconteceu.',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 22),

                // Stats
                Row(
                  children: [
                    _StatChip(
                      label: 'XP',
                      value: won ? '+${_s.xpIfWin}' : '+${_s.xpIfLose}',
                      color: accent,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'DURAÇÃO',
                      value: _duration,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'CENÁRIO',
                      value: _s.attackType.split(' ').first,
                      color: _s.avatarColor,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // O QUE ACONTECEU — só aparece depois da simulação
                _ResultCard(
                  icon: '🎭',
                  title: 'O que estava a acontecer',
                  borderColor: const Color(0xFFFFCC00),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_s.callerName} (${_s.organization}) era um atacante usando a técnica de ${_s.attackType}.',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._s.allRedFlags.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFCC00),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  f,
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: 13,
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
                ),

                const SizedBox(height: 14),

                // DICA — só aparece depois da simulação
                _ResultCard(
                  icon: '💡',
                  title: 'Como te proteger',
                  borderColor: const Color(0xFF00D68F),
                  child: Text(
                    _s.educationalTip,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: won ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'VOLTAR ÀS SIMULAÇÕES',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SOUND WAVE WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _SoundWave extends StatelessWidget {
  final Color color;
  final AnimationController ctrl;
  const _SoundWave({required this.color, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(7, (i) {
            final phase = (i / 6) * math.pi;
            final h = 6.0 + 18.0 * math.sin(ctrl.value * math.pi + phase).abs();
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _AvatarCircle extends StatelessWidget {
  final CallScenario scenario;
  final double size;
  final bool isSpeaking;
  final AnimationController ctrl;

  const _AvatarCircle({
    required this.scenario,
    required this.size,
    required this.isSpeaking,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final pulse = isSpeaking ? ctrl.value : 0.0;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scenario.avatarColor,
            boxShadow: [
              BoxShadow(
                color: scenario.avatarColor.withValues(
                  alpha: 0.3 + pulse * 0.25,
                ),
                blurRadius: 24 + pulse * 18,
                spreadRadius: -6 + pulse * 6,
              ),
            ],
            border: Border.all(
              color: isSpeaking
                  ? Colors.white.withValues(alpha: 0.3 + pulse * 0.3)
                  : Colors.white.withValues(alpha: 0.15),
              width: isSpeaking ? 2.5 : 2,
            ),
          ),
          child: Center(
            child: Text(
              scenario.callerEmoji,
              style: TextStyle(fontSize: size * 0.38),
            ),
          ),
        );
      },
    );
  }
}

class _CallActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _CallActionBtn({
    required this.icon,
    required this.color,
    this.iconColor = Colors.white,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 30),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        label,
        style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
      ),
    ],
  );
}

class _SmallCallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool large;
  final VoidCallback onTap;
  const _SmallCallBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.large = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: large ? 58 : 52,
          height: large ? 58 : 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: large ? 1.0 : 0.12),
            border: large
                ? null
                : Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: large
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 18,
                      spreadRadius: -4,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            icon,
            color: large ? Colors.white : color,
            size: large ? 24 : 22,
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
      ),
    ],
  );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.syne(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white30,
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ResultCard extends StatelessWidget {
  final String icon;
  final String title;
  final Color borderColor;
  final Widget child;
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1520),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor.withValues(alpha: 0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.syne(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _CallBgPainter extends CustomPainter {
  final Color color;
  final double intensity;
  _CallBgPainter({required this.color, this.intensity = 0.10});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 0.85,
          colors: [
            color.withValues(alpha: intensity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(_CallBgPainter old) => old.intensity != intensity;
}
