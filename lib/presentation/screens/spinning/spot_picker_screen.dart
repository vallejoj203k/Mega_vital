import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/class_provider.dart';
import '../../../services/class_schedule_service.dart';

// Pantalla de selección de puesto (bicicleta o trotadora) para una sesión.
// Al elegir un puesto libre se pide confirmación (no se puede cambiar después)
// y se hace la reserva. Devuelve por Navigator.pop el resultado ('ok', etc.).
class SpotPickerScreen extends StatefulWidget {
  final ClassSession session;
  final Color accentColor;

  const SpotPickerScreen({
    super.key,
    required this.session,
    required this.accentColor,
  });

  @override
  State<SpotPickerScreen> createState() => _SpotPickerScreenState();
}

class _SpotPickerScreenState extends State<SpotPickerScreen> {
  bool _busy = false;

  bool get _isSpinning => widget.session.activity == 'spinning';
  String get _spotLabel => _isSpinning ? 'bicicleta' : 'trotadora';
  IconData get _spotIcon =>
      _isSpinning ? Icons.directions_bike_rounded : Icons.directions_run_rounded;

  Future<void> _onSpotTap(int spot) async {
    if (_busy || widget.session.takenSeats.contains(spot)) return;
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tc = AppThemeColors.of(ctx);
        return AlertDialog(
          backgroundColor: tc.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(_spotIcon, color: widget.accentColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text('¿Confirmar puesto $spot?',
                  style: AppTextStyles.headingSmall.copyWith(color: tc.textPrimary)),
            ),
          ]),
          content: Text(
            'Vas a reservar la $_spotLabel #$spot para "${widget.session.scheduleName}".\n\n'
            'Una vez confirmada la reserva NO podrás cambiar de lugar.',
            style: AppTextStyles.bodyMedium.copyWith(color: tc.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: TextStyle(color: tc.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Reservar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final profile = context.read<AuthProvider>().profile;
    final name = profile?.name ?? 'Usuario';
    final result = await context
        .read<ClassProvider>()
        .bookSession(widget.session.id, name, seatIndex: spot);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final s = widget.session;
    final time =
        '${s.startsAt.hour.toString().padLeft(2, '0')}:${s.startsAt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Column(children: [
          // ── Header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: tc.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Elige tu $_spotLabel',
                          style: AppTextStyles.headingMedium
                              .copyWith(color: tc.textPrimary)),
                      Text('${s.scheduleName} · $time',
                          style: AppTextStyles.caption
                              .copyWith(color: tc.textSecondary)),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: widget.accentColor.withOpacity(0.35)),
                ),
                child: Text('${s.availableSpots} libres',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: widget.accentColor)),
              ),
            ]),
          ),
          const SizedBox(height: 10),

          // ── Leyenda ────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _LegendDot(color: widget.accentColor, label: 'Disponible'),
            const SizedBox(width: 18),
            _LegendDot(color: tc.textMuted, label: 'Ocupado'),
          ]),
          const SizedBox(height: 12),

          // ── Grid de puestos ────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemCount: s.capacity,
              itemBuilder: (_, i) {
                final spot = i + 1;
                final taken = s.takenSeats.contains(spot);
                return GestureDetector(
                  onTap: taken ? null : () => _onSpotTap(spot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: taken
                          ? tc.surface.withOpacity(0.5)
                          : widget.accentColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: taken
                            ? tc.border
                            : widget.accentColor.withOpacity(0.5),
                        width: taken ? 0.5 : 1.2,
                      ),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_spotIcon,
                              size: 26,
                              color: taken
                                  ? tc.textMuted.withOpacity(0.5)
                                  : widget.accentColor),
                          const SizedBox(height: 6),
                          Text('$spot',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: taken
                                      ? tc.textMuted.withOpacity(0.6)
                                      : tc.textPrimary)),
                          if (taken)
                            Text('Ocupado',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: tc.textMuted.withOpacity(0.7))),
                        ]),
                  ),
                );
              },
            ),
          ),

          if (_busy)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: CircularProgressIndicator(color: widget.accentColor),
            ),
        ]),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: color.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: AppTextStyles.caption.copyWith(color: tc.textSecondary)),
    ]);
  }
}
