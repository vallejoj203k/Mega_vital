import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/spinning_service.dart';


// 3 filas × 6 columnas = 18 bicicletas
const int _rows = 3;
const int _cols = 6;
const int _totalSeats = _rows * _cols;

String _seatLabel(int index) {
  final row = String.fromCharCode('A'.codeUnitAt(0) + index ~/ _cols);
  final col = index % _cols + 1;
  return '$row$col';
}

Color _levelColor(SpinLevel l) {
  switch (l) {
    case SpinLevel.basico:
      return AppColors.primary;
    case SpinLevel.intermedio:
      return AppColors.accentOrange;
    case SpinLevel.avanzado:
      return AppColors.accentPurple;
  }
}

Color _hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

class SeatSelectionScreen extends StatefulWidget {
  final SpinClass spinClass;
  final String sessionId;
  final SpinningService service;

  const SeatSelectionScreen({
    super.key,
    required this.spinClass,
    required this.sessionId,
    required this.service,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedSeat;
  Set<int> _occupiedSeats = {};
  List<SessionParticipant> _participants = [];
  bool _loading = true;
  bool _booking = false;

  late AnimationController _btnAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _btnAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _btnAnim, curve: Curves.easeInOut));
    _loadSeats();
  }

  @override
  void dispose() {
    _btnAnim.dispose();
    super.dispose();
  }

  Future<void> _loadSeats() async {
    final results = await Future.wait([
      widget.service.getBookedSeats(widget.sessionId),
      widget.service.getParticipants(widget.sessionId),
    ]);
    if (mounted) {
      setState(() {
        _occupiedSeats = results[0] as Set<int>;
        _participants = results[1] as List<SessionParticipant>;
        _loading = false;
      });
    }
  }

  Color get _accent => _levelColor(widget.spinClass.level);

  void _selectSeat(int index) {
    if (_occupiedSeats.contains(index)) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedSeat = _selectedSeat == index ? null : index);
  }

  Future<void> _confirm() async {
    if (_selectedSeat == null || _booking) return;
    HapticFeedback.mediumImpact();
    setState(() => _booking = true);
    await _btnAnim.forward();
    await _btnAnim.reverse();
    try {
      await widget.service.bookSeat(widget.sessionId, _selectedSeat!);
      if (mounted) Navigator.pop(context, _selectedSeat);
    } catch (e) {
      setState(() => _booking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('duplicate')
                  ? 'Ese puesto ya fue reservado, elige otro.'
                  : 'Error al reservar. Intenta de nuevo.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildInfo(),
            const SizedBox(height: 12),
            _buildLegend(),
            const SizedBox(height: 20),
            _buildInstructorPlatform(),
            const SizedBox(height: 16),
            Expanded(child: _loading ? _buildLoader() : _buildGrid()),
            if (!_loading) _buildParticipants(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _accent),
            const SizedBox(height: 12),
            const Text('Cargando disponibilidad...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _buildAppBar() {
    final nextLabel = widget.spinClass.nextSessionLabel;
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
                Text('Elige tu bicicleta',
                    style: AppTextStyles.headingMedium),
                Row(
                  children: [
                    Text(widget.spinClass.name,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(nextLabel,
                          style: TextStyle(
                              fontSize: 10,
                              color: _accent,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Time badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _accent.withOpacity(0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded, size: 12, color: _accent),
                const SizedBox(width: 4),
                Text(
                    '${widget.spinClass.startTime}–${widget.spinClass.endTime}',
                    style: TextStyle(
                        fontSize: 12,
                        color: _accent,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    final instColor = _hexColor(widget.spinClass.instructor.colorHex);
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
          _InfoCell(
            icon: Icons.person_rounded,
            value: widget.spinClass.instructor.name,
            label: 'Instructor',
            color: instColor,
          ),
          _VerticalDivider(),
          _InfoCell(
            icon: Icons.event_seat_rounded,
            value:
                '${_totalSeats - _occupiedSeats.length}/${_totalSeats}',
            label: 'Disponibles',
            color: (_totalSeats - _occupiedSeats.length) > 5
                ? AppColors.primary
                : AppColors.warning,
          ),
          _VerticalDivider(),
          _InfoCell(
            icon: Icons.local_fire_department_rounded,
            value:
                '${widget.spinClass.caloriesMin}–${widget.spinClass.caloriesMax}',
            label: 'kcal est.',
            color: AppColors.accentOrange,
          ),
          _VerticalDivider(),
          _InfoCell(
            icon: Icons.timer_rounded,
            value: '${widget.spinClass.durationMinutes}m',
            label: 'Duración',
            color: AppColors.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendDot(
              color: AppColors.surface,
              border: _accent,
              label: 'Disponible'),
          const SizedBox(width: 18),
          _LegendDot(color: _accent, border: _accent, label: 'Tu elección'),
          const SizedBox(width: 18),
          _LegendDot(
              color: AppColors.border,
              border: AppColors.border,
              label: 'Ocupado'),
        ],
      ),
    );
  }

  Widget _buildInstructorPlatform() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent.withOpacity(0.25), _accent.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(
                    color: _accent.withOpacity(0.15), blurRadius: 12)
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bike_rounded,
                    color: _accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${widget.spinClass.instructor.name.toUpperCase()} · INSTRUCTOR',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _accent,
                      letterSpacing: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Icon(Icons.keyboard_double_arrow_down_rounded,
              color: _accent.withOpacity(0.4), size: 22),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(_rows, (row) {
          return Expanded(
            child: Row(
              children: [
                // Fila label izquierdo
                SizedBox(
                  width: 20,
                  child: Text(
                    String.fromCharCode('A'.codeUnitAt(0) + row),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 6),
                // Bicicletas
                ...List.generate(_cols, (col) {
                  final index = row * _cols + col;
                  final occupied = _occupiedSeats.contains(index);
                  final selected = _selectedSeat == index;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: GestureDetector(
                        onTap: () => _selectSeat(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: occupied
                                ? AppColors.border.withOpacity(0.5)
                                : selected
                                    ? _accent
                                    : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: occupied
                                  ? AppColors.border
                                  : selected
                                      ? _accent
                                      : _accent.withOpacity(0.25),
                              width: selected ? 2 : 0.8,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                        color: _accent.withOpacity(0.5),
                                        blurRadius: 14,
                                        spreadRadius: 1)
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                occupied
                                    ? Icons.block_rounded
                                    : Icons.directions_bike_rounded,
                                size: 22,
                                color: occupied
                                    ? AppColors.textMuted.withOpacity(0.5)
                                    : selected
                                        ? Colors.white
                                        : _accent.withOpacity(0.7),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _seatLabel(index),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: occupied
                                      ? AppColors.textMuted.withOpacity(0.4)
                                      : selected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                // Fila label derecho
                SizedBox(
                  width: 20,
                  child: Text(
                    String.fromCharCode('A'.codeUnitAt(0) + row),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700),
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

  Widget _buildParticipants() {
    if (_participants.isEmpty) return const SizedBox.shrink();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_rounded, size: 14, color: _accent),
              const SizedBox(width: 6),
              Text(
                'Participantes (${_participants.length}/${_totalSeats})',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _accent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _participants.length,
              itemBuilder: (context, i) {
                final p = _participants[i];
                final isMe = p.userId == uid;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isMe
                                  ? _accent.withOpacity(0.2)
                                  : AppColors.surfaceVariant,
                              border: Border.all(
                                color: isMe
                                    ? _accent
                                    : AppColors.border,
                                width: isMe ? 2 : 1,
                              ),
                            ),
                            child: p.avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      p.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(p.initials,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isMe
                                                    ? _accent
                                                    : AppColors
                                                        .textSecondary)),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(p.initials,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isMe
                                                ? _accent
                                                : AppColors.textSecondary)),
                                  ),
                          ),
                          if (isMe)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.surface, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isMe ? 'Tú' : p.displayName.split(' ').first,
                        style: TextStyle(
                            fontSize: 9,
                            color: isMe ? _accent : AppColors.textMuted,
                            fontWeight: isMe
                                ? FontWeight.w700
                                : FontWeight.w400),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasSelection = _selectedSeat != null;
    final label =
        hasSelection ? 'Bici ${_seatLabel(_selectedSeat!)}' : 'Ninguna';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Seleccionaste',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      SlideTransition(
                        position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero)
                            .animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                  child: Text(
                    label,
                    key: ValueKey(label),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: hasSelection ? _accent : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ScaleTransition(
            scale: _scaleAnim,
            child: GestureDetector(
              onTap: hasSelection && !_booking ? _confirm : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 15),
                decoration: BoxDecoration(
                  gradient: hasSelection
                      ? LinearGradient(
                          colors: [_accent, _accent.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: hasSelection ? null : AppColors.border,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: hasSelection
                      ? [
                          BoxShadow(
                              color: _accent.withOpacity(0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                child: _booking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
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

// ── Helper widgets ───────────────────────────────────────

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InfoCell(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 38, color: AppColors.border);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final Color border;
  final String label;

  const _LegendDot(
      {required this.color, required this.border, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border, width: 1.5),
          ),
          child: const Icon(Icons.directions_bike_rounded,
              size: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
