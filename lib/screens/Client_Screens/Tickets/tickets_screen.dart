import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Tickets/createTicket.dart.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Tickets/ticket_detail_screen.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/widgets/Header.dart';
import 'package:helpdeskfrontend/widgets/NotificationScreen.dart';
import 'package:helpdeskfrontend/widgets/navbar_client.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/provider/notification_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:helpdeskfrontend/services/socket_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  _TicketsScreenState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  Future<List<Ticket>> _ticketsFuture = Future.value([]);
  bool _isRefreshing = false;
  String? _errorMessage;
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _selectedTypeFilter;
  late SocketService _socketService;
  bool _isSocketConnected = false;
  bool _isInitialized = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    print('TicketsScreen: initState called');
    _socketService = SocketService();
    _initializeSocketService();
    _loadInitialData();
    _searchController.addListener(_filterTickets);
  }

  @override
  void dispose() {
    print('TicketsScreen: dispose called');
    _searchController.removeListener(_filterTickets);
    _searchController.dispose();
    _socketService.removeNotificationListener(_handleNotification);
    _socketService.onConnectionStatus = null;
    _socketService.disconnect();
    super.dispose();
  }

  void _handleNotification(Map<String, dynamic> data) {
    print("TicketsScreen: Received notification: $data");
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.addNotification(data);
    print(
        "TicketsScreen: Added notification, unreadCount: ${notificationProvider.unreadCount}");
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
                  await _ticketsFuture.then((tickets) => tickets.firstWhere(
                        (ticket) => ticket.id == data['ticketId'],
                        orElse: () => throw Exception('Ticket not found'),
                      ));
              _navigateToTicketDetail(ticket);
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
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _initializeSocketService() async {
    if (_isInitialized) {
      print('TicketsScreen: Already initialized, skipping');
      return;
    }
    _isInitialized = true;

    try {
      final token = await _authService.getToken();
      final userId = await _authService.getCurrentUserId();
      if (token != null && userId != null) {
        print(
            'TicketsScreen: Initializing socket, token: ${token.substring(0, 10)}..., userId: $userId');
        _socketService.initialize(
          userId: userId,
          onNotification: _handleNotification,
        );
        _socketService.onConnectionStatus = (isConnected) {
          print('TicketsScreen: Socket connection status: $isConnected');
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
        await _socketService.connect(token);
      } else {
        print(
            'TicketsScreen: Authentication failed, token: $token, userId: $userId');
        if (mounted) {
          setState(() {
            _errorMessage = 'Authentication failed. Please log in again.';
          });
        }
      }
    } catch (e) {
      print('TicketsScreen: Error initializing socket: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize real-time updates.';
        });
      }
    }
  }

  Future<void> _loadInitialData() async {
    try {
      if (await _authService.isLoggedIn()) {
        await Provider.of<NotificationProvider>(context, listen: false)
            .loadInitialNotifications(await _authService.getToken() ?? '');
        await _loadTickets();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'User not authenticated. Please try again later.';
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
      final tickets = await TicketService.getTicketsByClient();
      if (mounted) {
        setState(() {
          _ticketsFuture = Future.value(tickets);
        });
      }
    } catch (e) {
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

  void _filterByType(String? type) {
    if (mounted) {
      setState(() {
        _selectedTypeFilter = type;
      });
    }
  }

  Future<void> _refreshTickets() async {
    if (_isRefreshing) return;
    await _loadTickets();
  }

  Future<void> _navigateToCreateTicket() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTicketPage()),
    );
    if (result == true) {
      await _refreshTickets();
    }
  }

  Future<void> _navigateToTicketDetail(Ticket ticket) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final token = await _authService.getToken();
      final userId = await _authService.getCurrentUserId();
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailScreen(
              ticket: ticket,
              token: token ?? '',
              currentUserId: userId ?? '',
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
                'Error navigating to ticket: $e',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ThemeToggleButton(),
          ),
          const SizedBox(width: 4),
        ],
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildTypeFilterChip(
                        context,
                        type: null,
                        label: 'All',
                        icon: Icons.all_inclusive,
                        isSelected: _selectedTypeFilter == null,
                      ),
                      const SizedBox(width: 8),
                      _buildTypeFilterChip(
                        context,
                        type: 'service',
                        label: 'Service',
                        icon: Icons.handyman,
                        isSelected: _selectedTypeFilter == 'service',
                      ),
                      const SizedBox(width: 8),
                      _buildTypeFilterChip(
                        context,
                        type: 'equipment',
                        label: 'Equipment',
                        icon: Icons.computer,
                        isSelected: _selectedTypeFilter == 'equipment',
                      ),
                    ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateTicket,
        label:
            const Text('Create Ticket', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.orange,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBar: NavbarClient(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (mounted) {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }

  Widget _buildTypeFilterChip(
    BuildContext context, {
    required String? type,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: () => _filterByType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (type == 'service'
                  ? Colors.orange
                  : type == 'equipment'
                      ? Colors.blue
                      : Colors.grey)
              : (isDarkMode ? const Color(0xFF3A4352) : Colors.white),
          borderRadius: BorderRadius.circular(50),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
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
          return _buildTicketGrid(tickets);
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Loading Error',
            style: GoogleFonts.poppins(
              fontSize: 20,
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
          ElevatedButton.icon(
            onPressed: _refreshTickets,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthError() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Authentication Issue',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Please try again later',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            icon: const Icon(Icons.login, size: 20),
            label: const Text('Login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in,
            size: 80,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Tickets Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first ticket now!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToCreateTicket,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Create Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketGrid(List<Ticket> tickets) {
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

    final typeFilteredTickets = _selectedTypeFilter == null
        ? filteredTickets
        : filteredTickets
            .where((ticket) => ticket.typeTicket == _selectedTypeFilter)
            .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: typeFilteredTickets.length,
      itemBuilder: (context, index) =>
          _buildGridTicketCard(typeFilteredTickets[index]),
    );
  }

  Widget _buildGridTicketCard(Ticket ticket) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return InkWell(
      onTap: () => _navigateToTicketDetail(ticket),
      splashColor: Colors.orange.withOpacity(0.2),
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(ticket.status),
                            _getStatusColor(ticket.status).withOpacity(0.7)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _translateStatus(ticket.status),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Icon(
                    ticket.typeTicket == 'service'
                        ? Icons.handyman
                        : Icons.computer,
                    size: 20,
                    color: ticket.typeTicket == 'service'
                        ? Colors.orange
                        : Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  ticket.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${_formatDate(ticket.creationDate)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (ticket.resolvedDate != null)
                Text(
                  'Resolved: ${_formatDate(ticket.resolvedDate!)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _translateStatus(String status) {
    const statusTranslations = {
      'Not Assigned': 'Not Assigned',
      'Assigned': 'Assigned',
      'In Progress': 'In Progress',
      'Resolved': 'Resolved',
      'Closed': 'Closed',
      'Expired': 'Expired',
      'Deleted': 'Deleted',
    };
    return statusTranslations[status] ?? status;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'not assigned':
        return Colors.grey;
      case 'assigned':
        return Colors.blue;
      case 'in progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.purple;
      case 'expired':
        return Colors.red;
      case 'deleted':
        return Colors.grey[700]!;
      default:
        return Colors.blueGrey;
    }
  }
}
