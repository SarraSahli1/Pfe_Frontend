import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/First_Screens/welcome_screen.dart';
import 'package:helpdeskfrontend/theme/theme.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';

class Firstpage extends StatelessWidget {
  const Firstpage({super.key});

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
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
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
                          const SizedBox(height: 0),

                          // Title
                          Text(
                            'Welcome to HelpDesk',
                            style: TextStyle(
                              color: textColor, // Use the determined text color
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),

                          // Subtitle
                          Text(
                            'Gérez vos tickets de support en toute simplicité',
                            style: TextStyle(
                              color: textColor.withOpacity(
                                  0.8), // Use the determined text color
                              fontSize: 18,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Flèche "Suivant"
                          IconButton(
                            icon: Icon(Icons.arrow_forward,
                                size: 40,
                                color:
                                    textColor), // Use the determined text color
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WelcomeScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Position the ThemeToggleButton higher in the top-right corner
          Positioned(
            top: 10, // Adjust this value to move the button higher or lower
            right: 10, // Adjust this value to move the button left or right
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ThemeToggleButton(),
            ),
          ),
        ],
      ),
    );
  }
}
