// lib/presentation/screens/meal_detail/meal_detail_screen.dart
// ─────────────────────────────────────────────────────────────────
// Detalle de un alimento registrado (FoodEntry real).
// Muestra macros, anillo interactivo y permite ajustar porciones.
// ─────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/nutrition_provider.dart';
import '../../../services/food_log_service.dart';
import '../../widgets/shared_widgets.dart';

// ── Pantalla de detalle de un FoodEntry real ──────────────────────
class FoodEntryDetailScreen extends StatefulWidget {
  final FoodEntry entry;
  const FoodEntryDetailScreen({super.key, required this.entry});
  @override
  State<FoodEntryDetailScreen> createState() => _FoodEntryDetailScreenState();
}

class _FoodEntryDetailScreenState extends State<FoodEntryDetailScreen> {
  late double _portions;
  String? _selectedMacro; // null = calorías totales

  @override
  void initState() {
    super.initState();
    _portions = widget.entry.portions;
  }

  FoodEntry get _adjusted => widget.entry.copyWithPortions(_portions);

  @override
  Widget build(BuildContext context) {
    final e   = _adjusted;
    final col = e.color;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: AppColors.background,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [col.withOpacity(0.2), AppColors.background],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                    child: Row(children: [
                      Container(width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: col.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: col.withOpacity(0.4)),
                        ),
                        child: Icon(e.icon, color: col, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(e.name, style: AppTextStyles.headingMedium,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(_mealLabel(e.mealType),
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: col)),
                        ],
                      )),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // ── Anillo de macros ─────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _MacroRingCard(
              calories: e.adjustedCalories,
              protein:  e.adjustedProtein,
              carbs:    e.adjustedCarbs,
              fat:      e.adjustedFat,
              color:    col,
              selected: _selectedMacro,
              onSelect: (m) => setState(() =>
              _selectedMacro = _selectedMacro == m ? null : m),
            ),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Control de porciones ─────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PortionControl(
              portions: _portions,
              onChange: (v) => setState(() => _portions = v),
              onSave: () async {
                await context.read<NutritionProvider>()
                    .updatePortions(widget.entry.id, _portions);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(SnackBar(
                      content: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text('Porciones actualizadas'),
                      ]),
                      backgroundColor: AppColors.surface,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                }
              },
            ),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Tabla de macros ──────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _MacroTable(entry: e),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  String _mealLabel(String type) {
    switch (type) {
      case 'desayuno': return 'Desayuno';
      case 'almuerzo': return 'Almuerzo';
      case 'merienda': return 'Merienda';
      case 'cena':     return 'Cena';
      default:         return 'Extra';
    }
  }
}

// ── Anillo de macros ───────────────────────────────────────────────
class _MacroRingCard extends StatelessWidget {
  final int    calories;
  final double protein, carbs, fat;
  final Color  color;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _MacroRingCard({required this.calories, required this.protein,
    required this.carbs, required this.fat, required this.color,
    required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final total = protein * 4 + carbs * 4 + fat * 9;

    return DarkCard(child: Column(children: [
      Row(children: [
        // Anillo
        SizedBox(width: 120, height: 120,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(size: const Size(120, 120),
              painter: _RingPainter(
                pRatio: total > 0 ? (protein * 4) / total : 0,
                cRatio: total > 0 ? (carbs   * 4) / total : 0,
                fRatio: total > 0 ? (fat      * 9) / total : 0,
              ),
            ),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$calories',
                  style: AppTextStyles.headingSmall.copyWith(fontSize: 22)),
              Text('kcal', style: AppTextStyles.caption),
            ]),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(children: [
          _MacroTile('Proteínas', '${protein.toStringAsFixed(1)}g',
              AppColors.primary, Icons.fitness_center_rounded,
              selected == 'prot', () => onSelect('prot')),
          const SizedBox(height: 8),
          _MacroTile('Carbohidratos', '${carbs.toStringAsFixed(1)}g',
              AppColors.accentBlue, Icons.bolt_rounded,
              selected == 'carbs', () => onSelect('carbs')),
          const SizedBox(height: 8),
          _MacroTile('Grasas', '${fat.toStringAsFixed(1)}g',
              AppColors.accentOrange, Icons.eco_rounded,
              selected == 'fat', () => onSelect('fat')),
        ])),
      ]),
    ]));
  }
}

class _MacroTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _MacroTile(this.label, this.value, this.color, this.icon,
      this.selected, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: selected ? color.withOpacity(0.4) : Colors.transparent,
            width: 0.5),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: AppTextStyles.caption)),
        Text(value, style: AppTextStyles.labelLarge.copyWith(color: color)),
      ]),
    ),
  );
}

class _RingPainter extends CustomPainter {
  final double pRatio, cRatio, fRatio;
  const _RingPainter({required this.pRatio, required this.cRatio,
    required this.fRatio});

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 10.0;
    final c  = Offset(size.width / 2, size.height / 2);
    final r  = (size.width - sw * 2) / 2;
    const gap = 0.04;
    const start = -math.pi / 2;

    canvas.drawCircle(c, r, Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = sw..style = PaintingStyle.stroke);

    double cur = start;
    for (final seg in [
      (pRatio, const Color(0xFF00FF87)),
      (cRatio, const Color(0xFF4FC3F7)),
      (fRatio, const Color(0xFFFF6B35)),
    ]) {
      if (seg.$1 <= 0) continue;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r),
          cur + gap / 2, 2 * math.pi * seg.$1 - gap, false,
          Paint()
            ..color = seg.$2..strokeWidth = sw
            ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      cur += 2 * math.pi * seg.$1;
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => false;
}

// ── Control de porciones ───────────────────────────────────────────
class _PortionControl extends StatelessWidget {
  final double portions;
  final ValueChanged<double> onChange;
  final VoidCallback onSave;
  const _PortionControl({required this.portions, required this.onChange,
    required this.onSave});

  @override
  Widget build(BuildContext context) => DarkCard(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text('Porciones', style: AppTextStyles.headingSmall),
        const Spacer(),
        Text(portions.toStringAsFixed(1),
            style: AppTextStyles.headingSmall.copyWith(color: AppColors.primary)),
        Text('×', style: AppTextStyles.bodyMedium),
      ]),
      const SizedBox(height: 10),
      SliderTheme(data: SliderThemeData(
        activeTrackColor:   AppColors.primary,
        inactiveTrackColor: AppColors.border,
        thumbColor:         AppColors.primary,
        overlayColor:       AppColors.primary.withOpacity(0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        activeTickMarkColor:   Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
      ), child: Slider(
        value:    portions,
        min:      0.25,
        max:      3.0,
        divisions: 11,
        onChanged: onChange,
      )),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('0.25×', style: AppTextStyles.caption),
        Text('3×',    style: AppTextStyles.caption),
      ]),
      const SizedBox(height: 12),
      NeonButton(label: 'Guardar cambios', icon: Icons.save_rounded,
          onTap: onSave, fullWidth: true),
    ],
  ));
}

// ── Tabla de macros detallada ──────────────────────────────────────
class _MacroTable extends StatelessWidget {
  final FoodEntry entry;
  const _MacroTable({required this.entry});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Calorías',      '${entry.adjustedCalories} kcal',    AppColors.accentOrange),
      ('Proteínas',     '${entry.adjustedProtein.toStringAsFixed(1)} g',  AppColors.primary),
      ('Carbohidratos', '${entry.adjustedCarbs.toStringAsFixed(1)} g',    AppColors.accentBlue),
      ('Grasas',        '${entry.adjustedFat.toStringAsFixed(1)} g',      AppColors.accentOrange),
      ('Porciones',     '${entry.portions}×',                AppColors.textSecondary),
    ];

    return DarkCard(padding: EdgeInsets.zero, child: Column(
      children: rows.asMap().entries.map((e) {
        final isLast = e.key == rows.length - 1;
        final row    = e.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: isLast ? null : Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: Row(children: [
            Text(row.$1, style: AppTextStyles.bodyMedium),
            const Spacer(),
            Text(row.$2, style: AppTextStyles.labelLarge.copyWith(color: row.$3)),
          ]),
        );
      }).toList(),
    ));
  }
}