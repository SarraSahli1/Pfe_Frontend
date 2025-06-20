// chat_message.dart
import 'package:helpdeskfrontend/models/user.dart';

class MeetingDetails {
  final DateTime scheduledDate;
  final int duration;
  final String status;
  final bool respondedByClient; // Added to track client response

  MeetingDetails({
    required this.scheduledDate,
    required this.duration,
    required this.status,
    this.respondedByClient = false,
  });

  factory MeetingDetails.fromJson(Map<String, dynamic> json) {
    return MeetingDetails(
      scheduledDate: DateTime.parse(json['scheduledDate']?.toString() ??
          DateTime.now().toIso8601String()),
      duration: (json['duration'] is int
              ? json['duration']
              : int.tryParse(json['duration']?.toString() ?? '0')) ??
          0,
      status: json['status']?.toString() ?? 'pending',
      respondedByClient: json['respondedByClient'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'scheduledDate': scheduledDate.toIso8601String(),
        'duration': duration,
        'status': status,
        'respondedByClient': respondedByClient,
      };
}

class ChatMessage {
  final String id;
  final String senderId;
  final String? message;
  final List<FileModel> files;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User sender;
  final bool isMeeting;
  final MeetingDetails? meetingDetails;

  ChatMessage({
    required this.id,
    required this.senderId,
    this.message,
    required this.files,
    required this.createdAt,
    required this.updatedAt,
    required this.sender,
    this.isMeeting = false,
    this.meetingDetails,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'],
      senderId: json['sender']['_id'],
      message: json['message'],
      files: (json['listOfFiles'] as List<dynamic>?)
              ?.map((file) => FileModel.fromJson(file))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      sender: User.fromJson(json['sender']),
      isMeeting: json['isMeeting'] as bool? ?? false,
      meetingDetails: json['meetingDetails'] != null
          ? MeetingDetails.fromJson(
              json['meetingDetails'] as Map<String, dynamic>)
          : null,
    );
  }
}

// file_model.dart
class FileModel {
  final String id;
  final String fileName;
  final String path;
  final String title;

  FileModel({
    required this.id,
    required this.fileName,
    required this.path,
    required this.title,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['_id'],
      fileName: json['fileName'],
      path: json['path'],
      title: json['title'],
    );
  }
}

// user.dart
class User {
  final String id;
  final String firstName;
  final FileModel? image;

  User({
    required this.id,
    required this.firstName,
    this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      firstName: json['firstName'],
      image: json['image'] != null ? FileModel.fromJson(json['image']) : null,
    );
  }
}

// chat.dart
class Chat {
  final String id;
  final List<ChatMessage> messages;

  Chat({
    required this.id,
    required this.messages,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['_id'],
      messages: (json['messages'] as List<dynamic>)
          .map((message) => ChatMessage.fromJson(message))
          .toList(),
    );
  }
}
