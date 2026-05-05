import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/dynamic_colors.dart';

class ContactAdminScreen extends StatelessWidget {
  const ContactAdminScreen({super.key});

  Future<void> _openWhatsApp(BuildContext context) async {
    const message =
        'Hola quiero ser usuario de la aplicacion mega vital, aun no he ido al gimnasio fisico';
    final uri = Uri.parse(
        'https://wa.me/${AppConfig.ownerWhatsApp}?text=${Uri.encodeComponent(message)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.ownerEmail,
      queryParameters: {
        'subject': 'Quiero ser usuario de Mega Vital',
        'body':
            'Hola quiero ser usuario de la aplicacion mega vital, aun no he ido al gimnasio fisico',
      },
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el correo.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
      final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Icono
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),

              Text('¿Quieres unirte\na Mega Vital?',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: c.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(height: 14),

              Text(
                'Contáctanos y te explicamos todo sobre nuestros planes, horarios y cómo comenzar.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 40),

              // Botón WhatsApp
              _ContactButton(
                icon: Icons.chat_rounded,
                label: 'Escribir por WhatsApp',
                subtitle: 'Respuesta rápida',
                color: const Color(0xFF25D366),
                onTap: () => _openWhatsApp(context),
              ),
              const SizedBox(height: 14),

              // Botón Gmail
              _ContactButton(
                icon: Icons.email_rounded,
                label: 'Enviar un correo',
                subtitle: AppConfig.ownerEmail,
                color: AppColors.accentOrange,
                onTap: () => _openEmail(context),
              ),

              const Spacer(),

              Center(
                child: Text(
                  'Una vez inscrito recibirás tu código\nde acceso a la app.',
                  style: AppTextStyles.caption
                      .copyWith(color: c.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
      final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: c.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
