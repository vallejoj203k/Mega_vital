// lib/presentation/main_screen.dart
// ──────────────────────────────────────────────────────
// Pantalla contenedora principal.
// Usa IndexedStack para mantener el estado de cada
// pantalla al cambiar de tab (NO las reconstruye).
// ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/nav_provider.dart';
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

class _MainScreenState extends State<MainScreen> {
  static const List<Widget> _screens = [
    HomeScreen(),
    WorkoutsScreen(),
    SpinningScreen(),
    NutritionScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  bool _premiumInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_premiumInitialized) {
      final auth = context.read<AuthProvider>();
      final uid  = auth.firebaseUser?.uid ?? auth.profile?.uid;
      final created = auth.profile?.createdAt;
      if (uid != null && created != null) {
        _premiumInitialized = true;
        context.read<PremiumProvider>().checkStatus(uid, created);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-check premium when profile loads (it may not be available on first build)
    final auth    = context.watch<AuthProvider>();
    final premium = context.read<PremiumProvider>();
    if (!_premiumInitialized && !auth.profileLoading) {
      final uid     = auth.firebaseUser?.uid ?? auth.profile?.uid;
      final created = auth.profile?.createdAt;
      if (uid != null && created != null) {
        _premiumInitialized = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          premium.checkStatus(uid, created);
        });
      }
    }

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
