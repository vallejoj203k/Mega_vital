// lib/presentation/main_screen.dart
// ──────────────────────────────────────────────────────
// Pantalla contenedora principal.
// Usa IndexedStack para mantener el estado de cada
// pantalla al cambiar de tab (NO las reconstruye).
// ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';
import 'screens/workouts/workouts_screen.dart';
import 'screens/nutrition/nutrition_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'widgets/custom_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Las 5 pantallas — se crean una vez y se conservan
  static const List<Widget> _screens = [
    HomeScreen(),
    WorkoutsScreen(),
    NutritionScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    if (index == _currentIndex) return; // Evita rebuild innecesario
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sin fondo propio — cada pantalla define el suyo
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        // IndexedStack mantiene el estado de TODAS las pantallas
        // activas simultáneamente (no las destruye al cambiar de tab)
        index: _currentIndex,
        children: _screens,
      ),
      // Eliminamos el bottomNavigationBar de Scaffold y usamos
      // Stack para tener control total del posicionamiento
      extendBody: true,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
