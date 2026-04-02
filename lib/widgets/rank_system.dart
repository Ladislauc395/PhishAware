import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Modelo de Patente ────────────────────────────────────────────────────────

enum CyberRank {
  novato, // 0–499 XP
  aprendiz, // 500–1499
  defensor, // 1500–2999
  especialista, // 3000–5999
  mestre, // 6000–9999
  sentinela, // 10000+
}

class RankInfo {
  final CyberRank rank;
  final String title;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final int minXp;
  final int maxXp;
  final String description;

  const RankInfo({
    required this.rank,
    required this.title,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.minXp,
    required this.maxXp,
    required this.description,
  });

  double progressTo(int currentXp) {
    if (maxXp == currentXp) return 1.0;
    return ((currentXp - minXp) / (maxXp - minXp)).clamp(0.0, 1.0);
  }
}

const _rankData = [
  RankInfo(
    rank: CyberRank.novato,
    title: 'Novato Digital',
    emoji: '🔰',
    primaryColor: Color(0xFF64748B),
    secondaryColor: Color(0xFF475569),
    minXp: 0,
    maxXp: 500,
    description: 'Ainda a aprender os fundamentos da cibersegurança.',
  ),
  RankInfo(
    rank: CyberRank.aprendiz,
    title: 'Aprendiz de Segurança',
    emoji: '🛡️',
    primaryColor: Color(0xFF3B82F6),
    secondaryColor: Color(0xFF2563EB),
    minXp: 500,
    maxXp: 1500,
    description: 'Começas a reconhecer padrões de phishing.',
  ),
  RankInfo(
    rank: CyberRank.defensor,
    title: 'Defensor Cibernético',
    emoji: '⚔️',
    primaryColor: Color(0xFF10B981),
    secondaryColor: Color(0xFF059669),
    minXp: 1500,
    maxXp: 3000,
    description: 'Proteges-te e educas os que te rodeiam.',
  ),
  RankInfo(
    rank: CyberRank.especialista,
    title: 'Especialista em Ameaças',
    emoji: '🔍',
    primaryColor: Color(0xFFF59E0B),
    secondaryColor: Color(0xFFD97706),
    minXp: 3000,
    maxXp: 6000,
    description: 'Analisas ameaças com precisão de analista.',
  ),
  RankInfo(
    rank: CyberRank.mestre,
    title: 'Mestre da Segurança',
    emoji: '🧠',
    primaryColor: Color(0xFFEC4899),
    secondaryColor: Color(0xFFDB2777),
    minXp: 6000,
    maxXp: 10000,
    description: 'O teu conhecimento é temido pelos atacantes.',
  ),
  RankInfo(
    rank: CyberRank.sentinela,
    title: 'Sentinela Elite',
    emoji: '👑',
    primaryColor: Color(0xFF00E5A0),
    secondaryColor: Color(0xFF0EA5E9),
    minXp: 10000,
    maxXp: 99999,
    description: 'O ápice da segurança digital. Ninguém te engana.',
  ),
];

/// Devolve a [RankInfo] correspondente a um valor de XP.
RankInfo rankFromXp(int xp) {
  for (final r in _rankData.reversed) {
    if (xp >= r.minXp) return r;
  }
  return _rankData.first;
}

// ─── Badge Widget ─────────────────────────────────────────────────────────────

/// Badge circular animado com glow + anel de progresso.
/// Ideal para o Dashboard e ecrã de perfil.
class RankBadge extends StatefulWidget {
  final int xp;
  final double size;
  final bool animated;

  const RankBadge({
    super.key,
    required this.xp,
    this.size = 100,
    this.animated = true,
  });

  @override
  State<RankBadge> createState() => _RankBadgeState();
}

class _RankBadgeState extends State<RankBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ring;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _ring = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _pulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    if (widget.animated) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rank = rankFromXp(widget.xp);
    final progress = rank.progressTo(widget.xp);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: rank.primaryColor.withAlpha(
                        (_ring.value * 60).toInt(),
                      ),
                      blurRadius: 32,
                      spreadRadius: -4,
                    ),
                  ],
                ),
              ),
              // Progress arc
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RankArcPainter(
                  progress: _ring.value * progress,
                  color: rank.primaryColor,
                  secondaryColor: rank.secondaryColor,
                ),
              ),
              // Inner circle
              Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: widget.size * 0.7,
                  height: widget.size * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        rank.primaryColor.withAlpha(30),
                        rank.secondaryColor.withAlpha(20),
                      ],
                    ),
                    border: Border.all(
                      color: rank.primaryColor.withAlpha(80),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      rank.emoji,
                      style: TextStyle(fontSize: widget.size * 0.28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RankArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color secondaryColor;

  const _RankArcPainter({
    required this.progress,
    required this.color,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    const startAngle = -math.pi / 2;
    const sweep = math.pi * 2;

    // Background ring
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      startAngle,
      sweep,
      false,
      Paint()
        ..color = color.withAlpha(20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Progress ring with gradient
    final shader = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweep * progress,
      colors: [color, secondaryColor],
    ).createShader(Rect.fromCircle(center: c, radius: r));

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      startAngle,
      sweep * progress,
      false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RankArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── RankCard Widget ──────────────────────────────────────────────────────────

/// Card compacto com badge + título + progresso — para o Dashboard e Perfil.
class RankCard extends StatelessWidget {
  final int xp;
  const RankCard({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    final rank = rankFromXp(xp);
    final progress = rank.progressTo(xp);
    final nextXp = rank.maxXp - xp;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rank.primaryColor.withAlpha(25),
            rank.secondaryColor.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rank.primaryColor.withAlpha(50)),
      ),
      child: Row(
        children: [
          RankBadge(xp: xp, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank.title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rank.description,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 5,
                      backgroundColor: rank.primaryColor.withAlpha(20),
                      valueColor: AlwaysStoppedAnimation(rank.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$xp XP',
                      style: GoogleFonts.inter(
                        color: rank.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (rank.rank != CyberRank.sentinela)
                      Text(
                        'Faltam $nextXp XP para subir',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 9,
                        ),
                      )
                    else
                      Text(
                        'Nível máximo atingido! 🎉',
                        style: GoogleFonts.inter(
                          color: rank.primaryColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RankUpOverlay ────────────────────────────────────────────────────────────

/// Overlay de animação de "subida de nível" — mostra quando o utilizador sobe de patente.
/// Chama: showRankUpOverlay(context, newXp: 1500);

void showRankUpOverlay(BuildContext context, {required int newXp}) {
  final rank = rankFromXp(newXp);
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Rank Up',
    barrierColor: Colors.black.withAlpha(160),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, anim, __) => _RankUpDialog(rank: rank, anim: anim),
  );
}

class _RankUpDialog extends StatelessWidget {
  final RankInfo rank;
  final Animation<double> anim;

  const _RankUpDialog({required this.rank, required this.anim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: anim,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E14),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: rank.primaryColor.withAlpha(80)),
              boxShadow: [
                BoxShadow(
                  color: rank.primaryColor.withAlpha(50),
                  blurRadius: 48,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '⬆️ Subiste de Nível!',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                RankBadge(xp: rank.minXp, size: 120),
                const SizedBox(height: 16),
                Text(
                  rank.title,
                  style: GoogleFonts.spaceGrotesk(
                    color: rank.primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rank.description,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [rank.primaryColor, rank.secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Continuar',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
