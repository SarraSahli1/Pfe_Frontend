import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/createTicket.dart.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/ticket_detail.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/widgets/Header.dart';
import 'package:helpdeskfrontend/widgets/navbar_technicien.dart';
import 'package:intl/intl.dart';

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_filterTickets);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    _token = await authService.getToken();
    _currentUserId = await authService.getCurrentUserId();

    if (_currentUserId == null && _token != null) {
      _currentUserId = _extractUserIdFromToken(_token!);
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
      if (await AuthService().isLoggedIn()) {
        await _loadTickets();
      } else {
        setState(() {
          _errorMessage = 'Technician not authenticated. Please login again.';
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

      final tickets = await TicketService.getMyTickets();
      setState(() {
        _ticketsFuture = Future.value(tickets);
      });
    } catch (e) {
      debugPrint('Error loading tickets: $e');
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

  Future<void> _refreshTickets() async {
    if (_isRefreshing) return;
    await _loadTickets();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppHeader(
        title: 'My Tickets',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketPage()),
          );
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
                ? [Color(0xFF141218), Color(0xFF242E3E)]
                : [Color(0xFF628FF6).withOpacity(0.8), Color(0xFFF7F9F5)],
            stops: [0.5, 1.0],
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
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color(0xFF242E3E) : Color(0xFFF7F9F5),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          SizedBox(height: 16),
          Text('Loading tickets...'),
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
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshTickets,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthError() {
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
            ),
          ),
          const SizedBox(height: 8),
          Text(_errorMessage ?? 'Please login again'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You currently have no tickets assigned to you',
            style: TextStyle(
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

            Navigator.of(context).pop();

            if (_token == null || _currentUserId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Authentication required. Please login again.'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketDetailScreen(
                  ticket: ticket,
                  token: _token!,
                  currentUserId: _currentUserId!,
                  onSolutionAdded: () {
                    // Refresh ticket data in parent widget
                    _loadTickets();
                  },
                ),
              ),
            );
          } catch (e) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                duration: const Duration(seconds: 2),
              ),
            );
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
                  style: TextStyle(
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
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
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
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
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
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
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
}
