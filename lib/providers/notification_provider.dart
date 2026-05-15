import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      final res = await apiService.getNotifications();
      final List data = res['data'] ?? [];
      _notifications = data.map((e) => NotificationModel.fromJson(e)).toList();
    } catch (_) {}

    _loading = false;
    notifyListeners();
  }

  Future<void> fetchUnreadCount() async {
    try {
      final res = await apiService.getUnreadCount();
      _unreadCount = res['count'] ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markRead(int id) async {
    try {
      await apiService.markNotificationRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          body: _notifications[index].body,
          type: _notifications[index].type,
          data: _notifications[index].data,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await apiService.markAllNotificationsRead();
      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id,
                title: n.title,
                body: n.body,
                type: n.type,
                data: n.data,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  void incrementUnread() {
    _unreadCount++;
    notifyListeners();
  }
}
