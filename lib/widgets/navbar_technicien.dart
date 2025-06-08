import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Profile/profile.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/Solutions/solutions_list.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/tech_dashboard.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/tickets_screen.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/equipments/myequipments.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';

class NavbarTechnician extends StatelessWidget {
  final int
      currentIndex; // 0: Dashboard, 1: Profile, 2: Tickets, 3: Solutions, 4: Equipment
  final BuildContext context;

  const NavbarTechnician({
    Key? key,
    required this.currentIndex,
    required this.context,
  }) : super(key: key);

  void _navigateToPage(int index) {
    if (index == currentIndex) return;

    // For all navigation, clear the stack completely
    Widget page;
    switch (index) {
      case 0:
        page = const TechnicianDashboard();
        break;
      case 1:
        page = const ProfilePage();
        break;
      case 2:
        page = const TechnicianTicketsScreen();
        break;
      case 3:
        page = const SolutionsListPage();
        break;
      case 4:
        page = MyEquipmentPage();
        break;
      default:
        return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final primaryColor =
        isDarkMode ? const Color(0xFF141218) : const Color(0xFF628ff6);

    // Toujours utiliser la couleur bleue pour le bouton dashboard
    final dashboardButtonColor =
        isDarkMode ? const Color(0xFF141218) : const Color(0xFF628ff6);

    // For BottomNavigationBar, we'll use a separate index (0-3 for nav items)
    final navbarIndex = currentIndex > 0 ? currentIndex - 1 : 0;

    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavigationBar(
              currentIndex: currentIndex == 0 ? 0 : navbarIndex,
              onTap: (index) {
                // Dashboard is handled by floating button, so index+1 for others
                _navigateToPage(index + 1);
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: primaryColor,
              selectedItemColor: currentIndex == 0
                  ? Colors.white.withOpacity(0.7) // Dimmed when on dashboard
                  : Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.7),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment),
                  label: 'Tickets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book),
                  label: 'Solutions',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.computer),
                  label: 'Equipment',
                ),
              ],
            ),
          ),
          // Center dashboard button - TOUJOURS BLEU
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 30,
            top: -30,
            child: GestureDetector(
              onTap: () => _navigateToPage(0),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: dashboardButtonColor, // Toujours bleu
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
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
                  Icons.build,
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
