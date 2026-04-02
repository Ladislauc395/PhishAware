import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double sigmaX;
  final double sigmaY;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.sigmaX = 12,
    this.sigmaY = 12,
    this.borderColor,
    this.gradientColors,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(borderRadius);

    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: br,
              border: Border.all(
                color: borderColor ?? Colors.white.withAlpha(18),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    gradientColors ??
                    [Colors.white.withAlpha(14), Colors.white.withAlpha(4)],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Versão colorida do GlassCard — ideal para cartões de estatísticas com cor de destaque.
class GlassAccentCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassAccentCard({
    super.key,
    required this.child,
    required this.accentColor,
    this.borderRadius = 20,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: borderRadius,
      padding: padding,
      borderColor: accentColor.withAlpha(50),
      gradientColors: [accentColor.withAlpha(18), accentColor.withAlpha(5)],
      shadows: [
        BoxShadow(
          color: accentColor.withAlpha(30),
          blurRadius: 28,
          spreadRadius: -6,
          offset: const Offset(0, 6),
        ),
      ],
      child: child,
    );
  }
}
