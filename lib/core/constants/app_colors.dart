// lib/core/constants/app_colors.dart
// ──────────────────────────────────────────
// Paleta de colores centralizada de Mega Vital.
// Cambia aquí para actualizar toda la app.
// ──────────────────────────────────────────

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Clase no instanciable

  // ── Fondos ────────────────────────────
  static const Color background     = Color(0xFF0A0A0A); // Negro principal
  static const Color surface        = Color(0xFF141414); // Tarjetas
  static const Color surfaceVariant = Color(0xFF1C1C1E); // Superficies secundarias
  static const Color navBackground  = Color(0xFF0D0D0D); // Bottom nav

  // ── Acento principal (neón verde) ─────
  static const Color primary        = Color(0xFF00FF87); // Verde neón
  static const Color primaryDim     = Color(0xFF00CC6A); // Verde menos intenso
  static const Color primaryGlow    = Color(0x3300FF87); // Glow translúcido

  // ── Acentos secundarios ───────────────
  static const Color accentBlue     = Color(0xFF4FC3F7); // Azul agua
  static const Color accentOrange   = Color(0xFFFF6B35); // Naranja energético
  static const Color accentPurple   = Color(0xFFBB86FC); // Púrpura suave

  // ── Texto ─────────────────────────────
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFFAAAAAA);
  static const Color textMuted      = Color(0xFF555555);

  // ── Iconos nav inactivos ──────────────
  static const Color navInactive    = Color(0xFF4A4A4A);

  // ── Bordes y divisores ────────────────
  static const Color border         = Color(0xFF2A2A2A);
  static const Color divider        = Color(0xFF1E1E1E);

  // ── Estados ───────────────────────────
  static const Color success        = Color(0xFF00FF87);
  static const Color warning        = Color(0xFFFFB020);
  static const Color error          = Color(0xFFCF6679);

  // ── Gradientes predefinidos ───────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00FF87), Color(0xFF00CC6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C1C1E), Color(0xFF141414)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient burnGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient waterGradient = LinearGradient(
    colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
