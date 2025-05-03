import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/screens/Chat_Screens/chat_screen.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/create_solution_page.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/solution_details.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  final String token;
  final String currentUserId;
  final Function()? onSolutionAdded;

  const TicketDetailScreen({
    Key? key,
    required this.ticket,
    required this.token,
    required this.currentUserId,
    this.onSolutionAdded,
  }) : super(key: key);

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final ticket = widget.ticket;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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
          child: Stack(
            children: [
              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Ticket Details',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 40),
                      ],
                    ),
                  ),
                  // Main Content
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? Color(0xFF242E3E) : Color(0xFFF7F9F5),
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Ticket Card
                            Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              color:
                                  isDarkMode ? Color(0xFF3A4352) : Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            ticket.title,
                                            style: GoogleFonts.poppins(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w700,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                _getStatusColor(ticket.status),
                                                _getStatusColor(ticket.status)
                                                    .withOpacity(0.7),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                          child: Text(
                                            _translateStatus(ticket.status),
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 24),
                                    Text(
                                      'Ticket Information',
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    Divider(
                                      color: isDarkMode
                                          ? Colors.grey[600]
                                          : Colors.grey[300],
                                      thickness: 1.5,
                                    ),
                                    SizedBox(height: 12),
                                    _buildInfoRow(
                                        context, 'Type:', ticket.typeTicket),
                                    _buildInfoRow(context, 'Description:',
                                        ticket.description),
                                    _buildInfoRow(context, 'Created:',
                                        dateFormat.format(ticket.creationDate)),
                                    if (ticket.assignedDate != null)
                                      _buildInfoRow(
                                          context,
                                          'Assigned:',
                                          dateFormat
                                              .format(ticket.assignedDate!)),
                                    if (ticket.resolvedDate != null)
                                      _buildInfoRow(
                                          context,
                                          'Resolved:',
                                          dateFormat
                                              .format(ticket.resolvedDate!)),
                                    if (ticket.closedDate != null)
                                      _buildInfoRow(
                                          context,
                                          'Closed:',
                                          dateFormat
                                              .format(ticket.closedDate!)),
                                    SizedBox(height: 24),
                                    // Action Buttons
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 16,
                                      runSpacing: 12,
                                      children: [
                                        if (ticket.solutionId != null)
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SolutionDetailsPage(
                                                    ticketId: ticket.id,
                                                    solutionId:
                                                        ticket.solutionId!,
                                                    token: widget.token,
                                                    currentUserId:
                                                        widget.currentUserId,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: Icon(Icons.description,
                                                size: 24, color: Colors.white),
                                            label: Text('View Solution',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 16)),
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              backgroundColor:
                                                  Color(0xFF628FF6),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                              elevation: 4,
                                              minimumSize: Size(150, 50),
                                            ),
                                          ),
                                        if (ticket.solutionId == null)
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CreateSolutionPage(
                                                    ticketId: ticket.id,
                                                    solutionId: '',
                                                    token: widget.token,
                                                    currentUserId:
                                                        widget.currentUserId,
                                                    initialSolution: null,
                                                  ),
                                                ),
                                              ).then((success) {
                                                if (success == true &&
                                                    widget.onSolutionAdded !=
                                                        null) {
                                                  widget.onSolutionAdded!();
                                                }
                                              });
                                            },
                                            icon: Icon(Icons.add,
                                                size: 24, color: Colors.white),
                                            label: Text('Add Solution',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 16)),
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              backgroundColor: Colors.green,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                              elevation: 4,
                                              minimumSize: Size(150, 50),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            // Equipment Section
                            if (ticket.equipmentHelpdeskIds != null &&
                                ticket.equipmentHelpdeskIds!.isNotEmpty)
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                color: isDarkMode
                                    ? Color(0xFF3A4352)
                                    : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Related Equipment',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Icon(Icons.computer,
                                              color: Colors.orange, size: 24),
                                        ],
                                      ),
                                      Divider(
                                          color: isDarkMode
                                              ? Colors.grey[600]
                                              : Colors.grey[300]),
                                      SizedBox(height: 8),
                                      ...ticket.equipmentHelpdeskIds!
                                          .map((id) => _buildInfoRow(
                                              context, 'Equipment:', id))
                                          .toList(),
                                    ],
                                  ),
                                ),
                              ),
                            SizedBox(height: 16),
                            // Files Section
                            if (ticket.fileUrls != null &&
                                ticket.fileUrls!.isNotEmpty)
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                color: isDarkMode
                                    ? Color(0xFF3A4352)
                                    : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Attachments (${ticket.fileUrls!.length})',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Icon(Icons.attach_file,
                                              color: Colors.orange, size: 24),
                                        ],
                                      ),
                                      Divider(
                                          color: isDarkMode
                                              ? Colors.grey[600]
                                              : Colors.grey[300]),
                                      SizedBox(height: 8),
                                      ...ticket.fileUrls!
                                          .map((url) => ListTile(
                                                leading: Icon(
                                                  _getFileIcon(url),
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                ),
                                                title: Text(
                                                  url.split('/').last,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: isDarkMode
                                                        ? Colors.white70
                                                        : Colors.black54,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                trailing: IconButton(
                                                  icon: Icon(Icons.download,
                                                      color: Colors.orange),
                                                  onPressed: () =>
                                                      _openFile(url),
                                                ),
                                                onTap: () => _openFile(url),
                                              ))
                                          .toList(),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Chat Floating Action Button
              if (ticket.chatId != null)
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton.large(
                    onPressed: _navigateToChat,
                    backgroundColor: Color(0xFF628FF6),
                    child: Icon(Icons.chat, color: Colors.white, size: 32),
                    tooltip: 'Chat',
                    elevation: 6,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFile(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening file: ${url.split('/').last}')),
    );
  }

  void _navigateToChat() {
    if (widget.ticket.chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No chat available for this ticket')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          ticketId: widget.ticket.id,
          token: widget.token,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  IconData _getFileIcon(String url) {
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  String _translateStatus(String status) {
    const statusTranslations = {
      'Not Assigned': 'Not Assigned',
      'Assigned': 'Assigned',
      'In Progress': 'In Progress',
      'Resolved': 'Resolved',
      'Closed': 'Closed',
    };
    return statusTranslations[status] ?? status;
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
      default:
        return Colors.blueGrey;
    }
  }
}
