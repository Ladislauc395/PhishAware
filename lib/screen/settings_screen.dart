import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_models.dart';
import 'api_service.dart';

class AppPreferences {
  static bool hapticEnabled    = true;
  static bool showXpAnimations = true;
  static bool showLeaderboard  = true;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hapticEnabled    = prefs.getBool('haptic')       ?? true;
    showXpAnimations = prefs.getBool('xp_anim')      ?? true;
    showLeaderboard  = prefs.getBool('show_ranking') ?? true;
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic',       hapticEnabled);
    await prefs.setBool('xp_anim',      showXpAnimations);
    await prefs.setBool('show_ranking', showLeaderboard);
  }

  static Future<void> setHaptic(bool v) async {
    hapticEnabled = v;
    await _save();
  }

  static Future<void> setXpAnimations(bool v) async {
    showXpAnimations = v;
    await _save();
  }

  static Future<void> setShowLeaderboard(bool v) async {
    showLeaderboard = v;
    await _save();
    await ApiService.updatePreferences(showInRanking: v);
  }
}

class _LegalContent {
  final String title, icon, lastUpdated;
  final List<_LegalSection> sections;
  const _LegalContent({required this.title, required this.icon, required this.lastUpdated, required this.sections});
}

class _LegalSection {
  final String heading, body;
  const _LegalSection({required this.heading, required this.body});
}

const _privacyPolicy = _LegalContent(
  title: 'Política de Privacidade', icon: '🔒', lastUpdated: 'Fevereiro 2026',
  sections: [
    _LegalSection(heading: '1. Dados que Recolhemos',
      body: 'A PhishAware recolhe apenas os dados estritamente necessários para o funcionamento da aplicação: nome de utilizador, endereço de email, e os resultados das simulações que completas (respostas correctas, incorrectas, pontos XP e categorias).\n\nNão recolhemos dados de localização, contactos, câmara ou qualquer outro dado sensível do dispositivo.'),
    _LegalSection(heading: '2. Como Usamos os Dados',
      body: 'Os teus dados são usados exclusivamente para:\n\n• Personalizar a tua experiência de aprendizagem\n• Calcular o teu nível de resiliência digital\n• Mostrar o teu progresso no ranking (se activado)\n• Gerar notificações relevantes sobre o teu desempenho\n\nNão vendemos, partilhamos nem cedemos os teus dados a terceiros para fins comerciais.'),
    _LegalSection(heading: '3. Armazenamento e Segurança',
      body: 'Os teus dados são armazenados num servidor local protegido. Utilizamos práticas de segurança standard para proteger as tuas informações contra acesso não autorizado. As passwords são armazenadas com hash e nunca em texto simples.'),
    _LegalSection(heading: '4. Os Teus Direitos',
      body: 'Tens o direito de:\n\n• Aceder aos teus dados a qualquer momento\n• Rectificar informações incorrectas\n• Solicitar a eliminação da tua conta e todos os dados associados\n• Desactivar a tua visibilidade no ranking global\n\nPodes exercer estes direitos directamente nas configurações da aplicação.'),
    _LegalSection(heading: '5. Retenção de Dados',
      body: 'Os teus dados são mantidos enquanto a tua conta estiver activa. Ao eliminares a conta, todos os dados são removidos permanentemente e de forma irreversível dos nossos servidores no prazo de 24 horas.'),
    _LegalSection(heading: '6. Contacto',
      body: 'Se tiveres dúvidas sobre esta política, podes contactar-nos através do suporte da aplicação. Comprometemo-nos a responder no prazo de 5 dias úteis.'),
  ],
);

const _termsOfService = _LegalContent(
  title: 'Termos de Serviço', icon: '📄', lastUpdated: 'Fevereiro 2026',
  sections: [
    _LegalSection(heading: '1. Aceitação dos Termos',
      body: 'Ao criares uma conta e utilizares a PhishAware, aceitas estes Termos de Serviço na íntegra. Se não concordares com alguma parte destes termos, deves descontinuar o uso da aplicação.'),
    _LegalSection(heading: '2. Utilização Permitida',
      body: 'A PhishAware é uma plataforma educativa de simulação de ciberameaças. Podes utilizar a aplicação para:\n\n• Treinar a tua capacidade de identificar ataques de phishing\n• Aprender sobre segurança digital\n• Competir no ranking global de forma justa\n\nÉ expressamente proibido utilizar os conteúdos da aplicação para fins maliciosos, enganosos ou ilegais.'),
    _LegalSection(heading: '3. Conteúdo Educativo',
      body: 'Todos os cenários de simulação presentes na aplicação são fictícios e criados exclusivamente para fins educativos. Qualquer semelhança com situações reais é coincidência.\n\nOs cenários baseiam-se em técnicas documentadas publicamente por investigadores de segurança e não constituem instrução para actividades ilegais.'),
    _LegalSection(heading: '4. Conta e Segurança',
      body: 'És responsável por manter a confidencialidade da tua password e por todas as actividades realizadas na tua conta. Deves notificar-nos imediatamente se suspeitares de acesso não autorizado.\n\nReservamo-nos o direito de suspender contas que violem estes termos ou que apresentem comportamentos abusivos.'),
    _LegalSection(heading: '5. Ranking e Competição',
      body: 'O ranking global deve ser utilizado de forma justa. É proibido:\n\n• Usar ferramentas automáticas para ganhar XP\n• Manipular resultados de qualquer forma\n• Criar múltiplas contas para benefício no ranking\n\nContas com actividade suspeita podem ser removidas do ranking ou suspensas.'),
    _LegalSection(heading: '6. Disponibilidade do Serviço',
      body: 'A PhishAware é disponibilizada "tal como está". Não garantimos disponibilidade ininterrupta do serviço e reservamo-nos o direito de efectuar manutenções ou actualizações sem aviso prévio.'),
    _LegalSection(heading: '7. Alterações aos Termos',
      body: 'Podemos actualizar estes Termos de Serviço periodicamente. Quando o fizermos, actualizaremos a data de "Última actualização". O uso continuado da aplicação após alterações constitui aceitação dos novos termos.'),
  ],
);

void _showLegalSheet(BuildContext context, _LegalContent content) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _LegalSheet(content: content),
  );
}

class _LegalSheet extends StatelessWidget {
  final _LegalContent content;
  const _LegalSheet({required this.content});
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.accent.withAlpha(15),
                      borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withAlpha(40))),
                  child: Center(child: Text(content.icon, style: const TextStyle(fontSize: 20)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(content.title, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('Última actualização: ${content.lastUpdated}',
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
              ])),
              GestureDetector(onTap: () => Navigator.pop(context),
                  child: Container(padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.close, color: AppColors.textMuted, size: 18))),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            itemCount: content.sections.length,
            itemBuilder: (_, i) {
              final s = content.sections[i];
              return Padding(padding: const EdgeInsets.only(bottom: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.heading, style: GoogleFonts.spaceGrotesk(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(s.body, style: GoogleFonts.inter(color: AppColors.text, fontSize: 12, height: 1.8)),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: AppColors.border.withAlpha(100)),
                ]),
              );
            },
          )),
        ]),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  bool _prefsLoaded   = false;
  bool _haptic        = true;
  bool _xpAnim        = true;
  bool _ranking       = true;
  bool _savingRanking = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    await AppPreferences.load();
    try {
      final data = await ApiService.getStats();
      final serverRanking = data['show_in_ranking'] as bool? ?? true;
      AppPreferences.showLeaderboard = serverRanking;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_ranking', serverRanking);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _haptic  = AppPreferences.hapticEnabled;
      _xpAnim  = AppPreferences.showXpAnimations;
      _ranking = AppPreferences.showLeaderboard;
      _prefsLoaded = true;
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _toggleHaptic(bool v) async {
    setState(() => _haptic = v);
    await AppPreferences.setHaptic(v);
    if (v) HapticFeedback.mediumImpact();
  }

  Future<void> _toggleXpAnim(bool v) async {
    setState(() => _xpAnim = v);
    await AppPreferences.setXpAnimations(v);
    _snack(v ? 'Animações XP activadas' : 'Animações XP desactivadas',
        v ? AppColors.accent : AppColors.textMuted);
  }

  Future<void> _toggleRanking(bool v) async {
    if (_savingRanking) return;
    setState(() { _ranking = v; _savingRanking = true; });
    try {
      await AppPreferences.setShowLeaderboard(v);
      if (!mounted) return;
      _snack(v ? 'Voltaste a aparecer no ranking! 🏆' : 'Removido do ranking global',
          v ? AppColors.accent : AppColors.warn);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ranking = !v);
      _snack('Erro ao guardar preferência.', AppColors.danger);
    } finally {
      if (mounted) setState(() => _savingRanking = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(
          color: color == AppColors.accent ? Colors.black : Colors.white,
          fontWeight: FontWeight.w600)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _deleteAccount() async {
    final step1 = await showDialog<bool>(context: context, barrierColor: Colors.black87,
      builder: (_) => _ConfirmDialog(icon: '⚠️', iconColor: AppColors.danger,
          title: 'Eliminar Conta',
          message: 'Esta acção é irreversível. Todos os teus dados, progresso e histórico serão eliminados permanentemente.',
          cancelLabel: 'Cancelar', confirmLabel: 'Continuar', confirmColor: AppColors.danger));
    if (step1 != true || !mounted) return;
    final step2 = await showDialog<bool>(context: context, barrierColor: Colors.black87,
      builder: (_) => _FinalDeleteDialog());
    if (step2 != true || !mounted) return;
    try {
      await ApiService.deleteAccount(UserSession.userId);
      if (!mounted) return;
      _snack('Conta eliminada com sucesso.', AppColors.accent);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      UserSession.userId = 1; UserSession.userName = 'Utilizador';
      UserSession.userEmail = ''; UserSession.avatarLetter = 'U';
      ApiService.currentUserId = 1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
    } catch (_) {
      if (!mounted) return;
      _snack('Erro ao eliminar conta. Tenta novamente.', AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: FadeTransition(opacity: _fade,
        child: !_prefsLoaded
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), children: [
              Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context),
                  child: Container(padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border)),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
                const SizedBox(width: 14),
                Text('Configurações', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 28),
              _SectionLabel('Experiência'), const SizedBox(height: 10),
              _SettingsCard(children: [
                _ToggleRow(icon: '📳', iconColor: AppColors.blue, title: 'Vibração / Haptic',
                    subtitle: 'Feedback táctil nas interacções', value: _haptic, onChanged: _toggleHaptic),
                _Divider(),
                _ToggleRow(icon: '🎬', iconColor: AppColors.accent, title: 'Animações XP',
                    subtitle: 'Animações ao ganhar pontos', value: _xpAnim, onChanged: _toggleXpAnim),
              ]),
              const SizedBox(height: 20),
              _SectionLabel('Privacidade'), const SizedBox(height: 10),
              _SettingsCard(children: [
                _ToggleRow(icon: '🏆', iconColor: AppColors.warn, title: 'Aparecer no Ranking',
                    subtitle: 'O teu nome é visível no ranking global',
                    value: _ranking, loading: _savingRanking, onChanged: _toggleRanking),
              ]),
              const SizedBox(height: 20),
              _SectionLabel('Conta'), const SizedBox(height: 10),
              _SettingsCard(children: [
                _InfoRow(icon: '👤', iconColor: AppColors.blue, title: 'Nome', value: UserSession.userName),
                _Divider(),
                _InfoRow(icon: '📧', iconColor: AppColors.accent, title: 'Email',
                    value: UserSession.userEmail.isNotEmpty ? UserSession.userEmail : '—'),
                _Divider(),
                _InfoRow(icon: '🆔', iconColor: AppColors.textMuted, title: 'ID de Utilizador', value: '#${UserSession.userId}'),
              ]),
              const SizedBox(height: 20),
              _SectionLabel('Sobre'), const SizedBox(height: 10),
              _SettingsCard(children: [
                _InfoRow(icon: '📱', iconColor: AppColors.blue, title: 'Versão', value: '1.0.0'),
                _Divider(),
                _TappableRow(icon: '🔒', iconColor: AppColors.accent, title: 'Política de Privacidade',
                    onTap: () => _showLegalSheet(context, _privacyPolicy)),
                _Divider(),
                _TappableRow(icon: '📄', iconColor: AppColors.textMuted, title: 'Termos de Serviço',
                    onTap: () => _showLegalSheet(context, _termsOfService)),
              ]),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.danger.withAlpha(40)),
                    gradient: LinearGradient(colors: [AppColors.danger.withAlpha(8), AppColors.bg],
                        begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Column(children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      const Text('💀', style: TextStyle(fontSize: 14)), const SizedBox(width: 8),
                      Text('Zona de Perigo', style: GoogleFonts.spaceGrotesk(color: AppColors.danger,
                          fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ])),
                  Container(margin: const EdgeInsets.fromLTRB(4, 0, 4, 4), padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Eliminar Conta', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Remove permanentemente a tua conta e todos os dados associados. Esta acção não pode ser desfeita.',
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, height: 1.5)),
                      const SizedBox(height: 14),
                      SizedBox(width: double.infinity,
                        child: OutlinedButton.icon(onPressed: _deleteAccount,
                          icon: const Icon(Icons.delete_forever, size: 16, color: AppColors.danger),
                          label: Text('Eliminar a Minha Conta', style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 13)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: AppColors.danger.withAlpha(60)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                    ])),
                ]),
              ),
            ]),
      )),
    );
  }
}

class _FinalDeleteDialog extends StatefulWidget {
  @override State<_FinalDeleteDialog> createState() => _FinalDeleteDialogState();
}
class _FinalDeleteDialogState extends State<_FinalDeleteDialog> {
  final _ctrl = TextEditingController();
  bool _valid = false;
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final firstName = UserSession.userName.split(' ').first;
    return Dialog(backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('💣', style: TextStyle(fontSize: 42)), const SizedBox(height: 12),
          Text('Tens a certeza?', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          RichText(textAlign: TextAlign.center, text: TextSpan(
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, height: 1.6),
            children: [const TextSpan(text: 'Escreve '),
              TextSpan(text: firstName, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
              const TextSpan(text: ' para confirmar a eliminação.')])),
          const SizedBox(height: 16),
          TextField(controller: _ctrl, autofocus: true,
            onChanged: (v) => setState(() => _valid = v.trim() == firstName),
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(hintText: firstName,
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
              filled: true, fillColor: AppColors.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textMuted, fontWeight: FontWeight.w600)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: _valid ? () => Navigator.pop(context, true) : null,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.danger, disabledBackgroundColor: AppColors.danger.withAlpha(40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Eliminar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)))),
          ]),
        ])));
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String icon, title, message, cancelLabel, confirmLabel;
  final Color iconColor, confirmColor;
  const _ConfirmDialog({required this.icon, required this.iconColor, required this.title,
      required this.message, required this.cancelLabel, required this.confirmLabel, required this.confirmColor});
  @override
  Widget build(BuildContext context) => Dialog(backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 40)), const SizedBox(height: 12),
        Text(title, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, height: 1.6)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(cancelLabel, style: GoogleFonts.inter(color: AppColors.textMuted, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: confirmColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(confirmLabel, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)))),
        ]),
      ])));
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(left: 4),
    child: Text(label, style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)));
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
    child: Column(children: children));
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(height: 1, color: AppColors.border, indent: 56);
}

class _ToggleRow extends StatelessWidget {
  final String icon, title, subtitle;
  final Color iconColor;
  final bool value, loading;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.icon, required this.iconColor, required this.title,
      required this.subtitle, required this.value, required this.onChanged, this.loading = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 16)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(subtitle, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
      ])),
      if (loading)
        const SizedBox(width: 36, height: 36, child: Center(child: SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))))
      else
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withAlpha(40),
            inactiveThumbColor: AppColors.textMuted, inactiveTrackColor: AppColors.surface2),
    ]));
}

class _InfoRow extends StatelessWidget {
  final String icon, title, value;
  final Color iconColor;
  const _InfoRow({required this.icon, required this.iconColor, required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 16)))),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
      Text(value, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
    ]));
}

class _TappableRow extends StatelessWidget {
  final String icon, title;
  final Color iconColor;
  final VoidCallback onTap;
  const _TappableRow({required this.icon, required this.iconColor, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 16)))),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
      ])));
}