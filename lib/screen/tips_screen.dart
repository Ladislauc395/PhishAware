import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_models.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});
  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
          child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aprende a Proteger-te',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Conhecimento é a tua melhor defesa.',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
          ]),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TabBar(
            controller: _tabCtrl,
            padding: const EdgeInsets.all(4),
            indicator: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent.withAlpha(60)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle:
                GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: '📧 Email'),
              Tab(text: '🔗 URL'),
              Tab(text: '📱 Mobile'),
              Tab(text: '🛡️ Boas Práticas'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _TipList(_emailTips),
              _TipList(_urlTips),
              _TipList(_mobileTips),
              _BestPracticesTab(),
            ],
          ),
        ),
      ])),
    );
  }
}

const _emailTips = [
  _TipData(
      'Verifica sempre o remetente',
      'Empresas legítimas usam sempre o seu domínio oficial. "paypa1.com" ou "banco-seguro.info" são falsos. Passa o rato por cima do email para ver o endereço real.',
      Icons.alternate_email,
      AppColors.accent),
  _TipData(
      'Desconfia de urgência',
      '"A tua conta será suspensa em 24h!" é uma técnica de pressão psicológica. Empresas legítimas nunca criam pânico artificial para te forçar a agir sem pensar.',
      Icons.timer_off_outlined,
      AppColors.danger),
  _TipData(
      'Não abras anexos suspeitos',
      'Ficheiros .exe, .zip, .docm e .xlsm podem conter malware. Mesmo PDFs podem ter scripts maliciosos. Verifica com o remetente por outro canal antes de abrir.',
      Icons.attach_file,
      AppColors.warn),
  _TipData(
      'Links em emails: nunca confiar',
      'Mesmo que o link pareça correto, passa o rato por cima para ver o URL real. Vai sempre ao site diretamente pelo browser em vez de clicar em links de email.',
      Icons.link_off,
      AppColors.blue),
  _TipData(
      'Spear Phishing: ataques personalizados',
      'Atacantes recolhem informação do LinkedIn, redes sociais e bases de dados para criar emails com o teu nome, empresa e contexto real. Sê cético mesmo com contexto correto.',
      Icons.person_search,
      AppColors.accent2),
  _TipData(
      'Cabeçalhos de email revelam tudo',
      'Os cabeçalhos técnicos de um email mostram o servidor de origem real. Em clientes como Gmail, podes ver "Ver original" para verificar a autenticidade.',
      Icons.code,
      AppColors.textMuted),
];

const _urlTips = [
  _TipData(
      'HTTPS não significa seguro',
      'O cadeado verde apenas indica que a ligação é cifrada. Não garante que o site é legítimo. Sites phishing usam HTTPS com certificados gratuitos (Let\'s Encrypt).',
      Icons.lock_open_outlined,
      AppColors.warn),
  _TipData(
      'O domínio real é o que importa',
      'Em "netflix.com.verificar-conta.xyz", o domínio real é "verificar-conta.xyz". Tudo antes é apenas um subdomínio. Aprende a identificar o domínio principal.',
      Icons.travel_explore,
      AppColors.danger),
  _TipData(
      'Typosquatting: erros propositados',
      '"arnazon.com", "goggle.com", "paypa1.com" — atacantes registam domínios com erros de digitação propositados para enganar utilizadores distraídos.',
      Icons.spellcheck,
      AppColors.accent),
  _TipData(
      'URLs encurtados: perigo escondido',
      'Links bit.ly, tinyurl ou t.co podem esconder URLs maliciosos. Usa serviços como "checkshorturl.com" para ver o destino real antes de clicar.',
      Icons.short_text,
      AppColors.blue),
  _TipData(
      'Analisa a estrutura completa do URL',
      'Verifica: protocolo (https://), domínio (empresa.com), caminho (/login). Páginas de login nunca devem ter domínios estranhos como "login.empresa.com.atacante.net".',
      Icons.schema_outlined,
      AppColors.accent2),
  _TipData(
      'Bookmarks em vez de links',
      'Para sites importantes como banco, email e redes sociais, usa sempre bookmarks guardados tu mesmo. Nunca acedas por links de emails ou mensagens.',
      Icons.bookmark_outline,
      AppColors.accent),
];

const _mobileTips = [
  _TipData(
      'Smishing: SMS Phishing',
      'SMS fraudulentos imitam bancos, CTT, operadoras e até AT (Finanças). Têm links para sites clonados. Os CTT nunca cobram taxas por SMS — acede sempre ao site oficial.',
      Icons.sms_outlined,
      AppColors.warn),
  _TipData(
      'QR Codes maliciosos',
      'QR codes em locais públicos podem ser colados por cima dos originais. Verifica sempre o URL antes de continuar. Um menu digital nunca precisa de aceder aos teus contactos ou SMS.',
      Icons.qr_code_scanner,
      AppColors.danger),
  _TipData(
      'Permissões de apps: menos é mais',
      'Uma lanterna não precisa de aceder aos teus contactos. Uma app de calculadora não precisa da câmara. Revê as permissões de todas as apps em Definições.',
      Icons.admin_panel_settings_outlined,
      AppColors.blue),
  _TipData(
      'Só instala apps de fontes oficiais',
      'Google Play Store e Apple App Store têm verificações de segurança. APKs de sites externos não têm. Mesmo assim, verifica o desenvolvedor e as avaliações na loja oficial.',
      Icons.store_outlined,
      AppColors.accent),
  _TipData(
      'Vishing: chamadas de voz falsas',
      'Chamadas fingindo ser banco, SEF, GNR ou Microsoft. Nunca dês dados pessoais, senhas ou códigos SMS ao telefone — nenhuma entidade legítima pede isso por chamada.',
      Icons.call_outlined,
      AppColors.accent2),
  _TipData(
      'Wi-Fi público: risco real',
      'Em Wi-Fi público, atacantes podem fazer "man-in-the-middle" para intercetar os teus dados. Usa sempre VPN em redes públicas e evita aceder a contas bancárias.',
      Icons.wifi_off_outlined,
      AppColors.danger),
];

class _TipData {
  final String title, description;
  final IconData icon;
  final Color color;
  const _TipData(this.title, this.description, this.icon, this.color);
}

class _TipList extends StatelessWidget {
  final List<_TipData> tips;
  const _TipList(this.tips, {super.key});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        itemCount: tips.length,
        itemBuilder: (_, i) => _TipCard(tip: tips[i]),
      );
}

class _TipCard extends StatefulWidget {
  final _TipData tip;
  const _TipCard({super.key, required this.tip});
  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _expanded ? widget.tip.color.withAlpha(80) : AppColors.border,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.tip.color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.tip.icon, color: widget.tip.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(widget.tip.title,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600))),
            Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.textMuted,
                size: 18),
          ]),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Text(widget.tip.description,
                style: GoogleFonts.inter(
                    color: AppColors.text, fontSize: 13, height: 1.6)),
          ],
        ]),
      ),
    );
  }
}

class _BestPracticesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        _SectionHeader('🔐 Gestão de Passwords'),
        _PracticeCard(
          title: 'Usa um gestor de passwords',
          desc:
              'Bitwarden, 1Password ou KeePass geram e guardam passwords únicas e complexas para cada site. Nunca reutilizes passwords.',
          score: 10,
          color: AppColors.accent,
        ),
        _PracticeCard(
          title: 'Autenticação de 2 Fatores (2FA)',
          desc:
              'Ativa 2FA em todas as contas importantes. Mesmo que a tua senha seja roubada, o atacante não consegue entrar sem o segundo fator.',
          score: 10,
          color: AppColors.accent,
        ),
        const SizedBox(height: 20),
        _SectionHeader('🔄 Atualizações e Backups'),
        _PracticeCard(
          title: 'Mantém tudo atualizado',
          desc:
              'Sistemas operativos, browsers e apps desatualizados têm vulnerabilidades conhecidas que atacantes exploram. Ativa atualizações automáticas.',
          score: 8,
          color: AppColors.blue,
        ),
        _PracticeCard(
          title: 'Backups regulares (3-2-1)',
          desc:
              '3 cópias dos dados, em 2 locais diferentes, com 1 offline. Se fores vítima de ransomware, backups são a única forma de recuperar sem pagar.',
          score: 9,
          color: AppColors.blue,
        ),
        const SizedBox(height: 20),
        _SectionHeader('🧠 Comportamento Digital'),
        _PracticeCard(
          title: 'Verifica antes de clicar',
          desc:
              'Para. Respira. Pensa. A urgência artificial é a principal ferramenta do phishing. Se a mensagem cria pressão, provavelmente é falsa.',
          score: 10,
          color: AppColors.warn,
        ),
        _PracticeCard(
          title: 'Confirma por outro canal',
          desc:
              'Se recebes um email suspeito do teu banco, liga diretamente para o banco usando o número oficial — nunca o número do email.',
          score: 9,
          color: AppColors.warn,
        ),
        _PracticeCard(
          title: 'Minimiza a tua pegada digital',
          desc:
              'Quanto menos informação pessoal publicares online, menos material os atacantes têm para spear phishing. Revê as definições de privacidade.',
          score: 7,
          color: AppColors.accent2,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withAlpha(10),
                AppColors.blue.withAlpha(10)
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withAlpha(40)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.verified_user,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text('Regra de Ouro',
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),
            ...[
              (
                Icons.visibility,
                'Nunca cliques em links — vai sempre diretamente ao site'
              ),
              (Icons.lock, 'Nunca partilhes senhas, mesmo que peçam'),
              (
                Icons.phone_callback,
                'Confirma pedidos urgentes por outro canal'
              ),
              (Icons.update, 'Mantém tudo atualizado'),
            ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(item.$1, color: AppColors.accent, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item.$2,
                            style: GoogleFonts.inter(
                                color: AppColors.text, fontSize: 13))),
                  ]),
                )),
          ]),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      );
}

class _PracticeCard extends StatelessWidget {
  final String title, desc;
  final int score;
  final Color color;
  const _PracticeCard(
      {required this.title,
      required this.desc,
      required this.score,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(desc,
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 11, height: 1.5)),
              ])),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Center(
                child: Text('$score',
                    style: GoogleFonts.spaceGrotesk(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
          ),
        ]),
      );
}
