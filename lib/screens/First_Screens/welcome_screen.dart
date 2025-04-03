import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/First_Screens/role_screen.dart';
import 'package:helpdeskfrontend/screens/First_Screens/signin_screen.dart';
import 'package:helpdeskfrontend/theme/theme.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
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
                        const SizedBox(height: 20),

                        // Buttons
                        Padding(
                          padding: MediaQuery.of(context).size.width > 640
                              ? const EdgeInsets.symmetric(horizontal: 40)
                              : const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildButton(
                                  text: 'Sign in',
                                  isPrimary: true,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignInScreen(),
                                      ),
                                    );
                                  },
                                  colorScheme: colorScheme,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildButton(
                                  text: 'Sign up',
                                  isPrimary: false,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RoleSelectionPage(),
                                      ),
                                    );
                                  },
                                  colorScheme: colorScheme,
                                ),
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

  // Button Widget
  Widget _buildButton({
    required String text,
    required bool isPrimary,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? colorScheme.primary : Colors.transparent,
          foregroundColor:
              isPrimary ? colorScheme.onPrimary : colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          elevation: isPrimary ? 6 : 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
