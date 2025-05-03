import 'package:helpdeskfrontend/services/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;
  String? userId;
  bool _isConnected = false;
  final List<Function(Map<String, dynamic>)> _notificationListeners = [];
  Function(bool)? onConnectionStatus;

  factory SocketService() => _instance;

  SocketService._internal();

  void initialize({
    required String userId,
    Function(Map<String, dynamic>)? onNotification,
  }) {
    print('SocketService: Initializing for user $userId');
    if (this.userId != null && this.userId != userId) {
      print(
          'SocketService: Already initialized with user ${this.userId}, disconnecting');
      disconnect();
    }
    this.userId = userId;
    if (onNotification != null &&
        !_notificationListeners.contains(onNotification)) {
      _notificationListeners.add(onNotification);
      print(
          'SocketService: Added notification listener, total: ${_notificationListeners.length}');
    }
  }

  void addNotificationListener(Function(Map<String, dynamic>) listener) {
    if (!_notificationListeners.contains(listener)) {
      _notificationListeners.add(listener);
      print(
          'SocketService: Added notification listener, total: ${_notificationListeners.length}');
    }
  }

  void removeNotificationListener(Function(Map<String, dynamic>) listener) {
    _notificationListeners.remove(listener);
    print(
        'SocketService: Removed notification listener, total: ${_notificationListeners.length}');
  }

  void connect(String token) {
    if (_isConnected && _socket != null) {
      print('SocketService: Already connected for user $userId');
      return;
    }

    // Disconnect any existing socket
    disconnect();

    _socket = IO.io(
      Config.baseUrl, // Use baseUrl from Config class
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;
      onConnectionStatus?.call(true);
      print('SocketService: Connected for user $userId');
      if (userId != null) {
        _socket!.emit('register-user', userId);
      }
    });

    _socket!.on('new-chat-notification', (data) {
      print('SocketService: Received notification: $data');
      if (data is Map<String, dynamic>) {
        for (var listener in List.from(_notificationListeners)) {
          listener(data);
        }
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      onConnectionStatus?.call(false);
      print('SocketService: Disconnected for user $userId');
    });

    _socket!.onError((error) {
      print('SocketService: Error: $error');
      onConnectionStatus?.call(false);
    });

    _socket!.onConnectError((error) {
      print('SocketService: Connection error: $error');
      onConnectionStatus?.call(false);
    });
  }

  bool get isConnected => _isConnected;

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      print('SocketService: Disconnected for user $userId');
    }
  }
}
