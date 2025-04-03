import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class RegisterPage2 extends StatefulWidget {
  final String role;
  final Map<String, dynamic> commonData;
  final Function(Map<String, dynamic>) onRegister;

  const RegisterPage2({
    super.key,
    required this.role,
    required this.commonData,
    required this.onRegister,
  });

  @override
  _RegisterPage2State createState() => _RegisterPage2State();
}

class _RegisterPage2State extends State<RegisterPage2> {
  final _formKey = GlobalKey<FormState>();
  bool? permisConduire;
  bool? passeport;
  TextEditingController secondEmailController = TextEditingController();
  TextEditingController expiredAtController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  TextEditingController aboutController = TextEditingController();
  TextEditingController companyController = TextEditingController();
  String? signatureFilePath;
  String? profileImagePath;

  @override
  void initState() {
    super.initState();
    profileImagePath = widget.commonData['image']; // Initialize the image
  }

  Future<void> _pickSignature() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        signatureFilePath = pickedFile.path;
      });
    }
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      final data = {
        ...widget.commonData,
        'secondEmail': secondEmailController.text.trim(),
        'permisConduire': permisConduire ?? false,
        'passeport': passeport ?? false,
        'expiredAt': expiredAtController.text.trim(),
        'birthDate': widget.role == 'Technicien'
            ? birthDateController.text.trim()
            : null,
        'signature': widget.role == 'Technicien' && signatureFilePath != null
            ? signatureFilePath
            : null,
        'image':
            profileImagePath ?? 'assets/default_profile.png', // Default image
        'about': widget.role == "Client" ? aboutController.text.trim() : null,
        'company':
            widget.role == "Client" ? companyController.text.trim() : null,
      };
      widget.onRegister(data);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [ThemeToggleButton()], // Theme toggle button
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(30, 30, 30, 40), // Padding applied here
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Let’s complete your profile',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              if (widget.role == "Technicien") ...[
                // Second Email
                _buildTextField(
                  label: 'Second Email',
                  controller: secondEmailController,
                  validator: (value) =>
                      value!.isEmpty ? "Enter second email" : null,
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                  icon: Icons.email,
                ),

                const SizedBox(height: 10),

                // Birthdate
                _buildTextField(
                  label: 'Birthdate',
                  controller: birthDateController,
                  validator: (value) =>
                      value!.isEmpty ? "Enter birthdate" : null,
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                  icon: Icons.calendar_today,
                ),

                const SizedBox(height: 10),

                // Permis de Conduire
                _buildDropdown(
                  label: 'Permis de Conduire',
                  value: permisConduire,
                  items: const ["Oui", "Non"],
                  onChanged: (value) {
                    setState(() {
                      permisConduire = value == "Oui";
                    });
                  },
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                  icon: Icons.directions_car,
                ),

                const SizedBox(height: 10),

                // Passeport
                _buildDropdown(
                  label: 'Passeport',
                  value: passeport,
                  items: const ["Oui", "Non"],
                  onChanged: (value) {
                    setState(() {
                      passeport = value == "Oui";
                    });
                  },
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                  icon: Icons.airplanemode_active,
                ),

                const SizedBox(height: 10),

                // Signature File Picker

                ElevatedButton(
                  onPressed: _pickSignature,
                  child: Text(signatureFilePath == null
                      ? "Upload Signature"
                      : "Change Signature"),
                ),
                if (signatureFilePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Selected File: ${signatureFilePath!.split('/').last}",
                      style: GoogleFonts.poppins(
                        color: hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],

              if (widget.role == "Client") ...[
                const SizedBox(height: 10),

                // About
                _buildTextField(
                  label: 'About',
                  controller: aboutController,
                  validator: (value) => value!.isEmpty ? "Enter about" : null,
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                  icon: Icons.info_outline,
                ),

                const SizedBox(height: 10),

                // Company
                _buildTextField(
                  label: 'Company',
                  controller: companyController,
                  validator: (value) => value!.isEmpty ? "Enter company" : null,
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                  icon: Icons.business,
                ),
              ],

              const SizedBox(height: 20),

              // Register Button
              Center(
                child: ElevatedButton(
                  onPressed: _register,
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
                    'Register',
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
    Color? backgroundColor,
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
              // ignore: unnecessary_null_comparison
              prefixIcon: icon != null ? Icon(icon, color: hintColor) : null,
              filled: false,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required bool? value,
    required List<String> items,
    required Function(String?) onChanged,
    required Color hintColor,
    required Color textColor,
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
          child: DropdownButtonFormField<String>(
            value: value == true ? "Oui" : "Non",
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              filled: false,
            ),
          ),
        ),
      ],
    );
  }
}
