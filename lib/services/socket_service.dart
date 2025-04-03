// socket_service.dart
import 'package:helpdeskfrontend/models/chat_message.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect(String token) {
    socket = IO.io('YOUR_BACKEND_URL', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'}
    });

    socket.connect();
  }

  void subscribeToChat(String ticketId, Function(ChatMessage) onNewMessage) {
    socket.on('chat:$ticketId', (data) {
      final message = ChatMessage.fromJson(data);
      onNewMessage(message);
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}
