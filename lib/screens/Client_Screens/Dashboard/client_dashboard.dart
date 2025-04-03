import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/widgets/navbar_client.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  _ClientDashboardState createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  int _selectedIndex = 0; // Index de l'onglet sélectionné

  // Méthode pour mettre à jour l'index sélectionné
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord Client'),
      ),
      body: Center(
        child: _selectedIndex == 0
            ? const Text(
                'Bienvenue, Client!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              )
            : const Text(
                'Page des Tickets',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
      ),
      bottomNavigationBar: NavbarClient(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
