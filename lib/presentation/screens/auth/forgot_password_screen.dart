// lib/presentation/screens/auth/forgot_password_screen.dart
// ─────────────────────────────────────────────────────────────────
// Recuperación de contraseña con dos estados:
//   1. Formulario con campo de email
//   2. Confirmación con instrucciones de revisión
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import 'login_screen.dart' show AuthField;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(_emailCtrl.text);

    if (ok && mounted) {
      setState(() => _sent = true);
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Error al enviar el correo'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 16),
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _sent ? _SuccessView(email: _emailCtrl.text) : _FormView(
                emailCtrl: _emailCtrl,
                formKey: _formKey,
                onSend: _sendReset,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Vista del formulario ─────────────────────────────────────
class _FormView extends StatelessWidget {
  final TextEditingController emailCtrl;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSend;
  const _FormView({required this.emailCtrl, required this.formKey, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Ícono
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: AppColors.accentBlue.withOpacity(0.3), width: 0.5),
            ),
            child: const Center(
              child: Text('🔑', style: TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Recuperar contraseña', style: AppTextStyles.displayMedium),
          const SizedBox(height: 8),
          Text(
            'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
            style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
          ),
          const SizedBox(height: 32),
          AuthField(
            controller: emailCtrl,
            label: 'Correo electrónico',
            hint: 'tu@correo.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
              if (!RegExp(r'^[\w.]+@[\w]+\.\w+$').hasMatch(v.trim())) {
                return 'Formato inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          Consumer<AuthProvider>(
            builder: (_, auth, __) => GestureDetector(
              onTap: auth.isLoading ? null : onSend,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: auth.isLoading ? null : AppColors.primaryGradient,
                  color: auth.isLoading ? AppColors.surface : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: auth.isLoading
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Center(
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: AppColors.primary,
                          ),
                        )
                      : const Text(
                          'Enviar enlace',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.background,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vista de confirmación ─────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        // Ícono animado
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 24,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: const Center(
                child: Text('✉️', style: TextStyle(fontSize: 40)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text('¡Revisa tu correo!', style: AppTextStyles.displayMedium),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
            children: [
              const TextSpan(text: 'Enviamos un enlace de recuperación a '),
              TextSpan(
                text: email,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(
                  text: '. Si no lo ves en bandeja de entrada, revisa la carpeta de spam.'),
            ],
          ),
        ),
        const SizedBox(height: 36),
        // Pasos de ayuda
        _StepHint(step: '1', text: 'Abre el correo de Mega Vital'),
        const SizedBox(height: 10),
        _StepHint(step: '2', text: 'Toca el enlace "Restablecer contraseña"'),
        const SizedBox(height: 10),
        _StepHint(step: '3', text: 'Elige tu nueva contraseña'),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Center(
              child: Text(
                'Volver al inicio de sesión',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepHint extends StatelessWidget {
  final String step, text;
  const _StepHint({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryGlow,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 0.5),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(text, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}
