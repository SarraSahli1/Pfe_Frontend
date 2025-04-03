import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Tickets/tickets_screen.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Equipments/my_equipments.dart';

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
      case 2: // Users (hhhzh)
        return; // Do nothing as per your current implementation
      case 3: // Tickets
        print('Navigating to tickets');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TicketsScreen()),
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
          icon: Icon(Icons.computer),
          label: 'Equipments',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'hhhzh',
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
