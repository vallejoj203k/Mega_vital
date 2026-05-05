import 'package:flutter/material.dart';

/// Colores que cambian entre modo claro y oscuro.
/// Se accede desde cualquier widget via: context.colors
@immutable
class DynamicColors extends ThemeExtension<DynamicColors> {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color navBackground;

  const DynamicColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.navBackground,
  });

  static const dark = DynamicColors(
    background:    Color(0xFF0A0A0A),
    surface:       Color(0xFF141414),
    surfaceVariant:Color(0xFF1C1C1E),
    border:        Color(0xFF2A2A2A),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0xFFAAAAAA),
    textMuted:     Color(0xFF555555),
    navBackground: Color(0xFF0D0D0D),
  );

  static const light = DynamicColors(
    background:    Color(0xFFF4F4F6),
    surface:       Color(0xFFFFFFFF),
    surfaceVariant:Color(0xFFEEEEEF),
    border:        Color(0xFFE0E0E0),
    textPrimary:   Color(0xFF0D0D0D),
    textSecondary: Color(0xFF666666),
    textMuted:     Color(0xFF999999),
    navBackground: Color(0xFFFFFFFF),
  );

  @override
  DynamicColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? navBackground,
  }) => DynamicColors(
    background:     background     ?? this.background,
    surface:        surface        ?? this.surface,
    surfaceVariant: surfaceVariant ?? this.surfaceVariant,
    border:         border         ?? this.border,
    textPrimary:    textPrimary    ?? this.textPrimary,
    textSecondary:  textSecondary  ?? this.textSecondary,
    textMuted:      textMuted      ?? this.textMuted,
    navBackground:  navBackground  ?? this.navBackground,
  );

  @override
  DynamicColors lerp(DynamicColors? other, double t) {
    if (other == null) return this;
    return DynamicColors(
      background:     Color.lerp(background,     other.background,     t)!,
      surface:        Color.lerp(surface,        other.surface,        t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border:         Color.lerp(border,         other.border,         t)!,
      textPrimary:    Color.lerp(textPrimary,    other.textPrimary,    t)!,
      textSecondary:  Color.lerp(textSecondary,  other.textSecondary,  t)!,
      textMuted:      Color.lerp(textMuted,      other.textMuted,      t)!,
      navBackground:  Color.lerp(navBackground,  other.navBackground,  t)!,
    );
  }
}

extension DynamicColorsX on BuildContext {
  DynamicColors get colors => Theme.of(this).extension<DynamicColors>()!;
}
