import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/widgets/navbar_admin.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/scheduler.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({Key? key}) : super(key: key);

  @override
  _DashboardAdminState createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin>
    with TickerProviderStateMixin {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _topTechnicians = [];
  bool _isLoadingTechnicians = true;
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadAllTickets();
    _loadTopTechnicians();
  }

  @override
  void dispose() {
    _refreshController.dispose();
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
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 120,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                      SizedBox(width: 8),
                      AnimatedCount(
                        count: count,
                        duration: Duration(seconds: 1),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.chevron_right,
                      size: 20, color: color.withOpacity(0.6)),
                ],
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getImageUrl(dynamic image) {
    if (image == null) return null;
    if (image is String) return '${Config.baseUrl}/files/files/$image';
    if (image is Map && image['path'] != null) {
      return image['path']!
          .replaceFirst('http://localhost:3000', Config.baseUrl);
    }
    return null;
  }

  Widget _buildDetailItem(
      IconData icon, String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
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
    final resolvedTickets = technician['resolvedTickets'] ?? 0;
    final imagePath = _getImageUrl(tech['image']) ??
        'https://ui-avatars.com/api/?name=$firstName+$lastName&background=random';

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Color(0xFF1E293B) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTechnicianDetails(technician, position, isDarkMode),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getPositionColor(position).withOpacity(0.2),
                ),
                child: Text(
                  '$position',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: _getPositionColor(position),
                  ),
                ),
              ),
              SizedBox(width: 16),
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    isDarkMode ? Colors.grey[700] : Colors.grey[200],
                backgroundImage: NetworkImage(imagePath),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$firstName $lastName',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.work_outline,
                            size: 14,
                            color: isDarkMode ? Colors.white70 : Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '$resolvedTickets resolved',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPerformanceColor(resolvedTickets).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_calculatePerformance(resolvedTickets)}%',
                  style: GoogleFonts.inter(
                    color: _getPerformanceColor(resolvedTickets),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Color(0xFFFFD700);
      case 2:
        return Color(0xFFC0C0C0);
      case 3:
        return Color(0xFFCD7F32);
      default:
        return Colors.blue;
    }
  }

  Color _getPerformanceColor(int resolved) {
    if (resolved > 15) return Colors.green;
    if (resolved > 10) return Colors.blue;
    if (resolved > 5) return Colors.orange;
    return Colors.red;
  }

  int _calculatePerformance(int resolved) {
    return (resolved * 5).clamp(0, 100);
  }

  void _showTechnicianDetails(
      Map<String, dynamic> technician, int position, bool isDarkMode) {
    final tech = technician['technician'] ?? {};
    final firstName = tech['firstName'] ?? 'Tech';
    final lastName = tech['lastName'] ?? '';
    final email = tech['email'] ?? 'Not available';
    final phoneNumber = tech['phoneNumber'] ?? 'Not available';
    final authority = tech['authority'] ?? 'Technician';
    final resolvedTickets = technician['resolvedTickets'] ?? 0;
    final imagePath = _getImageUrl(tech['image']) ??
        'https://ui-avatars.com/api/?name=$firstName+$lastName&background=random';
    final permisConduit = tech['permisConduire'] ?? false;
    final passport = tech['passeport'] ?? false;
    final birthDate =
        tech['birthDate'] != null ? DateTime.tryParse(tech['birthDate']) : null;

    String _formatDate(DateTime? date) {
      return date != null
          ? "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}"
          : 'N/A';
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      backgroundImage: NetworkImage(imagePath),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getPositionColor(position).withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? Colors.white24 : Colors.black12,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$position',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  '$firstName $lastName',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getPerformanceColor(resolvedTickets).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_calculatePerformance(resolvedTickets)}% Performance',
                    style: GoogleFonts.inter(
                      color: _getPerformanceColor(resolvedTickets),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _buildDetailItem(
                    Icons.email_outlined, 'Email', email, isDarkMode),
                _buildDetailItem(
                    Icons.phone_outlined, 'Phone', phoneNumber, isDarkMode),
                _buildDetailItem(Icons.person, 'Role', authority, isDarkMode),
                _buildDetailItem(Icons.work, 'Resolved Tickets',
                    resolvedTickets.toString(), isDarkMode),
                _buildDetailItem(Icons.drive_eta_outlined, 'Driver\'s License',
                    permisConduit ? 'Yes' : 'No', isDarkMode),
                _buildDetailItem(Icons.airport_shuttle, 'Passport',
                    passport ? 'Yes' : 'No', isDarkMode),
                _buildDetailItem(Icons.cake_outlined, 'Birth Date',
                    _formatDate(birthDate), isDarkMode),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode ? Colors.blue[800] : Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(120, 48),
                  ),
                  child: Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.people_alt_outlined,
              size: 48, color: isDarkMode ? Colors.white38 : Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No Technicians Available',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'When technicians are added, they will appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDarkMode ? Colors.white60 : Colors.grey[500],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Add navigation to add technician
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                Text('Add Technician', style: TextStyle(color: Colors.white)),
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
        title: Row(
          children: [
            Icon(Icons.dashboard, size: 28),
            SizedBox(width: 10),
            Text('Admin Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
        backgroundColor: isDarkMode ? Color(0xFF1A1A2E) : Color(0xFF628ff6),
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          ThemeToggleButton(),
          SizedBox(width: 12),
        ],
      ),
      backgroundColor: isDarkMode ? Color(0xFF121212) : Color(0xFFF5F5F7),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAllTickets();
          await _loadTopTechnicians();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket Statistics',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Overview of all ticket activities',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5, // Adjusted for rectangular shape
                        padding: EdgeInsets.zero,
                        children: [
                          _buildStatCard(
                            title: 'Total',
                            count: stats['total']!,
                            color: Colors.blue[700]!,
                            icon: Icons.list_alt,
                            isDarkMode: isDarkMode,
                          ),
                          _buildStatCard(
                            title: 'In Progress',
                            count: stats['inProgress']!,
                            color: Colors.orange[700]!,
                            icon: Icons.hourglass_top,
                            isDarkMode: isDarkMode,
                          ),
                          _buildStatCard(
                            title: 'Resolved',
                            count: stats['resolved']!,
                            color: Colors.green[600]!,
                            icon: Icons.check_circle_outline,
                            isDarkMode: isDarkMode,
                          ),
                          _buildStatCard(
                            title: 'Closed',
                            count: stats['closed']!,
                            color: Colors.teal[600]!,
                            icon: Icons.verified_outlined,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Top Performers',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Chip(
                            backgroundColor: isDarkMode
                                ? Colors.blue[900]
                                : Colors.blue[100],
                            label: Text(
                              'This Month',
                              style: GoogleFonts.inter(
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.blue[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _isLoadingTechnicians
                          ? Center(
                              child: CircularProgressIndicator(
                                color: isDarkMode ? Colors.white : Colors.blue,
                              ),
                            )
                          : _topTechnicians.isEmpty
                              ? _buildEmptyState(isDarkMode)
                              : ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: 400,
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
                                    itemCount: _topTechnicians.length > 5
                                        ? 5
                                        : _topTechnicians.length,
                                    separatorBuilder: (_, __) => SizedBox(),
                                    itemBuilder: (context, index) =>
                                        _buildTechnicianItem(
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
            );
          },
        ),
      ),
      bottomNavigationBar: NavbarAdmin(
        currentIndex: 0,
        context: context,
      ),
    );
  }
}

class AnimatedCount extends ImplicitlyAnimatedWidget {
  final int count;
  final TextStyle style;

  const AnimatedCount({
    Key? key,
    required this.count,
    required this.style,
    required Duration duration,
  }) : super(key: key, duration: duration);

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _AnimatedCountState();
}

class _AnimatedCountState extends AnimatedWidgetBaseState<AnimatedCount> {
  IntTween? _countTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _countTween = visitor(
      _countTween,
      widget.count,
      (dynamic value) => IntTween(begin: value as int),
    ) as IntTween;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_countTween?.evaluate(animation) ?? 0}',
      style: widget.style,
    );
  }
}
