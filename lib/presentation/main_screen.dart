// lib/presentation/main_screen.dart
// ──────────────────────────────────────────────────────
// Pantalla contenedora principal.
// Usa IndexedStack para mantener el estado de cada
// pantalla al cambiar de tab (NO las reconstruye).
// ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/nav_provider.dart';
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

class _MainScreenState extends State<MainScreen> {
  static const List<Widget> _screens = [
    HomeScreen(),
    WorkoutsScreen(),
    SpinningScreen(),
    NutritionScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

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
