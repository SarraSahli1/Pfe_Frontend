import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/chat_message.dart';
import 'package:helpdeskfrontend/screens/Chat_Screens/schedule_meeting_modal.dart';
import 'package:helpdeskfrontend/services/chat_service.dart';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:helpdeskfrontend/services/socket_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/notification_provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  DateTime _lastScrollTime = DateTime.now();
  final Duration _scrollDebounceDuration = const Duration(milliseconds: 100);
  ScaffoldMessengerState? _scaffoldMessenger;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _socketService = SocketService();
    _socketService.initialize(userId: widget.currentUserId);
    if (!_socketService.isConnected) {
      _socketService.connect(widget.token);
    }
    _socketService.setActiveTicketId(widget.ticketId); // Set active ticketId
    _socketService.subscribeToTicket(widget.ticketId);

    _socketService.onConnectionStatus = (isConnected) {
      if (!isConnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat server disconnected')),
        );
      }
    };

    _socketService.addNotificationListener(_handleSocketMessage);
    _loadChat();
    _fetchUserRole();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notificationProvider =
            Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.markAllAsReadForTicket(widget.ticketId);
      }
    });
  }

  Future<void> _fetchUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('userRole');
      if (role != null) {
        if (mounted) {
          setState(() {
            _userRole = role;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/user/role/${widget.currentUserId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fetchedRole = data['role']?.toString() ?? 'client';
        await prefs.setString('userRole', fetchedRole);
        if (mounted) {
          setState(() {
            _userRole = fetchedRole;
          });
        }
      } else {
        debugPrint('[ChatScreen] Failed to fetch role: ${response.body}');
        if (mounted) {
          setState(() {
            _userRole = 'client';
          });
        }
      }
    } catch (e) {
      debugPrint('[ChatScreen] Error fetching role: $e');
      if (mounted) {
        setState(() {
          _userRole = 'client';
        });
      }
    }
  }

  Future<void> _scheduleMeeting(
      DateTime scheduledDate, int duration, String? message) async {
    try {
      final meetingMessage = await _chatService.scheduleMeeting(
        ticketId: widget.ticketId,
        senderId: widget.currentUserId,
        scheduledDate: scheduledDate,
        duration: duration,
        message: message,
        token: widget.token,
      );

      if (mounted) {
        setState(() {
          if (!_messages.any((msg) => msg.id == meetingMessage.id)) {
            _messages.add(meetingMessage);
            debugPrint(
                '[ChatScreen] Scheduled and added meeting message: ${meetingMessage.id}');
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(content: Text('Failed to schedule meeting: $e')),
        );
      }
    }
  }

  Future<void> _acceptMeeting(String meetingMessageId) async {
    try {
      final message = await _chatService.acceptMeeting(
        ticketId: widget.ticketId,
        meetingMessageId: meetingMessageId,
        senderId: widget.currentUserId,
        token: widget.token,
      );

      if (mounted) {
        setState(() {
          if (!_messages.any((msg) => msg.id == message.id)) {
            _messages.add(message);
            debugPrint(
                '[ChatScreen] Accepted and added message: ${message.id}');
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(content: Text('Failed to accept meeting: $e')),
        );
      }
    }
  }

  Future<void> _declineMeeting(String meetingMessageId) async {
    try {
      final message = await _chatService.declineMeeting(
        ticketId: widget.ticketId,
        meetingMessageId: meetingMessageId,
        senderId: widget.currentUserId,
        token: widget.token,
      );

      if (mounted) {
        setState(() {
          if (!_messages.any((msg) => msg.id == message.id)) {
            _messages.add(message);
            debugPrint(
                '[ChatScreen] Declined and added message: ${message.id}');
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(content: Text('Failed to decline meeting: $e')),
        );
      }
    }
  }

  void _handleSocketMessage(Map<String, dynamic> data) {
    debugPrint('[ChatScreen] Received message data: $data');
    if (data['ticketId'] != widget.ticketId || !mounted) {
      debugPrint(
          '[ChatScreen] Ignoring message for ticket ${data['ticketId']} or screen not mounted');
      return;
    }

    // Skip new-chat-notification for active ticket
    if (data['event'] == 'new-chat-notification') {
      debugPrint(
          '[ChatScreen] Skipping new-chat-notification for active ticket: ${data['ticketId']}');
      return;
    }

    try {
      final messageData = data['message'];
      if (messageData == null || messageData['_id'] == null) {
        debugPrint('[ChatScreen] Invalid message data: $data');
        return;
      }

      // Skip if the message is from the current user
      final senderId = messageData['sender']?['_id']?.toString();
      if (senderId == widget.currentUserId) {
        debugPrint('[ChatScreen] Skipping own message: ${messageData['_id']}');
        return;
      }

      final message = ChatMessage.fromJson(messageData);
      debugPrint('[ChatScreen] Processing new message: ${message.id}');
      if (!_messages.any((msg) => msg.id == message.id)) {
        _handleNewMessage(message);
        final notificationProvider =
            Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.markAsRead(message.id);
        debugPrint(
            '[ChatScreen] Message added and marked as read: ${message.id}');
      } else {
        debugPrint('[ChatScreen] Duplicate message skipped: ${message.id}');
      }
    } catch (e) {
      debugPrint('[ChatScreen] Error processing message: $e');
    }
  }

  void _handleNewMessage(ChatMessage message) {
    if (!mounted) {
      debugPrint('[ChatScreen] Cannot handle new message, screen not mounted');
      return;
    }
    setState(() {
      if (!_messages.any((msg) => msg.id == message.id)) {
        _messages = [..._messages, message];
        debugPrint(
            '[ChatScreen] Added new message: ${message.id}, total messages: ${_messages.length}');
      }
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
      if (mounted) {
        setState(() {
          final existingIds = _messages.map((msg) => msg.id).toSet();
          _messages = [
            ..._messages,
            ...chat.messages.where((msg) => !existingIds.contains(msg.id))
          ];
          debugPrint(
              '[ChatScreen] Loaded chat with ${chat.messages.length} messages, total: ${_messages.length}');
        });

        final notificationProvider =
            Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.markAllAsReadForTicket(widget.ticketId);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat: $e')),
        );
      }
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

      if (mounted) {
        setState(() {
          if (!_messages.any((msg) => msg.id == message.id)) {
            _messages.add(message); // Add sender's message immediately
            debugPrint('[ChatScreen] Sent and added message: ${message.id}');
          }
          _messageController.clear();
          _selectedFiles.clear();
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (mounted) {
        setState(() {
          _selectedFiles.addAll(pickedFiles);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    final now = DateTime.now();
    if (now.difference(_lastScrollTime) < _scrollDebounceDuration) return;

    _lastScrollTime = now;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        debugPrint('[ChatScreen] Scrolling to bottom');
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        debugPrint(
            '[ChatScreen] ScrollController not ready or screen not mounted');
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
                      if (mounted) {
                        setState(() {
                          _selectedFiles.removeAt(index);
                        });
                      }
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
    final isClient = _userRole == 'client';
    final isPendingMeeting = message.isMeeting &&
        message.meetingDetails != null &&
        message.meetingDetails!.status == 'pending';
    final canShowButtons = _userRole == 'client' &&
        message.isMeeting &&
        message.meetingDetails != null &&
        message.meetingDetails!.status == 'pending' &&
        !message.meetingDetails!.respondedByClient;

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
                  if (message.isMeeting && message.meetingDetails != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black26 : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.meetingDetails!.status == 'accepted'
                                ? 'Meeting Accepted'
                                : message.meetingDetails!.status == 'declined'
                                    ? 'Meeting Declined'
                                    : 'Meeting Scheduled',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: isCurrentUser
                                  ? Colors.white
                                  : isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                            ),
                          ),
                          if (message.meetingDetails!.status == 'pending') ...[
                            Text(
                              'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(message.meetingDetails!.scheduledDate)}',
                              style: GoogleFonts.poppins(
                                color: isCurrentUser
                                    ? Colors.white70
                                    : isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                              ),
                            ),
                            Text(
                              'Duration: ${message.meetingDetails!.duration} minutes',
                              style: GoogleFonts.poppins(
                                color: isCurrentUser
                                    ? Colors.white70
                                    : isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                              ),
                            ),
                          ],
                          Text(
                            'Status: ${message.meetingDetails!.status}',
                            style: GoogleFonts.poppins(
                              color: isCurrentUser
                                  ? Colors.white70
                                  : isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (message.message != null && message.message!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
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
                    if (canShowButtons)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => _acceptMeeting(message.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Accept'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _declineMeeting(message.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Decline'),
                            ),
                          ],
                        ),
                      ),
                  ] else if (message.message != null &&
                      message.message!.isNotEmpty)
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.files.map((file) {
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(file.path),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              file.path,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              frameBuilder: (context, child, frame,
                                  wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) return child;
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 500),
                                  child: child,
                                );
                              },
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
                                      value:
                                          loadingProgress.expectedTotalBytes !=
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
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.refresh,
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        if (mounted) {
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
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
    if (mounted) {
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
                  onPressed: () async {
                    if (mounted) {
                      try {
                        final response = await http.get(Uri.parse(imageUrl));
                        if (response.statusCode == 200) {
                          final directory = await getTemporaryDirectory();
                          final filePath =
                              '${directory.path}/${imageUrl.split('/').last}';
                          final file = File(filePath);
                          await file.writeAsBytes(response.bodyBytes);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Image downloaded to $filePath')),
                          );
                        } else {
                          throw Exception('Failed to download image');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Download failed: $e')),
                        );
                      }
                    }
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
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.error, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _socketService.removeNotificationListener(_handleSocketMessage);
    _socketService.unsubscribeFromTicket(widget.ticketId);
    _socketService.setActiveTicketId(null); // Clear active ticketId
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
                        child: Stack(
                          children: [
                            Container(
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
                                        child:
                                            Text('Error: ${snapshot.error}'));
                                  } else {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback(
                                            (_) => _scrollToBottom());
                                    return ListView.builder(
                                      controller: _scrollController,
                                      reverse: true,
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final message = _messages[
                                            _messages.length - 1 - index];
                                        return _buildMessageBubble(
                                            message, isDarkMode);
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                            if (!_socketService.isConnected)
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'Chat server disconnected. Reconnecting...',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildFilePreview(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
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
                            if (_userRole == 'technician')
                              IconButton(
                                icon: Icon(
                                  Icons.access_time,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : const Color(0xFF628ff6),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ScheduleMeetingModal(
                                      onSchedule: _scheduleMeeting,
                                    ),
                                  );
                                },
                              ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: GoogleFonts.poppins(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black),
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
                                      horizontal: 16, vertical: 12),
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
