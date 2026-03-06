import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../models/app_models.dart';
import 'api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;
  bool _loading = false;
  String? _error;

  late AnimationController _enterCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _avatarCtrl;

  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _avatarScale;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _avatarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _avatarScale =
        CurvedAnimation(parent: _avatarCtrl, curve: Curves.easeOutBack);

    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _enterCtrl.dispose();
    _orbCtrl.dispose();
    _shakeCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    setState(() {});
    if (value.length == 1) _avatarCtrl.forward();
    if (value.isEmpty) _avatarCtrl.reverse();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _triggerError('Preenche todos os campos.');
      return;
    }
    if (password != confirm) {
      _triggerError('As senhas não coincidem.');
      return;
    }
    if (password.length < 6) {
      _triggerError('A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.register(name, email, password);
      if (data.containsKey('detail')) {
        _triggerError(data['detail'] ?? 'Erro no registo.');
        return;
      }
      UserSession.setFromLogin(data);
      ApiService.currentUserId = UserSession.userId;
      if (mounted) Navigator.pushReplacementNamed(context, Routes.dashboard);
    } catch (_) {
      _triggerError('Erro ao conectar ao servidor.');
    }
  }

  void _triggerError(String msg) {
    setState(() {
      _error = msg;
      _loading = false;
    });
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation:
            Listenable.merge([_enterCtrl, _orbCtrl, _shakeCtrl, _avatarCtrl]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(size),
              CustomPaint(painter: _GridPainter()),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      FadeTransition(
                        opacity: _cardFade,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withAlpha(10),
                              border:
                                  Border.all(color: Colors.white.withAlpha(22)),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Header
                      FadeTransition(
                        opacity: _cardFade,
                        child: _buildHeader(),
                      ),

                      const SizedBox(height: 28),

                      // Avatar preview
                      FadeTransition(
                        opacity: _cardFade,
                        child: Center(child: _buildAvatar()),
                      ),

                      const SizedBox(height: 28),

                      // Form card
                      SlideTransition(
                        position: _cardSlide,
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: _buildFormCard(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      FadeTransition(
                        opacity: _cardFade,
                        child: _buildLoginLink(),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(Size size) {
    final t = _orbCtrl.value;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -60 + (t * 25),
          right: -50 + (t * 15),
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF00E5A0).withAlpha(38),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -80 + (t * 20),
          left: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF3B82F6).withAlpha(30),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: const Color(0xFF00E5A0).withAlpha(15),
            border: Border.all(color: const Color(0xFF00E5A0).withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00E5A0), Color(0xFF0EA5E9)],
                  ),
                ),
                child: const Icon(Icons.shield, color: Colors.black, size: 12),
              ),
              const SizedBox(width: 8),
              Text(
                'PhishAware',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF00E5A0),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Criar\nconta.',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Junta-te à comunidade PhishAware.',
          style: GoogleFonts.dmSans(
            color: const Color(0xFF64748B),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final initial =
        _nameCtrl.text.isEmpty ? '?' : _nameCtrl.text.trim()[0].toUpperCase();
    final hasName = _nameCtrl.text.isNotEmpty;

    return ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.0).animate(_avatarScale),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasName
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00E5A0), Color(0xFF0EA5E9)],
                )
              : null,
          color: hasName ? null : Colors.white.withAlpha(10),
          border: Border.all(
            color: hasName ? Colors.transparent : Colors.white.withAlpha(22),
          ),
          boxShadow: hasName
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5A0).withAlpha(60),
                    blurRadius: 24,
                    spreadRadius: -4,
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            initial,
            style: GoogleFonts.dmSans(
              color: hasName ? Colors.black : const Color(0xFF475569),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    final shakeOffset = _shakeCtrl.isAnimating
        ? math.sin(_shakeCtrl.value * math.pi * 4) * 8.0
        : 0.0;

    return Transform.translate(
      offset: Offset(shakeOffset, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xFF1E293B).withAlpha(180),
              border: Border.all(color: Colors.white.withAlpha(22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RegisterGlassField(
                  controller: _nameCtrl,
                  label: 'Nome completo',
                  hint: 'Ex: João Silva',
                  icon: Icons.person_outline_rounded,
                  onChanged: _onNameChanged,
                ),
                const SizedBox(height: 16),
                _RegisterGlassField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'teu@email.com',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _RegisterGlassField(
                  controller: _passwordCtrl,
                  label: 'Senha',
                  hint: 'Mínimo 6 caracteres',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure1,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure1 = !_obscure1),
                    child: Icon(
                      _obscure1
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF475569),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _RegisterGlassField(
                  controller: _confirmCtrl,
                  label: 'Confirmar senha',
                  hint: 'Repete a senha',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure2,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure2 = !_obscure2),
                    child: Icon(
                      _obscure2
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF475569),
                      size: 18,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _ErrorBanner(message: _error!),
                ],
                const SizedBox(height: 20),
                _GradientButton(
                  label: 'Criar conta',
                  loading: _loading,
                  onTap: _loading ? null : _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.dmSans(fontSize: 14),
            children: const [
              TextSpan(
                text: 'Já tens conta? ',
                style: TextStyle(color: Color(0xFF475569)),
              ),
              TextSpan(
                text: 'Entrar →',
                style: TextStyle(
                  color: Color(0xFF00E5A0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared Glass Field ───────────────────────────────────────────────────────

class _RegisterGlassField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  const _RegisterGlassField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.onChanged,
  });

  @override
  State<_RegisterGlassField> createState() => _RegisterGlassFieldState();
}

class _RegisterGlassFieldState extends State<_RegisterGlassField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    const focusColor = Color(0xFF00E5A0);
    final borderColor = _focused ? focusColor : Colors.white.withAlpha(20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.dmSans(
            color: _focused ? focusColor : const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          child: Text(widget.label.toUpperCase()),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withAlpha(_focused ? 12 : 7),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: focusColor.withAlpha(25),
                      blurRadius: 16,
                      spreadRadius: -2,
                    )
                  ]
                : [],
          ),
          child: Focus(
            onFocusChange: (f) => setState(() => _focused = f),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GoogleFonts.dmSans(
                  color: const Color(0xFF334155),
                  fontSize: 15,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 10),
                  child: Icon(
                    widget.icon,
                    color: _focused ? focusColor : const Color(0xFF475569),
                    size: 18,
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 48, minHeight: 48),
                suffixIcon: widget.suffix != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: widget.suffix,
                      )
                    : null,
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 40, minHeight: 48),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared Gradient Button ────────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    required this.loading,
    this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.loading
                ? [
                    const Color(0xFF00E5A0).withAlpha(120),
                    const Color(0xFF0EA5E9).withAlpha(120),
                  ]
                : [
                    const Color(0xFF00E5A0),
                    const Color(0xFF0EA5E9),
                  ],
          ),
          boxShadow: widget.loading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF00E5A0).withAlpha(80),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
        ),
        child: Center(
          child: widget.loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.dmSans(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.black, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Error Banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFEF4444).withAlpha(18),
        border: Border.all(color: const Color(0xFFEF4444).withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                color: const Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
      ..color = Colors.white.withAlpha(6)
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
