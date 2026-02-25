import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_models.dart';
import 'api_service.dart';

// ── Modelo de Notificação ─────────────────────────────────────────────────────
class AppNotification {
  final String id;
  final NotifType type;
  final String title;
  final String body;
  final DateTime timestamp;
  bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.read = false,
  });
}

enum NotifType { xp, warning, achievement, tip, system }

// ── Serviço de Notificações (singleton simples) ───────────────────────────────
class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final List<AppNotification> _notifications = [];
  static int _idCounter = 0;

  List<AppNotification> get all => List.from(_notifications)
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  int get unreadCount => _notifications.where((n) => !n.read).length;

  void add(NotifType type, String title, String body) {
    _notifications.add(AppNotification(
      id: '${++_idCounter}',
      type: type,
      title: title,
      body: body,
      timestamp: DateTime.now(),
    ));
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.read = true;
    }
  }

  void remove(String id) {
    _notifications.removeWhere((n) => n.id == id);
  }

  void clear() => _notifications.clear();

  // Gera notificações baseadas nos stats reais do utilizador
  void syncFromStats(UserStats stats) {
    // Evita duplicar ao re-sincronizar
    if (_notifications.any((n) => n.id == 'stats_sync')) return;

    if (stats.xp > 0) {
      add(NotifType.xp, 'XP Acumulado! 🔥',
          'Tens ${stats.xp} XP — continua a treinar para subir de nível!');
    }
    if (stats.resilience >= 75) {
      add(NotifType.achievement, 'Resiliência Alta! 🛡️',
          'O teu nível de resiliência está em ${stats.resilience}%. Excelente!');
    } else if (stats.resilience > 0 && stats.resilience < 50) {
      add(NotifType.warning, 'Atenção ao Risco! ⚠️',
          'A tua resiliência está em ${stats.resilience}%. Completa mais simulações!');
    }
    if (stats.answeredTotal >= 5) {
      add(NotifType.achievement, 'Veterano! 🎯',
          'Respondeste a ${stats.answeredTotal} questões. Estás a crescer!');
    }
    // Dica diária sempre presente
    add(NotifType.tip, 'Dica do Dia 💡',
        'Verifica sempre o domínio do remetente antes de clicar em qualquer link. Pequenas diferenças escondem grandes ameaças.');

    _notifications
        .firstWhere((n) => true, orElse: () => _notifications.first)
        .id;
    // Marca o sync feito
    _notifications.add(AppNotification(
      id: 'stats_sync',
      type: NotifType.system,
      title: '',
      body: '',
      timestamp: DateTime(2000),
      read: true,
    ));
    // Remove o marcador invisível imediatamente mas fica no ID
    _notifications.removeWhere((n) => n.id == 'stats_sync');
    // Re-add com flag
    final marker = AppNotification(
      id: 'stats_sync',
      type: NotifType.system,
      title: 'Sistema Inicializado',
      body: 'PhishAware está activo e a monitorizar a tua segurança digital.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      read: true,
    );
    _notifications.add(marker);
  }
}

// ── Ecrã de Notificações ──────────────────────────────────────────────────────
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final _svc = NotificationService();
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _loadAndSync();
  }

  Future<void> _loadAndSync() async {
    try {
      final data = await ApiService.getStats();
      final stats = UserStats.fromJson(data);
      _svc.syncFromStats(stats);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _markAllRead() {
    HapticFeedback.lightImpact();
    setState(() => _svc.markAllRead());
  }

  void _dismiss(String id) {
    HapticFeedback.selectionClick();
    setState(() => _svc.remove(id));
  }

  void _tapNotif(AppNotification n) {
    setState(() => n.read = true);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _svc.all.where((n) => n.id != 'stats_sync').toList();
    final unread = notifications.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(children: [
            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(unread),
            // ── Lista ───────────────────────────────────────────────────────
            Expanded(
              child: notifications.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: notifications.length,
                      itemBuilder: (_, i) {
                        final notif = notifications[i];
                        return _NotifCard(
                          key: ValueKey(notif.id),
                          notif: notif,
                          onTap: () => _tapNotif(notif),
                          onDismiss: () => _dismiss(notif.id),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(int unread) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Notificações',
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$unread',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            Text('Desliza para eliminar',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 10)),
          ]),
        ),
        if (unread > 0)
          GestureDetector(
            onTap: _markAllRead,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withAlpha(50)),
              ),
              child: Text('Ler tudo',
                  style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
    );
  }
}

// ── Card de Notificação ───────────────────────────────────────────────────────
class _NotifCard extends StatefulWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotifCard({
    super.key,
    required this.notif,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotifCard> createState() => _NotifCardState();
}

class _NotifCardState extends State<_NotifCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slide = Tween<Offset>(
      begin: const Offset(0.4, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notif;
    final config = _notifConfig(n.type);

    return SlideTransition(
      position: _slide,
      child: Dismissible(
        key: ValueKey(n.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => widget.onDismiss(),
        background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.danger.withAlpha(30),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.danger.withAlpha(60)),
          ),
          child: const Icon(Icons.delete_outline,
              color: AppColors.danger, size: 22),
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: n.read ? AppColors.surface : config.color.withAlpha(10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: n.read ? AppColors.border : config.color.withAlpha(70),
              ),
              boxShadow: n.read
                  ? []
                  : [
                      BoxShadow(
                          color: config.color.withAlpha(15),
                          blurRadius: 12,
                          spreadRadius: -4)
                    ],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Ícone
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: config.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: config.color.withAlpha(50)),
                ),
                child: Center(
                  child:
                      Text(config.icon, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              // Conteúdo
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(n.title,
                              style: GoogleFonts.spaceGrotesk(
                                color: n.read ? AppColors.text : Colors.white,
                                fontSize: 13,
                                fontWeight:
                                    n.read ? FontWeight.w500 : FontWeight.w700,
                              )),
                        ),
                        if (!n.read)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: config.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ]),
                      const SizedBox(height: 4),
                      Text(n.body,
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              height: 1.5)),
                      const SizedBox(height: 6),
                      Text(_timeAgo(n.timestamp),
                          style: GoogleFonts.inter(
                              color: config.color.withAlpha(180),
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

({String icon, Color color}) _notifConfig(NotifType type) {
  switch (type) {
    case NotifType.xp:
      return (icon: '⚡', color: AppColors.warn);
    case NotifType.warning:
      return (icon: '⚠️', color: AppColors.danger);
    case NotifType.achievement:
      return (icon: '🏆', color: AppColors.accent);
    case NotifType.tip:
      return (icon: '💡', color: AppColors.blue);
    case NotifType.system:
      return (icon: '🔔', color: AppColors.textMuted);
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Agora mesmo';
  if (diff.inMinutes < 60) return 'Há ${diff.inMinutes}min';
  if (diff.inHours < 24) return 'Há ${diff.inHours}h';
  return 'Há ${diff.inDays}d';
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child:
                const Center(child: Text('🔕', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 16),
          Text('Sem notificações',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Completa simulações para receber alertas',
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
        ]),
      );
}
