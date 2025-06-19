import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:jwt_decoder/jwt_decoder.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;
  String? userId;
  bool _isConnected = false;
  bool _isConnecting = false;
  final List<Function(Map<String, dynamic>)> _notificationListeners = [];
  final List<String> _subscribedTickets = [];
  final Set<String> _processedNotificationIds = {}; // Deduplication
  Function(bool)? onConnectionStatus;
  Timer? _reconnectTimer;
  String? _currentToken;
  Timer? _connectionChecker;
  String? _activeTicketId;

  bool get isConnected => _isConnected;
  factory SocketService() => _instance;

  SocketService._internal();

  void setActiveTicketId(String? ticketId) {
    _activeTicketId = ticketId;
    debugPrint('[SOCKET] Active ticketId set to: $_activeTicketId');
  }

  void initialize({
    required String userId,
    Function(Map<String, dynamic>)? onNotification,
  }) {
    debugPrint(
        '[SOCKET] Initializing for user $userId, instance: ${this.hashCode}');
    if (_socket != null && this.userId != userId) {
      debugPrint(
          '[SOCKET] User changed from ${this.userId} to $userId, resetting');
      dispose();
    }
    this.userId = userId;
    if (onNotification != null) {
      addNotificationListener(onNotification);
    }

    _connectionChecker ??= Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_isConnected && !_isConnecting && _currentToken != null) {
        debugPrint('[SOCKET] Periodic connection check - reconnecting');
        connect(_currentToken!);
      }
    });
  }

  void addNotificationListener(Function(Map<String, dynamic>) listener) {
    if (!_notificationListeners.contains(listener)) {
      _notificationListeners.add(listener);
      debugPrint(
          '[SOCKET] Added listener, total: ${_notificationListeners.length}');
    }
  }

  void removeNotificationListener(Function(Map<String, dynamic>) listener) {
    _notificationListeners.remove(listener);
    debugPrint(
        '[SOCKET] Removed listener, total: ${_notificationListeners.length}');
  }

  Future<void> connect(String token) async {
    if (_isConnected || _isConnecting) {
      debugPrint('[SOCKET] Already connected or connecting');
      return;
    }

    try {
      if (!JwtDecoder.isExpired(token)) {
        final decoded = JwtDecoder.decode(token);
        if (decoded['_id'] != userId) {
          debugPrint(
              '[SOCKET] Token userId mismatch: ${decoded['_id']} vs $userId');
          return;
        }
      } else {
        debugPrint('[SOCKET] Token expired');
        return;
      }

      _isConnecting = true;
      _currentToken = token;
      debugPrint('[SOCKET] Connecting with token: ${_obfuscateToken(token)}');

      disconnect();

      _socket = IO.io(
        Config.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableReconnection()
            .build(),
      );

      _setupSocketEvents();
      _socket!.connect();
      debugPrint('[SOCKET] Connection initiated for user: $userId');
    } catch (e) {
      debugPrint('[SOCKET] Connection error: $e');
      _isConnecting = false;
      _startReconnect(token);
    }
  }

  void _setupSocketEvents() {
    if (_socket == null) return;

    // Clear existing listeners
    _socket!.off('connect');
    _socket!.off('disconnect');
    _socket!.off('error');
    _socket!.off('connect_error');

    _socket!.onConnect((_) {
      _isConnected = true;
      _isConnecting = false;
      debugPrint('[SOCKET] Connected. Socket ID: ${_socket!.id}');
      onConnectionStatus?.call(true);
      _cancelReconnect();
      _resubscribeToTickets();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      onConnectionStatus?.call(false);
      debugPrint('[SOCKET] Disconnected');
      _startReconnect(_currentToken);
    });

    _socket!.onError((error) {
      _isConnecting = false;
      debugPrint('[SOCKET] Error: $error');
      _startReconnect(_currentToken);
    });

    _socket!.onConnectError((error) {
      _isConnecting = false;
      debugPrint('[SOCKET] Connection error: $error');
      _startReconnect(_currentToken);
    });

    _setupApplicationListeners();
  }

  void _setupApplicationListeners() {
    // Clear existing listeners
    _socket!.off('new-chat-notification');
    _socket!.off('ticket:update');
    _socket!.off('user:notification');
    _socket!.off('status-change');
    _socket!.off('notification');
    _socket!.off('chat-message');

    _socket!.on('new-chat-notification', (data) {
      try {
        debugPrint('[SOCKET] Raw notification data: $data');
        final notification = _parseNotificationData(data);
        _handleEvent('new-chat-notification', notification);
      } catch (e) {
        debugPrint('[SOCKET] Notification processing error: $e');
      }
    });

    _socket!.on('ticket:update', (data) {
      try {
        debugPrint('[SOCKET] Ticket update received: $data');
        final notification = {
          'event': 'ticket-update',
          'type': 'status-change',
          'ticketId': data['ticketId']?.toString() ?? data['_id']?.toString(),
          'message': {
            '_id':
                data['message']?['_id']?.toString() ?? data['_id']?.toString(),
            'message':
                data['message'] ?? 'Ticket status updated to ${data['status']}',
            'status': data['status'],
            'oldStatus': data['oldStatus'],
            'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
          },
        };
        _handleEvent('ticket-update', notification);
      } catch (e) {
        debugPrint('[SOCKET] Ticket update processing error: $e');
      }
    });

    _socket!.on('user:notification', (data) {
      try {
        debugPrint('[SOCKET] User notification received: $data');
        final notification = {
          'event': 'user-notification',
          'type': 'status-change',
          'ticketId':
              data['ticketId']?.toString() ?? data['_id']?.toString() ?? '',
          'message': {
            '_id': data['_id']?.toString() ?? '',
            'message': data['message'] is String
                ? data['message']
                : data['message']?['message'] ??
                    'Ticket status updated to ${data['status']}',
            'status': data['status'],
            'oldStatus': data['oldStatus'],
            'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
          },
        };
        _handleEvent('user-notification', notification);
      } catch (e) {
        debugPrint('[SOCKET] User notification processing error: $e');
      }
    });

    _socket!.on('status-change', (data) {
      try {
        debugPrint('[SOCKET] Status change received: $data');
        final notification = {
          'event': 'status-change',
          'type': 'status-change',
          'ticketId': data['ticketId']?.toString() ?? data['_id']?.toString(),
          'message': {
            '_id':
                data['message']?['_id']?.toString() ?? data['_id']?.toString(),
            'message':
                data['message'] ?? 'Ticket status updated to ${data['status']}',
            'status': data['status'],
            'oldStatus': data['oldStatus'],
            'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
          },
        };
        _handleEvent('status-change', notification);
      } catch (e) {
        debugPrint('[SOCKET] Status change processing error: $e');
      }
    });

    _socket!.on('notification', (data) {
      try {
        debugPrint('[SOCKET] Generic notification received: $data');
        final notification = {
          'event': 'notification',
          'type': data['type'] ?? 'generic',
          'ticketId': data['ticketId']?.toString() ?? data['_id']?.toString(),
          'message': {
            '_id':
                data['message']?['_id']?.toString() ?? data['_id']?.toString(),
            'message': data['message'] ?? 'Notification received',
            'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
          },
        };
        _handleEvent('notification', notification);
      } catch (e) {
        debugPrint('[SOCKET] Notification processing error: $e');
      }
    });

    _socket!.on('chat-message', (data) {
      try {
        debugPrint('[SOCKET] Chat message received: $data');
        _handleEvent('chat-message', {
          'event': 'chat-message',
          'type': 'chat_message',
          'ticketId': data['ticketId']?.toString(),
          'message': {
            '_id':
                data['message']?['_id']?.toString() ?? data['_id']?.toString(),
            'message': data['message'] ?? '',
            'sender': data['sender'] ?? {},
            'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
            'listOfFiles': data['listOfFiles'] ?? [],
          },
        });
      } catch (e) {
        debugPrint('[SOCKET] Chat message processing error: $e');
      }
    });
  }

  Map<String, dynamic> _parseNotificationData(dynamic data) {
    try {
      Map<String, dynamic> parsedData;
      if (data is Map<String, dynamic>) {
        parsedData = data;
      } else if (data is String) {
        parsedData = jsonDecode(data);
      } else {
        throw FormatException('Invalid notification format');
      }

      final message = parsedData['message'] ?? {};
      final sender = message['sender'] ?? {};

      return {
        'event': 'new-chat-notification',
        'type': 'chat_message',
        'ticketId': parsedData['ticketId']?.toString() ?? '',
        'message': {
          '_id': message['_id']?.toString() ?? '',
          'message': message['message']?.toString(),
          'sender': {
            '_id': sender['_id']?.toString() ?? '',
            'firstName': sender['firstName']?.toString() ?? 'Unknown',
            'image': sender['image'] != null
                ? {
                    '_id': sender['image']['_id']?.toString() ?? '',
                    'fileName': sender['image']['fileName']?.toString() ?? '',
                    'path': sender['image']['path']?.toString() ?? '',
                    'title': sender['image']['title']?.toString() ?? '',
                  }
                : null,
          },
          'createdAt': message['createdAt']?.toString() ??
              DateTime.now().toIso8601String(),
          'listOfFiles':
              message['listOfFiles'] is List ? message['listOfFiles'] : [],
        },
      };
    } catch (e) {
      debugPrint('[SOCKET] Parse notification error: $e');
      return {
        'event': 'new-chat-notification',
        'type': 'chat_message',
        'ticketId': '',
        'message': {
          '_id': '',
          'message': '',
          'sender': {'_id': '', 'firstName': 'Unknown', 'image': null},
          'createdAt': DateTime.now().toIso8601String(),
          'listOfFiles': [],
        },
      };
    }
  }

  void _handleEvent(String event, Map<String, dynamic> data) {
    debugPrint(
        '[SOCKET] Handling $event with data: $data, activeTicketId: $_activeTicketId');
    if (!_isConnected && event != 'connection_status') return;

    final notificationId = data['message']?['_id']?.toString() ?? '';
    if (notificationId.isNotEmpty &&
        _processedNotificationIds.contains(notificationId)) {
      debugPrint('[SOCKET] Skipping duplicate notification: $notificationId');
      return;
    }
    if (notificationId.isNotEmpty) {
      _processedNotificationIds.add(notificationId);
    }

    for (var listener in List.from(_notificationListeners)) {
      try {
        listener({...data, 'activeTicketId': _activeTicketId});
      } catch (e) {
        debugPrint('[SOCKET] Listener error: $e');
      }
    }
  }

  Future<void> subscribeToTicket(String? ticketId) async {
    if (ticketId == null || _subscribedTickets.contains(ticketId)) {
      debugPrint('[SOCKET] Invalid ticketId or already subscribed: $ticketId');
      return;
    }

    _subscribedTickets.add(ticketId);
    if (_socket?.connected != true) {
      debugPrint('[SOCKET] Not connected, queueing subscription to $ticketId');
      await ensureConnected();
      if (_socket?.connected != true) {
        debugPrint('[SOCKET] Failed to connect for subscription to $ticketId');
        return;
      }
    }

    _socket!.emit('subscribe-to-chat', ticketId);
    debugPrint('[SOCKET] Emitted subscribe-to-chat for ticket: $ticketId');

    _socket!.off('chat:$ticketId');
    _socket!.on('chat:$ticketId', (data) {
      debugPrint('[SOCKET] Received chat:$ticketId event: $data');
      try {
        final messageData = {
          '_id': data['_id']?.toString() ?? '',
          'message': data['message']?.toString(),
          'sender': {
            '_id': data['sender']?['_id']?.toString() ?? '',
            'firstName': data['sender']?['firstName']?.toString() ?? 'Unknown',
            'image': data['sender']?['image'] != null
                ? {
                    '_id': data['sender']['image']['_id']?.toString() ?? '',
                    'fileName':
                        data['sender']['image']['fileName']?.toString() ?? '',
                    'path': data['sender']['image']['path']?.toString() ?? '',
                    'title': data['sender']['image']['title']?.toString() ?? '',
                  }
                : null,
          },
          'createdAt':
              data['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
          'updatedAt':
              data['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
          'listOfFiles': data['listOfFiles'] is List
              ? (data['listOfFiles'] as List)
                  .map((file) => {
                        '_id': file['_id']?.toString() ?? '',
                        'fileName': file['fileName']?.toString() ?? '',
                        'path': file['path']?.toString() ?? '',
                        'title': file['title']?.toString() ?? '',
                      })
                  .toList()
              : [],
        };

        _handleEvent('chat:$ticketId', {
          'ticketId': ticketId,
          'type': 'chat_message',
          'message': messageData,
          'activeTicketId': _activeTicketId,
        });
      } catch (e) {
        debugPrint('[SOCKET] Error processing chat:$ticketId event: $e');
      }
    });
  }

  void unsubscribeFromTicket(String ticketId) {
    _subscribedTickets.remove(ticketId);
    if (_socket?.connected == true) {
      _socket!.emit('unsubscribe-from-chat', ticketId);
      _socket!.off('chat:$ticketId');
      debugPrint('[SOCKET] Unsubscribed from ticket: $ticketId');
    }
  }

  void _resubscribeToTickets() {
    if (_subscribedTickets.isNotEmpty) {
      debugPrint(
          '[SOCKET] Resubscribing to ${_subscribedTickets.length} tickets');
      for (var ticketId in List.from(_subscribedTickets)) {
        _socket!.off('chat:$ticketId');
        subscribeToTicket(ticketId);
        debugPrint('[SOCKET] Resubscribed to ticket: $ticketId');
      }
    }
  }

  void sendEvent(String event, [dynamic data]) {
    if (_socket?.connected == true) {
      debugPrint('[SOCKET] Sending $event event');
      _socket!.emit(event, data);
    } else {
      debugPrint('[SOCKET] Cannot send event $event - not connected');
    }
  }

  void _startReconnect(String? token) {
    if (_reconnectTimer != null ||
        _isConnecting ||
        _isConnected ||
        token == null) {
      debugPrint(
          '[SOCKET] Reconnect skipped: already reconnecting or connected');
      return;
    }

    int retryCount = 0;
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 10);

    debugPrint('[SOCKET] Starting reconnect attempts');
    _reconnectTimer = Timer.periodic(baseDelay, (timer) {
      if (!_isConnected && !_isConnecting && retryCount < maxRetries) {
        debugPrint('[SOCKET] Reconnect attempt ${retryCount + 1}/$maxRetries');
        connect(token);
        retryCount++;
      } else {
        debugPrint(
            '[SOCKET] Stopping reconnect: ${retryCount >= maxRetries ? 'Max retries reached' : 'Connected or connecting'}');
        timer.cancel();
        _reconnectTimer = null;
        if (!_isConnected) {
          onConnectionStatus?.call(false);
          _handleEvent('connection_failed', {
            'message':
                'Failed to reconnect to chat server after $maxRetries attempts',
            'activeTicketId': _activeTicketId,
          });
        }
      }
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void disconnect() {
    if (_socket != null) {
      debugPrint('[SOCKET] Disconnecting...');
      _isConnected = false;
      _isConnecting = false;
      _socket!.disconnect();
      _socket!.destroy();
      _socket = null;
      _cancelReconnect();
      if (onConnectionStatus != null) {
        onConnectionStatus!(false);
      }
      _subscribedTickets.clear();
      _processedNotificationIds.clear();
      _activeTicketId = null;
    }
  }

  void dispose() {
    _connectionChecker?.cancel();
    disconnect();
    _notificationListeners.clear();
    _subscribedTickets.clear();
    _processedNotificationIds.clear();
    _activeTicketId = null;
    debugPrint('[SOCKET] Service disposed');
  }

  String _obfuscateToken(String token) {
    if (token.length < 10) return '***';
    return '${token.substring(0, 5)}...${token.substring(token.length - 5)}';
  }

  void printDebugInfo() {
    debugPrint('''
[SOCKET DEBUG]
Status: ${_isConnected ? 'Connected' : _isConnecting ? 'Connecting' : 'Disconnected'}
User ID: $userId
Subscribed tickets: ${_subscribedTickets.join(', ')}
Active ticketId: $_activeTicketId
Active listeners: ${_notificationListeners.length}
Processed notifications: ${_processedNotificationIds.length}
Reconnect timer: ${_reconnectTimer != null ? 'Active' : 'Inactive'}
''');
  }

  Future<void> ensureConnected() async {
    if (_isConnected) return;

    if (_isConnecting) {
      await Future.delayed(const Duration(seconds: 1));
      return ensureConnected();
    }

    if (_currentToken != null) {
      connect(_currentToken!);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
