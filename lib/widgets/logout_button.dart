import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback? onLogout; // Optional callback for additional actions
  final Color? iconColor;
  final double? iconSize;

  const LogoutButton({
    Key? key,
    this.onLogout,
    this.iconColor,
    this.iconSize,
  }) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    // Remove token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');

    // Optional: Navigate to login screen
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // Replace with your login route
      (Route<dynamic> route) => false,
    );

    // Execute any additional logout actions
    if (onLogout != null) {
      onLogout!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.logout,
        color: iconColor ?? Theme.of(context).iconTheme.color,
        size: iconSize ?? 24.0,
      ),
      onPressed: () => _logout(context),
      tooltip: 'Logout',
    );
  }
}
