import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/notification_provider.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Tickets/ticket_detail_screen.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: notificationProvider.notifications.isEmpty
          ? Center(
              child: Text(
                'No notifications',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          : ListView.builder(
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationProvider.notifications[index];
                final messageId = notification['message']?['_id'] ?? '';
                final ticketId = notification['ticketId'] ?? 'Unknown';
                final type = notification['type'] ?? 'unknown';
                final createdAt = notification['message']?['createdAt'] != null
                    ? DateTime.parse(notification['message']['createdAt'])
                        .toLocal()
                    : DateTime.now();

                String title, subtitle;
                IconData icon;

                if (type == 'status-change') {
                  title = 'Ticket $ticketId Status Update';
                  subtitle = notification['message']?['message'] ??
                      'Status changed to ${notification['message']?['status']}';
                  icon = Icons.update;
                } else if (type == 'chat_message') {
                  final senderName = notification['message']?['sender']
                          ?['firstName'] ??
                      'Unknown';
                  title = 'Ticket $ticketId';
                  subtitle =
                      '$senderName: ${notification['message']?['message'] ?? ''}';
                  icon = Icons.message;
                } else {
                  title = 'Notification';
                  subtitle = notification['message']?['message'] ??
                      'Unknown notification';
                  icon = Icons.notifications;
                }

                return ListTile(
                  leading: Icon(icon, color: Colors.blue),
                  title: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  trailing: Text(
                    '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                  ),
                  onTap: () async {
                    try {
                      final authService = AuthService();
                      final token = await authService.getToken();
                      final userId = await authService.getCurrentUserId();

                      if (token == null || userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please log in again.')),
                        );
                        return;
                      }

                      final ticket =
                          await TicketService.getTicketDetails(ticketId);
                      notificationProvider.markAsRead(messageId);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TicketDetailScreen(
                            ticket: ticket,
                            token: token,
                            currentUserId: userId,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
