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
        return const Color(0xFFD2DEFC); // Light blue
      case 'In Progress':
        return const Color(0xFFE3F2FD); // Pastel blue
      case 'Resolved':
        return const Color(0xFFDEFCEF); // Light green
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
      appBar: AppBar(
        title: Text(
          'Tickets',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFF628ff6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      backgroundColor: isDarkMode ? const Color(0xFF242E3E) : Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadAllTickets,
        color: Colors.orange,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: isDarkMode ? Colors.white : Colors.blue,
                ),
              )
            : _errorMessage.isNotEmpty
                ? _buildError(_errorMessage, isDarkMode)
                : _buildTicketListContent(isDarkMode),
      ),
      bottomNavigationBar: NavbarAdmin(currentIndex: 3, context: context),
    );
  }

  Widget _buildTicketListContent(bool isDarkMode) {
    final filteredTickets = _filterTicketsBySearch(
      _filterTicketsByStatus(_tickets, _selectedStatus),
      _searchQuery,
    );

    return SingleChildScrollView(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSearchBar(isDarkMode),
            const SizedBox(height: 30),
            _buildStatusFilterButtons(isDarkMode),
            const SizedBox(height: 24),
            filteredTickets.isEmpty
                ? _buildEmptyState(isDarkMode)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = filteredTickets[index];
                      return _buildTicketCard(ticket, isDarkMode);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
        borderRadius: BorderRadius.circular(25.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tickets...',
          hintStyle: GoogleFonts.poppins(
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.white : Colors.grey[600],
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.orange),
                  onPressed: () {
                    _searchController.clear();
                    _filterTickets();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        ),
        style: GoogleFonts.poppins(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildStatusFilterButtons(bool isDarkMode) {
    final statuses = [
      'all',
      'Not Assigned',
      'Assigned',
      'In Progress',
      'Resolved',
      'Closed'
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: statuses
            .asMap()
            .entries
            .map((entry) {
              final status = entry.value;
              return [
                _buildFilterButton(
                  status == 'all' ? 'All' : status,
                  status,
                  isDarkMode,
                ),
                if (entry.key < statuses.length - 1) const SizedBox(width: 20),
              ];
            })
            .expand((element) => element)
            .toList(),
      ),
    );
  }

  Widget _buildFilterButton(String label, String status, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedStatus = status),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedStatus == status
                  ? isDarkMode
                      ? Colors.blue.shade800
                      : Colors.blue
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedStatus == status
                    ? isDarkMode
                        ? Colors.blue.shade600
                        : Colors.blue
                    : isDarkMode
                        ? Colors.white
                        : Colors.black,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: _selectedStatus == status
                    ? Colors.white
                    : isDarkMode
                        ? Colors.white
                        : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (_selectedStatus == status)
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue.shade600 : Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
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
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? Colors.white : Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading tickets...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.grey[600],
            ),
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
          Icon(
            Icons.error_outline,
            size: 50,
            color: isDarkMode ? Colors.white : Colors.red,
          ),
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
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
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
                borderRadius: BorderRadius.circular(20),
              ),
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
            size: 100,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No tickets found' : 'No results found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'There are currently no tickets'
                : 'No tickets match your search',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket, bool isDarkMode) {
    final clientName = _clientCache.containsKey(ticket.clientId)
        ? '${_clientCache[ticket.clientId]?.firstName ?? ''} ${_clientCache[ticket.clientId]?.lastName ?? ''}'
        : 'Loading...';

    final statusColor = _getStatusColor(ticket.status);
    final textColor = _getStatusTextColor(ticket.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      color: statusColor,
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
                        icon: Icon(
                          Icons.refresh,
                          size: 16,
                          color: textColor.withOpacity(0.8),
                        ),
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
