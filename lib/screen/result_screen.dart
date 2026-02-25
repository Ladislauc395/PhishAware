import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'app_models.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl, _fadeCtrl;
  late Animation<double> _scaleAnim, _fadeAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleCtrl.forward();
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final int score = (args['score'] as num?)?.toInt() ?? 0;
    final int total = (args['total'] as num?)?.toInt() ?? 0;
    final String? simId = args['simId'] as String?;

    final int correct = args['correct'] as int? ?? 0;
    final double pct = total > 0
        ? correct / total
        : score > 0
            ? 1.0
            : 0.0;
    final bool great = pct >= 0.7;

    final String emoji = pct >= 0.9
        ? '🏆'
        : pct >= 0.7
            ? '🎯'
            : pct >= 0.4
                ? '💪'
                : '📚';
    final String title = pct >= 0.9
        ? 'Excelente!'
        : pct >= 0.7
            ? 'Muito Bem!'
            : pct >= 0.4
                ? 'Boa tentativa!'
                : 'Continua a praticar!';
    final Color color = pct >= 0.7
        ? AppColors.accent
        : pct >= 0.4
            ? AppColors.warn
            : AppColors.danger;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),

                // Animated trophy/emoji
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withAlpha(20),
                      border: Border.all(color: color.withAlpha(60), width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: color.withAlpha(40),
                            blurRadius: 40,
                            spreadRadius: -5)
                      ],
                    ),
                    child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 56))),
                  ),
                ),
                const SizedBox(height: 28),

                Text(title,
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Simulação concluída!',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 14)),
                const SizedBox(height: 36),

                // Score card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color.withAlpha(60)),
                    boxShadow: [
                      BoxShadow(
                          color: color.withAlpha(15),
                          blurRadius: 30,
                          spreadRadius: -5)
                    ],
                  ),
                  child: Column(children: [
                    // Circular score
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: _ScorePainter(value: pct, color: color),
                        child: Center(
                            child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${score}',
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700)),
                            Text('XP',
                                style: GoogleFonts.inter(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        )),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat('Pontuação', '$score XP', AppColors.accent),
                        _Stat('Questões', '$total', AppColors.blue),
                        _Stat('Resultado', great ? 'Aprovado ✓' : 'Reprovado ✗',
                            great ? AppColors.accent : AppColors.danger),
                      ],
                    ),
                  ]),
                ),

                const Spacer(),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, Routes.dashboard, (_) => false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('Voltar ao Dashboard',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, Routes.quiz),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Tentar Novamente',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600)),
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

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: GoogleFonts.spaceGrotesk(
                color: color, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
      ]);
}

class _ScorePainter extends CustomPainter {
  final double value;
  final Color color;
  const _ScorePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Track
    canvas.drawCircle(c, r, paint..color = AppColors.surface2);
    // Arc
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ScorePainter old) => old.value != value;
}
