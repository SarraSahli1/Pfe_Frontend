import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Equipments/create_equipment.dart';
import 'package:helpdeskfrontend/services/typeEquip_service.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';

class ChooseEquipmentType extends StatefulWidget {
  @override
  _ChooseEquipmentTypeState createState() => _ChooseEquipmentTypeState();
}

class _ChooseEquipmentTypeState extends State<ChooseEquipmentType> {
  final TypeEquipmentService _typeEquipmentService = TypeEquipmentService();
  List<dynamic> _typeEquipmentList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTypeEquipment();
  }

  Future<void> _fetchTypeEquipment() async {
    try {
      final types = await _typeEquipmentService.getAllTypeEquipment();
      setState(() {
        _typeEquipmentList = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération des types: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    // Couleurs
    final backgroundColor =
        isDarkMode ? const Color(0xFF242E3E) : const Color(0xFF628FF6);
    final topSectionColor = isDarkMode ? const Color(0xFF141218) : Colors.white;
    final topSectionTextColor =
        isDarkMode ? Colors.white : const Color(0xFF628FF6);
    final cardColor = isDarkMode ? Colors.white : Colors.white;
    final textColor = isDarkMode ? Colors.black : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      body: Column(
        children: [
          // Top section (smaller - about 1/4 of screen)
          Container(
            height: MediaQuery.of(context).size.height / 4,
            decoration: BoxDecoration(
              color: topSectionColor,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with back button
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: topSectionTextColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create Equipment',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: topSectionTextColor,
                          ),
                        ),
                        const Spacer(),
                        const ThemeToggleButton(),
                      ],
                    ),
                    const Spacer(),
                    // Centered and bigger subtitle
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          "Select the type of equipment you want to add",
                          style: GoogleFonts.poppins(
                            fontSize: 20, // Increased from 16 to 20
                            fontWeight: FontWeight.w500, // Added medium weight
                            color: isDarkMode
                                ? Colors.white
                                    .withOpacity(0.9) // Increased opacity
                                : const Color(0xFF628FF6).withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom section with grid
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
              ),
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.white : Colors.blue),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _typeEquipmentList.length,
                        itemBuilder: (context, index) {
                          final type = _typeEquipmentList[index];
                          final logoUrl = type['logo'] != null
                              ? type['logo']['path']
                              : null;
                          final typeName = type['typeName'] ?? 'No Name';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateEquipmentPage(
                                    typeEquipmentId: type['_id'],
                                    typeEquipmentName: typeName,
                                  ),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  // Refresh if needed
                                }
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  color: cardColor,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    padding: EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: logoUrl != null
                                                ? Image.network(
                                                    logoUrl,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Center(
                                                        child: Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 40,
                                                          color:
                                                              secondaryTextColor,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Center(
                                                    child: Icon(
                                                      Icons.build,
                                                      size: 40,
                                                      color: secondaryTextColor,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          typeName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
