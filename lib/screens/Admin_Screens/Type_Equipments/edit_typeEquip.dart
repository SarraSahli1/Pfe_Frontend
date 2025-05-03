import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:helpdeskfrontend/services/typeEquip_service.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';

class EditTypeEquipmentPage extends StatefulWidget {
  final String id;
  final String initialTypeName;
  final String initialTypeEquip;
  final String? initialLogoPath;

  const EditTypeEquipmentPage({
    Key? key,
    required this.id,
    required this.initialTypeName,
    required this.initialTypeEquip,
    this.initialLogoPath,
  }) : super(key: key);

  @override
  _EditTypeEquipmentPageState createState() => _EditTypeEquipmentPageState();
}

class _EditTypeEquipmentPageState extends State<EditTypeEquipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _typeNameController = TextEditingController();
  final _typeEquipController = TextEditingController();
  final TypeEquipmentService _typeEquipmentService = TypeEquipmentService();
  File? _logoFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _typeNameController.text = widget.initialTypeName;
    _typeEquipController.text = widget.initialTypeEquip;
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _logoFile = File(pickedFile.path);
      }
    });
  }

  Future<void> _updateTypeEquipment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _typeEquipmentService.updateTypeEquipment(
          id: widget.id,
          typeName: _typeNameController.text,
          typeEquip: _typeEquipController.text,
          logoFile: _logoFile,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF242E3E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? const Color(0xFF858397) : Colors.black54;
    final textFieldBackgroundColor =
        isDarkMode ? const Color(0xFF2A3447) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Modifier le type d\'équipement',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Color(0xFF628ff6),
        iconTheme: IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Image Section at the top
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        ),
                        child: _logoFile != null
                            ? ClipOval(
                                child: Image.file(
                                  _logoFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (widget.initialLogoPath != null
                                ? ClipOval(
                                    child: Image.network(
                                      widget.initialLogoPath!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: textColor,
                                    ),
                                  )),
                      ),
                    ),

                    // Form Fields
                    _buildTextField(
                      label: 'Nom du type*',
                      controller: _typeNameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                      hintColor: hintColor,
                      textColor: textColor,
                      backgroundColor: textFieldBackgroundColor,
                      icon: Icons.category,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Type d\'équipement*',
                      controller: _typeEquipController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un type';
                        }
                        return null;
                      },
                      hintColor: hintColor,
                      textColor: textColor,
                      backgroundColor: textFieldBackgroundColor,
                      icon: Icons.devices,
                    ),
                    const SizedBox(height: 30),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateTypeEquipment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode ? Colors.blue.shade800 : Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : Text(
                                'Enregistrer',
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
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    required Color hintColor,
    required Color textColor,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: hintColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: hintColor),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
