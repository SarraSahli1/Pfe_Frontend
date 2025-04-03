import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class RegisterPage1 extends StatefulWidget {
  final String role;
  final Function(Map<String, dynamic>) onNext;

  const RegisterPage1({super.key, required this.role, required this.onNext});

  @override
  _RegisterPage1State createState() => _RegisterPage1State();
}

class _RegisterPage1State extends State<RegisterPage1> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  String? profileImagePath;
  bool _obscurePassword = true;

  // Méthode pour sélectionner une image de profil
  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        profileImagePath = pickedFile.path;
      });
    }
  }

  void _next() {
    if (_formKey.currentState == null) {
      // Si le formulaire n'est pas encore initialisé, ne rien faire
      return;
    }

    if (_formKey.currentState!.validate()) {
      final data = {
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'phoneNumber': phoneNumberController.text.trim(),
        'image': profileImagePath, // Inclure l'image de profil
      };
      widget.onNext(data); // Passer les données communes à RegisterScreen
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
        ? const Color(0xFF2A3447) // Dark theme color
        : const Color(0xFFF5F5F5); // Light theme color

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [ThemeToggleButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            30, 30, 30, 40), // Déplacez le padding ici
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    'Create an Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Profile Image Picker (Cercle avec icône et icône "+")
              Center(
                child: GestureDetector(
                  onTap: _pickProfileImage, // Ouvrir la galerie d'images
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: profileImagePath != null
                            ? ClipOval(
                                child: Image.file(
                                  File(profileImagePath!),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
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

              const SizedBox(height: 20),

              // First Name et Last Name côte à côte
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'First Name',
                      controller: firstNameController,
                      validator: (value) =>
                          value!.isEmpty ? "Enter first name" : null,
                      hintColor: hintColor,
                      textColor: textColor,
                      backgroundColor: textFieldBackgroundColor,
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      label: 'Last Name',
                      controller: lastNameController,
                      validator: (value) =>
                          value!.isEmpty ? "Enter last name" : null,
                      hintColor: hintColor,
                      textColor: textColor,
                      backgroundColor: textFieldBackgroundColor,
                      icon: Icons.person,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Email
              _buildTextField(
                label: 'Email',
                controller: emailController,
                validator: (value) => value!.isEmpty ? "Enter email" : null,
                hintColor: hintColor,
                textColor: textColor,
                backgroundColor: textFieldBackgroundColor,
                icon: Icons.email,
              ),

              const SizedBox(height: 15),

              // Password
              _buildTextField(
                label: 'Password',
                controller: passwordController,
                obscureText: _obscurePassword,
                validator: (value) =>
                    value!.length < 6 ? "Password too short" : null,
                hintColor: hintColor,
                textColor: textColor,
                icon: Icons.lock,
                backgroundColor: textFieldBackgroundColor,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: hintColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 15),

              // Phone Number
              _buildTextField(
                label: 'Phone Number',
                controller: phoneNumberController,
                hintColor: hintColor,
                textColor: textColor,
                backgroundColor: textFieldBackgroundColor,
                icon: Icons.phone,
              ),

              const SizedBox(height: 10),

              // Accept Terms
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Poppins',
                          color: hintColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Next Button
              Center(
                child: ElevatedButton(
                  onPressed: _next,
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
                  child: const Text(
                    'Next',
                    style: TextStyle(
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
    IconData? icon, // Ajout de l'icône
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
            color: backgroundColor, // Use the provided background color
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
