import 'dart:io';
import 'package:helpdeskfrontend/models/chat_message.dart';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ChatService {
  Future<Chat> getChatForTicket(String ticketId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/chat/getChatForTicket/$ticketId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return Chat.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load chat: ${response.body}');
      }
    } catch (e) {
      print('[ChatService] Error fetching chat: $e');
      rethrow;
    }
  }

  Future<ChatMessage> sendMessage({
    required String ticketId,
    required String senderId,
    required String message,
    required String token,
    List<File>? files,
  }) async {
    try {
      final uri =
          Uri.parse('${Config.baseUrl}/chat/sendMessageToChat/$ticketId');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['senderId'] = senderId;
      if (message.isNotEmpty) {
        request.fields['message'] = message;
      }

      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          final mimeType = await _getMimeType(file);
          if (!['image/jpeg', 'image/png', 'image/gif'].contains(mimeType)) {
            throw Exception('Invalid file type: $mimeType');
          }
          request.files.add(await http.MultipartFile.fromPath(
            'files',
            file.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      }

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final responseData = json.decode(responseString);
        return ChatMessage.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to send message: $responseString');
      }
    } catch (e) {
      print('[ChatService] Error sending message: $e');
      rethrow;
    }
  }

  Future<String> _getMimeType(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  Future<ChatMessage> scheduleMeeting({
    required String ticketId,
    required String senderId,
    required DateTime scheduledDate,
    required int duration,
    String? message,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/chat/$ticketId/schedule-meeting'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'senderId': senderId,
          'scheduledDate': scheduledDate.toIso8601String(),
          'duration': duration,
          'message': message,
        }),
      );

      if (response.statusCode == 201) {
        return ChatMessage.fromJson(json.decode(response.body)['data']);
      } else {
        throw Exception('Failed to schedule meeting: ${response.body}');
      }
    } catch (e) {
      print('[ChatService] Error scheduling meeting: $e');
      rethrow;
    }
  }

  Future<ChatMessage> acceptMeeting({
    required String ticketId,
    required String meetingMessageId,
    required String senderId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${Config.baseUrl}/chat/$ticketId/meeting/$meetingMessageId/accept'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'senderId': senderId,
        }),
      );

      if (response.statusCode == 200) {
        return ChatMessage.fromJson(json.decode(response.body)['data']);
      } else {
        throw Exception('Failed to accept meeting: ${response.body}');
      }
    } catch (e) {
      print('[ChatService] Error accepting meeting: $e');
      rethrow;
    }
  }

  Future<ChatMessage> declineMeeting({
    required String ticketId,
    required String meetingMessageId,
    required String senderId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${Config.baseUrl}/chat/$ticketId/meeting/$meetingMessageId/decline'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'senderId': senderId,
        }),
      );

      if (response.statusCode == 200) {
        return ChatMessage.fromJson(json.decode(response.body)['data']);
      } else {
        throw Exception('Failed to decline meeting: ${response.body}');
      }
    } catch (e) {
      print('[ChatService] Error declining meeting: $e');
      rethrow;
    }
  }
}
