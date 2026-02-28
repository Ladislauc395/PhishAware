import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_models.dart';
import 'api_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

enum _MsgType { chat, urlAnalysis, quizChallenge, detectiveMode, tip }

class _Message {
  final String text;
  final bool isUser;
  final _MsgType type;
  final Map<String, dynamic>? extra;

  _Message({
    required this.text,
    required this.isUser,
    this.type = _MsgType.chat,
    this.extra,
  });
}

class _QuizData {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  _QuizData({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class _AssistantScreenState extends State<AssistantScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  final List<Map<String, String>> _history = [];
  bool _isLoading = false;
  String _activeMode = 'chat';

  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    _messages.add(_Message(
      text:
          'Olá! Sou o **Sentinela** 🛡️\n\nSou o teu assistente de cibersegurança especializado em phishing. Posso:\n\n🔍 **Analisar URLs** suspeitos\n🧠 **Lançar quizzes** para testar os teus conhecimentos\n🕵️ **Guiar-te** como detetive numa análise real\n💬 **Responder** a qualquer dúvida de segurança\n\nEscolhe um modo ou faz-me uma pergunta!',
      isUser: false,
      type: _MsgType.chat,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _fabAnim.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send({String? overrideText}) async {
    final text = overrideText ?? _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    if (overrideText == null) _controller.clear();

    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _messages.add(_Message(text: '', isUser: false)); // placeholder
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final contextPrefix = _buildContextPrefix(text);
      final reply =
          await ApiService.sendChatMessage(contextPrefix + text, _history);
      _history.add({'role': 'user', 'text': text});
      _history.add({'role': 'model', 'text': reply});
      setState(() {
        _messages[_messages.length - 1] = _Message(text: reply, isUser: false);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _messages[_messages.length - 1] = _Message(
          text:
              '⚠️ Erro de ligação. Verifica se o backend está a correr em localhost:8000.',
          isUser: false,
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  String _buildContextPrefix(String userText) {
    switch (_activeMode) {
      case 'url':
        return '[MODO ANÁLISE DE URL] O utilizador vai partilhar um URL ou texto suspeito. Analisa-o em detalhe, identifica red flags, verifica domínio, protocolo, typosquatting, urgência artificial, etc. Responde em Português PT. URL/Texto: ';
      case 'quiz':
        return '[MODO QUIZ] Cria um quiz de 1 pergunta sobre phishing com 4 opções (A,B,C,D), indica a resposta correcta e explica. Relaciona com: ';
      case 'detective':
        return '[MODO DETETIVE] Actua como mentor de cibersegurança. Guia o utilizador passo a passo para analisar este cenário suspeito como um detetive digital. Pergunta uma coisa de cada vez. Cenário: ';
      default:
        return '';
    }
  }

  void _activateUrlMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _activeMode = 'url';
      _messages.add(_Message(
        text:
            '🔍 **Modo Análise de URL activado!**\n\nCola um URL ou texto suspeito e vou analisar:\n• Domínio e TLD\n• Protocolo (http vs https)\n• Typosquatting\n• Padrões de phishing conhecidos\n• Nível de risco',
        isUser: false,
        type: _MsgType.urlAnalysis,
      ));
    });
    _scrollToBottom();
  }

  void _activateQuizMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _activeMode = 'quiz';
    });
    final quiz = _getRandomQuiz();
    setState(() {
      _messages.add(_Message(
        text: '',
        isUser: false,
        type: _MsgType.quizChallenge,
        extra: {
          'question': quiz.question,
          'options': quiz.options,
          'correctIndex': quiz.correctIndex,
          'explanation': quiz.explanation,
          'answered': false,
          'selectedIndex': -1,
        },
      ));
    });
    _scrollToBottom();
  }

  void _activateDetectiveMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _activeMode = 'detective';
      _messages.add(_Message(
        text:
            '🕵️ **Modo Detetive activado!**\n\nVou apresentar-te um cenário suspeito e guiar-te passo a passo na análise. Responde às minhas perguntas para descobrires se é phishing.\n\nQual o tipo de cenário que queres analisar?\n• Email corporativo\n• SMS bancário\n• URL suspeito\n• QR code desconhecido',
        isUser: false,
        type: _MsgType.detectiveMode,
      ));
    });
    _scrollToBottom();
  }

  void _quickAnalyze(String text) {
    _activateUrlMode();
    Future.delayed(
        const Duration(milliseconds: 300), () => _send(overrideText: text));
  }

  _QuizData _getRandomQuiz() {
    final quizzes = [
      _QuizData(
        question:
            'Um email diz "A tua conta será encerrada em 2 HORAS". O que é este tipo de técnica?',
        options: [
          'Spear phishing',
          'Urgência artificial (Fear-Based)',
          'Pharming',
          'Baiting'
        ],
        correctIndex: 1,
        explanation:
            'Urgência artificial cria pânico para que cliques sem pensar. É uma das técnicas mais comuns em phishing.',
      ),
      _QuizData(
        question: 'Qual destes URLs é mais provável de ser phishing?',
        options: [
          'https://ctt.pt/tracking',
          'http://ctt-rastreio.online/pacote',
          'https://www.ctt.pt',
          'ctt.pt/info'
        ],
        correctIndex: 1,
        explanation:
            '"ctt-rastreio.online" usa um domínio alternativo. O oficial é sempre ctt.pt.',
      ),
      _QuizData(
        question: 'O https:// (cadeado verde) num site significa que...',
        options: [
          'O site é 100% seguro e legítimo',
          'O dono do site é verificado',
          'A comunicação está encriptada',
          'O site foi aprovado pelo governo'
        ],
        correctIndex: 2,
        explanation:
            'https:// encripta APENAS a comunicação. Sites de phishing também podem ter certificado SSL válido!',
      ),
      _QuizData(
        question: 'O que é "typosquatting"?',
        options: [
          'Roubo de passwords por força bruta',
          'Registo de domínios com erros ortográficos para enganar',
          'Envio de spam em massa',
          'Ataque por rede Wi-Fi pública'
        ],
        correctIndex: 1,
        explanation:
            'Ex: "amaz0n.com" em vez de "amazon.com". O "0" substitui o "o" para enganar utilizadores desatentos.',
      ),
      _QuizData(
        question:
            'Recebes um SMS dos CTT a pedir 1.99€ para "taxas aduaneiras". O que fazes?',
        options: [
          'Pago, é uma quantia pequena',
          'Verifico diretamente em ctt.pt',
          'Respondo ao SMS para confirmar',
          'Reenvio aos contactos para alertar'
        ],
        correctIndex: 1,
        explanation:
            'Vai SEMPRE ao site oficial. Os CTT e outros nunca pedem pagamentos por SMS com links externos.',
      ),
      _QuizData(
        question: 'O que é "smishing"?',
        options: [
          'Phishing por email',
          'Phishing por SMS/mensagem de texto',
          'Phishing por chamada telefónica',
          'Phishing por QR code'
        ],
        correctIndex: 1,
        explanation:
            'Smishing = SMS + Phishing. É cada vez mais comum pois os telemóveis têm menos proteções do que email corporativo.',
      ),
    ];
    quizzes.shuffle();
    return quizzes.first;
  }

  void _answerQuiz(int msgIndex, int selectedIndex) {
    final msg = _messages[msgIndex];
    if (msg.extra?['answered'] == true) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _messages[msgIndex] = _Message(
        text: msg.text,
        isUser: false,
        type: _MsgType.quizChallenge,
        extra: {
          ...msg.extra!,
          'answered': true,
          'selectedIndex': selectedIndex,
        },
      );
    });
    _scrollToBottom();
  }

  List<String> get _suggestions {
    switch (_activeMode) {
      case 'url':
        return [
          'http://banco-portugal-seguro.xyz/login',
          'https://paypa1.com/conta',
          'ctt-entrega.online/pagamento',
          'bit.ly/3xK9abc',
        ];
      case 'detective':
        return [
          'Email corporativo',
          'SMS bancário',
          'URL suspeito',
          'QR code público'
        ];
      default:
        return [
          'O que é phishing?',
          'Como identifico um email falso?',
          'O que é smishing?',
          'Como protejo as minhas contas?',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _ModeBar(
              activeMode: _activeMode,
              onUrlMode: _activateUrlMode,
              onQuizMode: _activateQuizMode,
              onDetectiveMode: _activateDetectiveMode,
              onChatMode: () => setState(() => _activeMode = 'chat')),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_messages.length == 1 ? 1 : 0),
              itemBuilder: (_, i) {
                if (_messages.length == 1 && i == 1) {
                  return _SuggestionsRow(
                    suggestions: _suggestions,
                    onTap: (s) {
                      _controller.text = s;
                      _send();
                    },
                  );
                }
                final msg = _messages[i];
                if (msg.type == _MsgType.quizChallenge) {
                  return _QuizBubble(
                    extra: msg.extra!,
                    onAnswer: (idx) => _answerQuiz(i, idx),
                    onAskMore: () => _send(
                        overrideText:
                            'Explica mais sobre este tema de phishing'),
                  );
                }
                return _Bubble(message: msg);
              },
            ),
          ),
          if (!_isLoading && _messages.isNotEmpty)
            _ContextSuggestions(
              mode: _activeMode,
              suggestions:
                  _activeMode != 'chat' ? _suggestions.take(2).toList() : [],
              onTap: (s) => _send(overrideText: s),
            ),
          _InputBar(
            controller: _controller,
            isLoading: _isLoading,
            activeMode: _activeMode,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.accent.withAlpha(80),
              AppColors.blue.withAlpha(80)
            ]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.smart_toy_outlined,
              color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sentinela',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('Especialista Anti-Phishing',
                  style:
                      GoogleFonts.inter(color: AppColors.accent, fontSize: 9)),
            ]),
          ],
        ),
      ]),
      actions: [
        IconButton(
          icon: Icon(Icons.link_outlined, color: AppColors.textMuted, size: 22),
          tooltip: 'Analisar URL',
          onPressed: _activateUrlMode,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  final String activeMode;
  final VoidCallback onChatMode, onUrlMode, onQuizMode, onDetectiveMode;

  const _ModeBar({
    required this.activeMode,
    required this.onChatMode,
    required this.onUrlMode,
    required this.onQuizMode,
    required this.onDetectiveMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          _ModeChip(
            icon: '💬',
            label: 'Chat',
            active: activeMode == 'chat',
            onTap: onChatMode,
          ),
          const SizedBox(width: 8),
          _ModeChip(
            icon: '🔍',
            label: 'Analisar URL',
            active: activeMode == 'url',
            color: AppColors.blue,
            onTap: onUrlMode,
          ),
          const SizedBox(width: 8),
          _ModeChip(
            icon: '🧠',
            label: 'Quiz Rápido',
            active: activeMode == 'quiz',
            color: AppColors.warn,
            onTap: onQuizMode,
          ),
          const SizedBox(width: 8),
          _ModeChip(
            icon: '🕵️',
            label: 'Modo Detetive',
            active: activeMode == 'detective',
            color: AppColors.accent2,
            onTap: onDetectiveMode,
          ),
        ]),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String icon, label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color.withAlpha(25) : AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  color: active ? color : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
        ]),
      ),
    );
  }
}

class _QuizBubble extends StatelessWidget {
  final Map<String, dynamic> extra;
  final ValueChanged<int> onAnswer;
  final VoidCallback onAskMore;

  const _QuizBubble(
      {required this.extra, required this.onAnswer, required this.onAskMore});

  @override
  Widget build(BuildContext context) {
    final question = extra['question'] as String;
    final options = extra['options'] as List<String>;
    final correctIndex = extra['correctIndex'] as int;
    final explanation = extra['explanation'] as String;
    final answered = extra['answered'] as bool;
    final selectedIndex = extra['selectedIndex'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: answered
              ? (selectedIndex == correctIndex
                      ? AppColors.accent
                      : AppColors.danger)
                  .withAlpha(100)
              : AppColors.warn.withAlpha(80),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warn.withAlpha(15),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warn.withAlpha(15),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              const Text('🧠', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text('QUIZ RÁPIDO',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.warn,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const Spacer(),
              if (!answered)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warn.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.warn.withAlpha(60)),
                  ),
                  child: Text('Toca para responder',
                      style: GoogleFonts.inter(
                          color: AppColors.warn, fontSize: 9)),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Text(question,
                style: GoogleFonts.spaceGrotesk(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: options.asMap().entries.map((e) {
                final idx = e.key;
                final opt = e.value;
                Color bgColor = AppColors.surface2;
                Color borderColor = AppColors.border;
                Color textColor = AppColors.text;

                if (answered) {
                  if (idx == correctIndex) {
                    bgColor = AppColors.accent.withAlpha(20);
                    borderColor = AppColors.accent.withAlpha(100);
                    textColor = AppColors.accent;
                  } else if (idx == selectedIndex) {
                    bgColor = AppColors.danger.withAlpha(15);
                    borderColor = AppColors.danger.withAlpha(80);
                    textColor = AppColors.danger;
                  } else {
                    bgColor = AppColors.surface2.withAlpha(100);
                    borderColor = AppColors.border.withAlpha(50);
                    textColor = AppColors.textMuted;
                  }
                }

                return GestureDetector(
                  onTap: answered ? null : () => onAnswer(idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: answered && idx == correctIndex
                              ? AppColors.accent.withAlpha(20)
                              : answered && idx == selectedIndex
                                  ? AppColors.danger.withAlpha(20)
                                  : Colors.white.withAlpha(10),
                          border: Border.all(
                            color: answered && idx == correctIndex
                                ? AppColors.accent
                                : answered && idx == selectedIndex
                                    ? AppColors.danger
                                    : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: answered &&
                                  (idx == correctIndex || idx == selectedIndex)
                              ? Icon(
                                  idx == correctIndex
                                      ? Icons.check
                                      : Icons.close,
                                  size: 12,
                                  color: idx == correctIndex
                                      ? AppColors.accent
                                      : AppColors.danger,
                                )
                              : Text(
                                  String.fromCharCode(65 + idx),
                                  style: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(opt,
                            style: GoogleFonts.inter(
                                color: textColor, fontSize: 12, height: 1.4)),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
          if (answered) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (selectedIndex == correctIndex
                          ? AppColors.accent
                          : AppColors.danger)
                      .withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (selectedIndex == correctIndex
                            ? AppColors.accent
                            : AppColors.danger)
                        .withAlpha(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(selectedIndex == correctIndex ? '✅' : '❌',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        selectedIndex == correctIndex
                            ? 'Correcto!'
                            : 'Não foi desta!',
                        style: GoogleFonts.spaceGrotesk(
                            color: selectedIndex == correctIndex
                                ? AppColors.accent
                                : AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(explanation,
                        style: GoogleFonts.inter(
                            color: AppColors.text, fontSize: 11, height: 1.5)),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(children: [
              if (answered)
                Expanded(
                  child: GestureDetector(
                    onTap: onAskMore,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text('💬 Quero saber mais sobre este tema',
                            style: GoogleFonts.inter(
                                color: AppColors.textMuted, fontSize: 11)),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ContextSuggestions extends StatelessWidget {
  final String mode;
  final List<String> suggestions;
  final ValueChanged<String> onTap;

  const _ContextSuggestions(
      {required this.mode, required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    String modeLabel;
    Color modeColor;
    switch (mode) {
      case 'url':
        modeLabel = '🔍 Exemplos para analisar:';
        modeColor = AppColors.blue;
        break;
      case 'quiz':
        modeLabel = '🧠 Tópicos para quiz:';
        modeColor = AppColors.warn;
        break;
      case 'detective':
        modeLabel = '🕵️ Cenários:';
        modeColor = AppColors.accent2;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(modeLabel,
              style: GoogleFonts.inter(
                  color: modeColor, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions
                  .map((s) => GestureDetector(
                        onTap: () => onTap(s),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: modeColor.withAlpha(10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: modeColor.withAlpha(40)),
                          ),
                          child: Text(s,
                              style: GoogleFonts.inter(
                                  color: modeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsRow extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;
  const _SuggestionsRow({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions
            .map((s) => GestureDetector(
                  onTap: () => onTap(s),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(s,
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted, fontSize: 12)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Message message;
  const _Bubble({required this.message});

  List<InlineSpan> _parseText(String text, bool isUser) {
    final spans = <InlineSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: GoogleFonts.inter(
          color: isUser ? Colors.black : AppColors.text,
          fontSize: 14,
          height: 1.5,
          fontWeight: i % 2 == 1 ? FontWeight.w700 : FontWeight.normal,
        ),
      ));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    Color? modeColor;
    String? modeLabel;
    if (!isUser) {
      switch (message.type) {
        case _MsgType.urlAnalysis:
          modeColor = AppColors.blue;
          modeLabel = '🔍 ANÁLISE DE URL';
          break;
        case _MsgType.detectiveMode:
          modeColor = AppColors.accent2;
          modeLabel = '🕵️ MODO DETETIVE';
          break;
        case _MsgType.tip:
          modeColor = AppColors.accent;
          modeLabel = '💡 DICA';
          break;
        default:
          break;
      }
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentAlt])
              : null,
          color: isUser ? null : AppColors.surface,
          border: isUser
              ? null
              : Border.all(
                  color: modeColor != null
                      ? modeColor.withAlpha(60)
                      : AppColors.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: isUser
              ? [
                  BoxShadow(
                      color: AppColors.accent.withAlpha(30),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : modeColor != null
                  ? [
                      BoxShadow(
                          color: modeColor.withAlpha(15),
                          blurRadius: 16,
                          spreadRadius: -4)
                    ]
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (modeLabel != null && modeColor != null)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: modeColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: modeColor.withAlpha(60)),
                  ),
                  child: Text(modeLabel,
                      style: GoogleFonts.inter(
                          color: modeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ),
              ),
            Padding(
              padding:
                  EdgeInsets.fromLTRB(14, modeLabel != null ? 8 : 14, 14, 14),
              child: message.text.isEmpty && !isUser
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(delay: 0),
                        const SizedBox(width: 4),
                        _Dot(delay: 200),
                        const SizedBox(width: 4),
                        _Dot(delay: 400)
                      ],
                    )
                  : RichText(
                      text:
                          TextSpan(children: _parseText(message.text, isUser)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String activeMode;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.activeMode,
    required this.onSend,
  });

  String get _hint {
    switch (activeMode) {
      case 'url':
        return 'Cola um URL ou texto suspeito...';
      case 'quiz':
        return 'Pede um quiz sobre um tema específico...';
      case 'detective':
        return 'Descreve o cenário suspeito...';
      default:
        return 'Pergunta ao Sentinela...';
    }
  }

  Color get _accentColor {
    switch (activeMode) {
      case 'url':
        return AppColors.blue;
      case 'quiz':
        return AppColors.warn;
      case 'detective':
        return AppColors.accent2;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _accentColor.withAlpha(40)),
                ),
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onSend(),
                  maxLines: 3,
                  minLines: 1,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _hint,
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: isLoading ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLoading ? AppColors.surface2 : _accentColor,
                  boxShadow: isLoading
                      ? null
                      : [
                          BoxShadow(
                              color: _accentColor.withAlpha(60), blurRadius: 12)
                        ],
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _accentColor),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.black, size: 18),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0.3, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: AppColors.textMuted, shape: BoxShape.circle)),
      );
}
