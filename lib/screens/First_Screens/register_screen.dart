import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/First_Screens/RegisterPage1%20.dart';
import 'package:helpdeskfrontend/screens/First_Screens/RegisterPage2%20.dart';
import 'package:helpdeskfrontend/screens/First_Screens/welcome_screen.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic> _commonData = {}; // Données communes de la page 1
  Map<String, dynamic> _roleSpecificData =
      {}; // Données spécifiques au rôle de la page 2

  void _navigateToPage2(Map<String, dynamic> commonData) {
    setState(() {
      _commonData = commonData; // Sauvegarder les données communes
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage2(
          role: widget.role,
          onRegister: (roleSpecificData) {
            setState(() {
              _roleSpecificData =
                  roleSpecificData; // Sauvegarder les données spécifiques
            });
            _registerUser(); // Appeler l'inscription complète
          },
          commonData: _commonData, // Transmettre les données communes
        ),
      ),
    );
  }

  void _registerUser() async {
    try {
      // Vérifier que les données obligatoires sont présentes
      if (_commonData['email'] == null || _commonData['password'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email and password are required")),
        );
        return;
      }

      // Combiner les données communes et spécifiques
      final fullData = {
        ..._commonData,
        ..._roleSpecificData,
      };

      // Log des données pour le débogage
      print("Common Data: $_commonData");
      print("Role Specific Data: $_roleSpecificData");
      print("Full Data: $fullData");

      // Appeler le service d'inscription
      var response = await _authService.registerUser(
        firstName: fullData['firstName'],
        lastName: fullData['lastName'],
        email: fullData['email'],
        secondEmail: fullData['secondEmail'],
        password: fullData['password'],
        authority:
            widget.role.toLowerCase() == "technicien" ? "technician" : "client",
        phoneNumber: fullData['phoneNumber'],
        permisConduire: fullData['permisConduire'] ?? false,
        passeport: fullData['passeport'] ?? false,
        expiredAt: fullData['expiredAt'],
        birthDate: fullData['birthDate'],
        signature: fullData['signature'],
        image: fullData['image'], // Inclure l'image de profil
        about: fullData['about'],
        company: fullData['company'],
      );

      // Afficher un message à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'])),
      );

      // Si l'inscription est réussie, naviguer vers WelcomePage
      if (response['success']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(),
          ),
        );
      }
    } catch (e) {
      // Gérer les erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RegisterPage1(
      role: widget.role,
      onNext:
          _navigateToPage2, // Passer à la page 2 après avoir collecté les données communes
    );
  }
}
