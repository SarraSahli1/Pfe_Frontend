import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/widgets/navbar_client.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord Client'),
      ),
      body: const Center(
        child: Text(
          'Bienvenue, Client!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: NavbarClient(
        currentIndex: 0, // Index pour le dashboard
        onTap: (index) {
          // La navigation est gérée dans NavbarClient elle-même
        },
      ),
    );
  }
}
