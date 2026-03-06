import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});
  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> with TickerProviderStateMixin {
  int _selectedCategory = 0;
  late PageController _pageCtrl;
  late AnimationController _headerPulse;
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  final List<_CategoryData> _categories = const [
    _CategoryData(
        'Email', Icons.alternate_email_rounded, AppColors.accent, '6 dicas'),
    _CategoryData(
        'URLs', Icons.travel_explore_rounded, AppColors.blue, '6 dicas'),
    _CategoryData(
        'Mobile', Icons.smartphone_rounded, AppColors.warn, '6 dicas'),
    _CategoryData(
        'Proteção', Icons.verified_user_rounded, AppColors.accent2, '7 regras'),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _headerPulse =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _headerPulse.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _selectCategory(int index) {
    if (index == _selectedCategory) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = index);
    _pageCtrl.animateToPage(index,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic);
    _entryCtrl.reset();
    _entryCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        _buildHeader(),
        _buildCategoryRow(),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = i);
              _entryCtrl.reset();
              _entryCtrl.forward();
            },
            children: [
              _AnimatedTipList(
                  tips: _emailTips,
                  entryFade: _entryFade,
                  entrySlide: _entrySlide),
              _AnimatedTipList(
                  tips: _urlTips,
                  entryFade: _entryFade,
                  entrySlide: _entrySlide),
              _AnimatedTipList(
                  tips: _mobileTips,
                  entryFade: _entryFade,
                  entrySlide: _entrySlide),
              _AnimatedBestPractices(
                  entryFade: _entryFade, entrySlide: _entrySlide),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerPulse,
      builder: (_, __) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 16, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.bg,
            border:
                Border(bottom: BorderSide(color: Colors.white.withAlpha(8))),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Stack(alignment: Alignment.center, children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.accent
                        .withOpacity(0.12 + _headerPulse.value * 0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withAlpha(15),
                  border: Border.all(
                      color: AppColors.accent
                          .withOpacity(0.3 + _headerPulse.value * 0.2),
                      width: 1.5),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: AppColors.accent, size: 22),
              ),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Centro de\nInteligência',
                        style: GoogleFonts.syne(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.1)),
                    const SizedBox(height: 3),
                    Text('Conhecimento é a tua melhor defesa',
                        style: GoogleFonts.inter(
                            color: Colors.white.withAlpha(97),
                            fontSize: 11,
                            letterSpacing: 0.3)),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.danger
                        .withOpacity(0.2 + _headerPulse.value * 0.15),
                    width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.danger
                        .withOpacity(0.5 + _headerPulse.value * 0.5),
                  ),
                ),
                const SizedBox(width: 5),
                Text('ALERTA ATIVO',
                    style: GoogleFonts.jetBrainsMono(
                        color: AppColors.danger,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
              ]),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildCategoryRow() {
    return Container(
      height: 58,
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = i == _selectedCategory;
          return GestureDetector(
            onTap: () => _selectCategory(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              decoration: BoxDecoration(
                color: selected
                    ? cat.color.withAlpha(18)
                    : Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: selected
                        ? cat.color.withAlpha(70)
                        : Colors.white.withAlpha(10),
                    width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(cat.icon,
                    color: selected ? cat.color : Colors.white30, size: 14),
                const SizedBox(width: 7),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.label,
                          style: GoogleFonts.syne(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withAlpha(97),
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      Text(cat.count,
                          style: GoogleFonts.jetBrainsMono(
                              color: selected
                                  ? cat.color
                                  : Colors.white.withAlpha(51),
                              fontSize: 9)),
                    ]),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryData {
  final String label, count;
  final IconData icon;
  final Color color;
  const _CategoryData(this.label, this.icon, this.color, this.count);
}

class _TipData {
  final String title, description;
  final IconData icon;
  final Color color;
  final String? tag;
  const _TipData(this.title, this.description, this.icon, this.color,
      {this.tag});
}

const _emailTips = [
  _TipData(
      'Verifica sempre o remetente',
      'Empresas legítimas usam sempre o seu domínio oficial. "paypa1.com" ou "banco-seguro.info" são falsos. Passa o dedo sobre o email para ver o endereço real.',
      Icons.alternate_email_rounded,
      AppColors.accent,
      tag: 'BÁSICO'),
  _TipData(
      'Desconfia de urgência',
      '"A tua conta será suspensa em 24h!" é uma técnica de pressão psicológica. Empresas legítimas nunca criam pânico artificial para te forçar a agir sem pensar.',
      Icons.timer_off_outlined,
      AppColors.danger,
      tag: 'CRÍTICO'),
  _TipData(
      'Não abras anexos suspeitos',
      'Ficheiros .exe, .zip, .docm e .xlsm podem conter malware. Mesmo PDFs podem ter scripts maliciosos. Verifica com o remetente por outro canal antes de abrir.',
      Icons.attach_file_rounded,
      AppColors.warn,
      tag: 'PERIGO'),
  _TipData(
      'Links em emails: nunca confiar',
      'Mesmo que o link pareça correto, passa o dedo por cima para ver o URL real. Vai sempre ao site diretamente pelo browser em vez de clicar em links de email.',
      Icons.link_off_rounded,
      AppColors.blue,
      tag: 'BÁSICO'),
  _TipData(
      'Spear Phishing: ataques personalizados',
      'Atacantes recolhem informação do LinkedIn, redes sociais e bases de dados para criar emails com o teu nome, empresa e contexto real. Sê cético mesmo com contexto correto.',
      Icons.person_search_rounded,
      AppColors.accent2,
      tag: 'AVANÇADO'),
  _TipData(
      'Cabeçalhos de email revelam tudo',
      'Os cabeçalhos técnicos de um email mostram o servidor de origem real. Em clientes como Gmail, podes ver "Ver original" para verificar a autenticidade.',
      Icons.code_rounded,
      Color(0xFF6B7280),
      tag: 'TÉCNICO'),
];

const _urlTips = [
  _TipData(
      'HTTPS não significa seguro',
      'O cadeado verde apenas indica que a ligação é cifrada. Não garante que o site é legítimo. Sites phishing usam HTTPS com certificados gratuitos (Let\'s Encrypt).',
      Icons.lock_open_rounded,
      AppColors.warn,
      tag: 'MITO'),
  _TipData(
      'O domínio real é o que importa',
      'Em "netflix.com.verificar-conta.xyz", o domínio real é "verificar-conta.xyz". Tudo antes é apenas um subdomínio. Aprende a identificar o domínio principal.',
      Icons.travel_explore_rounded,
      AppColors.danger,
      tag: 'CRÍTICO'),
  _TipData(
      'Typosquatting: erros propositados',
      '"arnazon.com", "goggle.com", "paypa1.com" — atacantes registam domínios com erros de digitação propositados para enganar utilizadores distraídos.',
      Icons.spellcheck_rounded,
      AppColors.accent,
      tag: 'TÁTICA'),
  _TipData(
      'URLs encurtados: perigo escondido',
      'Links bit.ly, tinyurl ou t.co podem esconder URLs maliciosos. Usa serviços como "checkshorturl.com" para ver o destino real antes de clicar.',
      Icons.short_text_rounded,
      AppColors.blue,
      tag: 'PERIGO'),
  _TipData(
      'Analisa a estrutura completa do URL',
      'Verifica: protocolo (https://), domínio (empresa.com), caminho (/login). Páginas de login nunca devem ter domínios estranhos como "login.empresa.com.atacante.net".',
      Icons.schema_outlined,
      AppColors.accent2,
      tag: 'TÉCNICO'),
  _TipData(
      'Bookmarks em vez de links',
      'Para sites importantes como banco, email e redes sociais, usa sempre bookmarks guardados tu mesmo. Nunca acedas por links de emails ou mensagens.',
      Icons.bookmark_rounded,
      AppColors.accent,
      tag: 'HÁBITO'),
];

const _mobileTips = [
  _TipData(
      'Smishing: SMS Phishing',
      'SMS fraudulentos imitam bancos, CTT, operadoras e até AT (Finanças). Têm links para sites clonados. Os CTT nunca cobram taxas por SMS — acede sempre ao site oficial.',
      Icons.sms_rounded,
      AppColors.warn,
      tag: 'ALERTA'),
  _TipData(
      'QR Codes maliciosos',
      'QR codes em locais públicos podem ser colados por cima dos originais. Verifica sempre o URL antes de continuar. Um menu digital nunca precisa de aceder aos teus contactos ou SMS.',
      Icons.qr_code_scanner_rounded,
      AppColors.danger,
      tag: 'NOVO'),
  _TipData(
      'Permissões de apps: menos é mais',
      'Uma lanterna não precisa de aceder aos teus contactos. Uma app de calculadora não precisa da câmara. Revê as permissões de todas as apps em Definições.',
      Icons.admin_panel_settings_rounded,
      AppColors.blue,
      tag: 'HÁBITO'),
  _TipData(
      'Só instala apps de fontes oficiais',
      'Google Play Store e Apple App Store têm verificações de segurança. APKs de sites externos não têm. Mesmo assim, verifica o desenvolvedor e as avaliações na loja oficial.',
      Icons.store_rounded,
      AppColors.accent,
      tag: 'BÁSICO'),
  _TipData(
      'Vishing: chamadas de voz falsas',
      'Chamadas fingindo ser banco, SEF, GNR ou Microsoft. Nunca dês dados pessoais, senhas ou códigos SMS ao telefone — nenhuma entidade legítima pede isso por chamada.',
      Icons.call_rounded,
      AppColors.accent2,
      tag: 'CRÍTICO'),
  _TipData(
      'Wi-Fi público: risco real',
      'Em Wi-Fi público, atacantes podem fazer "man-in-the-middle" para intercetar os teus dados. Usa sempre VPN em redes públicas e evita aceder a contas bancárias.',
      Icons.wifi_off_rounded,
      AppColors.danger,
      tag: 'PERIGO'),
];

class _AnimatedTipList extends StatelessWidget {
  final List<_TipData> tips;
  final Animation<double> entryFade;
  final Animation<Offset> entrySlide;
  const _AnimatedTipList(
      {required this.tips, required this.entryFade, required this.entrySlide});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: entryFade,
      child: SlideTransition(
        position: entrySlide,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          itemCount: tips.length,
          itemBuilder: (_, i) => _TipCard(tip: tips[i], index: i),
        ),
      ),
    );
  }
}

class _TipCard extends StatefulWidget {
  final _TipData tip;
  final int index;
  const _TipCard({required this.tip, required this.index});
  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _expandAnim =
        CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
    _expanded ? _expandCtrl.forward() : _expandCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tip;
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _expanded ? tip.color.withAlpha(8) : const Color(0xFF0B1120),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                _expanded ? tip.color.withAlpha(60) : Colors.white.withAlpha(8),
            width: 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 3,
              decoration: BoxDecoration(
                color: _expanded ? tip.color : tip.color.withAlpha(50),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: tip.color.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(tip.icon, color: tip.color, size: 17),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tip.tag != null) ...[
                                  Text(tip.tag!,
                                      style: GoogleFonts.jetBrainsMono(
                                          color: tip.color,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2)),
                                  const SizedBox(height: 2),
                                ],
                                Text(tip.title,
                                    style: GoogleFonts.syne(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2)),
                              ]),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 280),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _expanded
                                ? tip.color
                                : Colors.white.withAlpha(61),
                            size: 20,
                          ),
                        ),
                      ]),
                      SizeTransition(
                        sizeFactor: _expandAnim,
                        child: FadeTransition(
                          opacity: _expandAnim,
                          child: Column(children: [
                            const SizedBox(height: 14),
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  tip.color.withAlpha(60),
                                  Colors.transparent,
                                ]),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(tip.description,
                                style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: 12.5,
                                    height: 1.65)),
                          ]),
                        ),
                      ),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AnimatedBestPractices extends StatelessWidget {
  final Animation<double> entryFade;
  final Animation<Offset> entrySlide;
  const _AnimatedBestPractices(
      {required this.entryFade, required this.entrySlide});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: entryFade,
      child: SlideTransition(
        position: entrySlide,
        child: const _BestPracticesTab(),
      ),
    );
  }
}

class _BestPracticesTab extends StatelessWidget {
  const _BestPracticesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        _buildSectionHeader(
            'Gestão de Passwords', Icons.key_rounded, AppColors.accent),
        _PracticeCard(
          priority: 1,
          title: 'Usa um gestor de passwords',
          desc:
              'Bitwarden, 1Password ou KeePass geram e guardam passwords únicas e complexas para cada site. Nunca reutilizes passwords.',
          score: 10,
          color: AppColors.accent,
          badge: 'ESSENCIAL',
        ),
        _PracticeCard(
          priority: 2,
          title: 'Autenticação de 2 Fatores (2FA)',
          desc:
              'Ativa 2FA em todas as contas importantes. Mesmo que a tua senha seja roubada, o atacante não consegue entrar sem o segundo fator.',
          score: 10,
          color: AppColors.accent,
          badge: 'ESSENCIAL',
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(
            'Atualizações e Backups', Icons.refresh_rounded, AppColors.blue),
        _PracticeCard(
          priority: 3,
          title: 'Mantém tudo atualizado',
          desc:
              'Sistemas operativos, browsers e apps desatualizados têm vulnerabilidades conhecidas que atacantes exploram. Ativa atualizações automáticas.',
          score: 8,
          color: AppColors.blue,
          badge: 'IMPORTANTE',
        ),
        _PracticeCard(
          priority: 4,
          title: 'Backups regulares (3-2-1)',
          desc:
              '3 cópias dos dados, em 2 locais diferentes, com 1 offline. Se fores vítima de ransomware, backups são a única forma de recuperar sem pagar.',
          score: 9,
          color: AppColors.blue,
          badge: 'IMPORTANTE',
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(
            'Comportamento Digital', Icons.psychology_rounded, AppColors.warn),
        _PracticeCard(
          priority: 5,
          title: 'Verifica antes de clicar',
          desc:
              'Para. Respira. Pensa. A urgência artificial é a principal ferramenta do phishing. Se a mensagem cria pressão, provavelmente é falsa.',
          score: 10,
          color: AppColors.warn,
          badge: 'CRÍTICO',
        ),
        _PracticeCard(
          priority: 6,
          title: 'Confirma por outro canal',
          desc:
              'Se recebes um email suspeito do teu banco, liga diretamente para o banco usando o número oficial — nunca o número do email.',
          score: 9,
          color: AppColors.warn,
          badge: 'IMPORTANTE',
        ),
        _PracticeCard(
          priority: 7,
          title: 'Minimiza a tua pegada digital',
          desc:
              'Quanto menos informação pessoal publicares online, menos material os atacantes têm para spear phishing. Revê as definições de privacidade.',
          score: 7,
          color: AppColors.accent2,
          badge: 'HÁBITO',
        ),
        const SizedBox(height: 20),
        _GoldenRulesCard(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.syne(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: Colors.white.withAlpha(8))),
      ]),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final int priority, score;
  final String title, desc, badge;
  final Color color;
  const _PracticeCard({
    required this.priority,
    required this.title,
    required this.desc,
    required this.score,
    required this.color,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withAlpha(12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Center(
            child: Text('$priority',
                style: GoogleFonts.jetBrainsMono(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(title,
                    style: GoogleFonts.syne(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withAlpha(40)),
                ),
                child: Text(badge,
                    style: GoogleFonts.jetBrainsMono(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 5),
            Text(desc,
                style: GoogleFonts.inter(
                    color: Colors.white.withAlpha(97),
                    fontSize: 11.5,
                    height: 1.55)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 10,
                    backgroundColor: Colors.white.withAlpha(8),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$score/10',
                  style: GoogleFonts.jetBrainsMono(
                      color: color, fontSize: 9, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _GoldenRulesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const rules = [
      (
        Icons.visibility_rounded,
        'Nunca cliques em links — vai sempre diretamente ao site'
      ),
      (Icons.lock_rounded, 'Nunca partilhes senhas, mesmo que peçam'),
      (
        Icons.phone_callback_rounded,
        'Confirma pedidos urgentes por outro canal'
      ),
      (Icons.system_update_rounded, 'Mantém tudo atualizado'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withAlpha(30)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('REGRA DE OURO',
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            Text('Os 4 mandamentos de segurança',
                style: GoogleFonts.syne(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
        ]),
        const SizedBox(height: 16),
        Container(height: 1, color: AppColors.accent.withAlpha(20)),
        const SizedBox(height: 16),
        ...rules.asMap().entries.map((entry) {
          final i = entry.key;
          final rule = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Text('0${i + 1}',
                  style: GoogleFonts.jetBrainsMono(
                      color: AppColors.accent.withAlpha(60),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(rule.$1, color: AppColors.accent, size: 15),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(rule.$2,
                    style: GoogleFonts.inter(
                        color: Colors.white60, fontSize: 12.5, height: 1.4)),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}
