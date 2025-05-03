import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Dashboard/admin_dashboard.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Users/admin_users_list.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Tickets/admin_tickets_list.dart'; // Ajoutez cette importation
import 'package:helpdeskfrontend/widgets/equipement_bottom_sheet.dart';

class NavbarAdmin extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavbarAdmin({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  void _navigateToPage(BuildContext context, int index) {
    print('Navigating to index: $index');
    switch (index) {
      case 0: // Home
        print('Navigating to Home');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardAdmin()),
        );
        break;
      case 1: // Users
        print('Navigating to Users');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminUsersList()),
        );
        break;
      case 2: // Equipements
        print('Showing Equipements BottomSheet');
        EquipementBottomSheet.show(context);
        return;
      case 3: // Tickets
        print('Navigating to Tickets');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminTicketsListPage()),
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
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        _navigateToPage(context, index);
      },
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.computer),
          label: 'Equipements',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.report_problem),
          label: 'Tickets',
        ),
      ],
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
    );
  }
}
