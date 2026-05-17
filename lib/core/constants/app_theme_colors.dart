// lib/core/constants/app_theme_colors.dart
// ──────────────────────────────────────────
// ThemeExtension que provee colores dinámicos
// que cambian entre modo claro y oscuro.
// Los colores de acento (primary, neon, etc.)
// NO están aquí — siguen viviendo en AppColors.
// ──────────────────────────────────────────

import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.navBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.navInactive,
    required this.border,
    required this.divider,
    required this.cardGradientStart,
    required this.cardGradientEnd,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color navBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color navInactive;
  final Color border;
  final Color divider;
  final Color cardGradientStart;
  final Color cardGradientEnd;

  // ── Gradiente de tarjeta dinámico ────────────────────────────
  LinearGradient get cardGradient => LinearGradient(
        colors: [cardGradientStart, cardGradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ── Acceso conveniente desde cualquier widget ────────────────
  static AppThemeColors of(BuildContext context) =>
      Theme.of(context).extension<AppThemeColors>()!;

  // ── Tema oscuro (valores originales de AppColors) ────────────
  factory AppThemeColors.dark() => const AppThemeColors(
        background: Color(0xFF0A0A0A),
        surface: Color(0xFF141414),
        surfaceVariant: Color(0xFF1C1C1E),
        navBackground: Color(0xFF0D0D0D),
        textPrimary: Color(0xFFFFFFFF),
        textSecondary: Color(0xFFAAAAAA),
        textMuted: Color(0xFF555555),
        navInactive: Color(0xFF4A4A4A),
        border: Color(0xFF2A2A2A),
        divider: Color(0xFF1E1E1E),
        cardGradientStart: Color(0xFF1C1C1E),
        cardGradientEnd: Color(0xFF141414),
      );

  // ── Tema claro ───────────────────────────────────────────────
  factory AppThemeColors.light() => const AppThemeColors(
        background: Color(0xFFF2F2F7),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFEEEEF4),
        navBackground: Color(0xFF1C1C1E),
        textPrimary: Color(0xFF0A0A0A),
        textSecondary: Color(0xFF666666),
        textMuted: Color(0xFF999999),
        navInactive: Color(0xFF636366),
        border: Color(0xFFE0E0E0),
        divider: Color(0xFFEEEEEE),
        cardGradientStart: Color(0xFFFFFFFF),
        cardGradientEnd: Color(0xFFF5F5FA),
      );

  // ── ThemeExtension overrides ─────────────────────────────────
  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? navBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? navInactive,
    Color? border,
    Color? divider,
    Color? cardGradientStart,
    Color? cardGradientEnd,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      navBackground: navBackground ?? this.navBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      navInactive: navInactive ?? this.navInactive,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      cardGradientStart: cardGradientStart ?? this.cardGradientStart,
      cardGradientEnd: cardGradientEnd ?? this.cardGradientEnd,
    );
  }

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      cardGradientStart:
          Color.lerp(cardGradientStart, other.cardGradientStart, t)!,
      cardGradientEnd: Color.lerp(cardGradientEnd, other.cardGradientEnd, t)!,
    );
  }
}
