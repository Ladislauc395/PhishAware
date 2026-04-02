import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import 'api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/url_inspector.dart';
import '../widgets/rank_system.dart';
import '../widgets/staggered_animations.dart';

class DashboardScreen extends StatefulWidget {
  final UserStats stats;
  final ValueChanged<AppTab> onNavigate;
  final VoidCallback onRefresh;

  const DashboardScreen({
    super.key,
    required this.stats,
    required this.onNavigate,
    required this.onRefresh,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ringAnim;
  List<HistoryEntry> _recentActivity = [];
  bool _activityLoading = false;

  // Rastreia a patente anterior para detectar subida de nível
  CyberRank? _prevRank;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ringAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
    _loadActivity();
    _prevRank = rankFromXp(widget.stats.xp).rank;
  }

  Future<void> _loadActivity() async {
    if (_activityLoading) return;
    setState(() => _activityLoading = true);
    try {
      final data = await ApiService.getHistory();
      if (!mounted) return;
      setState(() {
        _recentActivity = data
            .take(5)
            .map((e) => HistoryEntry.fromJson(e))
            .toList();
        _activityLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _activityLoading = false);
    }
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stats.xp != widget.stats.xp ||
        oldWidget.stats.correctTotal != widget.stats.correctTotal ||
        oldWidget.stats.answeredTotal != widget.stats.answeredTotal) {
      _loadActivity();

      // Detecta subida de nível e mostra overlay
      final newRank = rankFromXp(widget.stats.xp).rank;
      if (_prevRank != null && newRank.index > _prevRank!.index && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showRankUpOverlay(context, newXp: widget.stats.xp);
        });
      }
      _prevRank = newRank;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await Future.wait([Future(widget.onRefresh), _loadActivity()]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
          children: [
            // ── Header (sem delay — aparece imediatamente) ──────────────
            _Header(
              userName: UserSession.userName,
              avatarLetter: UserSession.avatarLetter,
              onProfile: () =>
                  Navigator.pushNamed(context, Routes.profile).then((_) {
                    widget.onRefresh();
                    _loadActivity();
                  }),
            ),
            const SizedBox(height: 32),

            // ── Conteúdo com Staggered Animations ──────────────────────
            StaggeredColumn(
              staggerDelay: const Duration(milliseconds: 80),
              children: [
                // Risk Ring com Glassmorphism
                _RiskRingGlass(stats: widget.stats, animation: _ringAnim),
                const SizedBox(height: 24),

                // Rank Card (NOVO)
                RankCard(xp: widget.stats.xp),
                const SizedBox(height: 24),

                // XP Bar
                _XpBar(stats: widget.stats),
                const SizedBox(height: 24),

                // Quick Actions
                _QuickActions(
                  onNavigate: widget.onNavigate,
                  onReturnFromRoute: _loadActivity,
                ),
                const SizedBox(height: 24),

                // Category Breakdown
                _CategoryBreakdown(stats: widget.stats),
                const SizedBox(height: 24),

                // Recent Activity
                _RecentActivity(
                  entries: _recentActivity,
                  isLoading: _activityLoading,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String userName, avatarLetter;
  final VoidCallback onProfile;
  const _Header({
    required this.userName,
    required this.avatarLetter,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PhishAware',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Olá, ${userName.split(' ').first}! 👋',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onProfile,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                avatarLetter,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Risk Ring com Glassmorphism ──────────────────────────────────────────────

class _RiskRingGlass extends StatelessWidget {
  final UserStats stats;
  final Animation<double> animation;
  const _RiskRingGlass({required this.stats, required this.animation});

  Color get _ringColor {
    if (stats.resilience >= 75) return AppColors.accent;
    if (stats.resilience >= 50) return AppColors.warn;
    return AppColors.danger;
  }

  String get _riskLabel {
    if (stats.resilience >= 75) return 'Baixo Risco';
    if (stats.resilience >= 50) return 'Risco Médio';
    return 'Alto Risco';
  }

  @override
  Widget build(BuildContext context) {
    // Glassmorphism sobre o fundo da app
    return GlassAccentCard(
      accentColor: _ringColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Nível de Resiliência',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: animation,
            builder: (_, __) {
              final value = animation.value * (stats.resilience / 100);
              return SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(180, 180),
                      painter: _ArcPainter(value: value, color: _ringColor),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(animation.value * stats.resilience).toInt()}%',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _ringColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _riskLabel,
                            style: GoogleFonts.inter(
                              color: _ringColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RingStat(
                label: 'Nível',
                value: stats.level,
                color: AppColors.accent,
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _RingStat(
                label: 'XP Total',
                value: '${stats.xp}',
                color: AppColors.blue,
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _RingStat(
                label: 'Acertos',
                value: stats.answeredTotal > 0
                    ? '${stats.correctTotal}/${stats.answeredTotal}'
                    : '—',
                color: AppColors.warn,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _RingStat({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      SizedBox(height: 2),
      Text(
        label,
        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  const _ArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 12;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      Paint()
        ..color = AppColors.surface2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        math.pi * 0.75,
        math.pi * 1.5 * value,
        false,
        Paint()
          ..color = color.withAlpha(60)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        math.pi * 0.75,
        math.pi * 1.5 * value,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.color != color;
}

// ─── XP Bar ───────────────────────────────────────────────────────────────────

class _XpBar extends StatelessWidget {
  final UserStats stats;
  const _XpBar({required this.stats});

  static const _levels = [
    (0, 'Iniciante', 500),
    (500, 'Aprendiz', 1500),
    (1500, 'Defensor', 3000),
    (3000, 'Especialista', 6000),
    (6000, 'Mestre', 10000),
    (10000, 'Sentinela Elite', 99999),
  ];

  (int, String, int) get _currentLevelData {
    for (final l in _levels.reversed) {
      if (stats.xp >= l.$1) return l;
    }
    return _levels.first;
  }

  @override
  Widget build(BuildContext context) {
    final lvl = _currentLevelData;
    final progress = ((stats.xp - lvl.$1) / (lvl.$3 - lvl.$1)).clamp(0.0, 1.0);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lvl.$2,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${stats.xp} / ${lvl.$3} XP',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 8,
                backgroundColor: AppColors.surface2,
                valueColor: AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final ValueChanged<AppTab> onNavigate;
  final VoidCallback onReturnFromRoute;
  const _QuickActions({
    required this.onNavigate,
    required this.onReturnFromRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acesso Rápido',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _ActionBtn(
              icon: Icons.shield_outlined,
              label: 'Simulações',
              color: AppColors.accent,
              onTap: () => onNavigate(AppTab.simulations),
            ),
            SizedBox(width: 10),
            _ActionBtn(
              icon: Icons.menu_book_outlined,
              label: 'Aprender',
              color: AppColors.blue,
              onTap: () => onNavigate(AppTab.tips),
            ),
            SizedBox(width: 10),
            _ActionBtn(
              icon: Icons.leaderboard_outlined,
              label: 'Ranking',
              color: AppColors.warn,
              onTap: () => onNavigate(AppTab.ranking),
            ),
            SizedBox(width: 10),
            _ActionBtn(
              icon: Icons.smart_toy_outlined,
              label: 'IA',
              color: AppColors.accent2,
              onTap: () => Navigator.pushNamed(
                context,
                Routes.assistant,
              ).then((_) => onReturnFromRoute()),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: GlassAccentCard(
        accentColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Category Breakdown ───────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final UserStats stats;
  const _CategoryBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.correctTotal > 0 ? stats.correctTotal : 1;
    final cats = [
      ('📧 E-mail', AppColors.accent, stats.byCategory['email'] ?? 0),
      ('💬 SMS', AppColors.warn, stats.byCategory['sms'] ?? 0),
      ('🔗 URL', AppColors.blue, stats.byCategory['url'] ?? 0),
      ('📱 App/QR', AppColors.accent2, stats.byCategory['app'] ?? 0),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desempenho por Categoria',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          ...cats.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      c.$1,
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: c.$3 / total),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          backgroundColor: AppColors.surface2,
                          valueColor: AlwaysStoppedAnimation(c.$2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${c.$3}',
                      style: GoogleFonts.inter(
                        color: c.$2,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
}

// ─── Recent Activity com Staggered ───────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  final List<HistoryEntry> entries;
  final bool isLoading;
  const _RecentActivity({required this.entries, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Atividade Recente',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.accent,
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, Routes.history),
                  child: Text(
                    'Ver tudo',
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Shimmer enquanto carrega
        if (entries.isEmpty && isLoading)
          const HistoryShimmer(count: 3)
        else if (entries.isEmpty && !isLoading)
          GlassCard(
            padding: const EdgeInsets.all(24),
            borderRadius: 20,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text(
                    'Ainda sem atividade',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Completa uma simulação para começar!',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Staggered items — cada entrada entra com delay
          Column(
            children: entries.asMap().entries.map((e) {
              final idx = e.key;
              final entry = e.value;
              final isLast = idx == entries.length - 1;
              return StaggeredItem(
                index: idx,
                staggerDelay: const Duration(milliseconds: 60),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: entry.isCorrect
                          ? AppColors.accent.withAlpha(30)
                          : AppColors.danger.withAlpha(20),
                    ),
                  ),
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  child: Row(
                    children: [
                      Text(
                        entry.categoryIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.scenario,
                          style: GoogleFonts.inter(
                            color: AppColors.text,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            entry.isCorrect ? '✅ Acerto' : '❌ Erro',
                            style: GoogleFonts.inter(
                              color: entry.isCorrect
                                  ? AppColors.accent
                                  : AppColors.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            entry.timeAgo,
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
