// lib/presentation/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _obscure     = true;
  bool _emailTouched = false;
  bool _passTouched  = false;

  late AnimationController _ctrl;
  late List<Animation<Offset>> _slides;
  late List<Animation<double>>  _fades;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this)..forward();
    _slides = List.generate(5, (i) {
      final s = i * 0.12, e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(CurvedAnimation(parent: _ctrl, curve: Interval(s, e, curve: Curves.easeOutCubic)));
    });
    _fades = List.generate(5, (i) {
      final s = i * 0.12, e = (s + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: _ctrl, curve: Interval(s, e)));
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 40),
              _Anim(slide: _slides[0], fade: _fades[0], child: _Logo()),
              const SizedBox(height: 36),
              _Anim(slide: _slides[1], fade: _fades[1], child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bienvenido', style: AppTextStyles.displayMedium),
                const SizedBox(height: 6),
                Text('Inicia sesión para continuar tu entrenamiento', style: AppTextStyles.bodyMedium),
              ])),
              const SizedBox(height: 36),
              _Anim(slide: _slides[2], fade: _fades[2], child: AuthField(
                controller: _emailCtrl, label: 'Correo electrónico', hint: 'tu@correo.com',
                icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                onChanged: (_) { if (!_emailTouched) setState(() => _emailTouched = true); context.read<AuthProvider>().clearError(); },
                validator: (v) { if (!_emailTouched) return null; if (v == null || v.trim().isEmpty) return 'Ingresa tu correo'; if (!RegExp(r'^[\w.]+@[\w]+\.\w+$').hasMatch(v.trim())) return 'Formato inválido'; return null; },
              )),
              const SizedBox(height: 14),
              _Anim(slide: _slides[3], fade: _fades[3], child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                AuthField(
                  controller: _passCtrl, label: 'Contraseña', hint: '••••••••',
                  icon: Icons.lock_outline_rounded, obscureText: _obscure,
                  onChanged: (_) { if (!_passTouched) setState(() => _passTouched = true); context.read<AuthProvider>().clearError(); },
                  validator: (v) { if (!_passTouched) return null; if (v == null || v.isEmpty) return 'Ingresa tu contraseña'; if (v.length < 6) return 'Mínimo 6 caracteres'; return null; },
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppColors.textMuted), onPressed: () => setState(() => _obscure = !_obscure)),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  child: Text('¿Olvidaste tu contraseña?', style: AppTextStyles.neonLabel.copyWith(fontSize: 13)),
                ),
              ])),
              const SizedBox(height: 28),
              _Anim(slide: _slides[4], fade: _fades[4], child: _LoginButton(onTap: _handleLogin)),
              const SizedBox(height: 20),
              _Anim(slide: _slides[4], fade: _fades[4], child: const _OrDivider()),
              const SizedBox(height: 20),
              _Anim(slide: _slides[4], fade: _fades[4], child: _RegisterPrompt(onTap: _goToRegister)),
              const SizedBox(height: 40),
            ])),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() { _emailTouched = true; _passTouched = true; });
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(email: _emailCtrl.text, password: _passCtrl.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18), const SizedBox(width: 10), Expanded(child: Text(auth.errorMessage ?? 'Error al iniciar sesión', style: AppTextStyles.bodyMedium))]),
        backgroundColor: AppColors.surface, behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _goToRegister() => Navigator.push(context, PageRouteBuilder(
    pageBuilder: (_, a1, a2) => const RegisterScreen(),
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ));
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 52, height: 52,
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]),
        child: const Icon(Icons.fitness_center_rounded, size: 26, color: AppColors.background),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Mega Vital', style: AppTextStyles.headingLarge.copyWith(color: AppColors.primary, letterSpacing: -0.5)),
        Text('Gym Tracker', style: AppTextStyles.caption),
      ]),
    ]);
  }
}

// ── AuthField (público para usar en register y forgot) ────────
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  const AuthField({super.key, required this.controller, required this.label,
    required this.hint, required this.icon, this.obscureText = false,
    this.keyboardType, this.validator, this.onChanged, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, obscureText: obscureText,
      keyboardType: keyboardType, validator: validator, onChanged: onChanged,
      style: AppTextStyles.bodyLarge, cursorColor: AppColors.primary,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: AppTextStyles.bodyMedium,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
        suffixIcon: suffixIcon, filled: true, fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LoginButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (_, auth, __) => GestureDetector(
      onTap: auth.isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          gradient: auth.isLoading ? null : AppColors.primaryGradient,
          color: auth.isLoading ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: auth.isLoading ? null : [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(child: auth.isLoading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary))
          : const Text('Iniciar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.background, letterSpacing: 0.3))),
      ),
    ));
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Divider(color: AppColors.border, height: 1)),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('o', style: AppTextStyles.bodyMedium)),
    Expanded(child: Divider(color: AppColors.border, height: 1)),
  ]);
}

class _RegisterPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _RegisterPrompt({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: double.infinity, height: 54,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Center(child: RichText(text: TextSpan(children: [
        TextSpan(text: '¿No tienes cuenta? ', style: AppTextStyles.bodyMedium),
        TextSpan(text: 'Regístrate', style: AppTextStyles.neonLabel),
      ]))),
    ),
  );
}

class _Anim extends StatelessWidget {
  final Animation<Offset> slide;
  final Animation<double> fade;
  final Widget child;
  const _Anim({required this.slide, required this.fade, required this.child});
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
}
