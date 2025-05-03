// chat_service.dart
import 'dart:io';
import 'package:helpdeskfrontend/models/chat_message.dart';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ChatService {
  // Remove the baseUrl parameter since we're using Config.baseUrl now
  Future<Chat> getChatForTicket(String ticketId, String token) async {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/chat/getChatForTicket/$ticketId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Chat.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load chat');
    }
  }

  Future<ChatMessage> sendMessage({
    required String ticketId,
    required String senderId,
    required String message,
    required String token,
    List<File>? files,
  }) async {
    final uri = Uri.parse('${Config.baseUrl}/chat/sendMessageToChat/$ticketId');
    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['senderId'] = senderId;
    request.fields['message'] = message;

    if (files != null) {
      for (var file in files) {
        request.files.add(await http.MultipartFile.fromPath(
          'files',
          file.path,
          contentType: MediaType('application', 'octet-stream'),
        ));
      }
    }

    final response = await request.send();
    final responseString = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final responseData = json.decode(responseString);
      return ChatMessage.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to send message');
    }
  }
}
