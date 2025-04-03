import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:helpdeskfrontend/services/typeEquip_service.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';

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
    print('Initial Logo Path: ${widget.initialLogoPath}');
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _logoFile = File(pickedFile.path);
      } else {
        print('No image selected.');
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
    final backgroundColor = themeProvider.themeMode == ThemeMode.dark
        ? const Color(0xFF242E3E)
        : Colors.white;
    final textColor =
        themeProvider.themeMode == ThemeMode.dark ? Colors.white : Colors.black;
    final hintColor = themeProvider.themeMode == ThemeMode.dark
        ? const Color(0xFF858397)
        : Colors.black54;
    final textFieldBackgroundColor = themeProvider.themeMode == ThemeMode.dark
        ? const Color(0xFF2A3447)
        : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Modifier le type d\'équipement',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: textColor),
            onPressed: _isLoading ? null : _updateTypeEquipment,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 30, 30, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 15),
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
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _logoFile != null
                                  ? FileImage(_logoFile!)
                                  : (widget.initialLogoPath != null
                                      ? NetworkImage(widget.initialLogoPath!)
                                      : null),
                              child: _logoFile == null &&
                                      widget.initialLogoPath == null
                                  ? Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: textColor,
                                    )
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateTypeEquipment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
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
    bool obscureText = false,
    String? Function(String?)? validator,
    required Color hintColor,
    required Color textColor,
    Widget? suffixIcon,
    Color? backgroundColor,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: hintColor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              filled: false,
              prefixIcon: icon != null ? Icon(icon, color: hintColor) : null,
              suffixIcon: suffixIcon,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
