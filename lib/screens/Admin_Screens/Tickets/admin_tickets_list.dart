import 'package:flutter/material.dart';
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
  int _currentIndex = 0;
  final Map<String, User> _clientCache = {};
  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    _loadAllTickets();
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

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          const ThemeToggleButton(),
        ],
      ),
      backgroundColor: isDarkMode ? const Color(0xFF242E3E) : Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadAllTickets,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: isDarkMode ? Colors.white : Colors.blue,
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadAllTickets,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filterTicketsBySearch(
                    _filterTicketsByStatus(_tickets, _selectedStatus),
                    _searchQuery,
                  ).isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment,
                              size: 60,
                              color: isDarkMode ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No tickets found'
                                  : 'No results for "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 480),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _buildSearchBar(isDarkMode),
                              const SizedBox(height: 20),
                              _buildStatusFilterChips(isDarkMode),
                              const SizedBox(height: 20),
                              ..._filterTicketsBySearch(
                                _filterTicketsByStatus(
                                    _tickets, _selectedStatus),
                                _searchQuery,
                              ).map((ticket) =>
                                  _buildTicketCard(ticket, isDarkMode)),
                            ],
                          ),
                        ),
                      ),
      ),
      bottomNavigationBar: NavbarAdmin(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
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
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search tickets...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.white : Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 15.0,
          ),
        ),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                status == 'all' ? 'All' : status,
                style: TextStyle(
                  color: _selectedStatus == status
                      ? Colors.white
                      : isDarkMode
                          ? Colors.white
                          : Colors.black,
                ),
              ),
              selected: _selectedStatus == status,
              selectedColor: Colors.orange,
              backgroundColor:
                  isDarkMode ? const Color(0xFF3A4352) : Colors.grey[200],
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? status : 'all';
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket, bool isDarkMode) {
    final clientName = _clientCache.containsKey(ticket.clientId)
        ? '${_clientCache[ticket.clientId]?.firstName ?? ''} '
            '${_clientCache[ticket.clientId]?.lastName ?? ''}'
        : 'Loading...';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.1)
            : const Color(0xFFe7eefe),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticket.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(ticket.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _translateStatus(ticket.status),
                  style: const TextStyle(
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
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 4),
              Text(
                'Created: ${_formatDate(ticket.creationDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
              if (ticket.clientId.isNotEmpty) ...[
                const Spacer(),
                if (_loadingStates[ticket.clientId] == true)
                  SizedBox(
                    width: 100,
                    height: 12,
                    child: LinearProgressIndicator(
                      backgroundColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  )
                else if (_clientCache.containsKey(ticket.clientId))
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        clientName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: () => _loadClientInfo(ticket.clientId),
                    color: Colors.orange,
                  ),
              ],
            ],
          ),
          if (ticket.equipmentHardIds?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.computer, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Equipment: ${ticket.equipmentHardIds!.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: isDarkMode ? Colors.white : Colors.black),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'see',
                  child: Row(
                    children: [
                      Icon(Icons.remove_red_eye,
                          color: isDarkMode ? Colors.white : Colors.black),
                      const SizedBox(width: 8),
                      Text('See details',
                          style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black)),
                    ],
                  ),
                ),
              ],
              onSelected: (String value) {
                if (value == 'see') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AdminTicketDetailsPage(ticketId: ticket.id),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Not Assigned':
        return Colors.orange;
      case 'Assigned':
        return Colors.blue;
      case 'In Progress':
        return Colors.blue[400]!;
      case 'Resolved':
        return Colors.green;
      case 'Closed':
        return Colors.green[400]!;
      case 'Expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
