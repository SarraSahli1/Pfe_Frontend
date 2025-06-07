import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/navbar_admin.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({Key? key}) : super(key: key);

  @override
  _DashboardAdminState createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _topTechnicians = [];
  bool _isLoadingTechnicians = true;

  @override
  void initState() {
    super.initState();
    _loadAllTickets();
    _loadTopTechnicians();
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tickets: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTopTechnicians() async {
    setState(() => _isLoadingTechnicians = true);

    try {
      final technicians = await TicketService.getTopTechnicians();
      setState(() {
        _topTechnicians = technicians;
        _isLoadingTechnicians = false;
      });
    } catch (e) {
      setState(() => _isLoadingTechnicians = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load technicians: $e'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Map<String, int> _calculateTicketStats() {
    return {
      'total': _tickets.length,
      'inProgress':
          _tickets.where((ticket) => ticket.status == 'In Progress').length,
      'resolved':
          _tickets.where((ticket) => ticket.status == 'Resolved').length,
      'closed': _tickets.where((ticket) => ticket.status == 'Closed').length,
    };
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianItem({
    required Map<String, dynamic> technician,
    required int position,
    required bool isDarkMode,
  }) {
    final tech = technician['technician'] ?? {};
    final firstName = tech['firstName'] ?? 'Tech';
    final lastName = tech['lastName'] ?? '';
    final imagePath = (tech['image'] is Map && tech['image']['path'] != null)
        ? tech['image']['path'].toString()
        : null;

    Color getMedalColor() {
      switch (position) {
        case 1:
          return Color(0xFFFFD700); // Or
        case 2:
          return Color(0xFFC0C0C0); // Argent
        case 3:
          return Color(0xFFCD7F32); // Bronze
        default:
          return Colors.grey;
      }
    }

    String getMedalEmoji() {
      switch (position) {
        case 1:
          return '🥇';
        case 2:
          return '🥈';
        case 3:
          return '🥉';
        default:
          return '';
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Médaille et position
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: getMedalColor().withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                getMedalEmoji(),
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          SizedBox(width: 16),

          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
            backgroundImage: imagePath != null ? NetworkImage(imagePath) : null,
            child: imagePath == null
                ? Icon(Icons.person, size: 24, color: Colors.grey)
                : null,
          ),
          SizedBox(width: 16),

          // Nom du technicien
          Expanded(
            child: Text(
              '$firstName ${lastName.isNotEmpty ? lastName[0] + '.' : ''}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),

          // Position numérique
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: getMedalColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#$position',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: getMedalColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final stats = _calculateTicketStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord Admin',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFF628ff6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      backgroundColor: isDarkMode ? const Color(0xFF242E3E) : Color(0xFFF5F5F7),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAllTickets();
          await _loadTopTechnicians();
        },
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDarkMode ? Colors.blue : Colors.blue[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistiques des tickets
                        Text(
                          'Statistiques des Tickets',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          children: [
                            _buildStatCard(
                              title: 'Total',
                              count: stats['total']!,
                              color: Colors.blue[700]!,
                              icon: Icons.list_alt,
                              isDarkMode: isDarkMode,
                            ),
                            _buildStatCard(
                              title: 'En Cours',
                              count: stats['inProgress']!,
                              color: Colors.orange[700]!,
                              icon: Icons.hourglass_top,
                              isDarkMode: isDarkMode,
                            ),
                            _buildStatCard(
                              title: 'Résolus',
                              count: stats['resolved']!,
                              color: Colors.green[600]!,
                              icon: Icons.check_circle_outline,
                              isDarkMode: isDarkMode,
                            ),
                            _buildStatCard(
                              title: 'Clôturés',
                              count: stats['closed']!,
                              color: Colors.teal[600]!,
                              icon: Icons.verified_outlined,
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),

                        // Classement des techniciens
                        const SizedBox(height: 40),
                        Text(
                          'Top Techniciens',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _isLoadingTechnicians
                            ? Center(
                                child: CircularProgressIndicator(
                                  color:
                                      isDarkMode ? Colors.white : Colors.blue,
                                ),
                              )
                            : _topTechnicians.isEmpty
                                ? Center(
                                    child: Text(
                                      'Aucun technicien disponible',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: List.generate(
                                      _topTechnicians.length > 3
                                          ? 3
                                          : _topTechnicians.length,
                                      (index) => _buildTechnicianItem(
                                        technician: _topTechnicians[index],
                                        position: index + 1,
                                        isDarkMode: isDarkMode,
                                      ),
                                    ),
                                  ),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: NavbarAdmin(
        currentIndex: 0, // Index fixe pour cette page
        context: context, // Contexte passé pour la navigation
      ),
    );
  }
}
