import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'spinning_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final SpinClass spinClass;
  final int? currentSeat; // pre-selected when the user is changing their seat

  const SeatSelectionScreen({super.key, required this.spinClass, this.currentSeat});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedSeat;
  late AnimationController _confirmAnim;
  late Animation<double> _scaleAnim;

  // Layout: 6 columnas x 3 filas = 18 bicicletas
  static const int cols = 6;
  static const int rows = 3;

  @override
  void initState() {
    super.initState();
    _selectedSeat = widget.currentSeat; // pre-select when changing seat
    _confirmAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _confirmAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _confirmAnim.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.spinClass.level) {
      case SpinLevel.basico:
        return AppColors.primary;
      case SpinLevel.intermedio:
        return AppColors.accentOrange;
      case SpinLevel.avanzado:
        return AppColors.accentPurple;
    }
  }

  void _onSeatTap(int index) {
    final isMySeat = index == widget.currentSeat;
    if (widget.spinClass.reservedSeats.contains(index) && !isMySeat) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSeat = _selectedSeat == index ? null : index;
    });
  }

  void _confirmBooking() async {
    if (_selectedSeat == null) return;
    HapticFeedback.mediumImpact();
    await _confirmAnim.forward();
    await _confirmAnim.reverse();
    if (mounted) Navigator.pop(context, _selectedSeat);
  }

  String _rowLabel(int row) =>
      String.fromCharCode('A'.codeUnitAt(0) + row);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildClassInfo(),
            const SizedBox(height: 8),
            _buildLegend(),
            const SizedBox(height: 20),
            _buildInstructorZone(),
            const SizedBox(height: 16),
            Expanded(child: _buildSeatGrid()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentSeat != null ? 'Cambiar lugar' : 'Elegir Puesto',
                  style: AppTextStyles.headingMedium,
                ),
                Text(
                  widget.spinClass.name,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _accentColor.withOpacity(0.4), width: 1),
            ),
            child: Text(
              widget.spinClass.time,
              style: TextStyle(
                  fontSize: 12,
                  color: _accentColor,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          _InfoItem(
            icon: Icons.chair_rounded,
            label: 'Disponibles',
            value: '${widget.spinClass.availableSpots}',
            color: widget.spinClass.availableSpots > 5
                ? AppColors.primary
                : AppColors.warning,
          ),
          _Divider(),
          _InfoItem(
            icon: Icons.local_fire_department_rounded,
            label: 'Calorías',
            value:
                '${widget.spinClass.caloriesMin}–${widget.spinClass.caloriesMax}',
            color: AppColors.accentOrange,
          ),
          _Divider(),
          _InfoItem(
            icon: Icons.timer_rounded,
            label: 'Duración',
            value: '${widget.spinClass.durationMinutes}m',
            color: AppColors.accentBlue,
          ),
          _Divider(),
          _InfoItem(
            icon: Icons.calendar_today_rounded,
            label: 'Días',
            value: widget.spinClass.days.split('·').length.toString() == '1'
                ? widget.spinClass.days.trim()
                : '${widget.spinClass.days.split('·').length} días',
            color: AppColors.accentPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 6,
        children: [
          _LegendItem(color: AppColors.surface, border: _accentColor, label: 'Disponible'),
          _LegendItem(color: _accentColor, border: _accentColor, label: 'Seleccionado'),
          _LegendItem(color: AppColors.border, border: AppColors.border, label: 'Ocupado'),
          if (widget.currentSeat != null)
            _LegendItem(
              color: _accentColor.withOpacity(0.2),
              border: _accentColor,
              label: 'Tu lugar actual',
              icon: Icons.person_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildInstructorZone() {
    return Column(
      children: [
        // Instructor platform
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _accentColor.withOpacity(0.3),
                _accentColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: _accentColor.withOpacity(0.5), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bike_rounded,
                  color: _accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'INSTRUCTOR',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _accentColor,
                    letterSpacing: 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Arrow pointing toward seats
        Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted, size: 20),
      ],
    );
  }

  Widget _buildSeatGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(rows, (row) {
          return Expanded(
            child: Row(
              children: [
                // Row label
                SizedBox(
                  width: 24,
                  child: Text(
                    _rowLabel(row),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                // Seats
                ...List.generate(cols, (col) {
                  final index = row * cols + col;
                  final isMySeat = index == widget.currentSeat;
                  final isOccupied =
                      widget.spinClass.reservedSeats.contains(index) &&
                          !isMySeat;
                  final isSelected = _selectedSeat == index;

                  Color bgColor;
                  Color borderColor;
                  Color iconColor;
                  Color textColor;
                  IconData iconData;

                  if (isOccupied) {
                    bgColor = AppColors.border;
                    borderColor = AppColors.border;
                    iconColor = AppColors.textMuted;
                    textColor = AppColors.textMuted;
                    iconData = Icons.close_rounded;
                  } else if (isSelected) {
                    bgColor = _accentColor;
                    borderColor = _accentColor;
                    iconColor = Colors.white;
                    textColor = Colors.white;
                    iconData = isMySeat
                        ? Icons.person_rounded
                        : Icons.directions_bike_rounded;
                  } else if (isMySeat) {
                    bgColor = _accentColor.withOpacity(0.2);
                    borderColor = _accentColor;
                    iconColor = _accentColor;
                    textColor = _accentColor;
                    iconData = Icons.person_rounded;
                  } else {
                    bgColor = AppColors.surface;
                    borderColor = _accentColor.withOpacity(0.3);
                    iconColor = _accentColor.withOpacity(0.7);
                    textColor = AppColors.textSecondary;
                    iconData = Icons.directions_bike_rounded;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: GestureDetector(
                        onTap: () => _onSeatTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: borderColor,
                              width: (isSelected || isMySeat) ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _accentColor.withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(iconData, size: 20, color: iconColor),
                              const SizedBox(height: 2),
                              Text(
                                '${_rowLabel(row)}${col + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                // Mirror label
                SizedBox(
                  width: 24,
                  child: Text(
                    _rowLabel(row),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasSelection = _selectedSeat != null;
    final row = hasSelection ? _selectedSeat! ~/ cols : 0;
    final col = hasSelection ? _selectedSeat! % cols : 0;
    final seatLabel =
        hasSelection ? '${_rowLabel(row)}${col + 1}' : '—';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Selected seat info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Puesto seleccionado',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    hasSelection ? 'Bici $seatLabel' : 'Ninguno',
                    key: ValueKey(seatLabel),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color:
                          hasSelection ? _accentColor : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Confirm button
          ScaleTransition(
            scale: _scaleAnim,
            child: GestureDetector(
              onTap: hasSelection ? _confirmBooking : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: hasSelection
                      ? LinearGradient(
                          colors: [_accentColor, _accentColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color:
                      hasSelection ? null : AppColors.border,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: hasSelection
                      ? [
                          BoxShadow(
                            color: _accentColor.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  'Confirmar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: hasSelection
                        ? Colors.white
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color),
          ),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 0.5, height: 36, color: AppColors.border);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color border;
  final String label;
  final IconData icon;

  const _LegendItem({
    required this.color,
    required this.border,
    required this.label,
    this.icon = Icons.directions_bike_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Icon(icon, size: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
