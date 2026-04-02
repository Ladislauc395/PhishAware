import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';

// ─── Main Screen ─────────────────────────────────────────────────────────────

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

  /// Tracks which tip indices have been read, per category
  final Map<int, Set<int>> _readTips = {0: {}, 1: {}, 2: {}, 3: {}};

  final List<_CategoryData> _categories = [
    _CategoryData('Email', Icons.alternate_email_rounded, AppColors.accent, 6),
    _CategoryData('URLs', Icons.travel_explore_rounded, AppColors.blue, 6),
    _CategoryData('Mobile', Icons.smartphone_rounded, AppColors.warn, 6),
    _CategoryData(
      'Proteção',
      Icons.verified_user_rounded,
      AppColors.accent2,
      7,
    ),
  ];

  // ── Computed helpers ──────────────────────────────────────────────────────
  int get _totalTips => _categories.fold<int>(0, (s, c) => s + c.count);
  int get _totalRead => _readTips.values.fold<int>(0, (s, r) => s + r.length);
  double get _overallProgress => _totalTips > 0 ? _totalRead / _totalTips : 0.0;

  int _catRead(int i) => _readTips[i]?.length ?? 0;
  int _catTotal(int i) => _categories[i].count;
  double _catProgress(int i) =>
      _catTotal(i) > 0 ? _catRead(i) / _catTotal(i) : 0.0;
  bool _catDone(int i) => _catRead(i) == _catTotal(i);

  void _markRead(int cat, int tip) {
    if (_readTips[cat]?.contains(tip) ?? false) return;
    setState(() => (_readTips[cat] ??= {}).add(tip));
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _headerPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
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
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
    _entryCtrl
      ..reset()
      ..forward();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildMasterProgressBar(),
          _buildCategoryRow(),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = i);
                _entryCtrl
                  ..reset()
                  ..forward();
              },
              children: [
                _TipListPage(
                  tips: _emailTips,
                  entryFade: _entryFade,
                  entrySlide: _entrySlide,
                  categoryIndex: 0,
                  readTips: _readTips[0]!,
                  onRead: _markRead,
                ),
                _TipListPage(
                  tips: _urlTips,
                  entryFade: _entryFade,
                  entrySlide: _entrySlide,
                  categoryIndex: 1,
                  readTips: _readTips[1]!,
                  onRead: _markRead,
                ),
                _TipListPage(
                  tips: _mobileTips,
                  entryFade: _entryFade,
                  entrySlide: _entrySlide,
                  categoryIndex: 2,
                  readTips: _readTips[2]!,
                  onRead: _markRead,
                ),
                _BestPracticesPage(
                  entryFade: _entryFade,
                  entrySlide: _entrySlide,
                  categoryIndex: 3,
                  readTips: _readTips[3]!,
                  onRead: _markRead,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerPulse,
      builder: (_, __) {
        final pulse = _headerPulse.value;
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.of(context).padding.top + 16,
            24,
            18,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.bg,
                AppColors.accent.withAlpha((6 + pulse * 10).round()),
                AppColors.bg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(color: Colors.white.withAlpha(8)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Progress ring around shield icon
              SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(58, 58),
                      painter: _RingPainter(
                        progress: _overallProgress,
                        color: AppColors.accent,
                        bgColor: AppColors.accent.withAlpha(18),
                        strokeWidth: 3,
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withAlpha(15),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(
                            0.25 + pulse * 0.25,
                          ),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.shield_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Centro de\nInteligência',
                      style: GoogleFonts.syne(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '$_totalRead',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '/$_totalTips dicas exploradas',
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
              // Blinking alert badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.danger.withOpacity(0.2 + pulse * 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.danger.withOpacity(0.5 + pulse * 0.5),
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'ALERTA ATIVO',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.danger,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Master progress bar ───────────────────────────────────────────────────
  Widget _buildMasterProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso geral',
                style: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 9,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '${(_overallProgress * 100).round()}%',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.accent.withAlpha(150),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _overallProgress,
              minHeight: 4,
              backgroundColor: Colors.white.withAlpha(8),
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category row ──────────────────────────────────────────────────────────
  Widget _buildCategoryRow() {
    return SizedBox(
      height: 62,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = i == _selectedCategory;
          final read = _catRead(i);
          final total = _catTotal(i);
          final done = _catDone(i);

          return GestureDetector(
            onTap: () => _selectCategory(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 10),
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 16 : 14,
                vertical: 0,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? cat.color.withAlpha(20)
                    : Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: selected
                      ? cat.color.withAlpha(80)
                      : Colors.white.withAlpha(10),
                  width: 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: cat.color.withAlpha(35),
                          blurRadius: 14,
                          spreadRadius: -3,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    color: selected ? cat.color : Colors.white30,
                    size: 14,
                  ),
                  const SizedBox(width: 7),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.label,
                        style: GoogleFonts.syne(
                          color: selected
                              ? Colors.white
                              : Colors.white.withAlpha(97),
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '$read/$total',
                            style: GoogleFonts.jetBrainsMono(
                              color: selected
                                  ? cat.color
                                  : Colors.white.withAlpha(51),
                              fontSize: 9,
                            ),
                          ),
                          if (done) ...[
                            const SizedBox(width: 3),
                            Icon(
                              Icons.check_circle_rounded,
                              color: cat.color,
                              size: 10,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  // Mini progress ring (visible when selected & has progress)
                  if (selected && read > 0 && !done) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(
                        painter: _RingPainter(
                          progress: _catProgress(i),
                          color: cat.color,
                          bgColor: cat.color.withAlpha(20),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color, bgColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    this.strokeWidth = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (math.min(size.width, size.height) - strokeWidth) / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, p..color = bgColor);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        p..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

// ─── Tip List Page ─────────────────────────────────────────────────────────────

class _TipListPage extends StatelessWidget {
  final List<_TipData> tips;
  final Animation<double> entryFade;
  final Animation<Offset> entrySlide;
  final int categoryIndex;
  final Set<int> readTips;
  final void Function(int cat, int tip) onRead;

  const _TipListPage({
    required this.tips,
    required this.entryFade,
    required this.entrySlide,
    required this.categoryIndex,
    required this.readTips,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: entryFade,
      child: SlideTransition(
        position: entrySlide,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: tips.length,
          itemBuilder: (_, i) => _TipCard(
            tip: tips[i],
            index: i,
            isRead: readTips.contains(i),
            onRead: () => onRead(categoryIndex, i),
          ),
        ),
      ),
    );
  }
}

// ─── Tip Card ─────────────────────────────────────────────────────────────────

class _TipCard extends StatefulWidget {
  final _TipData tip;
  final int index;
  final bool isRead;
  final VoidCallback onRead;

  const _TipCard({
    required this.tip,
    required this.index,
    required this.isRead,
    required this.onRead,
  });

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
    if (_expanded && !widget.isRead) widget.onRead();
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
          gradient: _expanded
              ? LinearGradient(
                  colors: [
                    tip.color.withAlpha(14),
                    AppColors.surface.withAlpha(220),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _expanded ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expanded
                ? tip.color.withAlpha(70)
                : widget.isRead
                ? tip.color.withAlpha(30)
                : Colors.white.withAlpha(8),
            width: 1,
          ),
          boxShadow: _expanded
              ? [
                  BoxShadow(
                    color: tip.color.withAlpha(25),
                    blurRadius: 20,
                    spreadRadius: -4,
                  ),
                ]
              : [],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color accent bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tip.color,
                      tip.color.withAlpha(_expanded ? 180 : 60),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              // Card body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icon
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  tip.color.withAlpha(30),
                                  tip.color.withAlpha(10),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: tip.color.withAlpha(40),
                                width: 1,
                              ),
                            ),
                            child: Icon(tip.icon, color: tip.color, size: 17),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tip.tag != null) ...[
                                  _TagPill(tag: tip.tag!, color: tip.color),
                                  const SizedBox(height: 3),
                                ],
                                Text(
                                  tip.title,
                                  style: GoogleFonts.syne(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Read indicator or chevron
                          if (widget.isRead && !_expanded)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tip.color.withAlpha(20),
                                border: Border.all(
                                  color: tip.color.withAlpha(60),
                                ),
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                color: tip.color,
                                size: 12,
                              ),
                            )
                          else
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
                        ],
                      ),
                      // Expanded content
                      SizeTransition(
                        sizeFactor: _anim,
                        child: FadeTransition(
                          opacity: _anim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 14),
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      tip.color.withAlpha(80),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tip.description,
                                style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: 12.5,
                                  height: 1.65,
                                ),
                              ),
                              if (tip.keyInsight != null) ...[
                                const SizedBox(height: 14),
                                _KeyInsightBox(
                                  text: tip.keyInsight!,
                                  color: tip.color,
                                ),
                              ],
                              const SizedBox(height: 10),
                              _ReadBadge(color: tip.color),
                            ],
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
      ),
    );
  }
}

// ─── Tag Pill ─────────────────────────────────────────────────────────────────

class _TagPill extends StatelessWidget {
  final String tag;
  final Color color;
  const _TagPill({required this.tag, required this.color});

  static Color _tagBg(String t, Color c) {
    switch (t) {
      case 'CRÍTICO':
        return const Color(0xFFFF4444);
      case 'PERIGO':
        return const Color(0xFFFF6B35);
      default:
        return c;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _tagBg(tag, color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withAlpha(18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: c.withAlpha(50)),
      ),
      child: Text(
        tag,
        style: GoogleFonts.jetBrainsMono(
          color: c,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Key Insight Box ──────────────────────────────────────────────────────────

class _KeyInsightBox extends StatelessWidget {
  final String text;
  final Color color;
  const _KeyInsightBox({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outlined, color: color, size: 13),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: color.withAlpha(200),
                fontSize: 11.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Read Badge ───────────────────────────────────────────────────────────────

class _ReadBadge extends StatelessWidget {
  final Color color;
  const _ReadBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: color, size: 12),
        const SizedBox(width: 5),
        Text(
          'Marcado como lida',
          style: GoogleFonts.inter(
            color: color.withAlpha(160),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _CategoryData {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  const _CategoryData(this.label, this.icon, this.color, this.count);
}

class _TipData {
  final String title, description;
  final IconData icon;
  final Color color;
  final String? tag;
  final String? keyInsight;

  const _TipData(
    this.title,
    this.description,
    this.icon,
    this.color, {
    this.tag,
    this.keyInsight,
  });
}

// ─── Tip Data ─────────────────────────────────────────────────────────────────

final _emailTips = [
  _TipData(
    'Verifica sempre o remetente',
    'Empresas legítimas usam sempre o seu domínio oficial. "paypa1.com" ou "banco-seguro.info" são falsos. Passa o dedo sobre o email para ver o endereço real.',
    Icons.alternate_email_rounded,
    AppColors.accent,
    tag: 'BÁSICO',
    keyInsight:
        'Regra de ouro: o que vês no nome do remetente pode ser falso. Só o domínio após "@" é verificável.',
  ),
  _TipData(
    'Desconfia de urgência',
    '"A tua conta será suspensa em 24h!" é uma técnica de pressão psicológica. Empresas legítimas nunca criam pânico artificial para te forçar a agir sem pensar.',
    Icons.timer_off_outlined,
    AppColors.danger,
    tag: 'CRÍTICO',
    keyInsight:
        'Se a mensagem cria pressão, para, respira, e verifica por outro canal. A urgência é a arma principal do phishing.',
  ),
  _TipData(
    'Não abras anexos suspeitos',
    'Ficheiros .exe, .zip, .docm e .xlsm podem conter malware. Mesmo PDFs podem ter scripts maliciosos. Verifica com o remetente por outro canal antes de abrir.',
    Icons.attach_file_rounded,
    AppColors.warn,
    tag: 'PERIGO',
    keyInsight:
        'Abre sempre os ficheiros numa sandbox ou pede à equipa de TI para verificar antes de abrir documentos inesperados.',
  ),
  _TipData(
    'Links em emails: nunca confiar',
    'Mesmo que o link pareça correto, passa o dedo por cima para ver o URL real. Vai sempre ao site diretamente pelo browser em vez de clicar em links de email.',
    Icons.link_off_rounded,
    AppColors.blue,
    tag: 'BÁSICO',
    keyInsight:
        'Adiciona o teu banco e serviços críticos a bookmarks. Nunca os acedas por links de emails.',
  ),
  _TipData(
    'Spear Phishing: ataques personalizados',
    'Atacantes recolhem informação do LinkedIn, redes sociais e bases de dados para criar emails com o teu nome, empresa e contexto real. Sê cético mesmo com contexto correto.',
    Icons.person_search_rounded,
    AppColors.accent2,
    tag: 'AVANÇADO',
    keyInsight:
        'Quanto menos informação pessoal partilhas online, menos eficaz é o spear phishing contra ti.',
  ),
  _TipData(
    'Cabeçalhos de email revelam tudo',
    'Os cabeçalhos técnicos de um email mostram o servidor de origem real. Em clientes como Gmail, podes ver "Ver original" para verificar a autenticidade.',
    Icons.code_rounded,
    Color(0xFF6B7280),
    tag: 'TÉCNICO',
    keyInsight:
        'No Gmail: três pontos → "Ver original". Procura "Received: from" para ver o servidor real que enviou o email.',
  ),
];

final _urlTips = [
  _TipData(
    'HTTPS não significa seguro',
    'O cadeado verde apenas indica que a ligação é cifrada. Não garante que o site é legítimo. Sites phishing usam HTTPS com certificados gratuitos (Let\'s Encrypt).',
    Icons.lock_open_rounded,
    AppColors.warn,
    tag: 'MITO',
    keyInsight:
        '97% dos sites de phishing modernos usam HTTPS. O cadeado verde não é garantia de segurança — é apenas encriptação.',
  ),
  _TipData(
    'O domínio real é o que importa',
    'Em "netflix.com.verificar-conta.xyz", o domínio real é "verificar-conta.xyz". Tudo antes é apenas um subdomínio. Aprende a identificar o domínio principal.',
    Icons.travel_explore_rounded,
    AppColors.danger,
    tag: 'CRÍTICO',
    keyInsight:
        'O domínio real é sempre o texto imediatamente antes do último "/" e após o último ponto antes dele.',
  ),
  _TipData(
    'Typosquatting: erros propositados',
    '"arnazon.com", "goggle.com", "paypa1.com" — atacantes registam domínios com erros de digitação propositados para enganar utilizadores distraídos.',
    Icons.spellcheck_rounded,
    AppColors.accent,
    tag: 'TÁTICA',
    keyInsight:
        'Verifica letra por letra os domínios importantes. O "rn" pode parecer "m" em certas fontes: "arnazon.com" vs "amazon.com".',
  ),
  _TipData(
    'URLs encurtados: perigo escondido',
    'Links bit.ly, tinyurl ou t.co podem esconder URLs maliciosos. Usa serviços como "checkshorturl.com" para ver o destino real antes de clicar.',
    Icons.short_text_rounded,
    AppColors.blue,
    tag: 'PERIGO',
    keyInsight:
        'Nunca cliques em links encurtados sem verificar. Adiciona "+", ao final de um link bit.ly para ver para onde redireciona.',
  ),
  _TipData(
    'Analisa a estrutura completa do URL',
    'Verifica: protocolo (https://), domínio (empresa.com), caminho (/login). Páginas de login nunca devem ter domínios estranhos como "login.empresa.com.atacante.net".',
    Icons.schema_outlined,
    AppColors.accent2,
    tag: 'TÉCNICO',
    keyInsight:
        'Lê o URL da direita para a esquerda: primeiro o domínio principal, depois os subdomínios. Assim identificas falsificações mais facilmente.',
  ),
  _TipData(
    'Bookmarks em vez de links',
    'Para sites importantes como banco, email e redes sociais, usa sempre bookmarks guardados tu mesmo. Nunca acedas por links de emails ou mensagens.',
    Icons.bookmark_rounded,
    AppColors.accent,
    tag: 'HÁBITO',
    keyInsight:
        'Cria uma pasta de bookmarks "Sites seguros" e usa-a exclusivamente para acessos críticos. Demora 5 minutos a configurar.',
  ),
];

final _mobileTips = [
  _TipData(
    'Smishing: SMS Phishing',
    'SMS fraudulentos imitam bancos, CTT, operadoras e até AT (Finanças). Têm links para sites clonados. Os CTT nunca cobram taxas por SMS — acede sempre ao site oficial.',
    Icons.sms_rounded,
    AppColors.warn,
    tag: 'ALERTA',
    keyInsight:
        'Em Portugal, o CTT, banco ou finanças nunca te pedem dados ou pagamentos por SMS. Se receberes, denuncia ao CNCS (cncs.gov.pt).',
  ),
  _TipData(
    'QR Codes maliciosos',
    'QR codes em locais públicos podem ser colados por cima dos originais. Verifica sempre o URL antes de continuar. Um menu digital nunca precisa de aceder aos teus contactos ou SMS.',
    Icons.qr_code_scanner_rounded,
    AppColors.danger,
    tag: 'NOVO',
    keyInsight:
        'Antes de seguir um QR code, verifica se há um autocolante colado por cima. QR codes físicos legítimos raramente pedem login.',
  ),
  _TipData(
    'Permissões de apps: menos é mais',
    'Uma lanterna não precisa de aceder aos teus contactos. Uma app de calculadora não precisa da câmara. Revê as permissões de todas as apps em Definições.',
    Icons.admin_panel_settings_rounded,
    AppColors.blue,
    tag: 'HÁBITO',
    keyInsight:
        'Android: Definições → Privacidade → Gestor de permissões. iOS: Definições → Privacidade e Segurança. Revoga permissões desnecessárias.',
  ),
  _TipData(
    'Só instala apps de fontes oficiais',
    'Google Play Store e Apple App Store têm verificações de segurança. APKs de sites externos não têm. Mesmo assim, verifica o desenvolvedor e as avaliações na loja oficial.',
    Icons.store_rounded,
    AppColors.accent,
    tag: 'BÁSICO',
    keyInsight:
        'Antes de instalar, verifica: quem é o desenvolvedor? Quantas descargas tem? As avaliações parecem reais? Data de publicação recente pode ser sinal de alerta.',
  ),
  _TipData(
    'Vishing: chamadas de voz falsas',
    'Chamadas fingindo ser banco, SEF, GNR ou Microsoft. Nunca dês dados pessoais, senhas ou códigos SMS ao telefone — nenhuma entidade legítima pede isso por chamada.',
    Icons.call_rounded,
    AppColors.accent2,
    tag: 'CRÍTICO',
    keyInsight:
        'Em caso de dúvida, desliga e liga tu próprio para o número oficial da instituição. Nunca uses o número que te ligaram.',
  ),
  _TipData(
    'Wi-Fi público: risco real',
    'Em Wi-Fi público, atacantes podem fazer "man-in-the-middle" para intercetar os teus dados. Usa sempre VPN em redes públicas e evita aceder a contas bancárias.',
    Icons.wifi_off_rounded,
    AppColors.danger,
    tag: 'PERIGO',
    keyInsight:
        'VPNs gratuitas podem ser perigosas (vendem os teus dados). Usa Mullvad, ProtonVPN ou a VPN da tua empresa para redes públicas.',
  ),
];

// ─── Best Practices Page ──────────────────────────────────────────────────────

class _BestPracticesPage extends StatelessWidget {
  final Animation<double> entryFade;
  final Animation<Offset> entrySlide;
  final int categoryIndex;
  final Set<int> readTips;
  final void Function(int cat, int tip) onRead;

  const _BestPracticesPage({
    required this.entryFade,
    required this.entrySlide,
    required this.categoryIndex,
    required this.readTips,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: entryFade,
      child: SlideTransition(
        position: entrySlide,
        child: _BestPracticesContent(
          categoryIndex: categoryIndex,
          readTips: readTips,
          onRead: onRead,
        ),
      ),
    );
  }
}

class _BestPracticesContent extends StatelessWidget {
  final int categoryIndex;
  final Set<int> readTips;
  final void Function(int cat, int tip) onRead;

  const _BestPracticesContent({
    required this.categoryIndex,
    required this.readTips,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _SectionDivider(
          'Gestão de Passwords',
          Icons.key_rounded,
          AppColors.accent,
        ),
        _PracticeCard(
          index: 0,
          priority: 1,
          title: 'Usa um gestor de passwords',
          desc:
              'Bitwarden, 1Password ou KeePass geram e guardam passwords únicas e complexas para cada site. Nunca reutilizes passwords.',
          score: 10,
          color: AppColors.accent,
          badge: 'ESSENCIAL',
          isRead: readTips.contains(0),
          onRead: () => onRead(categoryIndex, 0),
        ),
        _PracticeCard(
          index: 1,
          priority: 2,
          title: 'Autenticação de 2 Fatores (2FA)',
          desc:
              'Ativa 2FA em todas as contas importantes. Mesmo que a tua senha seja roubada, o atacante não consegue entrar sem o segundo fator.',
          score: 10,
          color: AppColors.accent,
          badge: 'ESSENCIAL',
          isRead: readTips.contains(1),
          onRead: () => onRead(categoryIndex, 1),
        ),
        SizedBox(height: 20),
        _SectionDivider(
          'Atualizações e Backups',
          Icons.refresh_rounded,
          AppColors.blue,
        ),
        _PracticeCard(
          index: 2,
          priority: 3,
          title: 'Mantém tudo atualizado',
          desc:
              'Sistemas operativos, browsers e apps desatualizados têm vulnerabilidades conhecidas que atacantes exploram. Ativa atualizações automáticas.',
          score: 8,
          color: AppColors.blue,
          badge: 'IMPORTANTE',
          isRead: readTips.contains(2),
          onRead: () => onRead(categoryIndex, 2),
        ),
        _PracticeCard(
          index: 3,
          priority: 4,
          title: 'Backups regulares (3-2-1)',
          desc:
              '3 cópias dos dados, em 2 locais diferentes, com 1 offline. Se fores vítima de ransomware, backups são a única forma de recuperar sem pagar.',
          score: 9,
          color: AppColors.blue,
          badge: 'IMPORTANTE',
          isRead: readTips.contains(3),
          onRead: () => onRead(categoryIndex, 3),
        ),
        SizedBox(height: 20),
        _SectionDivider(
          'Comportamento Digital',
          Icons.psychology_rounded,
          AppColors.warn,
        ),
        _PracticeCard(
          index: 4,
          priority: 5,
          title: 'Verifica antes de clicar',
          desc:
              'Para. Respira. Pensa. A urgência artificial é a principal ferramenta do phishing. Se a mensagem cria pressão, provavelmente é falsa.',
          score: 10,
          color: AppColors.warn,
          badge: 'CRÍTICO',
          isRead: readTips.contains(4),
          onRead: () => onRead(categoryIndex, 4),
        ),
        _PracticeCard(
          index: 5,
          priority: 6,
          title: 'Confirma por outro canal',
          desc:
              'Se recebes um email suspeito do teu banco, liga diretamente para o banco usando o número oficial — nunca o número do email.',
          score: 9,
          color: AppColors.warn,
          badge: 'IMPORTANTE',
          isRead: readTips.contains(5),
          onRead: () => onRead(categoryIndex, 5),
        ),
        _PracticeCard(
          index: 6,
          priority: 7,
          title: 'Minimiza a tua pegada digital',
          desc:
              'Quanto menos informação pessoal publicares online, menos material os atacantes têm para spear phishing. Revê as definições de privacidade.',
          score: 7,
          color: AppColors.accent2,
          badge: 'HÁBITO',
          isRead: readTips.contains(6),
          onRead: () => onRead(categoryIndex, 6),
        ),
        const SizedBox(height: 20),
        _GoldenRulesCard(),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionDivider(this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
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
          Text(
            title,
            style: GoogleFonts.syne(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 1, color: Colors.white.withAlpha(8)),
          ),
        ],
      ),
    );
  }
}

class _PracticeCard extends StatefulWidget {
  final int index, priority, score;
  final String title, desc, badge;
  final Color color;
  final bool isRead;
  final VoidCallback onRead;

  const _PracticeCard({
    required this.index,
    required this.priority,
    required this.title,
    required this.desc,
    required this.score,
    required this.color,
    required this.badge,
    required this.isRead,
    required this.onRead,
  });

  @override
  State<_PracticeCard> createState() => _PracticeCardState();
}

class _PracticeCardState extends State<_PracticeCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
    if (_expanded && !widget.isRead) widget.onRead();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: _expanded
              ? LinearGradient(
                  colors: [c.withAlpha(10), const Color(0xFF0B1120)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _expanded ? null : const Color(0xFF0B1120),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? c.withAlpha(60)
                : widget.isRead
                ? c.withAlpha(25)
                : Colors.white.withAlpha(8),
          ),
          boxShadow: _expanded
              ? [
                  BoxShadow(
                    color: c.withAlpha(20),
                    blurRadius: 12,
                    spreadRadius: -3,
                  ),
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority number badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.withAlpha(20), c.withAlpha(8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: c.withAlpha(50)),
              ),
              child: widget.isRead
                  ? Icon(Icons.check_rounded, color: c, size: 15)
                  : Center(
                      child: Text(
                        '${widget.priority}',
                        style: GoogleFonts.jetBrainsMono(
                          color: c,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: GoogleFonts.syne(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.withAlpha(12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: c.withAlpha(40)),
                        ),
                        child: Text(
                          widget.badge,
                          style: GoogleFonts.jetBrainsMono(
                            color: c,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Score bar (always visible)
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: widget.score / 10,
                            backgroundColor: Colors.white.withAlpha(8),
                            valueColor: AlwaysStoppedAnimation(c),
                            minHeight: 3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.score}/10',
                        style: GoogleFonts.jetBrainsMono(
                          color: c,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  // Expandable description
                  SizeTransition(
                    sizeFactor: _anim,
                    child: FadeTransition(
                      opacity: _anim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [c.withAlpha(60), Colors.transparent],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.desc,
                            style: GoogleFonts.inter(
                              color: Colors.white.withAlpha(97),
                              fontSize: 11.5,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Golden Rules Card ────────────────────────────────────────────────────────

class _GoldenRulesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const rules = [
      (
        Icons.visibility_rounded,
        'Nunca cliques em links — vai sempre diretamente ao site',
      ),
      (Icons.lock_rounded, 'Nunca partilhes senhas, mesmo que peçam'),
      (
        Icons.phone_callback_rounded,
        'Confirma pedidos urgentes por outro canal',
      ),
      (Icons.system_update_rounded, 'Mantém tudo atualizado'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0E1F14), Color(0xFF0B1120)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withAlpha(15),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REGRA DE OURO',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Os 4 mandamentos de segurança',
                      style: GoogleFonts.syne(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(height: 1, color: AppColors.accent.withAlpha(20)),
          const SizedBox(height: 16),
          ...rules.asMap().entries.map((entry) {
            final i = entry.key;
            final rule = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    '0${i + 1}',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.accent.withAlpha(60),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent.withAlpha(30)),
                    ),
                    child: Icon(rule.$1, color: AppColors.accent, size: 15),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rule.$2,
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
