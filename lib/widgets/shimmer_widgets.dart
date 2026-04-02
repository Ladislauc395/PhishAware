import 'package:flutter/material.dart';

/// Efeito de Shimmer (esqueleto de carregamento) sem dependências externas.
///
/// Uso simples:
///   ShimmerBox(width: double.infinity, height: 80)
///
/// Uso avançado (layout completo):
///   ShimmerWrapper(
///     child: Column(children: [
///       ShimmerBox(width: double.infinity, height: 120, radius: 20),
///       SizedBox(height: 12),
///       ShimmerBox(width: 200, height: 16),
///     ]),
///   )
class ShimmerWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
    this.baseColor = const Color(0xFF1A2030),
    this.highlightColor = const Color(0xFF2A3550),
  });

  @override
  State<ShimmerWrapper> createState() => _ShimmerWrapperState();
}

class _ShimmerWrapperState extends State<ShimmerWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
            stops: [
              (_anim.value - 0.5).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.5).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: widget.child,
        );
      },
    );
  }
}

/// Bloco rectangular shimmer — substitui qualquer elemento enquanto carrega.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
    this.color = const Color(0xFF1A2030),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Shimmer circular — para avatares e ícones.
class ShimmerCircle extends StatelessWidget {
  final double size;
  final Color color;

  const ShimmerCircle({
    super.key,
    required this.size,
    this.color = const Color(0xFF1A2030),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── Layouts de Shimmer prontos a usar ──────────────────────────────────────

/// Esqueleto do Dashboard (Ring + XP + activity).
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(width: 120, height: 20),
                    const SizedBox(height: 6),
                    const ShimmerBox(width: 160, height: 14),
                  ],
                ),
                const ShimmerCircle(size: 40),
              ],
            ),
            const SizedBox(height: 32),
            // Ring card
            const ShimmerBox(width: double.infinity, height: 300, radius: 28),
            const SizedBox(height: 28),
            // XP bar
            const ShimmerBox(width: double.infinity, height: 72, radius: 20),
            const SizedBox(height: 28),
            // Quick actions
            Row(
              children: [
                const Expanded(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: 80,
                    radius: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: 80,
                    radius: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: 80,
                    radius: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: 80,
                    radius: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Activity list
            const ShimmerBox(width: 160, height: 18),
            const SizedBox(height: 12),
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: const [
                    ShimmerCircle(size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: ShimmerBox(
                        width: double.infinity,
                        height: 36,
                        radius: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryShimmer extends StatelessWidget {
  final int count;
  const HistoryShimmer({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: count,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: const [
              ShimmerBox(width: 40, height: 40, radius: 10),
              SizedBox(width: 12),
              Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  height: 56,
                  radius: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
