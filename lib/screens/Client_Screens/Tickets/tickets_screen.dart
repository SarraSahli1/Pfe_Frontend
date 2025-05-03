import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Tickets/createTicket.dart.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Tickets/ticket_detail_screen.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/widgets/navbar_client.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/services/socket_service.dart'; // Import SocketService

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
  late SocketService _socketService; // SocketService instance
  bool _isSocketConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeSocketService();
    _loadInitialData();
    _searchController.addListener(_filterTickets);
  }

  @override
  void dispose() {
    _socketService.disconnect(); // Disconnect socket on dispose
    _searchController.dispose();
    super.dispose();
  }

  void _initializeSocketService() async {
    try {
      final token = await _authService.getToken();
      final userId = await _authService.getCurrentUserId();
      if (token != null && userId != null) {
        _socketService = SocketService();
        _socketService.initialize(
          userId: userId,
          onNotification: (data) {
            print("Received notification: $data");
            if (data['type'] == 'chat_message') {
              // Show a snackbar for new chat messages
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('New message in ticket ${data['ticketId']}'),
                  action: SnackBarAction(
                    label: 'View',
                    onPressed: () {
                      // Navigate to the ticket's chat screen
                      _navigateToTicketDetail(
                        _ticketsFuture.then((tickets) => tickets.firstWhere(
                              (ticket) => ticket.id == data['ticketId'],
                              orElse: () => throw Exception('Ticket not found'),
                            )) as Ticket,
                      );
                    },
                  ),
                ),
              );
            }
            _refreshTickets(); // Refresh tickets for any notification
          },
        );
        _socketService.onConnectionStatus = (isConnected) {
          setState(() {
            _isSocketConnected = isConnected;
          });
          if (!isConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Socket disconnected. Reconnecting...')),
            );
          }
        };
        _socketService.connect(token);
      }
    } catch (e) {
      print("Error initializing socket: $e");
      setState(() {
        _errorMessage = 'Failed to initialize real-time updates.';
      });
    }
  }

  Future<void> _loadInitialData() async {
    try {
      if (await _authService.isLoggedIn()) {
        await _loadTickets();
      } else {
        setState(() {
          _errorMessage = 'User not authenticated. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _loadTickets() async {
    try {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
      final tickets = await TicketService.getTicketsByClient();
      setState(() {
        _ticketsFuture = Future.value(tickets);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _ticketsFuture = Future.value([]);
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _filterTickets() {
    setState(() {});
  }

  void _filterByType(String? type) {
    setState(() {
      _selectedTypeFilter = type;
    });
  }

  Future<void> _refreshTickets() async {
    if (_isRefreshing) return;
    await _loadTickets();
  }

  Future<void> _navigateToCreateTicket() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateTicketPage()),
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
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating to ticket: $e'),
            duration: Duration(seconds: 6),
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
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Color(0xFF141218), Color(0xFF242E3E)]
                : [Color(0xFF628FF6).withOpacity(0.8), Color(0xFFF7F9F5)],
            stops: [0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment, color: Colors.white, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'My Tickets',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          _isSocketConnected
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: _isSocketConnected ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      radius: 20,
                      child: ThemeToggleButton(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color(0xFF3A4352) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: Offset(0, 4),
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
                              icon: Icon(Icons.clear, color: Colors.orange),
                              onPressed: () =>
                                  setState(() => _searchController.clear()),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    ),
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTypeFilterChip(context,
                        type: null,
                        label: 'All',
                        icon: Icons.all_inclusive,
                        isSelected: _selectedTypeFilter == null),
                    _buildTypeFilterChip(context,
                        type: 'service',
                        label: 'Service',
                        icon: Icons.handyman,
                        isSelected: _selectedTypeFilter == 'service'),
                    _buildTypeFilterChip(context,
                        type: 'equipment',
                        label: 'Equipment',
                        icon: Icons.computer,
                        isSelected: _selectedTypeFilter == 'equipment'),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color(0xFF242E3E) : Color(0xFFf7f9f5),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, -2),
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
        label: Text('Create Ticket', style: TextStyle(color: Colors.white)),
        icon: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.orange,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBar: NavbarClient(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
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
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (type == 'service'
                  ? Colors.orange
                  : type == 'equipment'
                      ? Colors.blue
                      : Colors.grey)
              : (isDarkMode ? Color(0xFF3A4352) : Colors.white),
          borderRadius: BorderRadius.circular(50),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white : Colors.black)),
            SizedBox(width: 8),
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
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)),
          SizedBox(height: 16),
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
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Loading Error',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshTickets,
            icon: Icon(Icons.refresh, size: 20),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          Icon(Icons.person_off, size: 60, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Authentication Issue',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Please try again later',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshTickets,
            icon: Icon(Icons.refresh, size: 20),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          SizedBox(height: 16),
          Text(
            'No Tickets Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first ticket now!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToCreateTicket,
            icon: Icon(Icons.add, size: 20),
            label: Text('Create Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        color: isDarkMode ? Color(0xFF3A4352) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              SizedBox(height: 8),
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
              SizedBox(height: 8),
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
              SizedBox(height: 8),
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
