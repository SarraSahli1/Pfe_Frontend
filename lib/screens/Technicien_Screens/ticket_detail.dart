import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/screens/Chat_Screens/chat_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  final String token; // Add token parameter
  final String currentUserId; // Add currentUserId parameter

  const TicketDetailScreen({
    Key? key,
    required this.ticket,
    required this.token,
    required this.currentUserId,
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
    final gradientStop = 0.25;

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: ticket.chatId != null
          ? FloatingActionButton(
              onPressed: _navigateToChat,
              child: const Icon(Icons.chat),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF141218), const Color(0xFF242e3e)]
                : [const Color(0xFF628ff6), const Color(0xFFf7f9f5)],
            stops: [gradientStop, gradientStop],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Ticket Details',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chat,
                        color: ticket.chatId != null
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                      onPressed: ticket.chatId != null ? _navigateToChat : null,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF242E3E) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ticket Title
                        Text(
                          ticket.title,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Basic Information Card
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          color: isDarkMode
                              ? const Color(0xFF3A4352)
                              : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ticket Information',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const Divider(),
                                _buildInfoRow(context, 'ID:', ticket.id),
                                _buildInfoRow(
                                    context, 'Type:', ticket.typeTicket),
                                _buildInfoRow(context, 'Description:',
                                    ticket.description),
                                _buildInfoRow(context, 'Created:',
                                    dateFormat.format(ticket.creationDate)),
                                if (ticket.resolvedDate != null)
                                  _buildInfoRow(context, 'Resolved:',
                                      dateFormat.format(ticket.resolvedDate!)),
                                if (ticket.closedDate != null)
                                  _buildInfoRow(context, 'Closed:',
                                      dateFormat.format(ticket.closedDate!)),
                              ],
                            ),
                          ),
                        ),

                        // Solution Card
                        if (ticket.solutionId != null)
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            color: isDarkMode
                                ? const Color(0xFF3A4352)
                                : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Solution',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const Divider(),
                                  _buildInfoRow(context, 'Solution ID:',
                                      ticket.solutionId!),
                                ],
                              ),
                            ),
                          ),

                        // Conversation Card with enhanced chat button
                        if (ticket.chatId != null)
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            color: isDarkMode
                                ? const Color(0xFF3A4352)
                                : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Conversation',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: _navigateToChat,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Text(
                                          'Open Chat',
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  _buildInfoRow(
                                      context, 'Chat ID:', ticket.chatId!),
                                ],
                              ),
                            ),
                          ),

                        // Equipment Card
                        if (ticket.equipmentHelpdeskIds != null &&
                            ticket.equipmentHelpdeskIds!.isNotEmpty)
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            color: isDarkMode
                                ? const Color(0xFF3A4352)
                                : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Related Equipment',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const Divider(),
                                  ...ticket.equipmentHelpdeskIds!
                                      .map((id) => _buildInfoRow(
                                          context, 'Equipment ID:', id))
                                      .toList(),
                                ],
                              ),
                            ),
                          ),

                        // Files Card
                        if (ticket.fileUrls != null &&
                            ticket.fileUrls!.isNotEmpty)
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            color: isDarkMode
                                ? const Color(0xFF3A4352)
                                : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Attached Files (${ticket.fileUrls!.length})',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const Divider(),
                                  ...ticket.fileUrls!
                                      .map((url) => ListTile(
                                            leading: Icon(
                                              Icons.attach_file,
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                            title: Text(
                                              url.split('/').last,
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
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
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFile(String url) {
    // TODO: Implement file opening functionality
    print('Opening file: $url');
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
}
