import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _service = NotificationService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _notifications = await _service.fetchNotifications();
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    _loading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    _notifications = [for (final n in _notifications) n.copyWith(isRead: true)];
    _unreadCount = 0;
    notifyListeners();
  }
}
