import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Profile/profile.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/Solutions/solutions_list.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/tickets_screen.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/equipments/myequipments.dart';

class NavbarTechnician extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavbarTechnician({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  void _navigateToPage(BuildContext context, int index) {
    print('Technician navigating to index: $index');
    switch (index) {
      case 0: // Dashboard
        print('Navigating to Technician Dashboard');
        Navigator.pushReplacementNamed(context, '/technician-dashboard');
        break;
      case 1: // Assigned Tickets
        print('Navigating to Assigned Tickets');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TechnicianTicketsScreen(),
          ),
        );
        break;
      case 2: // Solutions (Knowledge Base)
        print('Navigating to Solutions');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SolutionsListPage(),
          ),
        );
        break;
      case 3: // Equipment
        print('Navigating to My Equipments');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyEquipmentPage(), // Your equipment page
          ),
        );
        break;
      case 4: // Profile
        print('Navigating to Profile');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfilePage(),
          ),
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
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
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
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
    );
  }
}
