import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../models/app_models.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo fade + scale
  late AnimationController _logoCtrl;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // Pulse ring
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  // Tagline fade
  late AnimationController _tagCtrl;
  late Animation<double> _tagFade;
  late Animation<Offset> _tagSlide;

  // Background orbs
  late AnimationController _orbCtrl;

  // Exit fade
  late AnimationController _exitCtrl;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // ── Logo ──────────────────────────────────────────────
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );

    // ── Pulse ─────────────────────────────────────────────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    // ── Tagline ───────────────────────────────────────────
    _tagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _tagFade = CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut);
    _tagSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut));

    // ── Background orbs ───────────────────────────────────
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // ── Exit overlay ──────────────────────────────────────
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Short delay then show logo
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();

    // Start pulse after logo appears
    await Future.delayed(const Duration(milliseconds: 400));
    _pulseCtrl.repeat();

    // Tagline slides in
    await Future.delayed(const Duration(milliseconds: 600));
    _tagCtrl.forward();

    // Hold for 3s total visibility, then exit
    await Future.delayed(const Duration(milliseconds: 2000));
    _pulseCtrl.stop();
    _exitCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    _tagCtrl.dispose();
    _orbCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate-900
      body: AnimatedBuilder(
        animation: Listenable.merge(
            [_logoCtrl, _pulseCtrl, _tagCtrl, _orbCtrl, _exitCtrl]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Background ambient orbs ──────────────────
              _buildOrbLayer(),

              // ── Grid overlay ─────────────────────────────
              CustomPaint(painter: _GridPainter()),

              // ── Center content ───────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulse ring + Logo
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse ring
                          if (_pulseCtrl.isAnimating || _pulseCtrl.value > 0)
                            Opacity(
                              opacity: _pulseOpacity.value.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: _pulseScale.value,
                                child: Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF00E5A0),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Logo circle
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: _LogoBadge(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App name
                    FadeTransition(
                      opacity: _logoFade,
                      child: Text(
                        'PhishAware',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    SlideTransition(
                      position: _tagSlide,
                      child: FadeTransition(
                        opacity: _tagFade,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 1,
                              color: const Color(0xFF00E5A0).withAlpha(120),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Segurança. Educação. Proteção.',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 24,
                              height: 1,
                              color: const Color(0xFF00E5A0).withAlpha(120),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom loading bar ────────────────────────
              FadeTransition(
                opacity: _tagFade,
                child: Positioned(
                  bottom: 56,
                  left: 48,
                  right: 48,
                  child: _LoadingBar(),
                ),
              ),

              // ── Exit fade overlay ─────────────────────────
              if (_exitCtrl.value > 0)
                Opacity(
                  opacity: _exitFade.value,
                  child: Container(color: const Color(0xFF0F172A)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrbLayer() {
    final t = _orbCtrl.value;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Teal orb top-right
        Positioned(
          top: -60 + (t * 20),
          right: -60 + (t * 10),
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00E5A0).withAlpha(35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Blue orb bottom-left
        Positioned(
          bottom: -80 + (t * 15),
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF3B82F6).withAlpha(28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Logo Badge ──────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00E5A0), Color(0xFF0EA5E9)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5A0).withAlpha(70),
            blurRadius: 32,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: const Color(0xFF0EA5E9).withAlpha(50),
            blurRadius: 20,
            spreadRadius: -8,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.shield_outlined,
          color: Colors.black,
          size: 40,
        ),
      ),
    );
  }
}

// ── Loading Bar ─────────────────────────────────────────────────────────────

class _LoadingBar extends StatefulWidget {
  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              widthFactor: _progress.value,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5A0), Color(0xFF0EA5E9)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5A0).withAlpha(80),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A carregar…',
            style: GoogleFonts.dmSans(
              color: const Color(0xFF475569),
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid Painter ─────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(7)
      ..strokeWidth = 0.5;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
