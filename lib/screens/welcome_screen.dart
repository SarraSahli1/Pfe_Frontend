import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/role_screen.dart';
import 'package:helpdeskfrontend/screens/signin_screen.dart';
import 'package:helpdeskfrontend/theme/theme.dart';
import 'package:helpdeskfrontend/widgets/custom_scaffold.dart';
import 'package:helpdeskfrontend/widgets/welcome_button.dart';
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

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ThemeToggleButton(), // Bouton de basculement de thème en haut à droite
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 375),
              child: Padding(
                padding: MediaQuery.of(context).size.width > 640
                    ? const EdgeInsets.all(20)
                    : const EdgeInsets.all(15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration Section
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 20,
                            top: 60,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 20,
                            top: 70,
                            child: Container(
                              width: 100,
                              height: 60,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Text Content Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            'Welcome Back!',
                            style: TextStyle(
                              color: colorScheme.onBackground,
                              fontSize: MediaQuery.of(context).size.width > 991
                                  ? 24
                                  : MediaQuery.of(context).size.width > 640
                                      ? 22
                                      : 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Enter personal details to your employee account',
                            style: TextStyle(
                              color: colorScheme.onBackground.withOpacity(0.8),
                              fontSize: MediaQuery.of(context).size.width > 991
                                  ? 16
                                  : MediaQuery.of(context).size.width > 640
                                      ? 16
                                      : 14,
                              fontFamily: 'Poppins',
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Dots Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(colorScheme),
                        const SizedBox(width: 12),
                        _buildDot(colorScheme),
                        const SizedBox(width: 12),
                        _buildDot(colorScheme),
                      ],
                    ),
                    const SizedBox(height: 60),

                    // Buttons Section
                    Padding(
                      padding: MediaQuery.of(context).size.width > 640
                          ? const EdgeInsets.symmetric(horizontal: 20)
                          : const EdgeInsets.symmetric(horizontal: 10),
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
                                    builder: (context) => const SignInScreen(),
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
    );
  }

  Widget _buildDot(ColorScheme colorScheme) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.onBackground.withOpacity(0.5),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required bool isPrimary,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      height: 50,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor:
              isPrimary ? colorScheme.primary : colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(
                    color: colorScheme.primary,
                    width: 0.5,
                  ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isPrimary ? colorScheme.onPrimary : colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
