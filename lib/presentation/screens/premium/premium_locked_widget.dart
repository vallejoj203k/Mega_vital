// lib/presentation/screens/premium/premium_locked_widget.dart
// Widget que reemplaza la pantalla cuando el usuario no tiene acceso premium.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/premium_provider.dart';

class PremiumLockedWidget extends StatefulWidget {
  final String sectionName;
  final IconData sectionIcon;

  const PremiumLockedWidget({
    super.key,
    required this.sectionName,
    required this.sectionIcon,
  });

  @override
  State<PremiumLockedWidget> createState() => _PremiumLockedWidgetState();
}

class _PremiumLockedWidgetState extends State<PremiumLockedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _showRedeemDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _RedeemDialog(ctrl: ctrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono con glow animado
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentOrange.withOpacity(0.12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentOrange.withOpacity(0.3 * _pulseAnim.value),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(widget.sectionIcon,
                              size: 44, color: AppColors.accentOrange.withOpacity(0.4)),
                          const Positioned(
                            right: 16,
                            bottom: 16,
                            child: Icon(Icons.lock_rounded,
                                size: 28, color: AppColors.accentOrange),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Badge "PREMIUM"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB020), Color(0xFFFF6B35)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  widget.sectionName,
                  style: AppTextStyles.displayMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accentOrange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.accentOrange,
                        size: 22,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Para acceder a este servicio tiene que activar servicio premium.\n\n'
                        'Acércate en administración para canjear el código.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Botón activar código
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => _showRedeemDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB020), Color(0xFFFF6B35)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentOrange.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.vpn_key_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Tengo un código',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Planes disponibles: mensual · trimestral · anual',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dialog para ingresar el código ───────────────────────────────
class _RedeemDialog extends StatefulWidget {
  final TextEditingController ctrl;
  const _RedeemDialog({required this.ctrl});

  @override
  State<_RedeemDialog> createState() => _RedeemDialogState();
}

class _RedeemDialogState extends State<_RedeemDialog> {
  bool _loading = false;
  String? _error;

  Future<void> _redeem(BuildContext ctx) async {
    final code = widget.ctrl.text.trim();
    if (code.isEmpty) return;

    setState(() { _loading = true; _error = null; });

    final auth    = ctx.read<AuthProvider>();
    final premium = ctx.read<PremiumProvider>();
    final userId  = auth.firebaseUser?.uid ?? auth.profile?.uid ?? '';
    final created = auth.profile?.createdAt ?? DateTime.now();

    final result = await premium.redeemCode(code, userId, created);

    if (!mounted) return;

    if (result.success) {
      Navigator.of(ctx).pop();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            '¡Premium activado! Vence el ${_formatDate(result.expiresAt)}',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      setState(() { _loading = false; _error = result.message; });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.vpn_key_rounded, color: AppColors.accentOrange, size: 22),
          const SizedBox(width: 10),
          Text('Activar Premium', style: AppTextStyles.headingSmall),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ingresa el código que te proporcionó administración:',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.ctrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: 'MV-XXXX-XXXX',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentOrange, width: 1.5),
              ),
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: _loading ? null : () => _redeem(context),
          child: _loading
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentOrange),
                )
              : const Text(
                  'Activar',
                  style: TextStyle(
                    color: AppColors.accentOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}
