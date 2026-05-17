import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme_colors.dart';
import 'spinning_screen.dart';
import 'running_screen.dart';

class ActividadesScreen extends StatelessWidget {
  const ActividadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(tc)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ActivityCard(
                    title: 'Spinning',
                    subtitle: 'Ciclismo Indoor',
                    description:
                        'Sesiones de ciclismo de alta intensidad con instructores certificados. Elige tu bicicleta y reserva tu puesto.',
                    icon: Icons.directions_bike_rounded,
                    accentColor: AppColors.accentOrange,
                    gradient: AppColors.burnGradient,
                    features: const ['18 bicicletas', 'Keiser M3+', 'Monitor cardíaco'],
                    calRange: '400–800 kcal',
                    duration: '60 min',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SpinningScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActivityCard(
                    title: 'Running',
                    subtitle: 'Cardio en Trotadora',
                    description:
                        'Entrena en trotadoras profesionales con planes progresivos guiados. Reserva tu trotadora y corre a tu ritmo.',
                    icon: Icons.directions_run_rounded,
                    accentColor: AppColors.accentBlue,
                    gradient: LinearGradient(
                      colors: [AppColors.accentBlue, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    features: const ['6 trotadoras', 'NordicTrack X32i', 'Inclinación automática'],
                    calRange: '350–650 kcal',
                    duration: '45–60 min',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RunningScreen()),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeColors tc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentOrange.withOpacity(0.12), tc.background],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.burnGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentOrange.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Actividades',
                          style: AppTextStyles.displayMedium.copyWith(color: tc.textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.burnGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('PRO',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text('Elige tu actividad y reserva tu lugar',
                        style: AppTextStyles.bodySmall.copyWith(color: tc.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            _StatChip(
                icon: Icons.event_available_rounded,
                label: '2 actividades',
                color: AppColors.accentOrange),
            const SizedBox(width: 10),
            _StatChip(
                icon: Icons.verified_rounded,
                label: 'Instructores certificados',
                color: AppColors.accentBlue),
          ]),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color accentColor;
  final Gradient gradient;
  final List<String> features;
  final String calRange;
  final String duration;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.gradient,
    required this.features,
    required this.calRange,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
                color: accentColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 6)),
            BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(children: [
          // Hero
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor.withOpacity(0.35), tc.surface],
                  ),
                ),
                child: Stack(children: [
                  Positioned(
                    right: -24,
                    top: -24,
                    child: Icon(icon, size: 180, color: accentColor.withOpacity(0.08)),
                  ),
                  Center(child: Icon(icon, size: 72, color: accentColor.withOpacity(0.5))),
                ]),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, tc.surface.withOpacity(0.9)],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 8)
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 12, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5)),
                  ]),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: accentColor, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(description,
                  style: TextStyle(fontSize: 12, color: tc.textSecondary, height: 1.5)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: features
                    .map((f) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: accentColor.withOpacity(0.25), width: 0.5),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_circle_outline_rounded,
                                size: 10, color: accentColor),
                            const SizedBox(width: 4),
                            Text(f,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor)),
                          ]),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Container(height: 0.5, color: tc.border),
              const SizedBox(height: 10),
              Row(children: [
                _InfoPill(
                    icon: Icons.local_fire_department_rounded,
                    label: calRange,
                    color: AppColors.accentOrange),
                const SizedBox(width: 8),
                _InfoPill(
                    icon: Icons.timer_rounded,
                    label: duration,
                    color: AppColors.accentPurple),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: accentColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Ver clases',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: Colors.white),
                  ]),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}
