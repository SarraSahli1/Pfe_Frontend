import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../provider/theme_provider.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  final String role; // Role passed as argument

  const RegisterScreen({super.key, required this.role});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool? permisConduire;
  bool? passeport;
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController secondEmailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController expiredAtController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  TextEditingController aboutController = TextEditingController();
  TextEditingController companyController = TextEditingController();

  String? signatureFilePath;
  String? profileImagePath;

  late String authority;

  @override
  void initState() {
    super.initState();
    authority = widget.role.toLowerCase() == "technicien"
        ? "technician"
        : (widget.role.toLowerCase() == "client" ? "client" : "");
    print("Authority définie: $authority"); // Debugging
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

  void _register() async {
    if (_formKey.currentState!.validate()) {
      var response = await _authService.registerUser(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        secondEmail: secondEmailController.text.trim(),
        password: passwordController.text.trim(),
        authority: authority,
        phoneNumber: phoneNumberController.text.trim(),
        permisConduire: permisConduire ?? false,
        passeport: passeport ?? false,
        expiredAt: expiredAtController.text.trim(),
        birthDate: widget.role == 'Technicien'
            ? birthDateController.text.trim()
            : null,
        signature: widget.role == 'Technicien' && signatureFilePath != null
            ? signatureFilePath
            : null,
        image: profileImagePath,
        about: widget.role == "Client" ? aboutController.text.trim() : null,
        company: widget.role == "Client" ? companyController.text.trim() : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'])),
      );

      if (response['success']) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = themeProvider.themeMode == ThemeMode.dark
        ? darkColorScheme
        : lightColorScheme;

    final backgroundColor = themeProvider.themeMode == ThemeMode.dark
        ? const Color(0xFF242E3E) // Fond sombre
        : Colors.white; // Fond clair

    final textColor = themeProvider.themeMode == ThemeMode.dark
        ? Colors.white // Texte blanc en mode sombre
        : Colors.black; // Texte noir en mode clair

    final fieldColor = themeProvider.themeMode == ThemeMode.dark
        ? const Color(0xFF2C2C34) // Champ gris foncé en mode sombre
        : Colors.white; // Champ blanc en mode clair

    final hintColor = themeProvider.themeMode == ThemeMode.dark
        ? const Color(0xFF858397) // Texte gris en mode sombre
        : Colors.black54; // Texte gris en mode clair

    final borderColor = themeProvider.themeMode == ThemeMode.dark
        ? const Color(0xFF858397) // Bordure grise en mode sombre
        : Colors.black; // Bordure noire en mode clair

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ThemeToggleButton(), // Bouton de basculement de thème
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.only(top: 20), // Réduire l'espace en haut
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Titre
                Text(
                  'Sign Up as ${widget.role}',
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Profile Image Picker
                ElevatedButton(
                  onPressed: _pickProfileImage,
                  child: Text(profileImagePath == null
                      ? "Upload Profile Image"
                      : "Change Profile Image"),
                ),
                if (profileImagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Selected Profile Image: ${profileImagePath!.split('/').last}",
                      style: GoogleFonts.poppins(
                        color: hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // First Name
                _buildTextField(
                  label: 'First Name',
                  controller: firstNameController,
                  validator: (value) =>
                      value!.isEmpty ? "Enter first name" : null,
                  hintColor: hintColor,
                  textColor: textColor,
                  fieldColor: fieldColor,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 10),

                // Last Name
                _buildTextField(
                  label: 'Last Name',
                  controller: lastNameController,
                  validator: (value) =>
                      value!.isEmpty ? "Enter last name" : null,
                  hintColor: hintColor,
                  textColor: textColor,
                  fieldColor: fieldColor,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 10),

                // Email
                _buildTextField(
                  label: 'Email',
                  controller: emailController,
                  validator: (value) => value!.isEmpty ? "Enter email" : null,
                  hintColor: hintColor,
                  textColor: textColor,
                  fieldColor: fieldColor,
                  borderColor: borderColor,
                ),

                if (widget.role == "Technicien") ...[
                  const SizedBox(height: 10),

                  // Second Email (for Technicien)
                  _buildTextField(
                    label: 'Second Email',
                    controller: secondEmailController,
                    validator: (value) =>
                        value!.isEmpty ? "Enter second email" : null,
                    hintColor: hintColor,
                    textColor: textColor,
                    fieldColor: fieldColor,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 10),

                  // Birthdate (for Technicien)
                  _buildTextField(
                    label: 'Birthdate',
                    controller: birthDateController,
                    validator: (value) =>
                        value!.isEmpty ? "Enter birthdate" : null,
                    hintColor: hintColor,
                    textColor: textColor,
                    fieldColor: fieldColor,
                    borderColor: borderColor,
                  ),
                ],

                const SizedBox(height: 10),

                // Password
                _buildTextField(
                  label: 'Password',
                  controller: passwordController,
                  obscureText: true,
                  validator: (value) =>
                      value!.length < 6 ? "Password too short" : null,
                  hintColor: hintColor,
                  textColor: textColor,
                  fieldColor: fieldColor,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 10),

                // Phone Number
                _buildTextField(
                  label: 'Phone Number',
                  controller: phoneNumberController,
                  hintColor: hintColor,
                  textColor: textColor,
                  fieldColor: fieldColor,
                  borderColor: borderColor,
                ),

                if (authority == "client") ...[
                  const SizedBox(height: 10),

                  // About (for Client)
                  _buildTextField(
                    label: 'About',
                    controller: aboutController,
                    validator: (value) => value!.isEmpty ? "Enter about" : null,
                    hintColor: hintColor,
                    textColor: textColor,
                    fieldColor: fieldColor,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 10),

                  // Company (for Client)
                  _buildTextField(
                    label: 'Company',
                    controller: companyController,
                    validator: (value) =>
                        value!.isEmpty ? "Enter company" : null,
                    hintColor: hintColor,
                    textColor: textColor,
                    fieldColor: fieldColor,
                    borderColor: borderColor,
                  ),
                ],

                if (widget.role == "Technicien") ...[
                  const SizedBox(height: 10),

                  // Permis de Conduire (for Technicien)
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
                    fieldColor: fieldColor,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 10),

                  // Passeport (for Technicien)
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
                    fieldColor: fieldColor,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 10),

                  // Expiration Date (for Technicien)
                  _buildTextField(
                    label: 'Expiration Date',
                    controller: expiredAtController,
                    validator: (value) =>
                        value!.isEmpty ? "Enter expiration date" : null,
                    hintColor: hintColor,
                    textColor: textColor,
                    fieldColor: fieldColor,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 10),

                  // Signature File Picker (for Technicien)
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

                const SizedBox(height: 20),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _register,
                    child: const Text('Sign Up'),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
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
    required Color fieldColor,
    required Color borderColor,
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
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: fieldColor,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
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
                horizontal: 20,
                vertical: 15,
              ),
              border: InputBorder.none,
              errorBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
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
    required Color fieldColor,
    required Color borderColor,
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
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: fieldColor,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
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
                horizontal: 20,
                vertical: 15,
              ),
              border: InputBorder.none,
              errorBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
