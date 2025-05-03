import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/chat_message.dart';
import 'package:helpdeskfrontend/services/chat_service.dart';
import 'package:helpdeskfrontend/services/socket_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/notification_provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';

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
  final ChatService _chatService = ChatService();
  late final SocketService _socketService;
  late Future<Chat> _chatFuture;
  List<ChatMessage> _messages = [];
  List<XFile> _selectedFiles = [];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _socketService = SocketService();
    if (!_socketService.isConnected) {
      _socketService.connect(widget.token);
    }

    _socketService.onConnectionStatus = (isConnected) {
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat server disconnected')),
        );
      }
    };

    _socketService.addNotificationListener(_handleSocketMessage);
    _loadChat();

    // Mark all messages as read when chat opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.markAllAsReadForTicket(widget.ticketId);
    });
  }

  void _handleSocketMessage(Map<String, dynamic> data) {
    if (data['ticketId'] == widget.ticketId) {
      final message = ChatMessage.fromJson(data['message']);
      _handleNewMessage(message);

      // Mark incoming message as read
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.markAsRead(message.id);
    }
  }

  void _handleNewMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
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

      // Mark all messages as read when chat loads
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.markAllAsReadForTicket(widget.ticketId);

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load chat: ${e.toString()}')),
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
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickFiles() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null) {
        setState(() {
          _selectedFiles.addAll(pickedFiles);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick files: ${e.toString()}')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildFilePreview() {
    if (_selectedFiles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: Stack(
              children: [
                Container(
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
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFiles.removeAt(index);
                      });
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDarkMode) {
    final isCurrentUser = message.senderId == widget.currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode
                    ? const Color(0xFF3A4352)
                    : const Color(0xFFF2F8FF),
              ),
              child: message.sender.image?.path != null &&
                      message.sender.image!.path.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        message.sender.image!.path,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: isDarkMode
                                  ? Colors.white70
                                  : const Color(0xFF0070F0),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: SvgPicture.asset(
                            'assets/chat_avatar.svg',
                            width: 16,
                            height: 16,
                            color: isDarkMode
                                ? Colors.white70
                                : const Color(0xFF0070F0),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: SvgPicture.asset(
                        'assets/chat_avatar.svg',
                        width: 16,
                        height: 16,
                        color: isDarkMode
                            ? Colors.white70
                            : const Color(0xFF0070F0),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? const Color(0xFF628ff6)
                    : isDarkMode
                        ? const Color(0xFF3A4352)
                        : const Color(0xFFF2F4F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isCurrentUser ? 12 : 0),
                  topRight: const Radius.circular(12),
                  bottomLeft: const Radius.circular(12),
                  bottomRight: Radius.circular(isCurrentUser ? 0 : 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        message.sender.firstName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isCurrentUser
                              ? Colors.white
                              : isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF303437),
                        ),
                      ),
                    ),
                  if (message.message != null && message.message!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        message.message!,
                        style: GoogleFonts.poppins(
                          color: isCurrentUser
                              ? Colors.white
                              : isDarkMode
                                  ? Colors.white70
                                  : const Color(0xFF303437),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  if (message.files.isNotEmpty)
                    Column(
                      children: message.files.map((file) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: GestureDetector(
                            onTap: () => _showFullScreenImage(file.path),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                file.path,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 150,
                                    height: 150,
                                    color: isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 150,
                                    height: 150,
                                    color: isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    child: Center(
                                      child: Icon(
                                        Icons.error,
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      DateFormat('HH:mm').format(message.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isCurrentUser
                            ? Colors.white70
                            : isDarkMode
                                ? Colors.white54
                                : const Color(0xFF72777A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // TODO: Implement download functionality
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _socketService.removeNotificationListener(_handleSocketMessage);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF141218), const Color(0xFF242e3e)]
                : [const Color(0xFF628ff6), const Color(0xFFf7f9f5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const ThemeToggleButton(),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF242E3E) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: FutureBuilder<Chat>(
                            future: _chatFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              } else {
                                return ListView.builder(
                                  controller: _scrollController,
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    final message = _messages[index];
                                    return _buildMessageBubble(
                                        message, isDarkMode);
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      _buildFilePreview(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color:
                            isDarkMode ? const Color(0xFF3A4352) : Colors.white,
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.attach_file,
                                color: isDarkMode
                                    ? Colors.white70
                                    : const Color(0xFF628ff6),
                              ),
                              onPressed: _pickFiles,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: GoogleFonts.poppins(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: GoogleFonts.poppins(
                                    color: isDarkMode
                                        ? Colors.white54
                                        : Colors.grey[600],
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode
                                      ? const Color(0xFF2D3646)
                                      : const Color(0xFFF2F4F5),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF628ff6),
                              ),
                              child: IconButton(
                                icon:
                                    const Icon(Icons.send, color: Colors.white),
                                onPressed: _sendMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
