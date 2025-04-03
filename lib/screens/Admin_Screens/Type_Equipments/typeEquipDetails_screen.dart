import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Problems/problems_list_page.dart'; // Importez la page des problèmes

class TypeEquipDetailsPage extends StatelessWidget {
  final String typeName;
  final String typeEquip;
  final String? logo;
  final String typeEquipmentId;

  const TypeEquipDetailsPage({
    Key? key,
    required this.typeName,
    required this.typeEquip,
    this.logo,
    required this.typeEquipmentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'équipement'),
      ),
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? const Color(0xFF242E3E)
          : Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Afficher le logo
            if (logo != null)
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(logo!),
                  child: logo == null
                      ? Icon(Icons.build, size: 50)
                      : null, // Afficher une icône par défaut si le logo est null
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Nom du type: $typeName',
              style: TextStyle(
                fontSize: 18,
                color: themeProvider.themeMode == ThemeMode.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Type d\'équipement: $typeEquip',
              style: TextStyle(
                fontSize: 18,
                color: themeProvider.themeMode == ThemeMode.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            // Bouton pour afficher les problèmes associés
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Naviguer vers la page ProblemsListPage avec l'ID du type d'équipement
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProblemsListPage(
                        typeEquipmentId: typeEquipmentId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Couleur de fond du bouton
                  foregroundColor: Colors.white, // Couleur du texte
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text('Check Problems'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
