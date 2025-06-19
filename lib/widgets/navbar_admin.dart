import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Dashboard/admin_dashboard.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Solutions/solutions_list.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Tickets/admin_tickets_list.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Users/admin_users_list.dart';
import 'package:helpdeskfrontend/widgets/equipement_bottom_sheet.dart';

class NavbarAdmin extends StatelessWidget {
  final int
      currentIndex; // 0: Dashboard, 1: Users, 2: Equipments, 3: Tickets, 4: Solutions
  final BuildContext context;

  const NavbarAdmin({
    Key? key,
    required this.currentIndex,
    required this.context,
  }) : super(key: key);

  void _navigateToPage(int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardAdmin()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminUsersList()),
          (route) => false,
        );
        break;
      case 2:
        EquipementBottomSheet.show(context);
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminTicketsListPage()),
          (route) => false,
        );
        break;
      case 4:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SolutionsListPage()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              backgroundColor: const Color(0xFF628ff6),
              selectedItemColor: currentIndex == 0
                  ? Colors.white.withOpacity(0.7) // Dimmed when on dashboard
                  : Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.7),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.computer),
                  label: 'Equipments',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.report_problem),
                  label: 'Tickets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.lightbulb_outline),
                  label: 'Solutions',
                ),
              ],
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 30,
            top: -30,
            child: GestureDetector(
              onTap: () => _navigateToPage(0),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF79B72), // Always orange
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
                  Icons.admin_panel_settings,
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
