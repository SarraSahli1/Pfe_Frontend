import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback? onLogout;
  final Widget? child;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const LogoutButton({
    Key? key,
    this.onLogout,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.red,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Déconnexion'),
              ),
            ],
          ),
        );

        if (shouldLogout == true) {
          try {
            // Clear SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('user_data');
            await prefs.remove('auth_token'); // Adjust key if different

            // Perform logout
            await AuthService().logout();

            // Call onLogout callback
            onLogout?.call();

            // Navigate to login page, clearing navigation stack
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          } catch (e) {
            debugPrint('Logout error: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
            );
          }
        }
      },
      child: child ??
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 8),
              Text('Déconnexion'),
            ],
          ),
    );
  }
}
