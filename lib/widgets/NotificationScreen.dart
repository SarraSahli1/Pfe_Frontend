import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/provider/notification_provider.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/ticket_detail.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:provider/provider.dart';

class NotificationCard extends StatelessWidget {
  final VoidCallback onClose;

  const NotificationCard({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Color(0xFF242E3E) : Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 300,
          maxWidth: 300,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      if (notificationProvider.unreadCount > 0)
                        GestureDetector(
                          onTap: () {
                            notificationProvider.markAllAsRead();
                          },
                          child: Text(
                            'Mark All',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: onClose,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[300]),
            Expanded(
              child: notificationProvider.unreadCount == 0
                  ? Center(
                      child: Text(
                        'No unread notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount:
                          notificationProvider.unreadNotifications.length,
                      itemBuilder: (context, index) {
                        final notification =
                            notificationProvider.unreadNotifications[index];
                        final messageId = notification['message']?['_id'] ?? '';
                        final ticketId = notification['ticketId'] ?? 'Unknown';
                        final senderName = notification['message']?['sender']
                                ?['firstName'] ??
                            'Unknown';
                        final messageText =
                            notification['message']?['message'] ?? '';
                        final createdAt =
                            notification['message']?['createdAt'] != null
                                ? DateTime.parse(
                                        notification['message']['createdAt'])
                                    .toLocal()
                                : DateTime.now();

                        return ListTile(
                          dense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Icon(
                            Icons.message,
                            color: Colors.blue,
                            size: 20,
                          ),
                          title: Text(
                            'Ticket $ticketId',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '$senderName: $messageText',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color:
                                  isDarkMode ? Colors.grey[400] : Colors.grey,
                            ),
                          ),
                          onTap: () async {
                            try {
                              final authService = AuthService();
                              final token = await authService.getToken();
                              final userId =
                                  await authService.getCurrentUserId();

                              if (token == null || userId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please log in again.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              final ticket =
                                  await TicketService.getTicketDetails(
                                      ticketId);
                              if (ticket == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ticket not found.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              notificationProvider.markAsRead(messageId);
                              onClose();

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
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
