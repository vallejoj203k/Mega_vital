// lib/core/constants/app_text_styles.dart
// ────────────────────────────────────────
// Tipografía centralizada. Usa la fuente del
// sistema para máxima compatibilidad sin assets.
// ────────────────────────────────────────

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display ───────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // ── Headings ──────────────────────────
  static const TextStyle headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ──────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // ── Labels ────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  // ── Especiales ────────────────────────
  static const TextStyle neonLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 0.5,
  );

  static const TextStyle statNumber = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.0,
  );

  static const TextStyle statUnit = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 0.3,
  );

  // ── Context-aware variants (use these in widgets when possible) ──

  static TextStyle displayLargeOf(BuildContext context) => displayLarge.copyWith(
        color: AppThemeColors.of(context).textPrimary);

  static TextStyle displayMediumOf(BuildContext context) => displayMedium.copyWith(
        color: AppThemeColors.of(context).textPrimary);

  static TextStyle headingLargeOf(BuildContext context) => headingLarge.copyWith(
        color: AppThemeColors.of(context).textPrimary);

  static TextStyle headingMediumOf(BuildContext context) => headingMedium.copyWith(
        color: AppThemeColors.of(context).textPrimary);

  static TextStyle headingSmallOf(BuildContext context) => headingSmall.copyWith(
        color: AppThemeColors.of(context).textPrimary);

  static TextStyle bodyLargeOf(BuildContext context) => bodyLarge.copyWith(
        color: AppThemeColors.of(context).textPrimary);

  static TextStyle bodyMediumOf(BuildContext context) => bodyMedium.copyWith(
        color: AppThemeColors.of(context).textSecondary);

  static TextStyle bodySmallOf(BuildContext context) => bodySmall.copyWith(
        color: AppThemeColors.of(context).textMuted);

  static TextStyle labelLargeOf(BuildContext context) => labelLarge.copyWith(
        color: AppThemeColors.of(context).textPrimary);

  static TextStyle labelMediumOf(BuildContext context) => labelMedium.copyWith(
        color: AppThemeColors.of(context).textSecondary);

  static TextStyle statNumberOf(BuildContext context) => statNumber.copyWith(
        color: AppThemeColors.of(context).textPrimary);

  static TextStyle statUnitOf(BuildContext context) => statUnit.copyWith(
        color: AppThemeColors.of(context).textSecondary);

  static TextStyle captionOf(BuildContext context) => caption.copyWith(
        color: AppThemeColors.of(context).textMuted);
}
