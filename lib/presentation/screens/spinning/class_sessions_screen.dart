import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/class_provider.dart';
import '../../../services/class_schedule_service.dart';

class ClassSessionsScreen extends StatefulWidget {
  final String activity; // 'spinning' | 'running'
  final Color  accentColor;

  const ClassSessionsScreen({
    super.key,
    required this.activity,
    required this.accentColor,
  });

  @override
  State<ClassSessionsScreen> createState() => _ClassSessionsScreenState();
}

class _ClassSessionsScreenState extends State<ClassSessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadSessions(widget.activity);
    });
  }

  String get _title => widget.activity == 'spinning' ? 'Clases de Spinning' : 'Sesiones de Running';

  static const _dayNames = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _monthNames = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                               'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date  = DateTime(d.year, d.month, d.day);
    if (date == today) return 'Hoy';
    if (date == today.add(const Duration(days: 1))) return 'Mañana';
    return '${_dayNames[d.weekday]} ${d.day} ${_monthNames[d.month]}';
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  Future<void> _onBook(ClassSession session) async {
    final profile = context.read<AuthProvider>().profile;
    final name = profile?.name ?? 'Usuario';
    final provider = context.read<ClassProvider>();

    final result = await provider.bookSession(session.id, name);
    if (!mounted) return;

    String msg;
    switch (result) {
      case 'ok':             msg = '¡Reserva confirmada!'; break;
      case 'full':           msg = 'La clase ya está llena.'; break;
      case 'already_booked': msg = 'Ya tienes una reserva en esta clase.'; break;
      case 'completed':      msg = 'Esta clase ya finalizó.'; break;
      default:               msg = 'Error al reservar. Intenta de nuevo.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: result == 'ok' ? AppColors.primary : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onCancel(ClassSession session) async {
    final ok = await context.read<ClassProvider>().cancelBooking(session.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Reserva cancelada.' : 'Error al cancelar.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final provider = context.watch<ClassProvider>();
    final sessions = widget.activity == 'spinning'
        ? provider.spinningSessions : provider.runningSessions;

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: tc.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(child: Text(_title,
                  style: AppTextStyles.headingMedium.copyWith(color: tc.textPrimary))),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: widget.accentColor),
                onPressed: () => provider.loadSessions(widget.activity),
                tooltip: 'Actualizar',
              ),
            ]),
          ),
          const SizedBox(height: 8),
          // Body
          Expanded(
            child: provider.loading
                ? Center(child: CircularProgressIndicator(color: widget.accentColor))
                : sessions.isEmpty
                    ? _EmptyState(accentColor: widget.accentColor)
                    : RefreshIndicator(
                        color: widget.accentColor,
                        onRefresh: () => provider.loadSessions(widget.activity),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: sessions.length,
                          itemBuilder: (_, i) => _SessionCard(
                            session:     sessions[i],
                            accentColor: widget.accentColor,
                            dateLabel:   _formatDate(sessions[i].sessionDate),
                            timeLabel:   _formatTime(sessions[i].startsAt),
                            onBook:      () => _onBook(sessions[i]),
                            onCancel:    () => _onCancel(sessions[i]),
                          ),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color accentColor;
  const _EmptyState({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.event_busy_rounded, size: 56,
            color: accentColor.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text('Sin clases programadas',
            style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Text('El administrador aún no ha creado horarios.',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ClassSession session;
  final Color        accentColor;
  final String       dateLabel;
  final String       timeLabel;
  final VoidCallback onBook;
  final VoidCallback onCancel;

  const _SessionCard({
    required this.session,
    required this.accentColor,
    required this.dateLabel,
    required this.timeLabel,
    required this.onBook,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final tc = AppThemeColors.of(context);
    final spotsLeft = session.availableSpots;
    final isFull   = session.isFull;

    Color spotColor = AppColors.primary;
    if (isFull)              spotColor = AppColors.error;
    else if (spotsLeft <= 3) spotColor = AppColors.accentOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: session.isBookedByMe
            ? accentColor.withOpacity(0.08)
            : tc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.isBookedByMe
              ? accentColor.withOpacity(0.4)
              : AppColors.border,
          width: session.isBookedByMe ? 1.5 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          // Date block
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(dateLabel.length <= 3 ? dateLabel
                  : dateLabel.split(' ')[0],
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  )),
              if (dateLabel.contains(' '))
                Text(dateLabel.split(' ').skip(1).join(' '),
                    style: TextStyle(
                      color: accentColor.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    )),
            ]),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(session.scheduleName,
                style: AppTextStyles.labelLarge.copyWith(color: tc.textPrimary)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.access_time_rounded, size: 13, color: tc.textSecondary),
              const SizedBox(width: 4),
              Text(timeLabel,
                  style: AppTextStyles.caption.copyWith(color: tc.textSecondary)),
              const SizedBox(width: 12),
              Icon(Icons.people_rounded, size: 13, color: spotColor),
              const SizedBox(width: 4),
              Text(
                isFull ? 'Lleno' : '$spotsLeft cupos',
                style: AppTextStyles.caption.copyWith(
                    color: spotColor, fontWeight: FontWeight.w700),
              ),
            ]),
            if (session.isBookedByMe)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  Icon(Icons.check_circle_rounded,
                      size: 13, color: accentColor),
                  const SizedBox(width: 4),
                  Text('Reservado',
                      style: AppTextStyles.caption.copyWith(
                          color: accentColor, fontWeight: FontWeight.w700)),
                ]),
              ),
          ])),
          const SizedBox(width: 10),
          // Action button
          if (session.isBookedByMe)
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Cancelar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            )
          else if (!isFull)
            ElevatedButton(
              onPressed: onBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Reservar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Lleno',
                  style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
        ]),
      ),
    );
  }
}
