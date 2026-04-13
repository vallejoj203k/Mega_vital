// lib/presentation/screens/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../main_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: _buildChild(auth.status),
    );
  }

  Widget _buildChild(AuthStatus status) {
    switch (status) {
      case AuthStatus.initial:        return const _SplashScreen();
      case AuthStatus.authenticated:  return const MainScreen();
      case AuthStatus.unauthenticated: return const LoginScreen();
    }
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this)..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut).drive(Tween(begin: 0.5, end: 1.0));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn).drive(Tween(begin: 0.0, end: 1.0));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _fade.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 32, spreadRadius: 4)],
                  ),
                  child: const Icon(Icons.fitness_center_rounded, size: 48, color: AppColors.background),
                ),
                const SizedBox(height: 22),
                Text('Mega Vital', style: AppTextStyles.displayLarge.copyWith(color: AppColors.primary, letterSpacing: -1.5)),
                const SizedBox(height: 6),
                Text('Tu bienestar, tu poder.', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 40),
                SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary.withOpacity(0.6))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
