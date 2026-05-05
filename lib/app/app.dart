// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/dynamic_colors.dart';
import '../core/providers/nav_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/community_provider.dart';
import '../core/providers/follow_provider.dart';
import '../core/providers/notification_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../core/providers/workout_log_provider.dart';
import '../core/providers/stories_provider.dart';
import '../core/providers/challenges_provider.dart';
import '../core/providers/premium_provider.dart';
import '../core/providers/weight_provider.dart';
import '../core/providers/theme_provider.dart';
import '../presentation/screens/auth/auth_wrapper.dart';

ThemeData _buildTheme({required DynamicColors colors, required Brightness brightness}) {
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.accentBlue,
      surface: colors.surface,
      error: AppColors.error,
      onPrimary: colors.background,
      onSecondary: colors.background,
      onSurface: colors.textPrimary,
      onError: Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge:  TextStyle(color: colors.textPrimary),
      displayMedium: TextStyle(color: colors.textPrimary),
      displaySmall:  TextStyle(color: colors.textPrimary),
      headlineLarge: TextStyle(color: colors.textPrimary),
      headlineMedium:TextStyle(color: colors.textPrimary),
      headlineSmall: TextStyle(color: colors.textPrimary),
      titleLarge:    TextStyle(color: colors.textPrimary),
      titleMedium:   TextStyle(color: colors.textSecondary),
      titleSmall:    TextStyle(color: colors.textSecondary),
      bodyLarge:     TextStyle(color: colors.textPrimary),
      bodyMedium:    TextStyle(color: colors.textSecondary),
      bodySmall:     TextStyle(color: colors.textMuted),
      labelLarge:    TextStyle(color: colors.textPrimary),
      labelMedium:   TextStyle(color: colors.textSecondary),
      labelSmall:    TextStyle(color: colors.textMuted),
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: colors.textPrimary),
    ),
    dividerTheme: DividerThemeData(
      color: colors.border,
      thickness: 0.5,
    ),
    extensions: [colors],
    useMaterial3: true,
  );
}

final _darkTheme  = _buildTheme(colors: DynamicColors.dark,  brightness: Brightness.dark);
final _lightTheme = _buildTheme(colors: DynamicColors.light, brightness: Brightness.light);

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
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
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) {
          final isLight = !themeProvider.isDark;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
            systemNavigationBarColor:
                isLight ? DynamicColors.light.navBackground : DynamicColors.dark.navBackground,
            systemNavigationBarIconBrightness:
                isLight ? Brightness.dark : Brightness.light,
          ));
          return MaterialApp(
            title: 'Mega Vital',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.mode,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
