import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import 'api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false, _obscure1 = true, _obscure2 = true;
  String? _error;

  final List<TextEditingController> _digitCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    for (final c in _digitCtrl) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _digitCtrl.map((c) => c.text).join();

  Future<void> _sendCode() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Introduz o teu email.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService.forgotPassword(_emailCtrl.text.trim());
      setState(() {
        _step = 1;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Erro ao enviar código.';
        _loading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_otp.length < 6) {
      setState(() => _error = 'Introduz o código de 6 dígitos.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.verifyCode(_emailCtrl.text.trim(), _otp);
      if (res['ok'] == true) {
        setState(() {
          _step = 2;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Código inválido ou expirado.';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Código inválido ou expirado.';
        _loading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'A senha deve ter pelo menos 6 caracteres.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.resetPassword(
          _emailCtrl.text.trim(), _otp, _passwordCtrl.text);
      if (res['ok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Senha redefinida com sucesso!',
                  style: GoogleFonts.inter(color: Colors.black)),
              backgroundColor: AppColors.accent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacementNamed(context, Routes.login);
        }
      } else {
        setState(() {
          _error = res['detail'] ?? 'Erro ao redefinir senha.';
          _loading = false;
        });
      }
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _step > 0
                        ? () => setState(() {
                              _step--;
                              _error = null;
                            })
                        : () => Navigator.pop(context),
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
                  Row(
                    children: List.generate(
                        3,
                        (i) => Expanded(
                              child: Container(
                                height: 3,
                                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                                decoration: BoxDecoration(
                                  color: i <= _step
                                      ? AppColors.accent
                                      : AppColors.surface2,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            )),
                  ),
                  const SizedBox(height: 28),
                  if (_step == 0)
                    _StepEmail(
                      emailCtrl: _emailCtrl,
                      loading: _loading,
                      error: _error,
                      onSend: _sendCode,
                    ),
                  if (_step == 1)
                    _StepCode(
                      email: _emailCtrl.text.trim(),
                      digitCtrl: _digitCtrl,
                      focusNodes: _focusNodes,
                      loading: _loading,
                      error: _error,
                      onVerify: _verifyCode,
                      onResend: () {
                        setState(() => _step = 0);
                        _sendCode();
                      },
                    ),
                  if (_step == 2)
                    _StepNewPassword(
                      passwordCtrl: _passwordCtrl,
                      confirmCtrl: _confirmCtrl,
                      obscure1: _obscure1,
                      obscure2: _obscure2,
                      toggleObscure1: () =>
                          setState(() => _obscure1 = !_obscure1),
                      toggleObscure2: () =>
                          setState(() => _obscure2 = !_obscure2),
                      loading: _loading,
                      error: _error,
                      onReset: _resetPassword,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepEmail extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSend;

  const _StepEmail({
    required this.emailCtrl,
    required this.loading,
    this.error,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🔐', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text('Recuperar Senha',
          style: GoogleFonts.spaceGrotesk(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Vamos enviar um código de 6 dígitos para o teu email.',
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
      const SizedBox(height: 36),
      Text('Email',
          style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _buildField(emailCtrl, 'teu@email.com', Icons.email_outlined,
          keyboardType: TextInputType.emailAddress),
      if (error != null) ...[
        const SizedBox(height: 12),
        _ErrorBox(error!),
      ],
      const SizedBox(height: 32),
      _PrimaryBtn('Enviar Código', loading, onSend),
    ]);
  }
}

class _StepCode extends StatelessWidget {
  final String email;
  final List<TextEditingController> digitCtrl;
  final List<FocusNode> focusNodes;
  final bool loading;
  final String? error;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  const _StepCode({
    required this.email,
    required this.digitCtrl,
    required this.focusNodes,
    required this.loading,
    this.error,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('📧', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text('Verifica o Email',
          style: GoogleFonts.spaceGrotesk(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      RichText(
          text: TextSpan(style: GoogleFonts.inter(fontSize: 14), children: [
        TextSpan(
            text: 'Enviámos um código para ',
            style: const TextStyle(color: AppColors.textMuted)),
        TextSpan(
            text: email,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ])),
      const SizedBox(height: 36),
      Text('Código de 6 Dígitos',
          style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
            6,
            (i) => SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: digitCtrl[i],
                    focusNode: focusNodes[i],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.accent, width: 2)),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 5) {
                        focusNodes[i + 1].requestFocus();
                      } else if (val.isEmpty && i > 0) {
                        focusNodes[i - 1].requestFocus();
                      }
                    },
                  ),
                )),
      ),
      const SizedBox(height: 16),
      Center(
        child: TextButton(
          onPressed: onResend,
          child: Text('Não recebeste? Reenviar código',
              style: GoogleFonts.inter(color: AppColors.accent, fontSize: 13)),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 8),
        _ErrorBox(error!),
      ],
      const SizedBox(height: 32),
      _PrimaryBtn('Verificar Código', loading, onVerify),
    ]);
  }
}

class _StepNewPassword extends StatelessWidget {
  final TextEditingController passwordCtrl, confirmCtrl;
  final bool obscure1, obscure2, loading;
  final VoidCallback toggleObscure1, toggleObscure2, onReset;
  final String? error;

  const _StepNewPassword({
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscure1,
    required this.obscure2,
    required this.toggleObscure1,
    required this.toggleObscure2,
    required this.loading,
    this.error,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🔑', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text('Nova Senha',
          style: GoogleFonts.spaceGrotesk(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Escolhe uma senha segura com pelo menos 6 caracteres.',
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
      const SizedBox(height: 36),
      Text('Nova Senha',
          style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _buildField(passwordCtrl, '••••••••', Icons.lock_outline,
          obscure: obscure1,
          suffix: IconButton(
            icon: Icon(obscure1 ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textMuted, size: 20),
            onPressed: toggleObscure1,
          )),
      const SizedBox(height: 16),
      Text('Confirmar Senha',
          style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _buildField(confirmCtrl, '••••••••', Icons.lock_outline,
          obscure: obscure2,
          suffix: IconButton(
            icon: Icon(obscure2 ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textMuted, size: 20),
            onPressed: toggleObscure2,
          )),
      if (error != null) ...[
        const SizedBox(height: 12),
        _ErrorBox(error!),
      ],
      const SizedBox(height: 32),
      _PrimaryBtn('Redefinir Senha', loading, onReset),
    ]);
  }
}

Widget _buildField(
  TextEditingController ctrl,
  String hint,
  IconData icon, {
  bool obscure = false,
  Widget? suffix,
  TextInputType? keyboardType,
}) {
  final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border));
  return TextField(
    controller: ctrl,
    obscureText: obscure,
    keyboardType: keyboardType,
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
          borderSide: const BorderSide(color: AppColors.accent)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.danger.withAlpha(60)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(
                      color: AppColors.danger, fontSize: 12))),
        ]),
      );
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _PrimaryBtn(this.label, this.loading, this.onTap);
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : Text(label,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );
}
