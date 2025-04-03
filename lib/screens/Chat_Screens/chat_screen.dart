// chat_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/models/chat_message.dart';
import 'package:helpdeskfrontend/services/chat_service.dart';
import 'package:helpdeskfrontend/services/socket_service.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String ticketId;
  final String token;
  final String currentUserId;

  const ChatScreen({
    required this.ticketId,
    required this.token,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService(
      baseUrl: 'http://192.168.1.16:3000'); // Replace with your actual URL
  late final SocketService _socketService;
  late Future<Chat> _chatFuture;
  List<ChatMessage> _messages = [];
  List<XFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _socketService = SocketService();
    _socketService.connect(widget.token);
    _socketService.subscribeToChat(widget.ticketId, _handleNewMessage);
    _loadChat();
  }

  void _handleNewMessage(ChatMessage message) {
    setState(() {
      _messages.add(message); // Add to end of list since ListView is reversed
    });
  }

  Future<void> _loadChat() async {
    setState(() {
      _chatFuture =
          _chatService.getChatForTicket(widget.ticketId, widget.token);
    });

    try {
      final chat = await _chatFuture;
      setState(() {
        _messages = chat.messages;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load chat: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty && _selectedFiles.isEmpty) return;

    try {
      final message = await _chatService.sendMessage(
        ticketId: widget.ticketId,
        senderId: widget.currentUserId,
        message: _messageController.text,
        token: widget.token,
        files: _selectedFiles.map((xfile) => File(xfile.path)).toList(),
      );

      setState(() {
        _messages.add(message);
        _messageController.clear();
        _selectedFiles.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Future<void> _pickFiles() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    setState(() {
      _selectedFiles.addAll(pickedFiles);
    });
  }

  Widget _buildFilePreview() {
    if (_selectedFiles.isEmpty) return Container();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(4),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(file.path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      _selectedFiles.removeAt(index);
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isCurrentUser = message.senderId == widget.currentUserId;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isCurrentUser ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              Text(
                message.sender.firstName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.white : Colors.black,
                ),
              ),
            if (message.message != null && message.message!.isNotEmpty)
              Text(
                message.message!,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black,
                ),
              ),
            if (message.files.isNotEmpty)
              Column(
                children: message.files.map((file) {
                  return GestureDetector(
                    onTap: () {
                      // Show full screen image
                      _showFullScreenImage(file.path);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: Image.network(
                        file.path,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 4),
            Text(
              '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<Chat>(
              future: _chatFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      return _buildMessageBubble(message);
                    },
                  );
                }
              },
            ),
          ),
          _buildFilePreview(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickFiles,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
