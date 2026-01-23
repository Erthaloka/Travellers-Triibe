import 'package:flutter/material.dart';

class NotificationService extends ChangeNotifier {
  final List<Map<String, dynamic>> _notifications = [];

  List<Map<String, dynamic>> get notifications => _notifications;

  // Checks if there are any unread messages (useful for the red dot on your Home bell)
  int get unreadCount => _notifications.where((n) => n['isRead'] == false).length;

  void addNotification({
    required String title,
    required String body,
    required String orderId,
    required String category,
  }) {
    _notifications.insert(0, {
      'id': DateTime.now().toString(),
      'title': title,
      'body': body,
      'timestamp': DateTime.now(),
      'orderId': orderId,
      'category': category,
      'isRead': false,
    });
    notifyListeners(); 
  }

  void markAsRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications[index]['isRead'] = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n['isRead'] = true;
    }
    notifyListeners();
  }
}

// Global instance
final notificationService = NotificationService();