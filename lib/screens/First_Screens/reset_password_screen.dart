import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email; // Email passé depuis ForgotPasswordScreen
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email; // Pré-remplir l'email
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _passwordController.text.trim();

    try {
      final result = await _authService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success']
              ? 'Mot de passe réinitialisé avec succès !'
              : result['message'] ?? 'Erreur inconnue'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        // Naviguer vers SignInScreen après succès
        Navigator.pushReplacementNamed(context, '/sign-in');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur réseau : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    bool obscureText = false,
    VoidCallback? onSuffixTap,
    IconData? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              validator: validator,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: hintColor),
                suffixIcon: suffixIcon != null
                    ? IconButton(
                        icon: Icon(suffixIcon, color: hintColor),
                        onPressed: onSuffixTap,
                      )
                    : null,
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

    final textColor = themeProvider.themeMode == ThemeMode.dark
        ? colorScheme.onPrimary
        : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réinitialiser le mot de passe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Entrez le code reçu par email et votre nouveau mot de passe',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Email invalide';
                  }
                  return null;
                },
                icon: Icons.email,
                hintColor: textColor.withOpacity(0.8),
                textColor: textColor,
                backgroundColor: colorScheme.surface,
              ),
              _buildTextField(
                label: 'Code de vérification',
                controller: _codeController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le code';
                  }
                  if (value.length != 6 ||
                      !RegExp(r'^\d{6}$').hasMatch(value)) {
                    return 'Le code doit être 6 chiffres';
                  }
                  return null;
                },
                icon: Icons.vpn_key,
                hintColor: textColor.withOpacity(0.8),
                textColor: textColor,
                backgroundColor: colorScheme.surface,
              ),
              _buildTextField(
                label: 'Nouveau mot de passe',
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
                icon: Icons.lock,
                hintColor: textColor.withOpacity(0.8),
                textColor: textColor,
                backgroundColor: colorScheme.surface,
                obscureText: _obscurePassword,
                suffixIcon:
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                onSuffixTap: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              const SizedBox(height: 20),
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
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Réinitialiser',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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
}
