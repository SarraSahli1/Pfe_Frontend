import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/admin_users_list.dart';
import 'package:helpdeskfrontend/widgets/equipement_bottom_sheet.dart'; // Import the new widget

class NavbarAdmin extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavbarAdmin({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  void _navigateToPage(BuildContext context, int index) {
    print('Navigating to index: $index'); // Debug log
    switch (index) {
      case 0: // Home
        print('Navigating to Home');
        Navigator.pushReplacementNamed(context, '/home');
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
        EquipementBottomSheet.show(
            context); // Show the BottomSheet without navigation
        return; // Do not update the index or navigate further
      case 3: // Tickets
        print('Navigating to Tickets');
        Navigator.pushReplacementNamed(context, '/tickets');
        break;
      default:
        print('Unknown index: $index'); // Debug log
        break;
    }
    onTap(index); // Update parent state if necessary (except for Equipements)
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
