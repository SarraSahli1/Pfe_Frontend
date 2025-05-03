import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Problems/problems_list_page.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart'; // Importez le bouton de bascule de thème

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
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF242E3E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor =
        isDarkMode ? const Color(0xFF2A3447) : const Color(0xFFF5F5F5);
    final buttonColor =
        isDarkMode ? const Color(0xFF628ff6) : const Color(0xFF628ff6);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Equipment Type Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFF628ff6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(), // Ajout du bouton de bascule de thème
        ],
      ),
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Logo Section
            Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              child: logo != null
                  ? ClipOval(
                      child: Image.network(
                        logo!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.broken_image,
                            size: 50,
                            color: textColor,
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.build,
                        size: 50,
                        color: textColor,
                      ),
                    ),
            ),

            // Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(
                    icon: Icons.category,
                    label: 'Type Name',
                    value: typeName,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.devices,
                    label: 'Equipment Type',
                    value: typeEquip,
                    textColor: textColor,
                  ),
                ],
              ),
            ),

            // Problems Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
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
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'View Associated Problems',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: textColor.withOpacity(0.8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: textColor.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
