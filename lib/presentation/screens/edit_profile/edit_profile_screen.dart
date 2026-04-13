// lib/presentation/screens/edit_profile/edit_profile_screen.dart
// Edición de perfil completamente funcional — guarda con shared_preferences
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../widgets/shared_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl, _ageCtrl;
  late double _weight, _height;
  late String _selectedGoal;
  bool _hasChanges = false;
  bool _isSaving   = false;

  final _goals = [
    'Ganar músculo', 'Perder grasa', 'Mantenimiento',
    'Mejorar resistencia', 'Aumentar fuerza', 'Mejorar movilidad',
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final p = auth.profile;
    _nameCtrl = TextEditingController(text: p?.name ?? auth.displayName);
    _ageCtrl  = TextEditingController(text: '${p?.age ?? 25}');
    _weight   = p?.weight ?? 70.0;
    _height   = p?.height ?? 170.0;
    _selectedGoal = p?.goal ?? 'Ganar músculo';
    _nameCtrl.addListener(() => setState(() => _hasChanges = true));
    _ageCtrl.addListener(() => setState(() => _hasChanges = true));
  }

  @override
  void dispose() { _nameCtrl.dispose(); _ageCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile({
      'name': _nameCtrl.text.trim(),
      'age': int.tryParse(_ageCtrl.text) ?? 25,
      'weight': _weight,
      'height': _height,
      'goal': _selectedGoal,
    });
    setState(() { _isSaving = false; _hasChanges = false; });
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Row(children: [
            Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: ok ? AppColors.primary : AppColors.error),
            const SizedBox(width: 10),
            Text(ok ? 'Perfil guardado correctamente' : 'Error al guardar'),
          ]),
          backgroundColor: AppColors.surface, behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        // App bar
        SliverAppBar(
          pinned: true, backgroundColor: AppColors.background,
          leading: GestureDetector(
            onTap: () => _hasChanges ? _showDiscard() : Navigator.pop(context),
            child: Container(margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 0.5)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 16)),
          ),
          title: Text('Editar perfil', style: AppTextStyles.headingSmall),
          centerTitle: true,
          actions: [if (_hasChanges) Padding(padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(onTap: _isSaving ? null : _save,
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)]),
                  child: _isSaving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                      : const Text('Guardar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.background)),
                ),
              ))],
        ),

        // Avatar
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20,20,20,0),
            child: Center(child: _AvatarEditor(initials: context.watch<AuthProvider>().userInitials)))),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // Datos personales
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Datos personales', style: AppTextStyles.headingSmall))),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DarkCard(padding: EdgeInsets.zero, child: Column(children: [
              _FormRow(label: 'Nombre', controller: _nameCtrl, icon: Icons.person_outline_rounded, isFirst: true),
              Divider(color: AppColors.divider, height: 1, indent: 52),
              _FormRow(label: 'Edad', controller: _ageCtrl, icon: Icons.cake_outlined, suffix: 'años', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], isLast: true),
            ])))),

        // Email (solo lectura)
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DarkCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [
              const Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Correo electrónico', style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(context.watch<AuthProvider>().firebaseUser?.email ?? '', style: AppTextStyles.bodyMedium),
              ])),
              const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textMuted),
            ])))),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Medidas corporales
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Medidas corporales', style: AppTextStyles.headingSmall))),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DarkCard(child: Column(children: [
              _MeasureSlider(label: 'Peso', icon: Icons.monitor_weight_outlined, value: _weight, min: 40, max: 150, unit: 'kg', decimals: 1, color: AppColors.primary,
                  onChanged: (v) => setState(() { _weight = v; _hasChanges = true; })),
              const SizedBox(height: 20),
              _MeasureSlider(label: 'Altura', icon: Icons.straighten_rounded, value: _height, min: 140, max: 220, unit: 'cm', decimals: 0, color: AppColors.accentBlue,
                  onChanged: (v) => setState(() { _height = v; _hasChanges = true; })),
              const SizedBox(height: 12),
              _ImcIndicator(weight: _weight, heightCm: _height),
            ])))),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Objetivo
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Objetivo de entrenamiento', style: AppTextStyles.headingSmall))),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(spacing: 10, runSpacing: 10,
              children: _goals.map((g) {
                final sel = _selectedGoal == g;
                return GestureDetector(
                  onTap: () { HapticFeedback.selectionClick(); setState(() { _selectedGoal = g; _hasChanges = true; }); },
                  child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: sel ? AppColors.primaryGradient : null,
                      color: sel ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: sel ? AppColors.primary.withOpacity(0.5) : AppColors.border, width: 0.5),
                      boxShadow: sel ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8)] : null,
                    ),
                    child: Text(g, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? AppColors.background : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ))),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
    );
  }

  void _showDiscard() => showDialog(context: context, builder: (_) => AlertDialog(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text('¿Descartar cambios?', style: AppTextStyles.headingSmall),
    content: Text('Tienes cambios sin guardar.', style: AppTextStyles.bodyMedium),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
      TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: Text('Descartar', style: TextStyle(color: AppColors.error))),
    ],
  ));
}

// ─── Widgets internos ────────────────────────────────────────

class _AvatarEditor extends StatelessWidget {
  final String initials;
  const _AvatarEditor({required this.initials});
  @override
  Widget build(BuildContext context) => Stack(children: [
    Container(width: 96, height: 96,
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]),
        child: Center(child: Text(initials, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.background)))),
    Positioned(right: 0, bottom: 0, child: GestureDetector(onTap: () {},
        child: Container(width: 32, height: 32,
            decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 1.5)),
            child: const Icon(Icons.camera_alt_outlined, size: 15, color: AppColors.primary)))),
  ]);
}

class _FormRow extends StatelessWidget {
  final String label; final TextEditingController controller; final IconData icon;
  final String? suffix; final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isFirst, isLast;
  const _FormRow({required this.label, required this.controller, required this.icon,
    this.suffix, this.keyboardType, this.inputFormatters, this.isFirst = false, this.isLast = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textMuted),
      const SizedBox(width: 12),
      Expanded(child: TextField(
        controller: controller, keyboardType: keyboardType,
        inputFormatters: inputFormatters, style: AppTextStyles.bodyLarge,
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
            labelText: label, labelStyle: AppTextStyles.caption, border: InputBorder.none,
            suffixText: suffix, suffixStyle: AppTextStyles.caption,
            contentPadding: const EdgeInsets.symmetric(vertical: 14)),
      )),
    ]),
  );
}

class _MeasureSlider extends StatelessWidget {
  final String label, unit; final IconData icon; final double value, min, max;
  final int decimals; final Color color; final ValueChanged<double> onChanged;
  const _MeasureSlider({required this.label, required this.icon, required this.value,
    required this.min, required this.max, required this.unit, required this.decimals,
    required this.color, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final display = decimals > 0 ? value.toStringAsFixed(decimals) : value.round().toString();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Text(label, style: AppTextStyles.labelMedium)]),
        RichText(text: TextSpan(children: [
          TextSpan(text: display, style: AppTextStyles.headingSmall.copyWith(color: color)),
          TextSpan(text: ' $unit', style: AppTextStyles.caption),
        ])),
      ]),
      const SizedBox(height: 8),
      SliderTheme(data: SliderThemeData(
        activeTrackColor: color, inactiveTrackColor: AppColors.border,
        thumbColor: color, overlayColor: color.withOpacity(0.15),
        trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        activeTickMarkColor: Colors.transparent, inactiveTickMarkColor: Colors.transparent,
      ), child: Slider(value: value, min: min, max: max, onChanged: onChanged)),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${min.round()} $unit', style: AppTextStyles.caption),
        Text('${max.round()} $unit', style: AppTextStyles.caption),
      ]),
    ]);
  }
}

class _ImcIndicator extends StatelessWidget {
  final double weight, heightCm;
  const _ImcIndicator({required this.weight, required this.heightCm});
  double get _imc { final h = heightCm / 100; return weight / (h * h); }
  String get _label { if (_imc < 18.5) return 'Bajo peso'; if (_imc < 25) return 'Normal'; if (_imc < 30) return 'Sobrepeso'; return 'Obesidad'; }
  Color  get _color { if (_imc < 18.5) return AppColors.accentBlue; if (_imc < 25) return AppColors.primary; if (_imc < 30) return AppColors.warning; return AppColors.error; }
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: _color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: _color.withOpacity(0.25), width: 0.5)),
    child: Row(children: [
      Icon(Icons.monitor_heart_outlined, color: _color, size: 18),
      const SizedBox(width: 10),
      Text('IMC:', style: AppTextStyles.bodyMedium),
      const SizedBox(width: 6),
      Text(_imc.toStringAsFixed(1), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _color)),
      const Spacer(),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Text(_label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color))),
    ]),
  );
}