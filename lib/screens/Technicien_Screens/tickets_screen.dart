import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/provider/notification_provider.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Tickets/createTicket.dart.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/ticket_detail.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/services/socket_service.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/widgets/Header.dart';
import 'package:helpdeskfrontend/widgets/navbar_technicien.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  bool _isInitialized = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  String _selectedStatus = 'all';
  final List<String> _statusOptions = [
    'all',
    'In Progress',
    'Resolved',
    'Closed'
  ];

  // Very light pastel colors for cards (.shade50)
  final Map<String, Color> _statusCardColors = {
    'all': Colors.blueGrey.shade50,
    'In Progress': Colors.orange.shade50,
    'Resolved': Colors.green.shade50,
    'Closed': Colors.indigo.shade50,
  };

  // Light pastel colors for filter chips (.shade100)
  final Map<String, Color> _statusFilterColors = {
    'all': Colors.blueGrey.shade100,
    'In Progress': Colors.orange.shade100,
    'Resolved': Colors.green.shade100,
    'Closed': Colors.indigo.shade100,
  };

  // Vibrant colors for badges
  final Map<String, Color> _statusBadgeColors = {
    'all': Colors.blueGrey,
    'In Progress': Colors.orange,
    'Resolved': Colors.green,
    'Closed': Colors.indigo,
  };

  // Icons for each status
  final Map<String, IconData> _statusIcons = {
    'all': Icons.filter_alt,
    'In Progress': Icons.autorenew,
    'Resolved': Icons.check_circle,
    'Closed': Icons.lock,
  };

  @override
  void initState() {
    super.initState();
    _socketService = SocketService();
    _searchController.addListener(_filterTickets);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTickets);
    _searchController.dispose();
    _socketService.removeNotificationListener(_handleNotification);
    _socketService.onConnectionStatus = null;
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    try {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });

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

  Future<void> _loadInitialData() async {
    try {
      final authService = AuthService();
      if (await authService.isLoggedIn()) {
        await Provider.of<NotificationProvider>(context, listen: false)
            .loadInitialNotifications(_token ?? '');
        await _loadTickets();
        await _initializeSocketService();
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

  Future<void> _initializeSocketService() async {
    if (_isInitialized) return;

    try {
      final authService = AuthService();
      _token = await authService.getToken();
      _currentUserId = await authService.getCurrentUserId() ??
          _extractUserIdFromToken(_token!);

      if (_token != null && _currentUserId != null) {
        _socketService.initialize(
          userId: _currentUserId!,
          onNotification: _handleNotification,
        );

        _socketService.onConnectionStatus = (isConnected) {
          if (mounted) {
            setState(() {});
          }
        };

        await _socketService.connect(_token!);
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Error initializing socket: $e');
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

  List<Ticket> _filterTicketsByStatus(List<Ticket> tickets, String status) {
    if (status == 'all') return tickets;
    return tickets.where((ticket) => ticket.status == status).toList();
  }

  List<Ticket> _filterTicketsBySearch(List<Ticket> tickets, String query) {
    if (query.isEmpty) return tickets;
    return tickets.where((ticket) {
      final title = ticket.title.toLowerCase();
      final description = ticket.description.toLowerCase();
      final searchLower = query.toLowerCase();
      return title.contains(searchLower) || description.contains(searchLower);
    }).toList();
  }

  void _filterTickets() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshTickets() async {
    if (_isRefreshing) return;
    await _loadTickets();
  }

  void _onItemTapped(int index) {
    if (mounted) setState(() => _selectedIndex = index);
  }

  Widget _buildStatusFilterChips(bool isDarkMode) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _statusOptions.length,
        itemBuilder: (context, index) {
          final status = _statusOptions[index];
          final isSelected = _selectedStatus == status;
          final filterColor = _statusFilterColors[status]!;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _statusIcons[status],
                    size: 18,
                    color:
                        isSelected ? Colors.white : _statusBadgeColors[status],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status == 'all' ? 'All' : status,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              selectedColor: _statusBadgeColors[status],
              backgroundColor: filterColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? _statusBadgeColors[status]!.withOpacity(0.5)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              elevation: 2,
              onSelected: (selected) {
                if (mounted) {
                  setState(() => _selectedStatus = selected ? status : 'all');
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _handleNotification(Map<String, dynamic> data) {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.addNotification(data);

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
        content: Text(message),
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
                    content: Text('Error: $e'),
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
        actions: const [],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketPage()),
          );
          if (result == true && mounted) {
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
              _buildStatusFilterChips(isDarkMode),
              const SizedBox(height: 8),
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
        currentIndex: 2, // Index pour Tickets
        context: context,
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

  Widget _buildTicketList(List<Ticket> tickets) {
    final filteredTickets = _filterTicketsByStatus(
      _filterTicketsBySearch(tickets, _searchController.text),
      _selectedStatus,
    );

    if (filteredTickets.isEmpty) {
      return _buildEmptyFilterState();
    }

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
    final cardColor = _statusCardColors[ticket.status] ?? Colors.grey.shade50;
    final badgeColor = _statusBadgeColors[ticket.status] ?? Colors.grey;
    final textColor = Colors.black87;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: cardColor,
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
                  content: Text('Error: $e'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.status,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (ticket.description.isNotEmpty)
                Text(
                  ticket.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: textColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDate(ticket.creationDate)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                  if (ticket.assignedDate != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.person,
                      size: 16,
                      color: textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned: ${_formatDate(ticket.assignedDate!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textColor.withOpacity(0.6),
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
                        color: textColor.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ticket.equipmentHelpdeskIds!.length} equipment',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textColor.withOpacity(0.6),
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

  Widget _buildEmptyFilterState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No tickets found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
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
