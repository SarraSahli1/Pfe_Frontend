import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/screens/typeEquip_list_screen.dart';
import 'package:helpdeskfrontend/theme/theme.dart';
import 'package:provider/provider.dart';

class EquipementBottomSheet extends StatelessWidget {
  const EquipementBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ThemeData theme = Theme.of(context);
    final CustomColors? customColors = theme.extension<CustomColors>();

    return Container(
      height: 200, // Hauteur du BottomSheet
      padding: const EdgeInsets.all(16.0), // Espacement autour des cartes
      decoration: BoxDecoration(
        color: themeProvider.themeMode == ThemeMode.dark
            ? const Color(0xFF242E3E) // Fond sombre en mode sombre
            : Colors.grey[200], // Fond gris en mode clair
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly, // Espacement égal entre les cartes
        children: [
          // Première carte
          _buildSquareCard(
            context,
            icon: Icons.computer,
            label: 'Equipment',
            backgroundColor: themeProvider.themeMode == ThemeMode.dark
                ? Colors.white
                    .withOpacity(0.1) // Fond semi-transparent en mode sombre
                : Colors.white, // Fond blanc en mode clair
            iconColor: themeProvider.themeMode == ThemeMode.dark
                ? Colors.white // Icône blanche en mode sombre
                : const Color(0xFF416FDF), // Texte bleu en mode clair
            textColor: themeProvider.themeMode == ThemeMode.dark
                ? Colors.white // Texte blanc en mode sombre
                : Colors.black, // Texte noir en mode clair
            onPressed: () {
              Navigator.pop(context); // Fermer le BottomSheet
              // Ajouter votre logique ici
            },
          ),
          // Deuxième carte
          _buildSquareCard(
            context,
            icon: Icons.list,
            label: 'Equipment Type',
            backgroundColor: themeProvider.themeMode == ThemeMode.dark
                ? Colors.white
                    .withOpacity(0.1) // Fond semi-transparent en mode sombre
                : Colors.white, // Fond blanc en mode clair
            iconColor: themeProvider.themeMode == ThemeMode.dark
                ? Colors.white // Icône blanche en mode sombre
                : const Color(0xFF416FDF), // Texte bleu en mode clair
            textColor: themeProvider.themeMode == ThemeMode.dark
                ? Colors.white // Texte blanc en mode sombre
                : Colors.black, // Texte noir en mode clair
            onPressed: () {
              Navigator.pop(context); // Fermer le BottomSheet
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TypeEquipmentListPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // Méthode pour construire une carte carrée
  Widget _buildSquareCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed, // Action lors du clic sur la carte
      child: Container(
        width: 120, // Largeur de la carte
        height: 120, // Hauteur de la carte (pour la rendre carrée)
        decoration: BoxDecoration(
          color: backgroundColor, // Couleur de fond de la carte
          borderRadius: BorderRadius.circular(12), // Bords arrondis
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: iconColor, // Couleur de l'icône
            ),
            const SizedBox(height: 10), // Espace entre l'icône et le texte
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor, // Couleur du texte
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return const EquipementBottomSheet();
      },
    );
  }
}
