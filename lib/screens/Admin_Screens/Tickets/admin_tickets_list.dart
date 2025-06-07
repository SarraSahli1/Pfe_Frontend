import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Tickets/admin_ticket_details.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/navbar_admin.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminTicketsListPage extends StatefulWidget {
  const AdminTicketsListPage({Key? key}) : super(key: key);

  @override
  _AdminTicketsListPageState createState() => _AdminTicketsListPageState();
}

class _AdminTicketsListPageState extends State<AdminTicketsListPage> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedStatus = 'all';
  final Map<String, User> _clientCache = {};
  final Map<String, bool> _loadingStates = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterTickets);
    _loadAllTickets();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTickets);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final tickets = await TicketService.getAllTicketsAdmin();
      setState(() {
        _tickets = tickets;
      });

      for (final ticket in tickets) {
        if (ticket.clientId.isNotEmpty &&
            !_clientCache.containsKey(ticket.clientId)) {
          _loadClientInfo(ticket.clientId);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tickets: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClientInfo(String clientId) async {
    if (clientId.isEmpty || _loadingStates[clientId] == true) return;

    setState(() {
      _loadingStates[clientId] = true;
    });

    try {
      final userService = UserService();
      final cleanId = clientId.contains('_id')
          ? clientId.split('_id:')[1].split(',')[0].trim()
          : clientId;
      final client = await userService.getUserById(cleanId);
      setState(() {
        _clientCache[clientId] = client;
      });
    } catch (e) {
      debugPrint('Error loading client $clientId: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingStates[clientId] = false;
        });
      }
    }
  }

  void _filterTickets() {
    setState(() {
      _searchQuery = _searchController.text;
    });
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Not Assigned':
        return const Color.fromARGB(255, 235, 203, 129); // Light pastel yellow
      case 'Assigned':
        return const Color(0xFFE0F7FA); // Light pastel blue
      case 'In Progress':
        return const Color(0xFFE3F2FD); // Pastel blue
      case 'Resolved':
        return const Color(0xFFE8F5E9); // Light pastel green
      case 'Closed':
        return const Color(0xFFE0F7F6); // Mint pastel
      case 'Expired':
        return const Color(0xFFFFEBEE); // Light pastel red
      default:
        return const Color(0xFFFAFAFA); // Off-white
    }
  }

  Color _getStatusTextColor(String status) {
    return Colors.black87; // Dark text for better contrast on pastel
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Tickets',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ThemeToggleButton(),
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
                      hintStyle: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
                  child: RefreshIndicator(
                    onRefresh: _loadAllTickets,
                    color: Colors.orange,
                    child: _buildTicketList(isDarkMode),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavbarAdmin(currentIndex: 3, context: context),
    );
  }

  Widget _buildStatusFilterChips(bool isDarkMode) {
    final statuses = [
      'all',
      'Not Assigned',
      'Assigned',
      'In Progress',
      'Resolved',
      'Closed'
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(
                status == 'all' ? 'All' : status,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _selectedStatus == status
                      ? Colors.black87
                      : isDarkMode
                          ? Colors.white
                          : Colors.black87,
                ),
              ),
              selected: _selectedStatus == status,
              selectedColor: _getStatusColor(status),
              backgroundColor:
                  isDarkMode ? const Color(0xFF3A4352) : Colors.grey[200],
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? status : 'all';
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketList(bool isDarkMode) {
    if (_isLoading) {
      return _buildLoading(isDarkMode);
    }

    if (_errorMessage.isNotEmpty) {
      return _buildError(_errorMessage, isDarkMode);
    }

    final filteredTickets = _filterTicketsBySearch(
      _filterTicketsByStatus(_tickets, _selectedStatus),
      _searchQuery,
    );

    if (filteredTickets.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: filteredTickets.length,
      itemBuilder: (context, index) {
        final ticket = filteredTickets[index];
        return _buildTicketCard(ticket, isDarkMode);
      },
    );
  }

  Widget _buildLoading(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)),
          const SizedBox(height: 16),
          Text(
            'Loading tickets...',
            style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, bool isDarkMode) {
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
            onPressed: _loadAllTickets,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
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
            _searchQuery.isEmpty ? 'No tickets found' : 'No results found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'There are currently no tickets'
                : 'No tickets match your search',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket, bool isDarkMode) {
    final clientName = _clientCache.containsKey(ticket.clientId)
        ? '${_clientCache[ticket.clientId]?.firstName ?? ''} '
            '${_clientCache[ticket.clientId]?.lastName ?? ''}'
        : 'Loading...';

    final statusColor = _getStatusColor(ticket.status);
    final textColor = _getStatusTextColor(ticket.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: statusColor, // Pastel color applied here
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminTicketDetailsPage(ticketId: ticket.id),
            ),
          );
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
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _translateStatus(ticket.status),
                      style: GoogleFonts.poppins(
                        color: textColor,
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
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: textColor.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDate(ticket.creationDate)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                  if (ticket.clientId.isNotEmpty) ...[
                    const Spacer(),
                    if (_loadingStates[ticket.clientId] == true)
                      SizedBox(
                        width: 100,
                        height: 12,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              textColor.withOpacity(0.8)),
                        ),
                      )
                    else if (_clientCache.containsKey(ticket.clientId))
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: textColor.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            clientName,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: textColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.refresh,
                            size: 16, color: textColor.withOpacity(0.8)),
                        onPressed: () => _loadClientInfo(ticket.clientId),
                      ),
                  ],
                ],
              ),
              if (ticket.equipmentHardIds?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.computer,
                        size: 16,
                        color: textColor.withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ticket.equipmentHardIds!.length} equipment',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textColor.withOpacity(0.8),
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
}
