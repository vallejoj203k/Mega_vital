// lib/presentation/screens/auth/register_screen.dart
// ─────────────────────────────────────────────────────────────────
// Registro en 3 pasos con barra de progreso animada:
//   Paso 1 → Datos personales (nombre, email, contraseña)
//   Paso 2 → Medidas corporales (peso, altura, edad)
//   Paso 3 → Objetivo de entrenamiento
//
// Cada paso valida sus propios campos antes de avanzar.
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../widgets/shared_widgets.dart';
import 'login_screen.dart' show AuthField;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  // ── Pasos del formulario ──
  int _step = 0;
  final _totalSteps = 3;

  // ── Controladores paso 1 ──
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  final _formKey1 = GlobalKey<FormState>();

  // ── Controladores paso 2 ──
  double _weight = 70.0;
  double _height = 170.0;
  int _age = 25;
  final _ageCtrl = TextEditingController(text: '25');
  final _formKey2 = GlobalKey<FormState>();

  // ── Paso 3: objetivo ──
  String _selectedGoal = 'Ganar músculo';
  final List<Map<String, dynamic>> _goals = [
    {'label': 'Ganar músculo', 'icon': Icons.fitness_center_rounded, 'desc': 'Aumentar masa y fuerza'},
    {'label': 'Perder grasa', 'icon': Icons.local_fire_department_rounded, 'desc': 'Definir y quemar calorías'},
    {'label': 'Mantenimiento', 'icon': Icons.balance_rounded, 'desc': 'Mantener mi físico actual'},
    {'label': 'Mejorar resistencia', 'icon': Icons.directions_run_rounded, 'desc': 'Cardio y aguante'},
    {'label': 'Aumentar fuerza', 'icon': Icons.sports_gymnastics_rounded, 'desc': 'Levantamientos pesados'},
    {'label': 'Mejorar movilidad', 'icon': Icons.self_improvement_rounded, 'desc': 'Flexibilidad y yoga'},
  ];

  // ── Títulos de cada paso ──
  final _stepTitles = [
    ('Tu cuenta', 'Crea tus credenciales de acceso'),
    ('Tu cuerpo', 'Ayúdanos a personalizar tu plan'),
    ('Tu meta', 'Define tu objetivo principal'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // ── Header con progreso ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_step > 0)
                          GestureDetector(
                            onTap: _previousStep,
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.border, width: 0.5),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        Expanded(
                          child: _StepProgressBar(
                            currentStep: _step,
                            totalSteps: _totalSteps,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_step + 1}/$_totalSteps',
                          style: AppTextStyles.neonLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Título animado del paso
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey(_step),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stepTitles[_step].$1,
                            style: AppTextStyles.displayMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stepTitles[_step].$2,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Contenido del paso ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _Step1(
          nameCtrl: _nameCtrl,
          emailCtrl: _emailCtrl,
          passCtrl: _passCtrl,
          passConfirmCtrl: _passConfirmCtrl,
          obscurePass: _obscurePass,
          obscureConfirm: _obscureConfirm,
          formKey: _formKey1,
          onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
          onToggleConfirm: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          onNext: _nextStep,
        );
      case 1:
        return _Step2(
          weight: _weight,
          height: _height,
          age: _age,
          ageCtrl: _ageCtrl,
          formKey: _formKey2,
          onWeightChanged: (v) => setState(() => _weight = v),
          onHeightChanged: (v) => setState(() => _height = v),
          onAgeChanged: (v) => setState(() => _age = int.tryParse(v) ?? _age),
          onNext: _nextStep,
        );
      case 2:
        return _Step3(
          goals: _goals,
          selectedGoal: _selectedGoal,
          onGoalSelected: (g) => setState(() => _selectedGoal = g),
          onRegister: _handleRegister,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Avanzar paso ──
  void _nextStep() {
    if (_step == 0 && !(_formKey1.currentState?.validate() ?? false)) return;
    if (_step == 1 && !(_formKey2.currentState?.validate() ?? false)) return;
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    }
  }

  // ── Retroceder paso ──
  void _previousStep() {
    if (_step > 0) setState(() => _step--);
  }

  // ── Enviar registro a Firebase ──
  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();

    final ok = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      goal: _selectedGoal,
      weight: _weight,
      height: _height,
      age: _age,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  auth.errorMessage ?? 'Error al registrarse',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    // Si ok → AuthWrapper redirige al MainScreen automáticamente
  }
}

// ─── Barra de progreso de pasos ───────────────────────────────
class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepProgressBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              gradient: active ? AppColors.primaryGradient : null,
              color: active ? null : AppColors.border,
              borderRadius: BorderRadius.circular(4),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 6,
                      )
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PASO 1 — Datos de cuenta
// ─────────────────────────────────────────────────────────────────
class _Step1 extends StatelessWidget {
  final TextEditingController nameCtrl, emailCtrl, passCtrl, passConfirmCtrl;
  final bool obscurePass, obscureConfirm;
  final GlobalKey<FormState> formKey;
  final VoidCallback onTogglePass, onToggleConfirm, onNext;

  const _Step1({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.passConfirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.formKey,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            AuthField(
              controller: nameCtrl,
              label: 'Nombre completo',
              hint: 'Juan García',
              icon: Icons.person_outline_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa tu nombre';
                if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            AuthField(
              controller: passCtrl,
              label: 'Contraseña',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePass,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20, color: AppColors.textMuted,
                ),
                onPressed: onTogglePass,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthField(
              controller: passConfirmCtrl,
              label: 'Confirmar contraseña',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20, color: AppColors.textMuted,
                ),
                onPressed: onToggleConfirm,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                if (v != passCtrl.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
            const SizedBox(height: 28),
            _StepButton(label: 'Siguiente →', onTap: onNext),
            const SizedBox(height: 20),
            _LoginPrompt(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PASO 2 — Medidas corporales
// ─────────────────────────────────────────────────────────────────
class _Step2 extends StatelessWidget {
  final double weight, height;
  final int age;
  final TextEditingController ageCtrl;
  final GlobalKey<FormState> formKey;
  final ValueChanged<double> onWeightChanged, onHeightChanged;
  final ValueChanged<String> onAgeChanged;
  final VoidCallback onNext;

  const _Step2({
    required this.weight,
    required this.height,
    required this.age,
    required this.ageCtrl,
    required this.formKey,
    required this.onWeightChanged,
    required this.onHeightChanged,
    required this.onAgeChanged,
    required this.onNext,
  });

  double get _imc {
    final h = height / 100;
    return weight / (h * h);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            // ── Peso ──
            DarkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('⚖️  Peso', style: AppTextStyles.labelMedium),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: weight.toStringAsFixed(1),
                            style: AppTextStyles.headingMedium.copyWith(
                                color: AppColors.primary),
                          ),
                          TextSpan(text: ' kg', style: AppTextStyles.caption),
                        ]),
                      ),
                    ],
                  ),
                  _ColoredSlider(
                    value: weight, min: 40, max: 150,
                    onChanged: onWeightChanged,
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('40 kg', style: AppTextStyles.caption),
                    Text('150 kg', style: AppTextStyles.caption),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ── Altura ──
            DarkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('📏  Altura', style: AppTextStyles.labelMedium),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: height.round().toString(),
                            style: AppTextStyles.headingMedium.copyWith(
                                color: AppColors.accentBlue),
                          ),
                          TextSpan(text: ' cm', style: AppTextStyles.caption),
                        ]),
                      ),
                    ],
                  ),
                  _ColoredSlider(
                    value: height, min: 140, max: 220,
                    color: AppColors.accentBlue,
                    onChanged: onHeightChanged,
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('140 cm', style: AppTextStyles.caption),
                    Text('220 cm', style: AppTextStyles.caption),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ── Edad ──
            TextFormField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.bodyLarge,
              cursorColor: AppColors.primary,
              onChanged: onAgeChanged,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 13 || n > 100) {
                  return 'Edad entre 13 y 100 años';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: '🎂  Edad',
                suffixText: 'años',
                suffixStyle: AppTextStyles.caption,
                filled: true,
                fillColor: AppColors.surface,
                labelStyle: AppTextStyles.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.error, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 14),
            // ── IMC en tiempo real ──
            _ImcCard(imc: _imc),
            const SizedBox(height: 28),
            _StepButton(label: 'Siguiente →', onTap: onNext),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ColoredSlider extends StatelessWidget {
  final double value, min, max;
  final Color color;
  final ValueChanged<double> onChanged;

  const _ColoredSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: color,
        inactiveTrackColor: AppColors.border,
        thumbColor: color,
        overlayColor: color.withOpacity(0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
      ),
      child: Slider(value: value, min: min, max: max, onChanged: onChanged),
    );
  }
}

class _ImcCard extends StatelessWidget {
  final double imc;
  const _ImcCard({required this.imc});

  String get _label {
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25) return 'Normal ✓';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  Color get _color {
    if (imc < 18.5) return AppColors.accentBlue;
    if (imc < 25) return AppColors.primary;
    if (imc < 30) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.monitor_heart_outlined, color: _color, size: 20),
          const SizedBox(width: 10),
          Text('Tu IMC: ', style: AppTextStyles.bodyMedium),
          Text(
            imc.toStringAsFixed(1),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _color),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PASO 3 — Objetivo de entrenamiento
// ─────────────────────────────────────────────────────────────────
class _Step3 extends StatelessWidget {
  final List<Map<String, dynamic>> goals;
  final String selectedGoal;
  final ValueChanged<String> onGoalSelected;
  final VoidCallback onRegister;

  const _Step3({
    required this.goals,
    required this.selectedGoal,
    required this.onGoalSelected,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final goal = goals[i];
              final isSelected = selectedGoal == goal['label'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onGoalSelected(goal['label']!);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF0F2318), Color(0xFF081A0E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.5)
                          : AppColors.border,
                      width: isSelected ? 1 : 0.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(
                            color: AppColors.primary.withOpacity(0.12),
                            blurRadius: 12)]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(goal['icon'] as IconData,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['label']!,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(goal['desc']!, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 13, color: AppColors.background),
                        )
                      else
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.border, width: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Consumer<AuthProvider>(
            builder: (_, auth, __) => _StepButton(
              label: auth.isLoading ? '' : '¡Comenzar mi viaje! 🚀',
              isLoading: auth.isLoading,
              onTap: auth.isLoading ? () {} : onRegister,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Botón de paso ─────────────────────────────────────────────
class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  const _StepButton({required this.label, required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppColors.primaryGradient,
          color: isLoading ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
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
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.primary,
                  ),
                )
              : Text(label, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.background, letterSpacing: 0.3,
                )),
        ),
      ),
    );
  }
}

// ─── Prompt de login ───────────────────────────────────────────
class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Center(
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '¿Ya tienes cuenta? ',
                style: AppTextStyles.bodyMedium,
              ),
              TextSpan(
                text: 'Inicia sesión',
                style: AppTextStyles.neonLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}