import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/tickets_screen.dart';

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
      case 2: // Schedule
        print('Navigating to Schedule');
        Navigator.pushReplacementNamed(context, '/technician-schedule');
        break;
      case 3: // Profile
        print('Navigating to Technician Profile');
        Navigator.pushReplacementNamed(context, '/technician-profile');
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
          icon: Icon(Icons.calendar_today),
          label: 'Schedule',
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
