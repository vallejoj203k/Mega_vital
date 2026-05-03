// lib/presentation/main_screen.dart
// ──────────────────────────────────────────────────────
// Pantalla contenedora principal.
// Usa IndexedStack para mantener el estado de cada
// pantalla al cambiar de tab (NO las reconstruye).
// ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/nav_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/premium_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/workouts/workouts_screen.dart';
import 'screens/nutrition/nutrition_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/spinning/spinning_screen.dart';
import 'widgets/custom_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const List<Widget> _screens = [
    HomeScreen(),
    WorkoutsScreen(),
    SpinningScreen(),
    NutritionScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-verifica el estado premium cada vez que la app vuelve al primer plano.
  // Si la suscripción venció mientras la app estaba en background, el provider
  // actualizará el estado a expired y los widgets bloqueados se reactivarán.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final auth = context.read<AuthProvider>();
      if (auth.firebaseUser != null && auth.profile != null) {
        context.read<PremiumProvider>().checkStatus(
          auth.firebaseUser!.uid,
          auth.profile!.createdAt,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: nav.index,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: nav.index,
        onTap: context.read<NavProvider>().goTo,
      ),
    );
  }
}
