import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme_colors.dart';
import 'running_screen.dart';

class TreadmillSelectionScreen extends StatefulWidget {
  final RunClass runClass;
  final int? currentSpot;

  const TreadmillSelectionScreen(
      {super.key, required this.runClass, this.currentSpot});

  @override
  State<TreadmillSelectionScreen> createState() =>
      _TreadmillSelectionScreenState();
}

class _TreadmillSelectionScreenState extends State<TreadmillSelectionScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedSpot;
  late AnimationController _confirmAnim;
  late Animation<double> _scaleAnim;

  static const int cols = 2;
  static const int rows = 3;

  @override
  void initState() {
    super.initState();
    _selectedSpot = widget.currentSpot;
    _confirmAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _confirmAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _confirmAnim.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.runClass.level) {
      case RunLevel.basico:      return AppColors.primary;
      case RunLevel.intermedio:  return AppColors.accentBlue;
      case RunLevel.avanzado:    return AppColors.accentPurple;
    }
  }

  void _onSpotTap(int index) {
    final isMySpot = index == widget.currentSpot;
    if (widget.runClass.reservedSeats.contains(index) && !isMySpot) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedSpot = _selectedSpot == index ? null : index);
  }

  void _confirmBooking() async {
    if (_selectedSpot == null) return;
    HapticFeedback.mediumImpact();
    await _confirmAnim.forward();
    await _confirmAnim.reverse();
    if (mounted) Navigator.pop(context, _selectedSpot);
  }

  String _rowLabel(int row) => String.fromCharCode('A'.codeUnitAt(0) + row);

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Column(children: [
          _buildAppBar(context, tc),
          _buildClassInfo(tc),
          const SizedBox(height: 8),
          _buildLegend(tc),
          const SizedBox(height: 20),
          _buildInstructorZone(tc),
          const SizedBox(height: 16),
          Expanded(child: _buildTreadmillGrid(tc)),
          _buildBottomBar(tc),
        ]),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: tc.textPrimary, size: 20),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              widget.currentSpot != null
                  ? 'Cambiar trotadora'
                  : 'Elegir Trotadora',
              style: AppTextStyles.headingMedium.copyWith(color: tc.textPrimary),
            ),
            Text(widget.runClass.name,
                style: TextStyle(fontSize: 12, color: tc.textSecondary)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accentColor.withOpacity(0.4), width: 1),
          ),
          child: Text(widget.runClass.time,
              style: TextStyle(
                  fontSize: 12,
                  color: _accentColor,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _buildClassInfo(AppThemeColors tc) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.border, width: 0.5),
      ),
      child: Row(children: [
        _InfoItem(
          icon: Icons.directions_run_rounded,
          label: 'Disponibles',
          value: '${widget.runClass.availableSpots}',
          color: widget.runClass.availableSpots > 2
              ? AppColors.primary
              : AppColors.warning,
          muted: tc.textMuted,
        ),
        _Divider(color: tc.border),
        _InfoItem(
          icon: Icons.local_fire_department_rounded,
          label: 'Calorías',
          value: '${widget.runClass.caloriesMin}–${widget.runClass.caloriesMax}',
          color: AppColors.accentOrange,
          muted: tc.textMuted,
        ),
        _Divider(color: tc.border),
        _InfoItem(
          icon: Icons.timer_rounded,
          label: 'Duración',
          value: '${widget.runClass.durationMinutes}m',
          color: AppColors.accentBlue,
          muted: tc.textMuted,
        ),
        _Divider(color: tc.border),
        _InfoItem(
          icon: Icons.calendar_today_rounded,
          label: 'Días',
          value: widget.runClass.days.split('·').length.toString() == '1'
              ? widget.runClass.days.trim()
              : '${widget.runClass.days.split('·').length} días',
          color: AppColors.accentPurple,
          muted: tc.textMuted,
        ),
      ]),
    );
  }

  Widget _buildLegend(AppThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 6,
        children: [
          _LegendItem(
              color: tc.surface,
              border: _accentColor,
              label: 'Disponible',
              secondary: tc.textSecondary),
          _LegendItem(
              color: _accentColor,
              border: _accentColor,
              label: 'Seleccionado',
              secondary: tc.textSecondary),
          _LegendItem(
              color: tc.border,
              border: tc.border,
              label: 'Ocupado',
              secondary: tc.textSecondary),
          if (widget.currentSpot != null)
            _LegendItem(
              color: _accentColor.withOpacity(0.2),
              border: _accentColor,
              label: 'Tu lugar actual',
              secondary: tc.textSecondary,
              icon: Icons.person_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildInstructorZone(AppThemeColors tc) {
    return Column(children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 60),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            _accentColor.withOpacity(0.3),
            _accentColor.withOpacity(0.1)
          ]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accentColor.withOpacity(0.5), width: 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.directions_run_rounded, color: _accentColor, size: 18),
          const SizedBox(width: 8),
          Text('INSTRUCTOR',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _accentColor,
                  letterSpacing: 2)),
        ]),
      ),
      const SizedBox(height: 8),
      Icon(Icons.keyboard_arrow_down_rounded, color: tc.textMuted, size: 20),
    ]);
  }

  Widget _buildTreadmillGrid(AppThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: List.generate(rows, (row) {
          return Expanded(
            child: Row(children: [
              SizedBox(
                width: 24,
                child: Text(_rowLabel(row),
                    style: TextStyle(
                        fontSize: 12,
                        color: tc.textMuted,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(width: 8),
              ...List.generate(cols, (col) {
                final index = row * cols + col;
                final isMySpot = index == widget.currentSpot;
                final isOccupied =
                    widget.runClass.reservedSeats.contains(index) && !isMySpot;
                final isSelected = _selectedSpot == index;

                Color bgColor, borderColor, iconColor, textColor;
                IconData iconData;

                if (isOccupied) {
                  bgColor = tc.border;
                  borderColor = tc.border;
                  iconColor = tc.textMuted;
                  textColor = tc.textMuted;
                  iconData = Icons.close_rounded;
                } else if (isSelected) {
                  bgColor = _accentColor;
                  borderColor = _accentColor;
                  iconColor = Colors.white;
                  textColor = Colors.white;
                  iconData = isMySpot
                      ? Icons.person_rounded
                      : Icons.directions_run_rounded;
                } else if (isMySpot) {
                  bgColor = _accentColor.withOpacity(0.2);
                  borderColor = _accentColor;
                  iconColor = _accentColor;
                  textColor = _accentColor;
                  iconData = Icons.person_rounded;
                } else {
                  bgColor = tc.surface;
                  borderColor = _accentColor.withOpacity(0.3);
                  iconColor = _accentColor.withOpacity(0.7);
                  textColor = tc.textSecondary;
                  iconData = Icons.directions_run_rounded;
                }

                return Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => _onSpotTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: borderColor,
                            width: (isSelected || isMySpot) ? 2 : 1),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: _accentColor.withOpacity(0.5),
                                    blurRadius: 12,
                                    spreadRadius: 1)
                              ]
                            : null,
                      ),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(iconData, size: 28, color: iconColor),
                            const SizedBox(height: 4),
                            Text('${_rowLabel(row)}${col + 1}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textColor)),
                            Text('Trotadora',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: textColor.withOpacity(0.7))),
                          ]),
                    ),
                  ),
                ));
              }),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                child: Text(_rowLabel(row),
                    style: TextStyle(
                        fontSize: 12,
                        color: tc.textMuted,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
              ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar(AppThemeColors tc) {
    final hasSelection = _selectedSpot != null;
    final row = hasSelection ? _selectedSpot! ~/ cols : 0;
    final col = hasSelection ? _selectedSpot! % cols : 0;
    final spotLabel = hasSelection ? '${_rowLabel(row)}${col + 1}' : '—';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border(top: BorderSide(color: tc.border, width: 0.5)),
      ),
      child: Row(children: [
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Trotadora seleccionada',
                style: TextStyle(fontSize: 11, color: tc.textSecondary)),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                hasSelection ? 'Trotadora $spotLabel' : 'Ninguna',
                key: ValueKey(spotLabel),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: hasSelection ? _accentColor : tc.textMuted),
              ),
            ),
          ],
        )),
        ScaleTransition(
          scale: _scaleAnim,
          child: GestureDetector(
            onTap: hasSelection ? _confirmBooking : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: hasSelection
                    ? LinearGradient(
                        colors: [_accentColor, _accentColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                color: hasSelection ? null : tc.border,
                borderRadius: BorderRadius.circular(14),
                boxShadow: hasSelection
                    ? [
                        BoxShadow(
                            color: _accentColor.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Text('Confirmar',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: hasSelection ? Colors.white : tc.textMuted)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color, muted;
  const _InfoItem(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.muted});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: muted)),
        ]),
      );
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 36, color: color);
}

class _LegendItem extends StatelessWidget {
  final Color color, border, secondary;
  final String label;
  final IconData icon;
  const _LegendItem({
    required this.color,
    required this.border,
    required this.label,
    required this.secondary,
    this.icon = Icons.directions_run_rounded,
  });

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: border, width: 1.5)),
          child: Icon(icon, size: 12, color: secondary),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: secondary)),
      ]);
}
