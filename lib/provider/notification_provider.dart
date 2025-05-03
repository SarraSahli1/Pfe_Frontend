import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _notifications = [];
  final Set<String> _readIds = {};

  List<Map<String, dynamic>> get unreadNotifications => _notifications
      .where((n) => !_readIds.contains(n['message']?['_id']))
      .toList();

  List<Map<String, dynamic>> get allNotifications => _notifications;

  int get unreadCount => unreadNotifications.length;

  void addNotification(Map<String, dynamic> notification) {
    final messageId = notification['message']?['_id'];
    if (messageId != null &&
        !_notifications.any((n) => n['message']?['_id'] == messageId)) {
      _notifications.add(notification);
      notifyListeners();
    }
  }

  void markAsRead(String messageId) {
    if (!_readIds.contains(messageId)) {
      _readIds.add(messageId);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool changed = false;
    for (final n in _notifications) {
      final messageId = n['message']?['_id'];
      if (messageId != null && !_readIds.contains(messageId)) {
        _readIds.add(messageId);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void markAllAsReadForTicket(String ticketId) {
    bool changed = false;
    for (final n in _notifications) {
      if (n['ticketId'] == ticketId && n['message']?['_id'] != null) {
        final messageId = n['message']['_id'];
        if (!_readIds.contains(messageId)) {
          _readIds.add(messageId);
          changed = true;
        }
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void removeNotification(String messageId) {
    _notifications.removeWhere((n) => n['message']?['_id'] == messageId);
    _readIds.remove(messageId);
    notifyListeners();
  }

  void clearReadNotifications() {
    _notifications.removeWhere((n) => _readIds.contains(n['message']?['_id']));
    notifyListeners();
  }
}
