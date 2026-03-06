import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import 'api_service.dart';
import 'notification_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserStats _stats = const UserStats();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getStats();
      if (!mounted) return;
      setState(() {
        _stats = UserStats.fromJson(data);
        _loading = false;
      });
      NotificationService().syncFromStats(_stats);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _logout() {
    UserSession.userId = 1;
    UserSession.userName = 'Utilizador';
    UserSession.userEmail = '';
    UserSession.avatarLetter = 'U';
    ApiService.currentUserId = 1;
    Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    ).then((_) => setState(() {}));
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = NotificationService().unreadCount;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent))
            : RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.surface,
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text('Perfil',
                          style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openSettings,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.settings_outlined,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _openNotifications,
                        child: Stack(clipBehavior: Clip.none, children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 20),
                          ),
                          if (unread > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.bg, width: 1.5),
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 18, minHeight: 18),
                                child: Center(
                                  child: Text('$unread',
                                      style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 32),
                    Stack(alignment: Alignment.bottomRight, children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.blue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.accent.withAlpha(80),
                                blurRadius: 24,
                                spreadRadius: -4)
                          ],
                        ),
                        child: Center(
                          child: Text(UserSession.avatarLetter,
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.black,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bg, width: 3),
                        ),
                        child: const Icon(Icons.shield,
                            size: 12, color: Colors.white),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Text(UserSession.userName,
                        style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(_stats.level,
                        style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    if (UserSession.userEmail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(UserSession.userEmail,
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                    const SizedBox(height: 28),
                    Row(children: [
                      _StatCard(
                          icon: Icons.bolt,
                          iconColor: AppColors.warn,
                          value: '${_stats.xp}',
                          label: 'XP TOTAL'),
                      const SizedBox(width: 12),
                      _StatCard(
                          icon: Icons.check_circle_outline,
                          iconColor: AppColors.accent,
                          value:
                              '${_stats.correctTotal}/${_stats.answeredTotal}',
                          label: 'ACERTOS'),
                      const SizedBox(width: 12),
                      _StatCard(
                          icon: Icons.shield_outlined,
                          iconColor: AppColors.blue,
                          value: '${_stats.resilience}%',
                          label: 'RESILIÊNCIA'),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Desempenho por Categoria',
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            ...[
                              ('📧 E-mail', AppColors.accent, 'email'),
                              ('💬 SMS', AppColors.warn, 'sms'),
                              ('🔗 URL', AppColors.blue, 'url'),
                              ('📱 App/QR', AppColors.accent2, 'app'),
                            ].map((c) {
                              final count = _stats.byCategory[c.$3] ?? 0;
                              final total = _stats.correctTotal > 0
                                  ? _stats.correctTotal
                                  : 1;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(children: [
                                  SizedBox(
                                      width: 72,
                                      child: Text(c.$1,
                                          style: GoogleFonts.inter(
                                              color: AppColors.textMuted,
                                              fontSize: 11))),
                                  Expanded(
                                      child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: TweenAnimationBuilder<double>(
                                      tween:
                                          Tween(begin: 0, end: count / total),
                                      duration:
                                          const Duration(milliseconds: 900),
                                      curve: Curves.easeOutCubic,
                                      builder: (_, v, __) =>
                                          LinearProgressIndicator(
                                        value: v,
                                        minHeight: 6,
                                        backgroundColor: AppColors.surface2,
                                        valueColor:
                                            AlwaysStoppedAnimation(c.$2),
                                      ),
                                    ),
                                  )),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                      width: 24,
                                      child: Text('$count',
                                          style: GoogleFonts.inter(
                                              color: c.$2,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600))),
                                ]),
                              );
                            }),
                          ]),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(children: [
                        _MenuItem(
                          icon: Icons.history,
                          label: 'Histórico de Atividade',
                          color: AppColors.blue,
                          onTap: () =>
                              Navigator.pushNamed(context, Routes.history)
                                  .then((_) => _load()),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _MenuItem(
                          icon: Icons.notifications_none,
                          label: 'Notificações',
                          color: AppColors.warn,
                          badge: unread,
                          onTap: _openNotifications,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _MenuItem(
                          icon: Icons.settings_outlined,
                          label: 'Configurações',
                          color: AppColors.textMuted,
                          onTap: _openSettings,
                          isLast: true,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout,
                            size: 18, color: AppColors.danger),
                        label: Text('Terminar Sessão',
                            style: GoogleFonts.inter(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side:
                              BorderSide(color: AppColors.danger.withAlpha(60)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value, label;
  const _StatCard(
      {required this.icon,
      required this.iconColor,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
          ]),
        ),
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool isLast;
  final int badge;
  const _MenuItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.isLast = false,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w500))),
            if (badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$badge',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 18),
          ]),
        ),
      );
}
