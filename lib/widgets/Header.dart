import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/provider/notification_provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/NotificationScreen.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
  });

  void _showNotificationCard(BuildContext context, Offset position) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: NotificationCard(
            onClose: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      backgroundColor: isDarkMode ? Color(0xFF141218) : Color(0xFF81A3F7),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        GestureDetector(
          onTapDown: (details) {
            if (notificationProvider.unreadCount > 0) {
              final position = details.globalPosition;
              _showNotificationCard(context, position);
            }
          },
          child: badges.Badge(
            showBadge: notificationProvider.unreadCount > 0,
            badgeContent: Text(
              '${notificationProvider.unreadCount}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
            child: Icon(
              Icons.notifications,
              color: notificationProvider.unreadCount > 0
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        const ThemeToggleButton(),
        const SizedBox(width: 16),
        if (actions != null) ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
