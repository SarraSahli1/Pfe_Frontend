import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/provider/notification_provider.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/createTicket.dart.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/ticket_detail.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/services/socket_service.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/widgets/Header.dart';
import 'package:helpdeskfrontend/widgets/NotificationScreen.dart';
import 'package:helpdeskfrontend/widgets/navbar_technicien.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

class TechnicianTicketsScreen extends StatefulWidget {
  const TechnicianTicketsScreen({Key? key}) : super(key: key);

  @override
  _TechnicianTicketsScreenState createState() =>
      _TechnicianTicketsScreenState();
}

class _TechnicianTicketsScreenState extends State<TechnicianTicketsScreen> {
  Future<List<Ticket>> _ticketsFuture = Future.value([]);
  bool _isRefreshing = false;
  String? _errorMessage;
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserId;
  String? _token;
  late SocketService _socketService;
  bool _isSocketConnected = false;
  bool _isInitialized = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    print('TechnicianTicketsScreen: initState called');
    _socketService = SocketService();
    _searchController.addListener(_filterTickets);
    _loadInitialData();
  }

  @override
  void dispose() {
    print('TechnicianTicketsScreen: dispose called');
    _searchController.removeListener(_filterTickets);
    _searchController.dispose();
    _socketService.removeNotificationListener(_handleNotification);
    _socketService.onConnectionStatus = null;
    _socketService.disconnect();
    super.dispose();
  }

  void _initializeSocketService() async {
    if (_isInitialized) {
      print('TechnicianTicketsScreen: Already initialized, skipping');
      return;
    }
    _isInitialized = true;

    try {
      final authService = AuthService();
      _token = await authService.getToken();
      _currentUserId = await authService.getCurrentUserId() ??
          _extractUserIdFromToken(_token!);
      if (_token != null && _currentUserId != null) {
        print(
            'TechnicianTicketsScreen: Initializing socket, token: ${_token!.substring(0, 10)}..., userId: $_currentUserId');
        _socketService.initialize(
          userId: _currentUserId!,
          onNotification: _handleNotification,
        );
        _socketService.onConnectionStatus = (isConnected) {
          print(
              'TechnicianTicketsScreen: Socket connection status: $isConnected');
          if (mounted) {
            setState(() {
              _isSocketConnected = isConnected;
            });
            if (!isConnected) {
              _scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: const Text('Socket disconnected. Reconnecting...'),
                  ),
                ),
              );
            }
          }
        };
        await _socketService.connect(_token!);
      } else {
        print(
            'TechnicianTicketsScreen: Authentication failed, token: $_token, userId: $_currentUserId');
        if (mounted) {
          setState(() {
            _errorMessage = 'Authentication failed. Please log in again.';
          });
        }
      }
    } catch (e) {
      print('TechnicianTicketsScreen: Error initializing socket: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize real-time updates.';
        });
      }
    }
  }

  String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      return payload['userId'] ?? payload['sub'] ?? payload['_id'];
    } catch (e) {
      debugPrint('Error extracting user ID from token: $e');
      return null;
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final authService = AuthService();
      if (await authService.isLoggedIn()) {
        await Provider.of<NotificationProvider>(context, listen: false)
            .loadInitialNotifications(_token ?? '');
        await _loadTickets();
        _initializeSocketService();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Technician not authenticated. Please log in again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _loadTickets() async {
    try {
      if (mounted) {
        setState(() {
          _isRefreshing = true;
          _errorMessage = null;
        });
      }
      final tickets = await TicketService.getMyTickets();
      if (mounted) {
        setState(() {
          _ticketsFuture = Future.value(tickets);
        });
      }
    } catch (e) {
      debugPrint('Error loading tickets: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _ticketsFuture = Future.value([]);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _filterTickets() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshTickets() async {
    if (_isRefreshing) return;
    await _loadTickets();
  }

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _handleNotification(Map<String, dynamic> data) {
    print("TechnicianTicketsScreen: Received notification: $data");
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.addNotification(data);
    print(
        "TechnicianTicketsScreen: Added notification, unreadCount: ${notificationProvider.unreadCount}");
    if (!mounted) return;

    String message;
    if (data['type'] == 'status-change') {
      message = data['message']?['message'] ?? 'Ticket status updated';
    } else if (data['type'] == 'chat_message') {
      message = 'New message in ticket ${data['ticketId']}';
    } else {
      return;
    }

    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () async {
            try {
              final ticket =
                  await TicketService.getTicketDetails(data['ticketId']);
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketDetailScreen(
                      ticket: ticket,
                      token: _token ?? '',
                      currentUserId: _currentUserId ?? '',
                      onSolutionAdded: _loadTickets,
                    ),
                  ),
                );
                notificationProvider.markAllAsReadForTicket(data['ticketId']);
              }
            } catch (e) {
              if (mounted) {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        'Error: $e',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldMessengerKey,
      extendBodyBehindAppBar: true,
      appBar: AppHeader(
        title: 'My Tickets',
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              print(
                  'AppHeader badge rebuild, unreadCount: ${notificationProvider.unreadCount}, '
                  'provider instance: ${notificationProvider.hashCode}');
              return badges.Badge(
                key: const ValueKey('notification_badge'),
                showBadge: notificationProvider.unreadCount > 0,
                badgeContent: Text(
                  '${notificationProvider.unreadCount}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
                badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
                child: IconButton(
                  key: const ValueKey('notification_icon'),
                  icon: Icon(
                    Icons.notifications,
                    color: notificationProvider.unreadCount > 0
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () {
                    print(
                        'Notification icon tapped, unreadCount: ${notificationProvider.unreadCount}');
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Notifications',
                      pageBuilder: (context, _, __) => Center(
                        child: NotificationCard(
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      ),
                      barrierColor: Colors.black.withOpacity(0.5),
                      transitionBuilder: (context, animation, __, child) {
                        return ScaleTransition(
                          scale: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          ),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 200),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                position: badges.BadgePosition.topEnd(top: -8, end: -8),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketPage()),
          );
          if (result == true) {
            await _refreshTickets();
          }
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF141218), const Color(0xFF242E3E)]
                : [
                    const Color(0xFF628FF6).withOpacity(0.8),
                    const Color(0xFFF7F9F5)
                  ],
            stops: const [0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tickets...',
                      hintStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon:
                                  const Icon(Icons.clear, color: Colors.orange),
                              onPressed: () {
                                _searchController.clear();
                                _filterTickets();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 18),
                    ),
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF242E3E)
                        : const Color(0xFFF7F9F5),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavbarTechnician(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null &&
        (_errorMessage!.toLowerCase().contains('authenticated') ||
            _errorMessage!.toLowerCase().contains('session expired'))) {
      return _buildAuthError();
    }

    return RefreshIndicator(
      onRefresh: _refreshTickets,
      color: Colors.orange,
      child: FutureBuilder<List<Ticket>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_isRefreshing) {
            return _buildLoading();
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }
          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return _buildEmptyState();
          }
          return _buildTicketList(tickets);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)),
          const SizedBox(height: 16),
          Text(
            'Loading tickets...',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Loading Error',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshTickets,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthError() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 50, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Authentication Problem',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Please log in again',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 60,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No tickets assigned',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You currently have no tickets assigned to you',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList(List<Ticket> tickets) {
    final filteredTickets = _searchController.text.isEmpty
        ? tickets
        : tickets
            .where((ticket) =>
                ticket.title
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()) ||
                ticket.description
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()))
            .toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: filteredTickets.length,
      itemBuilder: (context, index) {
        final ticket = filteredTickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );

          try {
            if (_token == null || _currentUserId == null) {
              await _loadUserData();
            }

            if (_token == null || _currentUserId == null) {
              throw Exception('Authentication required. Please log in again.');
            }

            if (mounted) {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TicketDetailScreen(
                    ticket: ticket,
                    token: _token!,
                    currentUserId: _currentUserId!,
                    onSolutionAdded: _loadTickets,
                  ),
                ),
              );
              Provider.of<NotificationProvider>(context, listen: false)
                  .markAllAsReadForTicket(ticket.id);
            }
          } catch (e) {
            if (mounted) {
              Navigator.of(context).pop();
              _scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      'Error: $e',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.title,
                style: GoogleFonts.poppins(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (ticket.description.isNotEmpty)
                Text(
                  ticket.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDate(ticket.creationDate)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  if (ticket.assignedDate != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.person,
                      size: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned: ${_formatDate(ticket.assignedDate!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              if (ticket.equipmentHelpdeskIds != null &&
                  ticket.equipmentHelpdeskIds!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.computer,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ticket.equipmentHelpdeskIds!.length} equipment',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    _token = await authService.getToken();
    _currentUserId = await authService.getCurrentUserId() ??
        _extractUserIdFromToken(_token!);
  }
}
