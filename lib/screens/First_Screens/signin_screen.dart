import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Dashboard/admin_dashboard.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Dashboard/client_dashboard.dart';
import 'package:helpdeskfrontend/screens/First_Screens/forgot_password_screen.dart';
import 'package:helpdeskfrontend/screens/First_Screens/role_screen.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/tech_dashboard.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/services/socket_service.dart';
import 'package:helpdeskfrontend/theme/theme.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/provider/notification_provider.dart';

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
  final SocketService _socketService = SocketService();
  late NotificationProvider _notificationProvider;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _isMounted = false;
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formSignInKey.currentState!.validate() || !rememberPassword) {
      if (!rememberPassword && _isMounted) {
        _showError('Veuillez accepter le traitement des données personnelles');
      }
      return;
    }

    try {
      final result = await _authService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!_isMounted) return;

      if (!result['success']) {
        _showError(result['message'] ?? 'Échec de la connexion');
        return;
      }

      final payload = result['payload'];
      final accessToken = result['accessToken'];

      if (payload == null || payload['user'] == null || accessToken == null) {
        _showError('Erreur: Données utilisateur ou token manquants');
        return;
      }

      final user = payload['user'];
      final String? userId = user['_id']?.toString();
      final String? token = accessToken?.toString();
      final String? userAuthority = user['authority']?.toString();

      if (userId == null || token == null || userAuthority == null) {
        _showError('Erreur: Informations utilisateur incomplètes');
        return;
      }

      print('SignInScreen: Initializing SocketService for user $userId');
      _socketService.initialize(
        userId: userId,
        onNotification: _notificationProvider.addNotification,
      );
      _socketService.connect(token);

      _socketService.onConnectionStatus = (isConnected) {
        if (_isMounted && !isConnected) {
          _showError('Échec de la connexion au serveur de chat');
        }
      };

      _navigateToDashboard(userAuthority);
    } catch (e) {
      if (_isMounted) {
        _showError('Une erreur est survenue: ${e.toString()}');
      }
    }
  }

  void _navigateToDashboard(String authority) {
    if (!_isMounted) return;

    Widget destination;
    switch (authority) {
      case 'admin':
        destination = const DashboardAdmin();
        break;
      case 'client':
        destination = const ClientDashboard();
        break;
      case 'technician':
        destination = const TechnicianDashboard();
        break;
      default:
        _showError('Rôle utilisateur non reconnu');
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  void _showError(String message, {bool isSuccess = false}) {
    if (!_isMounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
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

    final backgroundImage = themeProvider.themeMode == ThemeMode.dark
        ? 'assets/images/bg_dark.png'
        : 'assets/images/bg_light.png';

    final logoImage = themeProvider.themeMode == ThemeMode.dark
        ? 'assets/images/opmlogo.png'
        : 'assets/images/logoopm_light.png';

    final textColor = themeProvider.themeMode == ThemeMode.dark
        ? colorScheme.onPrimary
        : Colors.black;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
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
                        SizedBox(
                          height: 300,
                          width: 300,
                          child: Image.asset(
                            logoImage,
                            fit: BoxFit.contain,
                            semanticLabel: 'HelpDesk Logo',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Form(
                          key: _formSignInKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                label: 'Email',
                                controller: _emailController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Entrez votre email';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                                hintColor: textColor.withOpacity(0.8),
                                textColor: textColor,
                                backgroundColor: colorScheme.surface,
                                icon: Icons.email,
                              ),
                              _buildTextField(
                                label: 'Mot de passe',
                                controller: _passwordController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Entrez votre mot de passe';
                                  }
                                  if (value.length < 6) {
                                    return 'Le mot de passe doit contenir au moins 6 caractères';
                                  }
                                  return null;
                                },
                                hintColor: textColor.withOpacity(0.8),
                                textColor: textColor,
                                backgroundColor: colorScheme.surface,
                                icon: Icons.lock,
                                obscureText: true,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPasswordScreen(),
                                        ),
                                      );
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
                              const SizedBox(height: 20),
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
                              const SizedBox(height: 15),
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
          const Positioned(
            top: 10,
            right: 10,
            child: ThemeToggleButton(),
          ),
        ],
      ),
    );
  }
}
