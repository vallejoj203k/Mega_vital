import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../services/notification_service.dart';
import '../../widgets/shared_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Notificaciones', style: AppTextStyles.displayMedium),
                  const Spacer(),
                  Consumer<NotificationProvider>(
                    builder: (_, np, __) => np.unreadCount > 0
                        ? GestureDetector(
                            onTap: np.markAllAsRead,
                            child: Text(
                              'Marcar todo',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primary),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (_, np, __) {
                  if (np.loading && np.notifications.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  if (np.notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 56, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('Sin notificaciones',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          Text('Sigue a alguien para ver sus publicaciones',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: np.load,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: np.notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _NotifCard(
                        notif: np.notifications[i],
                        timeAgo: _timeAgo(np.notifications[i].createdAt),
                        onTap: () => np.markAsRead(np.notifications[i].id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final String timeAgo;
  final VoidCallback onTap;

  const _NotifCard({
    required this.notif,
    required this.timeAgo,
    required this.onTap,
  });

  IconData get _icon {
    switch (notif.type) {
      case 'new_post': return Icons.post_add_rounded;
      case 'new_follower': return Icons.person_add_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color get _iconColor {
    switch (notif.type) {
      case 'new_post': return AppColors.primary;
      case 'new_follower': return AppColors.accentBlue;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DarkCard(
        padding: const EdgeInsets.all(14),
        borderColor: notif.isRead
            ? AppColors.border
            : AppColors.primary.withOpacity(0.35),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BoxedIcon(icon: _icon, color: _iconColor, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: notif.isRead
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      )),
                  const SizedBox(height: 2),
                  Text(notif.body,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeAgo,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
                if (!notif.isRead) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
