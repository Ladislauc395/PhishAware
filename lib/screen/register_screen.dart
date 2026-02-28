import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_models.dart';
import 'api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Preenche todos os campos.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.register(name, email, password);
      if (data.containsKey('detail')) {
        setState(() {
          _error = data['detail'];
          _loading = false;
        });
        return;
      }
      UserSession.setFromLogin(data);
      ApiService.currentUserId = UserSession.userId;
      if (mounted) Navigator.pushReplacementNamed(context, Routes.dashboard);
    } catch (_) {
      setState(() {
        _error = 'Erro ao conectar ao servidor.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(height: 32),
              Text('Criar Conta',
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Junta-te à comunidade PhishAware',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 14)),
              const SizedBox(height: 36),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.blue]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.accent.withAlpha(60), blurRadius: 20)
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _nameCtrl.text.isEmpty
                          ? '?'
                          : _nameCtrl.text[0].toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _Label('Nome completo'),
              const SizedBox(height: 8),
              _Field(
                controller: _nameCtrl,
                hint: 'Ex: João Silva',
                icon: Icons.person_outline,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _Label('Email'),
              const SizedBox(height: 8),
              _Field(
                controller: _emailCtrl,
                hint: 'teu@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _Label('Senha'),
              const SizedBox(height: 8),
              _Field(
                controller: _passwordCtrl,
                hint: 'Mínimo 6 caracteres',
                icon: Icons.lock_outline,
                obscure: _obscure1,
                suffix: IconButton(
                  icon: Icon(
                      _obscure1 ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textMuted,
                      size: 20),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                ),
              ),
              const SizedBox(height: 16),
              _Label('Confirmar Senha'),
              const SizedBox(height: 8),
              _Field(
                controller: _confirmCtrl,
                hint: 'Repete a senha',
                icon: Icons.lock_outline,
                obscure: _obscure2,
                suffix: IconButton(
                  icon: Icon(
                      _obscure2 ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textMuted,
                      size: 20),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withAlpha(60)),
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
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
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
                      : Text('Criar Conta',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 13),
                      children: [
                        TextSpan(
                            text: 'Já tens conta? ',
                            style: TextStyle(color: AppColors.textMuted)),
                        TextSpan(
                            text: 'Entrar',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600));
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  const _Field(
      {required this.controller,
      required this.hint,
      required this.icon,
      this.keyboardType,
      this.obscure = false,
      this.suffix,
      this.onChanged});

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
