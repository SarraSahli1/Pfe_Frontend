import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/screens/admin_users_list.dart';
import 'package:helpdeskfrontend/screens/client_dashboard.dart';
import 'package:helpdeskfrontend/screens/role_screen.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Couleurs dynamiques en fonction du mode
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ThemeToggleButton(), // Bouton de basculement de thème en haut à droite
        ],
      ),
      backgroundColor: backgroundColor, // Fond dynamique
      body: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 200, // Ajoutez une hauteur fixe pour l'image
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                        'https://cdn.builder.io/api/v1/image/assets/TEMP/748240f0ebae1f26d4276f774dca3852e541f07262969600a32d614f27561dd5?placeholderIfAbsent=true'),
                    fit: BoxFit.cover,
                  ),
                ),
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.poppins(
                          color: textColor, // Texte dynamique
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Form(
                key: _formSignInKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Email',
                          style: GoogleFonts.poppins(
                            color: hintColor, // Texte dynamique
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: fieldColor, // Fond dynamique
                            border: Border.all(
                              color: borderColor, // Bordure dynamique
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            style: GoogleFonts.poppins(
                              color: textColor, // Texte dynamique
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre email';
                              }
                              if (!value.contains('@')) {
                                return 'Veuillez entrer un email valide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Password Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password',
                          style: GoogleFonts.poppins(
                            color: hintColor, // Texte dynamique
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: fieldColor, // Fond dynamique
                            border: Border.all(
                              color: borderColor, // Bordure dynamique
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: GoogleFonts.poppins(
                              color: textColor, // Texte dynamique
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre mot de passe';
                              }
                              if (value.length < 6) {
                                return 'Le mot de passe doit contenir au moins 6 caractères';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Remember Me and Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: rememberPassword,
                              onChanged: (bool? value) {
                                setState(() {
                                  rememberPassword = value!;
                                });
                              },
                              activeColor: const Color(0xFF3D5CFF),
                            ),
                            Text(
                              'Se souvenir de moi',
                              style: GoogleFonts.poppins(
                                color: hintColor, // Texte dynamique
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
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
                    const SizedBox(height: 24),

                    // Sign In Button
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3D5CFF), Color(0xFF2541CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: TextButton(
                        onPressed: _handleSignIn,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 70),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
                    const SizedBox(height: 17),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pas de compte ? ',
                          style: GoogleFonts.poppins(
                            color: hintColor, // Texte dynamique
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RoleSelectionPage(),
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
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
