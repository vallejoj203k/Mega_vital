// lib/presentation/screens/nutrition/nutrition_screen.dart
// ─────────────────────────────────────────────────────────────────
// Pantalla de Nutrición conectada a datos reales.
// Lee del NutritionProvider y muestra metas calculadas con
// FitnessCalculator según los datos del usuario logueado.
// ─────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/nutrition_provider.dart';
import '../../../services/fitness_calculator.dart';
import '../../../services/food_log_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/app_config.dart';
import '../../../services/food_search_service.dart';
import '../../../services/food_vision_service.dart';
import '../../widgets/shared_widgets.dart';
import '../meal_detail/meal_detail_screen.dart';
import '../api_keys/api_keys_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final nutrition = context.watch<NutritionProvider>();
    final auth      = context.watch<AuthProvider>();
    final profile   = auth.profile;

    // Metas calculadas con datos reales del usuario
    final calc = profile != null
        ? FitnessCalculator(
        weight: profile.weight, height: profile.height,
        age: profile.age, goal: profile.goal)
        : null;

    final metaCal   = calc?.metaCalorias  ?? 2000;
    final metaProt  = calc?.metaProteina  ?? 120.0;
    final metaCarbs = calc?.metaCarbos    ?? 250.0;
    final metaFat   = calc?.metaGrasas    ?? 60.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _AddFab(
        onTap: () => _showAddFoodSheet(context, nutrition),
      ),
      body: SafeArea(
        child: nutrition.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header con fecha y nav ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _DateHeader(nutrition: nutrition),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Anillo calórico con metas reales ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CalorieRing(
                consumed: nutrition.totalCalories,
                goal:     metaCal,
              ),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Macros con metas reales ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MacrosRow(
                protein:     nutrition.totalProtein,
                carbs:       nutrition.totalCarbs,
                fat:         nutrition.totalFat,
                goalProtein: metaProt,
                goalCarbs:   metaCarbs,
                goalFat:     metaFat,
              ),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Lista de comidas agrupadas ──
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(
                title: 'Registro del día',
                actionLabel: nutrition.log.entries.isNotEmpty ? 'Limpiar' : null,
                onAction: () => _confirmClear(context, nutrition),
              ),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            if (nutrition.log.entries.isEmpty)
              SliverToBoxAdapter(child: _EmptyState(
                onAdd: () => _showAddFoodSheet(context, nutrition),
              ))
            else
              SliverList(delegate: SliverChildListDelegate(
                FoodLog.mealOrder.map((mealType) {
                  final entries = nutrition.byMealType[mealType] ?? [];
                  if (entries.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: _MealSection(
                      mealType: entries.first.icon,
                      mealColor: entries.first.color,
                      mealLabel: _mealLabel(mealType),
                      entries: entries,
                      onDelete: (id) => nutrition.removeEntry(id),
                    ),
                  );
                }).toList(),
              )),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
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

  void _confirmClear(BuildContext ctx, NutritionProvider nutrition) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('¿Limpiar el día?', style: AppTextStyles.headingSmall),
      content: Text('Se eliminarán todos los alimentos de hoy.',
          style: AppTextStyles.bodyMedium),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
        TextButton(onPressed: () { Navigator.pop(ctx); nutrition.clearDay(); },
            child: Text('Limpiar', style: TextStyle(color: AppColors.error))),
      ],
    ));
  }

  void _showAddFoodSheet(BuildContext ctx, NutritionProvider nutrition) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodSheet(nutrition: nutrition),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────────

// ── Header con fecha + navegación ────────────────────────────────
class _DateHeader extends StatelessWidget {
  final NutritionProvider nutrition;
  const _DateHeader({required this.nutrition});

  String get _label {
    final d = nutrition.selectedDate;
    final n = DateTime.now();
    if (d.year == n.year && d.month == n.month && d.day == n.day) return 'Hoy';
    final yesterday = n.subtract(const Duration(days: 1));
    if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) return 'Ayer';
    final months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) => Row(children: [
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Nutrición', style: AppTextStyles.displayMedium),
      Text(_label, style: AppTextStyles.bodyMedium),
    ]),
    const Spacer(),
    // Navegar fecha anterior
    _NavBtn(icon: Icons.chevron_left_rounded,
        onTap: () => nutrition.previousDay()),
    const SizedBox(width: 4),
    // Navegar fecha siguiente (solo si no es hoy)
    _NavBtn(
      icon: Icons.chevron_right_rounded,
      onTap: nutrition.isToday ? null : () => nutrition.nextDay(),
      disabled: nutrition.isToday,
    ),
  ]);
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;
  const _NavBtn({required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Icon(icon,
          color: disabled ? AppColors.textMuted : AppColors.textSecondary,
          size: 20),
    ),
  );
}

// ── Anillo calórico ───────────────────────────────────────────────
class _CalorieRing extends StatelessWidget {
  final int consumed, goal;
  const _CalorieRing({required this.consumed, required this.goal});

  @override
  Widget build(BuildContext context) {
    final pct       = (consumed / goal).clamp(0.0, 1.0);
    final remaining = goal - consumed;
    final over      = consumed > goal;

    return DarkCard(child: Row(children: [
      // Anillo
      SizedBox(width: 120, height: 120,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: const Size(120, 120),
              painter: _RingPainter(progress: pct, over: over)),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$consumed', style: AppTextStyles.statNumber.copyWith(fontSize: 24)),
            Text('kcal', style: AppTextStyles.caption),
          ]),
        ]),
      ),
      const SizedBox(width: 20),
      Expanded(child: Column(children: [
        _CalRow('Objetivo',   '$goal kcal',          AppColors.textSecondary),
        const SizedBox(height: 10),
        _CalRow('Consumidas', '$consumed kcal',       AppColors.primary),
        const SizedBox(height: 10),
        _CalRow(over ? 'Exceso' : 'Restantes',
            '${remaining.abs()} kcal',
            over ? AppColors.error : AppColors.accentBlue),
        const SizedBox(height: 12),
        NeonProgressBar(
          progress: pct,
          gradient: over
              ? LinearGradient(colors: [AppColors.error, AppColors.error.withOpacity(0.7)])
              : AppColors.burnGradient,
          height: 6,
        ),
      ])),
    ]));
  }
}

class _CalRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CalRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(child: Text(label, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 8),
      Text(value, style: AppTextStyles.labelLarge.copyWith(color: color)),
    ],
  );
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool over;
  const _RingPainter({required this.progress, required this.over});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const sw = 10.0;
    final r = (size.width - sw * 2) / 2;

    canvas.drawCircle(c, r, Paint()
      ..color = AppColors.border..strokeWidth = sw..style = PaintingStyle.stroke);

    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r),
          -math.pi / 2, 2 * math.pi * progress, false,
          Paint()
            ..shader = (over
                ? LinearGradient(colors: [AppColors.error, AppColors.error.withOpacity(0.7)])
                : const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)])
            ).createShader(Rect.fromCircle(center: c, radius: r))
            ..strokeWidth = sw..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

// ── Macros con metas reales ───────────────────────────────────────
class _MacrosRow extends StatelessWidget {
  final double protein, carbs, fat;
  final double goalProtein, goalCarbs, goalFat;
  const _MacrosRow({required this.protein, required this.carbs, required this.fat,
    required this.goalProtein, required this.goalCarbs, required this.goalFat});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _MacroCard('Proteínas', protein, goalProtein,
        AppColors.primary, Icons.fitness_center_rounded)),
    const SizedBox(width: 10),
    Expanded(child: _MacroCard('Carbos', carbs, goalCarbs,
        AppColors.accentBlue, Icons.bolt_rounded)),
    const SizedBox(width: 10),
    Expanded(child: _MacroCard('Grasas', fat, goalFat,
        AppColors.accentOrange, Icons.eco_rounded)),
  ]);
}

class _MacroCard extends StatelessWidget {
  final String label;
  final double value, goal;
  final Color color;
  final IconData icon;
  const _MacroCard(this.label, this.value, this.goal, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    final pct = (value / goal).clamp(0.0, 1.0);
    return DarkCard(padding: const EdgeInsets.all(12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        RichText(text: TextSpan(children: [
          TextSpan(text: value.toInt().toString(),
              style: AppTextStyles.headingSmall.copyWith(color: color)),
          TextSpan(text: 'g', style: AppTextStyles.caption),
        ])),
        Text('/ ${goal.toInt()}g', style: AppTextStyles.caption),
        const SizedBox(height: 6),
        NeonProgressBar(progress: pct,
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            height: 4, showGlow: false),
      ],
    ));
  }
}

// ── Sección de comida (grupo por tipo) ────────────────────────────
class _MealSection extends StatelessWidget {
  final IconData mealType;
  final Color mealColor;
  final String mealLabel;
  final List<FoodEntry> entries;
  final ValueChanged<String> onDelete;
  const _MealSection({required this.mealType, required this.mealColor,
    required this.mealLabel, required this.entries, required this.onDelete});

  int get _totalCal => entries.fold(0, (s, e) => s + e.adjustedCalories);

  @override
  Widget build(BuildContext context) => DarkCard(
    padding: const EdgeInsets.all(0),
    child: Column(children: [
      // Header de la comida
      Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Row(children: [
          Container(width: 34, height: 34,
              decoration: BoxDecoration(
                  color: mealColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: mealColor.withOpacity(0.3), width: 0.5)),
              child: Icon(mealType, color: mealColor, size: 16)),
          const SizedBox(width: 10),
          Text(mealLabel, style: AppTextStyles.headingSmall),
          const Spacer(),
          Text('$_totalCal kcal',
              style: AppTextStyles.neonLabel.copyWith(color: mealColor, fontSize: 12)),
        ]),
      ),
      Divider(color: AppColors.divider, height: 1),
      // Entradas
      ...entries.map((e) => _FoodEntryRow(entry: e, onDelete: () => onDelete(e.id))),
    ]),
  );
}

class _FoodEntryRow extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onDelete;
  const _FoodEntryRow({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(
      builder: (_) => FoodEntryDetailScreen(entry: entry),
    )),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.name, style: AppTextStyles.labelLarge,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Wrap(spacing: 4, runSpacing: 4, children: [
            _MacroPill('${entry.adjustedCalories}', 'kcal', AppColors.accentOrange),
            _MacroPill('${entry.adjustedProtein.toInt()}g', 'P', AppColors.primary),
            _MacroPill('${entry.adjustedCarbs.toInt()}g', 'C', AppColors.accentBlue),
            _MacroPill('${entry.adjustedFat.toInt()}g', 'G', AppColors.accentOrange),
            if (entry.portions != 1.0)
              Text('×${entry.portions}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
          ]),
        ])),
        GestureDetector(
          onTap: onDelete,
          child: Container(padding: const EdgeInsets.all(6),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textMuted, size: 17)),
        ),
      ]),
    ),
  );
}


class _MacroPill extends StatelessWidget {
  final String value, unit;
  final Color color;
  const _MacroPill(this.value, this.unit, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text('$unit $value',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );
}

// ── Estado vacío ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(children: [
      Container(width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
          child: const Icon(Icons.restaurant_menu_rounded,
              color: AppColors.textMuted, size: 32)),
      const SizedBox(height: 16),
      Text('Sin alimentos registrados', style: AppTextStyles.headingSmall),
      const SizedBox(height: 8),
      Text('Toca + para agregar tu primera comida',
          style: AppTextStyles.bodyMedium),
      const SizedBox(height: 20),
      NeonButton(label: 'Agregar comida',
          icon: Icons.add_rounded, onTap: onAdd),
    ]),
  );
}

// ── FAB de agregar ────────────────────────────────────────────────
class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.add, color: AppColors.background, size: 20),
        SizedBox(width: 8),
        Text('Agregar comida', style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w700, color: AppColors.background)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// BOTTOM SHEET: Agregar alimento
// ─────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────
// BOTTOM SHEET — Buscar y agregar alimento
// ─────────────────────────────────────────────────────────────────
class AddFoodSheet extends StatefulWidget {
  final NutritionProvider nutrition;
  const AddFoodSheet({super.key, required this.nutrition});
  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  // ── Controladores ──────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  final _nameCtrl   = TextEditingController();
  final _calCtrl    = TextEditingController();
  final _protCtrl   = TextEditingController();
  final _carbCtrl   = TextEditingController();
  final _fatCtrl    = TextEditingController();
  final _gramCtrl   = TextEditingController(text: '100');

  // ── Estado ─────────────────────────────────────────────────────
  String _mealType                   = 'almuerzo';
  bool   _isSaving                   = false;
  bool   _isSearching                = false;
  bool   _isAnalyzingPhoto           = false;
  bool   _manualMode                 = false;
  List<FoodSearchResult>  _results   = [];
  List<VisionFoodItem>    _visionItems = [];
  FoodSearchResult?       _selected;
  File?                   _photoFile;
  String?                 _visionError;

  // ── Carrito: lista de alimentos a guardar juntos ───────────────
  final List<_CartItem> _cart = [];

  String get _suggestedMealType {
    final h = DateTime.now().hour;
    if (h >= 5  && h < 11) return 'desayuno';
    if (h >= 11 && h < 16) return 'almuerzo';
    if (h >= 16 && h < 19) return 'merienda';
    return 'cena';
  }

  @override
  void initState() {
    super.initState();
    _mealType = _suggestedMealType;
  }

  @override
  void dispose() {
    _searchCtrl.dispose(); _nameCtrl.dispose(); _calCtrl.dispose();
    _protCtrl.dispose(); _carbCtrl.dispose(); _fatCtrl.dispose();
    _gramCtrl.dispose();
    super.dispose();
  }

  // ── Agregar al carrito ─────────────────────────────────────────
  void _addToCart() {
    if (!_formFilled) return;
    setState(() {
      _cart.add(_CartItem(
        name:     _nameCtrl.text.trim(),
        calories: int.tryParse(_calCtrl.text) ?? 0,
        protein:  double.tryParse(_protCtrl.text) ?? 0,
        carbs:    double.tryParse(_carbCtrl.text) ?? 0,
        fat:      double.tryParse(_fatCtrl.text) ?? 0,
      ));
      // Limpiar formulario para agregar el siguiente
      _nameCtrl.clear(); _calCtrl.clear(); _protCtrl.clear();
      _carbCtrl.clear(); _fatCtrl.clear(); _gramCtrl.text = '100';
      _searchCtrl.clear(); _selected = null; _manualMode = false;
      _results = []; _visionItems = []; _photoFile = null; _visionError = null;
    });
  }

  // ── Guardar todos del carrito ──────────────────────────────────
  Future<void> _saveAll() async {
    if (_cart.isEmpty) return;
    setState(() => _isSaving = true);
    for (final item in _cart) {
      await widget.nutrition.addEntry(
        name: item.name, mealType: _mealType,
        calories: item.calories, protein: item.protein,
        carbs: item.carbs, fat: item.fat,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  // ── Búsqueda ───────────────────────────────────────────────────
  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() { _results = []; _isSearching = false; });
      return;
    }
    setState(() { _isSearching = true; _selected = null; });
    final r = await FoodSearchService.search(query);
    if (mounted) setState(() { _results = r; _isSearching = false; });
  }

  void _selectResult(FoodSearchResult r) {
    _selected = r;
    _nameCtrl.text = r.name;
    _recalcFromGrams(double.tryParse(_gramCtrl.text) ?? 100);
    setState(() { _results = []; _searchCtrl.text = ''; _manualMode = false; });
  }

  void _recalcFromGrams(double grams) {
    if (_selected == null) return;
    final f = grams / 100.0;
    _calCtrl.text  = ((_selected!.calories * f).round()).toString();
    _protCtrl.text = (_selected!.protein  * f).toStringAsFixed(1);
    _carbCtrl.text = (_selected!.carbs    * f).toStringAsFixed(1);
    _fatCtrl.text  = (_selected!.fat      * f).toStringAsFixed(1);
    setState(() {});
  }

  // ── Foto con IA ────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 1024);
      if (picked == null) return;
      final file = File(picked.path);
      setState(() {
        _photoFile = file; _isAnalyzingPhoto = true;
        _visionError = null; _visionItems = [];
        _results = []; _selected = null; _manualMode = false;
      });
      final result = await FoodVisionService.analyzeFood(file);
      if (!mounted) return;
      if (!result.success) {
        setState(() { _isAnalyzingPhoto = false; _visionError = result.error; });
        return;
      }
      // Si detectó varios alimentos, agregarlos todos al carrito directo
      if (result.foods.length > 1) {
        setState(() {
          _isAnalyzingPhoto = false;
          for (final food in result.foods) {
            _cart.add(_CartItem(
              name: food.name, calories: food.calories,
              protein: food.protein, carbs: food.carbs, fat: food.fat,
            ));
          }
          _photoFile = null; _visionItems = [];
        });
        return;
      }
      // Si detectó uno solo, llenar el formulario
      if (result.foods.length == 1) {
        final food = result.foods.first;
        _nameCtrl.text  = food.name;
        _gramCtrl.text  = food.estimatedWeightG.toString();
        _calCtrl.text   = food.calories.toString();
        _protCtrl.text  = food.protein.toStringAsFixed(1);
        _carbCtrl.text  = food.carbs.toStringAsFixed(1);
        _fatCtrl.text   = food.fat.toStringAsFixed(1);
      }
      setState(() { _isAnalyzingPhoto = false; _visionItems = result.foods; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isAnalyzingPhoto = false;
      _visionError = 'No se pudo acceder a la cámara.'; });
    }
  }

  void _selectVisionItem(VisionFoodItem item) {
    _nameCtrl.text  = item.name;
    _gramCtrl.text  = item.estimatedWeightG.toString();
    _calCtrl.text   = item.calories.toString();
    _protCtrl.text  = item.protein.toStringAsFixed(1);
    _carbCtrl.text  = item.carbs.toStringAsFixed(1);
    _fatCtrl.text   = item.fat.toStringAsFixed(1);
    setState(() { _selected = null; _manualMode = false; });
  }

  bool get _formFilled =>
      _nameCtrl.text.trim().isNotEmpty && _calCtrl.text.isNotEmpty;

  bool get _formEmpty =>
      _nameCtrl.text.trim().isEmpty && _calCtrl.text.isEmpty;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final totalCartCal = _cart.fold(0, (s, i) => s + i.calories);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),

          // Título + tipo de comida
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Agregar alimentos', style: AppTextStyles.headingSmall),
            GestureDetector(onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 22)),
          ]),

          const SizedBox(height: 10),

          // Selector de tipo de comida
          _MealTypePicker(selected: _mealType,
              onChanged: (t) => setState(() => _mealType = t)),

          const SizedBox(height: 14),

          // ── CARRITO de alimentos ───────────────────────────────
          if (_cart.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(children: [
                // Header carrito
                Padding(padding: const EdgeInsets.fromLTRB(14,10,14,6),
                    child: Row(children: [
                      const Icon(Icons.shopping_basket_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('${_cart.length} alimento(s) — $totalCartCal kcal total',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.primary)),
                    ])),
                Divider(color: AppColors.primary.withOpacity(0.2), height: 1),
                // Items del carrito
                ..._cart.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: AppTextStyles.labelLarge,
                              overflow: TextOverflow.ellipsis),
                          Text('${item.calories} kcal  ·  '
                              'P:${item.protein.toInt()}g  '
                              'C:${item.carbs.toInt()}g  '
                              'G:${item.fat.toInt()}g',
                              style: AppTextStyles.caption),
                        ],
                      )),
                      GestureDetector(
                        onTap: () => setState(() => _cart.removeAt(i)),
                        child: const Icon(Icons.remove_circle_outline_rounded,
                            size: 18, color: AppColors.textMuted),
                      ),
                    ]),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // ── Botones de foto ────────────────────────────────────
          _PhotoButtons(
            onCamera:  () => _pickImage(ImageSource.camera),
            onGallery: () => _pickImage(ImageSource.gallery),
            visionEnabled: AppConfig.visionEnabled,
          ),

          const SizedBox(height: 12),

          // ── Estado análisis foto ───────────────────────────────
          if (_isAnalyzingPhoto)
            _AnalyzingIndicator(photoFile: _photoFile),

          if (_visionError != null)
            _ErrorCard(
              message: _visionError!,
              onDismiss: () => setState(() => _visionError = null),
              onAddKey: _visionError!.contains('ímite') || _visionError!.contains('clave')
                  ? () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ApiKeysScreen()))
                      .then((_) => setState(() {}))
                  : null,
            ),

          if (_visionItems.isNotEmpty && !_isAnalyzingPhoto)
            _VisionResultsCard(
                items: _visionItems, photoFile: _photoFile,
                onSelect: _selectVisionItem, onSaveAll: null),

          // ── Separador ─────────────────────────────────────────
          if (_visionItems.isEmpty && !_isAnalyzingPhoto) ...[
            Row(children: [
              Expanded(child: Divider(color: AppColors.border, height: 1)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('busca por nombre',
                      style: AppTextStyles.caption)),
              Expanded(child: Divider(color: AppColors.border, height: 1)),
            ]),

            const SizedBox(height: 10),

            // ── Campo de búsqueda ──────────────────────────────
            TextField(
              controller: _searchCtrl,
              style: AppTextStyles.bodyLarge,
              cursorColor: AppColors.primary,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'huevo, arepa, pollo, café...',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                prefixIcon: _isSearching
                    ? const Padding(padding: EdgeInsets.all(12),
                    child: SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary)))
                    : const Icon(Icons.search_rounded,
                    size: 20, color: AppColors.textMuted),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        size: 18, color: AppColors.textMuted),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _results = []);
                    }) : null,
                filled: true, fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.border, width: 0.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.border, width: 0.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
            ),

            // Resultados de búsqueda
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5)),
                child: Column(
                  children: _results.asMap().entries.map((e) {
                    final r = e.value;
                    final isLast = e.key == _results.length - 1;
                    return GestureDetector(
                      onTap: () => _selectResult(r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(border: isLast ? null
                            : Border(bottom: BorderSide(
                            color: AppColors.divider, width: 0.5))),
                        child: Row(children: [
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: r.source == 'local'
                                      ? AppColors.primaryGlow
                                      : AppColors.accentBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(r.source == 'local' ? 'Local' : 'OFF',
                                  style: TextStyle(fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: r.source == 'local'
                                          ? AppColors.primary
                                          : AppColors.accentBlue))),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.displayName, style: AppTextStyles.labelLarge,
                                    overflow: TextOverflow.ellipsis),
                                Text(r.macroSummary, style: AppTextStyles.caption),
                              ])),
                          const Icon(Icons.add_circle_rounded,
                              color: AppColors.primary, size: 20),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // No encontrado
            if (_results.isEmpty && _searchCtrl.text.isNotEmpty && !_isSearching)
              Padding(padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: () {
                      _nameCtrl.text = _searchCtrl.text;
                      setState(() { _manualMode = true; _results = []; });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 0.5)),
                      child: Row(children: [
                        const Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                            '"${_searchCtrl.text}" — ingresar manualmente',
                            style: AppTextStyles.bodyMedium,
                            overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  )),
          ],

          // ── Formulario del alimento actual ─────────────────────
          if (_selected != null || _manualMode) ...[
            const SizedBox(height: 14),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),

            _SheetField(controller: _nameCtrl, label: 'Nombre',
                hint: 'Nombre del alimento',
                icon: Icons.restaurant_menu_rounded,
                onChanged: (_) => setState(() {})),

            const SizedBox(height: 10),

            // Gramos si viene de búsqueda
            if (_selected != null) ...[
              Row(children: [
                const Icon(Icons.scale_outlined,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text('Cantidad (g)', style: AppTextStyles.labelMedium),
                const Spacer(),
                SizedBox(width: 90,
                    child: TextField(
                      controller: _gramCtrl,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingSmall
                          .copyWith(color: AppColors.primary),
                      cursorColor: AppColors.primary,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (v) {
                        final g = double.tryParse(v);
                        if (g != null && g > 0) _recalcFromGrams(g);
                      },
                      decoration: InputDecoration(
                          suffixText: 'g', suffixStyle: AppTextStyles.caption,
                          filled: true, fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.border, width: 0.5)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.border, width: 0.5)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10)),
                    )),
              ]),
              const SizedBox(height: 10),
            ],

            _MacrosPreview(
              cal:  int.tryParse(_calCtrl.text) ?? 0,
              prot: double.tryParse(_protCtrl.text) ?? 0,
              carbs: double.tryParse(_carbCtrl.text) ?? 0,
              fat:   double.tryParse(_fatCtrl.text) ?? 0,
              calCtrl: _calCtrl, protCtrl: _protCtrl,
              carbCtrl: _carbCtrl, fatCtrl: _fatCtrl,
              editable: _manualMode,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 14),

            // Botón "+ Agregar a la lista" (no guarda aún)
            GestureDetector(
              onTap: _formFilled ? _addToCart : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity, height: 48,
                decoration: BoxDecoration(
                  color: _formFilled
                      ? AppColors.accentBlue.withOpacity(0.12)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _formFilled
                        ? AppColors.accentBlue.withOpacity(0.5)
                        : AppColors.border,
                    width: _formFilled ? 1.0 : 0.5,
                  ),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded,
                          color: _formFilled
                              ? AppColors.accentBlue : AppColors.textMuted,
                          size: 18),
                      const SizedBox(width: 8),
                      Text('Agregar a la lista',
                          style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _formFilled
                                  ? AppColors.accentBlue : AppColors.textMuted)),
                    ]),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Botón GUARDAR TODOS ────────────────────────────────
          if (_cart.isNotEmpty || (_formFilled && _cart.isEmpty)) ...[
            GestureDetector(
              onTap: () async {
                // Si hay algo en el form pero no se agregó al carrito, agregarlo
                if (_formFilled) _addToCart();
                await _saveAll();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16)],
                ),
                child: Center(child: _isSaving
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.background))
                    : Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded,
                          color: AppColors.background, size: 18),
                      const SizedBox(width: 8),
                      Text(
                          _cart.length > 1
                              ? 'Guardar ${_cart.length + (_formFilled ? 1 : 0)} alimentos'
                              : 'Guardar alimento',
                          style: const TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.background)),
                    ])),
              ),
            ),
          ],

          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ── Modelo temporal del carrito ───────────────────────────────────
class _CartItem {
  final String name;
  final int    calories;
  final double protein, carbs, fat;
  const _CartItem({required this.name, required this.calories,
    required this.protein, required this.carbs, required this.fat});
}

// ── Selector de tipo de comida ────────────────────────────────────
class _MealTypePicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _MealTypePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final types = [
      ('desayuno', 'Desayuno', Icons.wb_sunny_rounded,     const Color(0xFFFFB020)),
      ('almuerzo', 'Almuerzo', Icons.lunch_dining_rounded,  const Color(0xFF4FC3F7)),
      ('merienda', 'Merienda', Icons.apple_rounded,         const Color(0xFF00FF87)),
      ('cena',     'Cena',     Icons.nightlight_round,      const Color(0xFFBB86FC)),
      ('extra',    'Extra',    Icons.restaurant_rounded,    const Color(0xFFFF6B35)),
    ];
    return SizedBox(height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (id, label, icon, color) = types[i];
          final sel = selected == id;
          return GestureDetector(
            onTap: () => onChanged(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: sel ? color.withOpacity(0.15) : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: sel ? color.withOpacity(0.5) : AppColors.border,
                      width: sel ? 1.0 : 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 14, color: sel ? color : AppColors.textMuted),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? color : AppColors.textSecondary)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ── Campo del sheet ────────────────────────────────────────────────
class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final Color? color;
  final ValueChanged<String>? onChanged;
  const _SheetField({required this.controller, required this.label,
    required this.hint, required this.icon, this.keyboardType,
    this.color, this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    onChanged: onChanged,
    style: AppTextStyles.bodyLarge,
    cursorColor: color ?? AppColors.primary,
    decoration: InputDecoration(
      labelText: label, hintText: hint,
      labelStyle: AppTextStyles.caption
          .copyWith(color: color ?? AppColors.textMuted),
      hintStyle: AppTextStyles.caption,
      prefixIcon: Icon(icon, size: 16,
          color: color?.withOpacity(0.7) ?? AppColors.textMuted),
      filled: true, fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color ?? AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}

// ── Preview de macros ──────────────────────────────────────────────
class _MacrosPreview extends StatelessWidget {
  final int    cal;
  final double prot, carbs, fat;
  final TextEditingController calCtrl, protCtrl, carbCtrl, fatCtrl;
  final bool   editable;
  final ValueChanged<String> onChanged;

  const _MacrosPreview({required this.cal, required this.prot,
    required this.carbs, required this.fat,
    required this.calCtrl, required this.protCtrl,
    required this.carbCtrl, required this.fatCtrl,
    required this.editable, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (editable) {
      return Column(children: [
        Row(children: [
          Expanded(child: _SheetField(controller: calCtrl, label: 'Calorías',
              hint: '0', icon: Icons.local_fire_department_rounded,
              keyboardType: TextInputType.number,
              color: AppColors.accentOrange, onChanged: onChanged)),
          const SizedBox(width: 8),
          Expanded(child: _SheetField(controller: protCtrl, label: 'Proteínas (g)',
              hint: '0', icon: Icons.fitness_center_rounded,
              keyboardType: TextInputType.number,
              color: AppColors.primary, onChanged: onChanged)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _SheetField(controller: carbCtrl, label: 'Carbos (g)',
              hint: '0', icon: Icons.bolt_rounded,
              keyboardType: TextInputType.number,
              color: AppColors.accentBlue, onChanged: onChanged)),
          const SizedBox(width: 8),
          Expanded(child: _SheetField(controller: fatCtrl, label: 'Grasas (g)',
              hint: '0', icon: Icons.eco_rounded,
              keyboardType: TextInputType.number,
              color: AppColors.accentOrange, onChanged: onChanged)),
        ]),
      ]);
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 0.5)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _MPrev('$cal', 'kcal', AppColors.accentOrange),
        _MPDiv(),
        _MPrev('${prot.toStringAsFixed(1)}g', 'Prot.', AppColors.primary),
        _MPDiv(),
        _MPrev('${carbs.toStringAsFixed(1)}g', 'Carb.', AppColors.accentBlue),
        _MPDiv(),
        _MPrev('${fat.toStringAsFixed(1)}g', 'Gras.', AppColors.accentOrange),
      ]),
    );
  }
}

class _MPrev extends StatelessWidget {
  final String v, l; final Color c;
  const _MPrev(this.v, this.l, this.c);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(v, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c)),
    Text(l, style: AppTextStyles.caption),
  ]);
}

class _MPDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 28, color: AppColors.border);
}

// ── Botones de foto ────────────────────────────────────────────────
class _PhotoButtons extends StatelessWidget {
  final VoidCallback onCamera, onGallery;
  final bool visionEnabled;
  const _PhotoButtons({required this.onCamera, required this.onGallery,
    required this.visionEnabled});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: GestureDetector(
      onTap: visionEnabled ? onCamera : () => _showKeyInfo(context),
      child: Container(height: 54,
        decoration: BoxDecoration(
            color: visionEnabled
                ? AppColors.primary.withOpacity(0.08)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: visionEnabled
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.border,
                width: visionEnabled ? 1.0 : 0.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.camera_alt_rounded,
              color: visionEnabled ? AppColors.primary : AppColors.textMuted,
              size: 20),
          const SizedBox(width: 8),
          Column(mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tomar foto', style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: visionEnabled ? AppColors.primary : AppColors.textMuted)),
                Text('IA calcula los macros',
                    style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ]),
        ]),
      ),
    )),
    const SizedBox(width: 10),
    Expanded(child: GestureDetector(
      onTap: visionEnabled ? onGallery : () => _showKeyInfo(context),
      child: Container(height: 54,
        decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.photo_library_rounded,
              color: visionEnabled ? AppColors.accentBlue : AppColors.textMuted,
              size: 20),
          const SizedBox(width: 8),
          Column(mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Galería', style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: visionEnabled ? AppColors.accentBlue : AppColors.textMuted)),
                Text('Elegir imagen',
                    style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ]),
        ]),
      ),
    )),
  ]);

  void _showKeyInfo(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Activa el análisis con IA', style: AppTextStyles.headingSmall),
      content: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Agrega tu clave gratuita de Gemini para analizar fotos de comida.',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Obtén una clave gratis en: aistudio.google.com/apikey',
                style: AppTextStyles.bodySmall),
          ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted))),
        TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ApiKeysScreen()));
            },
            child: Text('Agregar clave', style: TextStyle(color: AppColors.primary))),
      ],
    ));
  }
}

// ── Indicador de análisis ──────────────────────────────────────────
class _AnalyzingIndicator extends StatelessWidget {
  final File? photoFile;
  const _AnalyzingIndicator({this.photoFile});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: AppColors.primaryGlow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5)),
    child: Row(children: [
      if (photoFile != null) ...[
        ClipRRect(borderRadius: BorderRadius.circular(8),
            child: Image.file(photoFile!, width: 48, height: 48, fit: BoxFit.cover)),
        const SizedBox(width: 12),
      ],
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analizando con IA...', style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.primary)),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              borderRadius: BorderRadius.circular(4),
            ),
          ])),
    ]),
  );
}

// ── Error card ─────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  final VoidCallback? onAddKey;
  const _ErrorCard({required this.message, required this.onDismiss, this.onAddKey});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: AppTextStyles.bodySmall
            .copyWith(color: AppColors.error))),
        GestureDetector(onTap: onDismiss,
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.error)),
      ]),
      if (onAddKey != null) ...[
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onAddKey,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8)),
            child: Text('+ Agregar clave de Gemini',
                style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
          ),
        ),
      ],
    ]),
  );
}

// ── Resultados de visión ───────────────────────────────────────────
class _VisionResultsCard extends StatelessWidget {
  final List<VisionFoodItem> items;
  final File?       photoFile;
  final ValueChanged<VisionFoodItem> onSelect;
  final VoidCallback? onSaveAll;
  const _VisionResultsCard({required this.items, this.photoFile,
    required this.onSelect, this.onSaveAll});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        if (photoFile != null) ...[
          ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Image.file(photoFile!, width: 48, height: 48, fit: BoxFit.cover)),
          const SizedBox(width: 10),
        ],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gemini detectó ${items.length} alimento(s)',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.primary)),
              Text('Toca uno para editarlo antes de agregar',
                  style: AppTextStyles.bodySmall),
            ])),
      ])),
      Divider(color: AppColors.border, height: 1),
      ...items.asMap().entries.map((e) {
        final item   = e.value;
        final isLast = e.key == items.length - 1;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(border: isLast ? null : Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5))),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppTextStyles.labelLarge,
                        overflow: TextOverflow.ellipsis),
                    Text('~${item.estimatedWeightG}g · ${item.calories} kcal · '
                        'P:${item.protein.toInt()}g C:${item.carbs.toInt()}g '
                        'G:${item.fat.toInt()}g',
                        style: AppTextStyles.caption),
                  ])),
              const Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.primary, size: 18),
            ]),
          ),
        );
      }),
    ]),
  );
}