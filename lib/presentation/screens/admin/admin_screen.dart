import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/shared_widgets.dart';
import '../auth/login_screen.dart' show AuthField;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const _adminPass = 'cocodemegavital';

  bool _authenticated = false;
  bool _sending = false;
  String? _generatedCode;

  final _passCtrl   = TextEditingController();
  final _memberCtrl = TextEditingController();
  bool _obscurePass = true;
  String? _passError;

  @override
  void dispose() {
    _passCtrl.dispose();
    _memberCtrl.dispose();
    super.dispose();
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _createCode() async {
    final member = _memberCtrl.text.trim();
    if (member.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar('Ingresa el nombre del miembro', isError: true),
      );
      return;
    }

    setState(() {
      _sending = true;
      _generatedCode = null;
    });

    final code = _generateCode();

    await _sendWhatsApp(member: member, code: code);

    if (mounted) {
      setState(() {
        _generatedCode = code;
        _sending = false;
      });
    }
  }

  Future<void> _sendWhatsApp({required String member, required String code}) async {
    final text = Uri.encodeComponent(
      '🏋️ *Mega Vital — Código Premium*\n\n'
      'Se está generando un código de acceso premium:\n\n'
      '👤 Usuario: *$member*\n'
      '🔑 Código: *$code*\n\n'
      '_(Generado desde la app el ${_formattedDate()})_',
    );
    final uri = Uri.parse('https://wa.me/${AppConfig.ownerWhatsApp}?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formattedDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  SnackBar _snackBar(String msg, {bool isError = false}) => SnackBar(
    content: Text(msg, style: AppTextStyles.bodyMedium),
    backgroundColor: isError ? AppColors.surface : AppColors.surface,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary, size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Administración', style: AppTextStyles.displayMedium),
                      Text('Panel exclusivo del administrador',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _authenticated
                    ? _AdminPanel(
                        memberCtrl: _memberCtrl,
                        generatedCode: _generatedCode,
                        sending: _sending,
                        onCreateCode: _createCode,
                      )
                    : _AuthGate(
                        passCtrl: _passCtrl,
                        obscure: _obscurePass,
                        error: _passError,
                        onToggle: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        onVerify: () {
                          if (_passCtrl.text.trim() == _adminPass) {
                            setState(() {
                              _authenticated = true;
                              _passError = null;
                            });
                          } else {
                            setState(
                                () => _passError = 'Contraseña incorrecta');
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Gate de contraseña ────────────────────────────────────────────
class _AuthGate extends StatelessWidget {
  final TextEditingController passCtrl;
  final bool obscure;
  final String? error;
  final VoidCallback onToggle;
  final VoidCallback onVerify;

  const _AuthGate({
    required this.passCtrl,
    required this.obscure,
    required this.error,
    required this.onToggle,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DarkCard(
            borderColor: AppColors.accentOrange.withOpacity(0.3),
            child: Row(children: [
              Icon(Icons.admin_panel_settings_outlined,
                  color: AppColors.accentOrange, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Solo el administrador del gimnasio puede acceder a este panel.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.accentOrange),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          AuthField(
            controller: passCtrl,
            label: 'Contraseña de administrador',
            hint: '••••••••••••',
            icon: Icons.shield_outlined,
            obscureText: obscure,
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
              onPressed: onToggle,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 15),
              const SizedBox(width: 6),
              Text(error!,
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 12)),
            ]),
          ],
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onVerify,
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
              child: Center(
                child: Text('Verificar',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.background)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Panel de admin ────────────────────────────────────────────────
class _AdminPanel extends StatelessWidget {
  final TextEditingController memberCtrl;
  final String? generatedCode;
  final bool sending;
  final VoidCallback onCreateCode;

  const _AdminPanel({
    required this.memberCtrl,
    required this.generatedCode,
    required this.sending,
    required this.onCreateCode,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección: Código Premium
          DarkCard(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0F2E), Color(0xFF10081A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderColor: AppColors.accentPurple.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  BoxedIcon(
                    icon: Icons.workspace_premium_rounded,
                    color: AppColors.accentPurple,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Código de acceso premium',
                            style: AppTextStyles.headingSmall),
                        Text('Se notificará al dueño por WhatsApp',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.accentPurple)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                // Campo: nombre del miembro
                TextField(
                  controller: memberCtrl,
                  style: AppTextStyles.bodyLarge,
                  cursorColor: AppColors.accentPurple,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre del miembro',
                    hintText: 'Juan García',
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: AppColors.textMuted, size: 20),
                    labelStyle: AppTextStyles.bodyMedium,
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.border, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.border, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: AppColors.accentPurple, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                // Botón generar
                GestureDetector(
                  onTap: sending ? null : onCreateCode,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: sending
                          ? null
                          : const LinearGradient(
                              colors: [
                                Color(0xFF7B2FBE),
                                Color(0xFF5A1A9A),
                              ],
                            ),
                      color: sending ? AppColors.surface : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: sending
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.accentPurple,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.generating_tokens_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Generar código y notificar',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Resultado: código generado
          if (generatedCode != null) ...[
            const SizedBox(height: 16),
            DarkCard(
              borderColor: AppColors.primary.withOpacity(0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Código generado',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Text(
                          generatedCode!,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 6,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: generatedCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Código copiado',
                                  style: AppTextStyles.bodyMedium),
                              backgroundColor: AppColors.surface,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        child: const Icon(Icons.copy_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.whatsapp, color: AppColors.primary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Notificación enviada al dueño por WhatsApp',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ]),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
