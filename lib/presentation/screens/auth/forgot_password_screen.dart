// lib/presentation/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Ícono
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.accentOrange.withOpacity(0.3),
                      width: 0.5),
                ),
                child: const Center(
                  child: Text('🔐', style: TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(height: 24),

              Text('¿Olvidaste tu contraseña?',
                  style: AppTextStyles.displayMedium),
              const SizedBox(height: 12),
              Text(
                'Como el acceso es por nombre de usuario, el restablecimiento de contraseña lo gestiona el administrador del gimnasio.',
                style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
              ),
              const SizedBox(height: 32),

              // Pasos
              _StepHint(
                step: '1',
                text: 'Acércate al gimnasio o contacta al administrador',
              ),
              const SizedBox(height: 12),
              _StepHint(
                step: '2',
                text: 'El administrador restablecerá tu contraseña',
              ),
              const SizedBox(height: 12),
              _StepHint(
                step: '3',
                text: 'Ingresa con tu usuario y la nueva contraseña',
              ),
              const SizedBox(height: 40),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Volver al inicio de sesión',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.background,
                      ),
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
            border: Border.all(
                color: AppColors.primary.withOpacity(0.4), width: 0.5),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ],
    );
  }
}
