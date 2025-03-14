import 'package:flutter/material.dart';
import 'provider/theme_provider.dart'; // Import your ThemeProvider
import 'screens/welcome_screen.dart'; // Import your WelcomeScreen
import 'package:provider/provider.dart'; // Add this import

void main() {
  runApp(
    // Use ChangeNotifierProvider.value or Provider
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData.light(), // Light theme
      darkTheme: ThemeData.dark(), // Dark theme
      themeMode:
          themeProvider.themeMode, // Use the theme mode from the provider
      home: const WelcomeScreen(),
    );
  }
}
