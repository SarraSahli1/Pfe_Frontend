import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Dashboard/admin_dashboard.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Users/admin_users_list.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Tickets/admin_tickets_list.dart';
import 'package:helpdeskfrontend/widgets/equipement_bottom_sheet.dart';

class NavbarAdmin extends StatelessWidget {
  final int currentIndex;
  final BuildContext context;

  const NavbarAdmin({
    Key? key,
    required this.currentIndex,
    required this.context,
  }) : super(key: key);

  void _handleEquipmentTap() {
    // Affiche le bottom sheet même si on est déjà sur la page EquipmentList
    EquipementBottomSheet.show(context);
  }

  void _navigateToPage(int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardAdmin()),
        );
        break;
      case 1: // Users
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminUsersList()),
        );
        break;
      case 2: // Equipements
        _handleEquipmentTap();
        break;
      case 3: // Tickets
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminTicketsListPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: _navigateToPage,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        BottomNavigationBarItem(
            icon: Icon(Icons.computer), label: 'Equipements'),
        BottomNavigationBarItem(
            icon: Icon(Icons.report_problem), label: 'Tickets'),
      ],
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
    );
  }
}
