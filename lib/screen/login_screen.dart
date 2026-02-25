import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_models.dart';
import 'api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Validações ─────────────────────────────────────────────────────────────
  String? _validateEmail(String email) {
    if (email.isEmpty) return 'O email é obrigatório.';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email))
      return 'Introduz um email válido (ex: nome@email.com).';
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return 'A senha é obrigatória.';
    if (password.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
    return null;
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Validação local antes de chamar o servidor
    final emailError = _validateEmail(email);
    final passwordError = _validatePassword(password);

    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }
    if (passwordError != null) {
      setState(() => _error = passwordError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        UserSession.setFromLogin(data);
        ApiService.currentUserId = UserSession.userId;
        if (mounted) Navigator.pushReplacementNamed(context, Routes.dashboard);
      } else {
        // Servidor respondeu com erro (401, 400, etc.)
        setState(() {
          _error = data['detail'] ?? 'Email ou senha incorretos.';
          _loading = false;
        });
      }
    } on http.ClientException {
      setState(() {
        _error =
            'Sem ligação ao servidor. Verifica se o backend está a correr.';
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Erro inesperado. Tenta novamente.';
        _loading = false;
      });
    }
  }

  Future<void> _loginAsGuest() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) Navigator.pushReplacementNamed(context, Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  // ── Logo ───────────────────────────────────────────────────
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.accent.withAlpha(80),
                            blurRadius: 32,
                            spreadRadius: -4)
                      ],
                    ),
                    child: const Center(
                        child: Text('🛡️', style: TextStyle(fontSize: 40))),
                  ),
                  const SizedBox(height: 24),
                  Text('PhishAware',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                  const SizedBox(height: 8),
                  Text('A tua defesa contra phishing',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textMuted)),
                  const SizedBox(height: 40),

                  // ── Campos ─────────────────────────────────────────────────
                  _Field(
                    controller: _emailCtrl,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    controller: _passwordCtrl,
                    hint: 'Senha',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    onChanged: (_) => setState(() => _error = null),
                    suffix: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                          size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),

                  // ── Esqueceste a senha ──────────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.forgotPassword),
                      child: Text('Esqueceste a senha?',
                          style: GoogleFonts.inter(
                              color: AppColors.accent, fontSize: 12)),
                    ),
                  ),

                  // ── Erro ───────────────────────────────────────────────────
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.danger.withAlpha(60)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: GoogleFonts.inter(
                                    color: AppColors.danger, fontSize: 12))),
                      ]),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Botão Entrar ────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : Text('Entrar',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Links Criar Conta / Convidado ───────────────────────────
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.register),
                      child: Text('Criar Conta',
                          style: GoogleFonts.inter(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                    Text('·',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted, fontSize: 14)),
                    TextButton(
                      onPressed: _loading ? null : _loginAsGuest,
                      child: Text('Entrar como Convidado',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted, fontSize: 13)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Campo de texto reutilizável ───────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
