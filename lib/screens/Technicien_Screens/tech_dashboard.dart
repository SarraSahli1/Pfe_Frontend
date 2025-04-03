import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/widgets/navbar_technicien.dart';

class TechnicianDashboard extends StatefulWidget {
  const TechnicianDashboard({super.key});

  @override
  _TechnicianDashboardState createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  int _selectedIndex = 0; // Index of selected tab

  // Tab titles corresponding to each index
  final List<String> _tabTitles = ['Dashboard', 'My Tickets', 'Schedule'];

  // Update selected index
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: Center(
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: NavbarTechnician(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0: // Dashboard
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.engineering, size: 64, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Welcome, Technician!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'You have 5 assigned tickets',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1; // Navigate to tickets
                });
              },
              child: const Text('View My Tickets'),
            ),
          ],
        );
      case 1: // My Tickets
        return const Center(
          child: Text(
            'My Tickets List',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      case 2: // Schedule
        return const Center(
          child: Text(
            'Work Schedule',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
      default:
        return const Center(child: Text('Invalid tab'));
    }
  }
}
