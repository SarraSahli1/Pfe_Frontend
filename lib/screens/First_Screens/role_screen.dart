import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/First_Screens/register_screen.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:helpdeskfrontend/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  void _navigateToRegister(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(role: role),
      ),
    );
  }

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
                            'Select Your Role',
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
                            'Choose your role to continue',
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

                    // Role Cards Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RoleCard(
                          title: 'Technicien',
                          icon: Icons.build,
                          onTap: () =>
                              _navigateToRegister(context, 'Technicien'),
                        ),
                        const SizedBox(width: 20),
                        RoleCard(
                          title: 'Client',
                          icon: Icons.person,
                          onTap: () => _navigateToRegister(context, 'Client'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const RoleCard({
    required this.title,
    required this.icon,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = themeProvider.themeMode == ThemeMode.dark
        ? darkColorScheme
        : lightColorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: colorScheme.surface,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: 140,
          height: 180,
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
