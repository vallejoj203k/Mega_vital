// lib/presentation/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

// ─── Tarjeta oscura base ─────────────────────────────────────
class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Gradient? gradient;
  final Color? borderColor;

  const DarkCard({super.key, required this.child, this.padding, this.onTap,
    this.borderRadius = 16, this.gradient, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.cardGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor ?? AppColors.border, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: child,
      ),
    );
  }
}

// ─── Barra de progreso neón ──────────────────────────────────
class NeonProgressBar extends StatelessWidget {
  final double progress;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double height;
  final bool showGlow;

  const NeonProgressBar({super.key, required this.progress, this.gradient,
    this.backgroundColor, this.height = 6, this.showGlow = true});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(children: [
        Container(height: height, decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.border,
          borderRadius: BorderRadius.circular(height),
        )),
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          height: height,
          width: constraints.maxWidth * progress.clamp(0.0, 1.0),
          decoration: BoxDecoration(
            gradient: gradient ?? const LinearGradient(colors: [Color(0xFF00FF87), Color(0xFF00CC6A)]),
            borderRadius: BorderRadius.circular(height),
            boxShadow: showGlow ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 6)] : null,
          ),
        ),
      ]);
    });
  }
}

// ─── Chip de dificultad ──────────────────────────────────────
class DifficultyChip extends StatelessWidget {
  final String difficulty;
  const DifficultyChip({super.key, required this.difficulty});

  Color get _color {
    switch (difficulty) {
      case 'Fácil': return AppColors.primary;
      case 'Medio': return AppColors.accentBlue;
      case 'Difícil': return AppColors.accentOrange;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(difficulty, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color)),
    );
  }
}

// ─── Header de sección ───────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headingMedium),
        if (actionLabel != null)
          GestureDetector(onTap: onAction,
            child: Text(actionLabel!, style: AppTextStyles.neonLabel)),
      ],
    );
  }
}

// ─── Avatar circular con foto o iniciales ───────────────────
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? bgColor;
  final String? photoUrl;
  const InitialsAvatar({super.key, required this.initials, this.size = 44, this.bgColor, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: (!hasPhoto && bgColor == null) ? AppColors.primaryGradient : null,
        color: !hasPhoto ? bgColor : null,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasPhoto
          ? Image.network(
              photoUrl!,
              width: size, height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _initials() => Text(initials, style: TextStyle(
    fontSize: size * 0.36, fontWeight: FontWeight.w700,
    color: AppColors.background, letterSpacing: 0.5,
  ));
}

// ─── Botón neón ──────────────────────────────────────────────
class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool fullWidth;
  const NeonButton({super.key, required this.label, this.onTap, this.icon, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: AppColors.background), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.background, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}

// ─── Badge de racha ──────────────────────────────────────────
class StreakBadge extends StatelessWidget {
  final int days;
  const StreakBadge({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: AppColors.burnGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.accentOrange.withOpacity(0.3), blurRadius: 8)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text('$days días', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
    );
  }
}

// ─── Icono en caja ───────────────────────────────────────────
class BoxedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const BoxedIcon({super.key, required this.icon, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}
