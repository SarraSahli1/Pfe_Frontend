import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Profile/profile.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Tickets/tickets_screen.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Equipments/my_equipments.dart';
import 'package:helpdeskfrontend/screens/client_dashboard.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';

class NavbarClient extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavbarClient({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  void _navigateToPage(BuildContext context, int index) {
    print('Navigating to index: $index');
    switch (index) {
      case 0: // Home
        print('Navigating to Home');
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1: // Equipments
        print('Navigating to equipments');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyEquipmentPage()),
        );
        break;
      case 2: // Profile
        print('Navigating to profile');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
      case 3: // Tickets
        print('Navigating to tickets');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TicketsScreen()),
        );
        break;
      case 4: // Dashboard Client (centered button)
        print('Navigating to Client Dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ClientDashboard()),
        );
        break;
      default:
        print('Unknown index: $index');
        break;
    }
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final primaryColor =
        isDarkMode ? const Color(0xFF141218) : const Color(0xFF628ff6);

    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main navigation bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavigationBar(
              currentIndex:
                  currentIndex > 3 ? 0 : currentIndex, // Handle dashboard case
              onTap: (index) {
                _navigateToPage(context, index);
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: primaryColor,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.7),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.computer),
                  label: 'Équipements',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.report_problem),
                  label: 'Tickets',
                ),
              ],
            ),
          ),
          // Center dashboard button - RÉTABLI AVEC COULEUR VERTE ORIGINALE
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 30,
            top: -30,
            child: GestureDetector(
              onTap: () => _navigateToPage(context, 4), // Dashboard navigation
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(
                      0xFFa3e388), // Couleur verte originale (#a3e388)
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person, // Icône person conservée
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
