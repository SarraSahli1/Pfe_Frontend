import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Users/admin_users_list.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Dashboard/client_dashboard.dart';
import 'package:helpdeskfrontend/screens/First_Screens/role_screen.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/tech_dashboard.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/theme/theme.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formSignInKey = GlobalKey<FormState>();
  bool rememberPassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_formSignInKey.currentState!.validate() && rememberPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connexion en cours...'),
        ),
      );

      final result = await _authService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result['success']) {
        final userAuthority = result['payload']['user']['authority'];
        print('Rôle de l\'utilisateur: $userAuthority'); // Pour déboguer

        if (userAuthority == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminUsersList(),
            ),
          );
        } else if (userAuthority == 'client') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ClientDashboard(),
            ),
          );
        } else if (userAuthority == 'technician') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TechnicianDashboard(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rôle utilisateur non reconnu'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
          ),
        );
      }
    } else if (!rememberPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Veuillez accepter le traitement des données personnelles'),
        ),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    required Color hintColor,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              validator: validator,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  icon,
                  color: hintColor,
                ),
                labelText: label,
                labelStyle: GoogleFonts.poppins(
                  color: hintColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = themeProvider.themeMode == ThemeMode.dark
        ? darkColorScheme
        : lightColorScheme;

    // Dynamic background image based on theme
    final backgroundImage = themeProvider.themeMode == ThemeMode.dark
        ? 'assets/images/bg_dark.png'
        : 'assets/images/bg_light.png';

    // Dynamic logo based on theme
    final logoImage = themeProvider.themeMode == ThemeMode.dark
        ? 'assets/images/opmlogo.png'
        : 'assets/images/logoopm_light.png';

    // Determine text color based on theme
    final textColor = themeProvider.themeMode == ThemeMode.dark
        ? colorScheme.onPrimary
        : Colors.black;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image (without frosted glass effect)
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 375),
                  child: Padding(
                    padding: MediaQuery.of(context).size.width > 640
                        ? const EdgeInsets.fromLTRB(40, 5, 40, 40)
                        : const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Logo
                        SizedBox(
                          height: 300,
                          width: 300,
                          child: Image.asset(
                            logoImage,
                            fit: BoxFit.contain,
                            semanticLabel: 'HelpDesk Logo',
                          ),
                        ),
                        const SizedBox(height: 10), // Reduced spacing

                        // Login Form
                        Form(
                          key: _formSignInKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                label: 'Email',
                                controller: _emailController,
                                validator: (value) => value!.isEmpty
                                    ? "Entrez votre email"
                                    : null,
                                hintColor: textColor.withOpacity(0.8),
                                textColor: textColor,
                                backgroundColor: colorScheme.surface,
                                icon: Icons.email,
                              ),
                              _buildTextField(
                                label: 'Password',
                                controller: _passwordController,
                                validator: (value) => value!.isEmpty
                                    ? "Entrez votre mot de passe"
                                    : null,
                                hintColor: textColor.withOpacity(0.8),
                                textColor: textColor,
                                backgroundColor: colorScheme.surface,
                                icon: Icons.lock,
                              ),
                              const SizedBox(height: 20), // Reduced spacing
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      // Handle forgot password
                                    },
                                    child: Text(
                                      'Mot de passe oublié ?',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF3D5CFF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20), // Reduced spacing
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3D5CFF),
                                      Color(0xFF2541CC)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: _handleSignIn,
                                  child: Text(
                                    'Se connecter',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15), // Reduced spacing
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Pas de compte ? ',
                                    style: GoogleFonts.poppins(
                                      color: textColor.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RoleSelectionPage(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'S\'inscrire',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF3D5CFF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Theme Toggle Button in the top-right corner
          Positioned(
            top: 10, // Adjust top position as needed
            right: 10, // Adjust right position as needed
            child: ThemeToggleButton(),
          ),
        ],
      ),
    );
  }
}
