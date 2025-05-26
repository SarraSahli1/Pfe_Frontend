import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:helpdeskfrontend/services/config.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void addNotification(Map<String, dynamic> notification) {
    final messageId = notification['message']?['_id'];
    debugPrint('[NotificationProvider] Adding notification: $notification');
    if (messageId != null &&
        !_notifications.any((n) => n['message']?['_id'] == messageId)) {
      _notifications.add(notification);
      _unreadCount++;
      debugPrint(
          '[NotificationProvider] Notification added, unreadCount: $_unreadCount');
      notifyListeners();
    } else {
      debugPrint(
          '[NotificationProvider] Duplicate or invalid notification skipped');
    }
  }

  void markAsRead(String messageId) {
    final index =
        _notifications.indexWhere((n) => n['message']?['_id'] == messageId);
    if (index != -1) {
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      debugPrint(
          '[NotificationProvider] Marked as read, unreadCount: $_unreadCount');
      notifyListeners();
    }
  }

  void markAllAsReadForTicket(String ticketId) {
    final relatedNotifications =
        _notifications.where((n) => n['ticketId'] == ticketId).toList();
    if (relatedNotifications.isNotEmpty) {
      _unreadCount = (_unreadCount - relatedNotifications.length)
          .clamp(0, _notifications.length);
      debugPrint(
          '[NotificationProvider] Marked all for ticket $ticketId as read, unreadCount: $_unreadCount');
      notifyListeners();
    }
  }

  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    debugPrint('[NotificationProvider] Cleared notifications');
    notifyListeners();
  }

  Future<void> loadInitialNotifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/notifications/unread'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> notifications = jsonDecode(response.body);
        for (var notification in notifications) {
          addNotification(notification);
        }
        debugPrint(
            '[NotificationProvider] Loaded ${notifications.length} initial notifications');
      }
    } catch (e) {
      debugPrint(
          '[NotificationProvider] Failed to load initial notifications: $e');
    }
  }
}
