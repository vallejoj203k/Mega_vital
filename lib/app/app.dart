// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/nav_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/community_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../core/providers/workout_log_provider.dart';
import '../core/providers/stories_provider.dart';
import '../services/api_key_manager.dart';
import '../presentation/screens/auth/auth_wrapper.dart';

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.navBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // NutritionProvider carga el día actual al inicializarse
        ChangeNotifierProvider(create: (_) => NutritionProvider()..init()),
        // WorkoutLogProvider carga historial y pesos guardados
        ChangeNotifierProvider(create: (_) => WorkoutLogProvider()..init()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => StoriesProvider()),
      ],
      child: MaterialApp(
        title: 'Mega Vital',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.accentBlue,
            surface: AppColors.surface,
            error: AppColors.error,
            onPrimary: AppColors.background,
            onSecondary: AppColors.background,
            onSurface: AppColors.textPrimary,
          ),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
          ),
          dividerTheme: const DividerThemeData(
            color: AppColors.divider,
            thickness: 0.5,
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
