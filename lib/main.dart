import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/First_Screens/firstpage.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/provider/notification_provider.dart';
import 'package:helpdeskfrontend/screens/First_Screens/signin_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Builder to access providers below MaterialApp
    return Builder(
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'HelpDesk App',
          theme: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              secondary: Colors.blueAccent,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blueGrey,
              secondary: Colors.blueAccent,
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const Firstpage(),
          // Add route management if needed
          routes: {
            '/firstpage': (context) => const Firstpage(),
            '/login': (context) => const SignInScreen(), // Your login screen
          },
        );
      },
    );
  }
}
