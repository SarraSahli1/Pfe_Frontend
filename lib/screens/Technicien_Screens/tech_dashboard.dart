import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/widgets/Header.dart';
import 'package:helpdeskfrontend/widgets/navbar_technicien.dart';

class TechnicianDashboard extends StatefulWidget {
  const TechnicianDashboard({Key? key}) : super(key: key);

  @override
  _TechnicianDashboardState createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  Future<List<Ticket>> _ticketsFuture = Future.value([]);
  bool _isRefreshing = false;
  String? _errorMessage;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTickets();
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

  Map<String, int> _calculateTicketStats(List<Ticket> tickets) {
    return {
      'total': tickets.length,
      'inProgress':
          tickets.where((ticket) => ticket.status == 'In Progress').length,
      'resolved': tickets.where((ticket) => ticket.status == 'Resolved').length,
      'closed': tickets.where((ticket) => ticket.status == 'Closed').length,
    };
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation logic here, e.g., Navigator.push to other pages like TechnicianTicketsScreen
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppHeader(
        title: 'Technician Dashboard',
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
          child: RefreshIndicator(
            onRefresh: _loadTickets,
            color: Colors.orange,
            child: FutureBuilder<List<Ticket>>(
              future: _ticketsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !_isRefreshing) {
                  return _buildLoading();
                }

                if (snapshot.hasError || _errorMessage != null) {
                  return _buildError(
                      _errorMessage ?? snapshot.error.toString());
                }

                final tickets = snapshot.data ?? [];
                return _buildDashboard(tickets);
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavbarTechnician(
        currentIndex: _selectedIndex,
        context: context, // Added context parameter to match admin style
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
          Text('Loading dashboard...'),
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
            onPressed: _loadTickets,
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

  Widget _buildDashboard(List<Ticket> tickets) {
    final stats = _calculateTicketStats(tickets);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Ticket Statistics',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                title: 'Total Tickets',
                count: stats['total']!,
                color: Colors.blue,
                icon: Icons.list,
                isDarkMode: isDarkMode,
              ),
              _buildStatCard(
                title: 'In Progress',
                count: stats['inProgress']!,
                color: Colors.blue[400]!,
                icon: Icons.hourglass_empty,
                isDarkMode: isDarkMode,
              ),
              _buildStatCard(
                title: 'Resolved',
                count: stats['resolved']!,
                color: Colors.green,
                icon: Icons.check_circle,
                isDarkMode: isDarkMode,
              ),
              _buildStatCard(
                title: 'Closed',
                count: stats['closed']!,
                color: Colors.green[400]!,
                icon: Icons.done_all,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
