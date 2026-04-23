// lib/presentation/widgets/custom_bottom_nav.dart
// ──────────────────────────────────────────────────
// Barra de navegación inferior 100% personalizada.
// Características:
//   • Fondo oscuro con bordes superiores redondeados
//   • Sombra suave con glow verde en item activo
//   • Microanimación de escala al seleccionar
//   • Indicador de punto animado bajo el ícono activo
//   • Sin paquetes externos — solo Flutter puro
// ──────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// Modelo de cada ítem en la barra de navegación
class NavItem {
  final IconData icon;
  final IconData activeIcon; // ícono "filled" cuando está activo
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Lista de ítems de la barra inferior
const List<NavItem> navItems = [
  NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  NavItem(
    icon: Icons.fitness_center_outlined,
    activeIcon: Icons.fitness_center,
    label: 'Workouts',
  ),
  NavItem(
    icon: Icons.directions_bike_outlined,
    activeIcon: Icons.directions_bike_rounded,
    label: 'Spinning',
  ),
  NavItem(
    icon: Icons.restaurant_outlined,
    activeIcon: Icons.restaurant,
    label: 'Nutrition',
  ),
  NavItem(
    icon: Icons.group_outlined,
    activeIcon: Icons.group,
    label: 'Community',
  ),
  NavItem(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
  ),
];

// ─────────────────────────────────────────────────────
// Widget principal de la barra inferior
// ─────────────────────────────────────────────────────

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Sombra exterior con toque de verde
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              navItems.length,
              (index) => _NavBarItem(
                item: navItems[index],
                isActive: currentIndex == index,
                onTap: () {
                  // Vibración háptica sutil al cambiar de tab
                  HapticFeedback.lightImpact();
                  onTap(index);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Ítem individual animado
// ─────────────────────────────────────────────────────

class _NavBarItem extends StatefulWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Animación de rebote (escala: 1.0 → 1.25 → 1.0)
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Animación del glow (opacidad del halo)
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dispara la animación cuando este ítem se vuelve activo
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Contenedor del ícono con glow ──
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Halo de glow detrás del ícono activo
                    if (widget.isActive)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGlow,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                    // Ícono con animación de escala
                    Transform.scale(
                      scale: widget.isActive ? _scaleAnim.value : 1.0,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: child,
                        ),
                        child: Icon(
                          widget.isActive
                              ? widget.item.activeIcon
                              : widget.item.icon,
                          key: ValueKey(widget.isActive),
                          size: 24,
                          color: widget.isActive
                              ? AppColors.primary
                              : AppColors.navInactive,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // ── Label animado ──
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: widget.isActive
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: widget.isActive
                        ? AppColors.primary
                        : AppColors.navInactive,
                    letterSpacing: 0.2,
                  ),
                  child: Text(widget.item.label),
                ),

                const SizedBox(height: 4),

                // ── Indicador de punto activo ──
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: widget.isActive ? 20 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: widget.isActive
                        ? AppColors.primaryGradient
                        : null,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.6),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
