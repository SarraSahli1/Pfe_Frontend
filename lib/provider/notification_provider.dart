import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:helpdeskfrontend/services/config.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  String? _currentUserId;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    debugPrint(
        '[NotificationProvider] Current user ID set to: $_currentUserId');
  }

  void addNotification(Map<String, dynamic> notification,
      {String? activeTicketId}) {
    final messageId = notification['message']?['_id'];
    final ticketId = notification['ticketId'];
    final senderId = notification['message']?['sender']?['_id']?.toString();
    final listOfFiles = notification['message']?['listOfFiles'] ?? [];
    debugPrint(
        '[NotificationProvider] Adding notification: $notification, activeTicketId: $activeTicketId, hasFiles: ${listOfFiles.isNotEmpty}');

    if (ticketId != null && ticketId == activeTicketId) {
      debugPrint(
          '[NotificationProvider] Skipping notification for active chat: $ticketId');
      return;
    }

    if (senderId != null && senderId == _currentUserId) {
      debugPrint(
          '[NotificationProvider] Skipping notification for own message: $messageId');
      return;
    }

    if (messageId != null &&
        _notifications.any((n) => n['message']?['_id'] == messageId)) {
      debugPrint(
          '[NotificationProvider] Duplicate notification skipped: $messageId');
      return;
    }

    if (messageId != null) {
      _notifications.add({
        ...notification,
        'message': {
          ...notification['message'],
          'listOfFiles': listOfFiles,
        },
      });
      _unreadCount++;
      debugPrint(
          '[NotificationProvider] Notification added, unreadCount: $_unreadCount');
      notifyListeners();
    } else {
      debugPrint(
          '[NotificationProvider] Invalid notification skipped: no messageId');
    }
  }

  void markAsRead(String messageId) {
    final index =
        _notifications.indexWhere((n) => n['message']?['_id'] == messageId);
    if (index != -1) {
      _notifications.removeAt(index);
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
      _notifications.removeWhere((n) => n['ticketId'] == ticketId);
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
