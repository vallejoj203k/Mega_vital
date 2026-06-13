// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_theme_colors.dart';
import '../core/providers/nav_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/community_provider.dart';
import '../core/providers/follow_provider.dart';
import '../core/providers/notification_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../core/providers/workout_log_provider.dart';
import '../core/providers/stories_provider.dart';
import '../core/providers/challenges_provider.dart';
import '../core/providers/exercise_provider.dart';
import '../core/providers/premium_provider.dart';
import '../core/providers/weight_provider.dart';
import '../core/providers/theme_provider.dart';
import '../services/api_key_manager.dart';
import '../presentation/screens/auth/auth_wrapper.dart';

final _darkTheme = ThemeData(
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
  extensions: [AppThemeColors.dark()],
  useMaterial3: true,
);

final _lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF2F2F7),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF00AA5B),
    secondary: Color(0xFF0288D1),
    surface: Color(0xFFFFFFFF),
    error: Color(0xFFB00020),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF0A0A0A),
  ),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(color: Color(0xFF0A0A0A)),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFFE0E0E0),
    thickness: 0.5,
  ),
  extensions: [AppThemeColors.light()],
  useMaterial3: true,
);

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()..init()),
        ChangeNotifierProvider(create: (_) => WorkoutLogProvider()..init()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => StoriesProvider()),
        ChangeNotifierProvider(create: (_) => FollowProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ChallengesProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ChangeNotifierProvider(create: (_) => WeightProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final isDark = themeProvider.isDark;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor:
                isDark ? AppColors.navBackground : const Color(0xFF1C1C1E),
            systemNavigationBarIconBrightness: Brightness.light,
          ));
          return MaterialApp(
            title: 'Mega Vital',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
