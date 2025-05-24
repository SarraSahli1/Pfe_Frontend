import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:jwt_decoder/jwt_decoder.dart'; // Ajout pour le décodage JWT

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;
  String? userId;
  bool _isConnected = false;
  bool _isConnecting = false;
  final List<Function(Map<String, dynamic>)> _notificationListeners = [];
  final List<String> _subscribedTickets = [];
  Function(bool)? onConnectionStatus;
  Timer? _reconnectTimer;
  String? _currentToken;
  Timer? _connectionChecker;

  bool get isConnected => _isConnected;
  factory SocketService() => _instance;

  SocketService._internal();

  void initialize({
    required String userId,
    Function(Map<String, dynamic>)? onNotification,
  }) {
    debugPrint('[SOCKET] Initializing for user $userId');
    if (this.userId != null && this.userId != userId) {
      debugPrint(
          '[SOCKET] User changed from ${this.userId} to $userId, resetting connection');
      disconnect();
    }
    this.userId = userId;
    if (onNotification != null) {
      addNotificationListener(onNotification);
    }

    // Vérification périodique de la connexion
    _connectionChecker = Timer.periodic(const Duration(minutes: 1), (_) {
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
          '[SOCKET] Added notification listener, total: ${_notificationListeners.length}');
    }
  }

  void removeNotificationListener(Function(Map<String, dynamic>) listener) {
    _notificationListeners.remove(listener);
    debugPrint(
        '[SOCKET] Removed notification listener, total: ${_notificationListeners.length}');
  }

  Future<void> connect(String token) async {
    if (_isConnected || _isConnecting) return;

    try {
      // Vérification du token JWT
      if (!JwtDecoder.isExpired(token)) {
        final decoded = JwtDecoder.decode(token);
        if (decoded['_id'] != userId) {
          debugPrint('[SOCKET] Token userId mismatch');
          return;
        }
      } else {
        debugPrint('[SOCKET] Token expired');
        return;
      }

      _isConnecting = true;
      _currentToken = token;
      debugPrint('[SOCKET] Connecting with token: ${_obfuscateToken(token)}');

      disconnect(); // Nettoyer toute connexion existante

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
    } catch (e) {
      debugPrint('[SOCKET] Connection error: $e');
      _isConnecting = false;
      _startReconnect(token);
    }
  }

  void _setupSocketEvents() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _isConnected = true;
      _isConnecting = false;
      debugPrint('[SOCKET] Connected successfully. Socket ID: ${_socket!.id}');
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
    _socket!.on('new-chat-notification', (data) {
      try {
        debugPrint('[SOCKET] Raw notification data: $data');
        final notification = _parseNotificationData(data);
        _handleEvent('new-chat-notification', notification);
      } catch (e) {
        debugPrint('[SOCKET] Notification processing error: $e');
      }
    });

    _socket!.on('ticket-update', (data) => _handleEvent('ticket-update', data));
    _socket!.on('status-change', (data) => _handleEvent('status-change', data));
    _socket!.on('notification', (data) => _handleEvent('notification', data));
    _socket!.on('chat-message', (data) => _handleEvent('chat-message', data));
  }

  Map<String, dynamic> _parseNotificationData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return {
        'event': 'new-chat-notification',
        ...data,
      };
    } else if (data is String) {
      return {
        'event': 'new-chat-notification',
        'data': jsonDecode(data),
      };
    }
    throw FormatException('Invalid notification format');
  }

  void _handleEvent(String event, Map<String, dynamic> data) {
    debugPrint('[SOCKET] Handling $event with data: $data');
    for (var listener in List.from(_notificationListeners)) {
      try {
        listener(data);
      } catch (e) {
        debugPrint('[SOCKET] Listener error: $e');
      }
    }
  }

  Future<void> subscribeToTicket(String ticketId) async {
    if (_socket?.connected != true) {
      debugPrint('[SOCKET] Not connected, queueing subscription to $ticketId');
      _subscribedTickets.add(ticketId);
      return;
    }

    if (!_subscribedTickets.contains(ticketId)) {
      _subscribedTickets.add(ticketId);
    }

    debugPrint('[SOCKET] Subscribing to ticket: $ticketId');
    _socket!.emit('subscribe-to-chat', ticketId);

    _socket!.on('chat:$ticketId', (data) {
      _handleEvent('chat:$ticketId', {
        'ticketId': ticketId,
        'data': data,
      });
    });
  }

  void unsubscribeFromTicket(String ticketId) {
    _subscribedTickets.remove(ticketId);
    if (_socket?.connected == true) {
      _socket!.emit('unsubscribe-from-chat', ticketId);
      _socket!.off('chat:$ticketId');
    }
  }

  void _resubscribeToTickets() {
    if (_subscribedTickets.isNotEmpty) {
      debugPrint(
          '[SOCKET] Resubscribing to ${_subscribedTickets.length} tickets');
      for (var ticketId in _subscribedTickets) {
        subscribeToTicket(ticketId);
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
    if (_reconnectTimer != null || _isConnecting || _isConnected) return;
    if (token == null) return;

    debugPrint('[SOCKET] Starting reconnect attempts');
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isConnected && !_isConnecting) {
        debugPrint('[SOCKET] Attempting to reconnect');
        connect(token);
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
      _socket!.disconnect();
      _socket!.destroy();
      _socket = null;
      _isConnected = false;
      _isConnecting = false;
      _cancelReconnect();
    }
  }

  void dispose() {
    _connectionChecker?.cancel();
    disconnect();
    _notificationListeners.clear();
    _subscribedTickets.clear();
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
Active listeners: ${_notificationListeners.length}
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
