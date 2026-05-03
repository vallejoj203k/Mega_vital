// lib/presentation/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/premium_provider.dart';
import '../../../core/providers/workout_log_provider.dart';
import '../../widgets/shared_widgets.dart';
import '../../../core/config/app_config.dart';
import '../admin/admin_panel_screen.dart';
import '../api_keys/api_keys_screen.dart';
import '../edit_profile/edit_profile_screen.dart';
import '../premium/premium_locked_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar(AuthProvider auth) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (xfile == null || !mounted) return;
    setState(() => _uploadingAvatar = true);
    await auth.uploadAvatar(File(xfile.path));
    if (mounted) setState(() => _uploadingAvatar = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<AuthProvider>();
    final name = auth.profile?.name ?? auth.displayName;
    final initials = auth.userInitials;
    final avatarUrl = auth.profile?.avatarUrl;
    final goal = auth.profile?.goal ?? MockData.currentUser.goal;
    final weight = auth.profile?.weight ?? MockData.currentUser.weight;
    final height = auth.profile?.height ?? MockData.currentUser.height;
    final age = auth.profile?.age ?? MockData.currentUser.age;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20,16,20,0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Perfil', style: AppTextStyles.displayMedium),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    setState(() {}); // refresca al volver
                  },
                  child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.5)),
                    child: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20)),
                ),
              ]),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Tarjeta principal
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DarkCard(
                gradient: const LinearGradient(colors: [Color(0xFF0F2318), Color(0xFF0A1A10)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderColor: AppColors.primary.withOpacity(0.2),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => _pickAndUploadAvatar(auth),
                    child: Stack(children: [
                      _uploadingAvatar
                          ? Container(
                              width: 72, height: 72,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceVariant,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary, strokeWidth: 2),
                              ),
                            )
                          : InitialsAvatar(
                              initials: initials, size: 72, photoUrl: avatarUrl),
                      Positioned(right: 0, bottom: 0, child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2)),
                        child: const Icon(Icons.camera_alt, size: 12, color: AppColors.background)),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: AppTextStyles.headingMedium),
                    const SizedBox(height: 2),
                    Text(
                      () {
                        final e = auth.profile?.email ?? auth.firebaseUser?.email ?? '';
                        return e.isEmpty || e.startsWith('noemail_') ? 'Sin correo registrado' : e;
                      }(),
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Row(children: [const Icon(Icons.flag_outlined, size: 13, color: AppColors.textMuted), const SizedBox(width: 4), Text(goal, style: AppTextStyles.bodyMedium)]),
                    const SizedBox(height: 10),
                    _Chip(label: '${MockData.achievements.where((a) => a.unlocked).length} logros', color: AppColors.accentBlue),
                  ])),
                ]),
              ),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Medidas corporales
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: _BodyStatCard(icon: Icons.monitor_weight_outlined, label: 'Peso', value: weight.toStringAsFixed(1), unit: 'kg', color: AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(child: _BodyStatCard(icon: Icons.straighten_rounded, label: 'Altura', value: '${height.round()}', unit: 'cm', color: AppColors.accentBlue)),
                const SizedBox(width: 10),
                Expanded(child: _BodyStatCard(icon: Icons.cake_outlined, label: 'Edad', value: '$age', unit: 'años', color: AppColors.accentOrange)),
                const SizedBox(width: 10),
                Expanded(child: _BodyStatCard(icon: Icons.favorite_outline_rounded, label: 'IMC', value: _imc(weight, height), unit: '', color: AppColors.accentPurple)),
              ]),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Tarjeta de plan premium
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _PremiumCard(),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Logros
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'Logros', actionLabel: 'Ver todos', onAction: () {}))),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: SizedBox(height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: MockData.achievements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _AchievementCard(a: MockData.achievements[i]),
              ),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Estadísticas totales
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _LifetimeStats())),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Menú de configuración
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SettingsList())),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Cerrar sesión
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _LogoutButton())),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Eliminar cuenta
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DeleteAccountButton())),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  String _imc(double w, double h) {
    final hm = h / 100;
    return (w / (hm * hm)).toStringAsFixed(1);
  }
}

class _Chip extends StatelessWidget {
  final String label; final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}

class _BodyStatCard extends StatelessWidget {
  final IconData icon; final String label, value, unit; final Color color;
  const _BodyStatCard({required this.icon, required this.label, required this.value, required this.unit, required this.color});
  @override
  Widget build(BuildContext context) => DarkCard(padding: const EdgeInsets.all(12), child: Column(children: [
    Icon(icon, color: color, size: 20),
    const SizedBox(height: 6),
    Text(value, style: AppTextStyles.headingSmall.copyWith(color: color)),
    if (unit.isNotEmpty) Text(unit, style: AppTextStyles.caption),
    const SizedBox(height: 2),
    Text(label, style: AppTextStyles.caption),
  ]));
}

class _AchievementCard extends StatelessWidget {
  final AchievementModel a;
  const _AchievementCard({required this.a});
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: a.unlocked ? 1.0 : 0.35,
    child: DarkCard(
      borderColor: a.unlocked ? a.color.withOpacity(0.3) : null,
      padding: const EdgeInsets.all(14),
      child: SizedBox(width: 90, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: a.color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(a.icon, color: a.color, size: 20)),
        const SizedBox(height: 6),
        Text(a.title, style: AppTextStyles.caption.copyWith(color: a.unlocked ? AppColors.textPrimary : AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ),
  );
}

class _LifetimeStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final history = context.watch<WorkoutLogProvider>().history;
    final totalWorkouts = history.length;
    final totalMinutes  = history.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final totalHours    = (totalMinutes / 60).toStringAsFixed(1);

    final stats = [
      {'label': 'Total entrenamientos', 'value': '$totalWorkouts', 'icon': Icons.fitness_center_rounded, 'color': AppColors.primary},
      {'label': 'Horas de ejercicio',   'value': '$totalHours h',  'icon': Icons.timer_rounded,           'color': AppColors.accentBlue},
    ];
    return DarkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Estadísticas totales', style: AppTextStyles.headingSmall),
      const SizedBox(height: 14),
      ...stats.map((s) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
        BoxedIcon(icon: s['icon'] as IconData, color: s['color'] as Color, size: 36),
        const SizedBox(width: 12),
        Expanded(child: Text(s['label'] as String, style: AppTextStyles.bodyMedium)),
        Text(s['value'] as String, style: AppTextStyles.labelLarge),
      ]))),
    ]));
  }
}

class _SettingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final email = context.read<AuthProvider>().profile?.email ?? '';
    final isAdmin = AppConfig.adminEmails.contains(email.toLowerCase().trim());
    final items = [
      _SI(icon: Icons.auto_awesome_rounded, label: 'Claves de IA (análisis fotos)',
          color: AppColors.primary,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ApiKeysScreen()))),
      if (isAdmin)
        _SI(icon: Icons.admin_panel_settings_outlined, label: 'Administración',
            color: AppColors.accentPurple,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminAccessScreen()))),
    ];
    return DarkCard(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(
      children: items.map((item) => GestureDetector(
        onTap: item.onTap,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            BoxedIcon(icon: item.icon, color: item.color, size: 36),
            const SizedBox(width: 12),
            Expanded(child: Text(item.label, style: AppTextStyles.labelLarge)),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ])),
      )).toList(),
    ));
  }
}

// Simple data class — top-level so it's visible everywhere
class _SI {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  const _SI({required this.icon, required this.label,
      required this.color, required this.onTap});
}


class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('¿Cerrar sesión?', style: AppTextStyles.headingSmall),
          content: Text('¿Seguro que quieres salir de tu cuenta?', style: AppTextStyles.bodyMedium),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Salir', style: TextStyle(color: AppColors.error))),
          ],
        ));
        if ((ok ?? false) && context.mounted) await context.read<AuthProvider>().signOut();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.error.withOpacity(0.3), width: 0.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Text('Cerrar sesión', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
        ]),
      ),
    );
  }
}

class _DeleteAccountButton extends StatefulWidget {
  @override
  State<_DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<_DeleteAccountButton> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _deleting ? null : () => _confirmDelete(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.textMuted.withOpacity(0.3), width: 0.5),
        ),
        child: _deleting
            ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 8),
                Text('Eliminar cuenta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
              ]),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar cuenta', style: AppTextStyles.headingSmall.copyWith(color: AppColors.error)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Esta acción es permanente e irreversible.', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Se eliminarán:\n• Tu perfil y datos personales\n• Todas tus publicaciones y comentarios\n• Tu historial de entrenamientos y nutrición\n• Tus rutinas y retos', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (!(ok ?? false) || !mounted) return;

    setState(() => _deleting = true);
    final success = await context.read<AuthProvider>().deleteAccount();
    if (mounted) setState(() => _deleting = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se pudo eliminar la cuenta. Intenta de nuevo.'),
        backgroundColor: Colors.red,
      ));
    }
  }
}

// ── Tarjeta de estado premium ─────────────────────────────────────
class _PremiumCard extends StatelessWidget {
  void _showRedeemDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _RedeemDialog(ctrl: ctrl),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();
    final status  = premium.status;

    final Color  cardColor;
    final Color  accentColor;
    final IconData icon;
    final String title;
    final String subtitle;

    switch (status.tier) {
      case PremiumTier.trial:
        cardColor   = AppColors.accentBlue;
        accentColor = AppColors.accentBlue;
        icon        = Icons.hourglass_top_rounded;
        title       = 'Período de prueba';
        subtitle    = 'Vence el ${_formatDate(status.expiresAt!)} · ${status.daysRemaining} días restantes';
      case PremiumTier.active:
        cardColor   = AppColors.primary;
        accentColor = AppColors.primary;
        icon        = Icons.verified_rounded;
        title       = 'Plan ${status.type![0].toUpperCase()}${status.type!.substring(1)}';
        subtitle    = 'Vence el ${_formatDate(status.expiresAt!)} · ${status.daysRemaining} días restantes';
      case PremiumTier.expired:
        cardColor   = AppColors.accentOrange;
        accentColor = AppColors.accentOrange;
        icon        = Icons.lock_rounded;
        title       = 'Sin plan activo';
        subtitle    = 'Ingresa un código para desbloquear todas las funciones';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.tier == PremiumTier.expired ? 'FREE' : 'PREMIUM',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showRedeemDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status.tier == PremiumTier.expired ? 'Activar' : 'Código',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog para canjear código (reutilizado desde profile)
class _RedeemDialog extends StatefulWidget {
  final TextEditingController ctrl;
  const _RedeemDialog({required this.ctrl});
  @override
  State<_RedeemDialog> createState() => _RedeemDialogState();
}

class _RedeemDialogState extends State<_RedeemDialog> {
  bool    _loading = false;
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
      final dt = result.expiresAt!;
      final fecha = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('¡Premium activado! Vence el $fecha'),
        backgroundColor: AppColors.primary,
      ));
    } else {
      setState(() { _loading = false; _error = result.message; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.vpn_key_rounded, color: AppColors.accentOrange, size: 22),
        const SizedBox(width: 10),
        Text('Activar Premium', style: AppTextStyles.headingSmall),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          'Ingresa el código que te proporcionó administración:',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.ctrl,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 2),
          decoration: InputDecoration(
            hintText: 'XXXXXXXX',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentOrange, width: 1.5)),
            errorText: _error,
          ),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: _loading ? null : () => _redeem(context),
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentOrange))
              : const Text('Activar', style: TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
