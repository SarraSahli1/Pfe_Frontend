import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Définition des couleurs personnalisées
class CustomColors extends ThemeExtension<CustomColors> {
  final Color userListBackground;
  final Color userCardBackground;
  final Color userCardText;
  final Color userCardSecondaryText;

  const CustomColors({
    required this.userListBackground,
    required this.userCardBackground,
    required this.userCardText,
    required this.userCardSecondaryText,
  });

  @override
  ThemeExtension<CustomColors> copyWith({
    Color? userListBackground,
    Color? userCardBackground,
    Color? userCardText,
    Color? userCardSecondaryText,
  }) {
    return CustomColors(
      userListBackground: userListBackground ?? this.userListBackground,
      userCardBackground: userCardBackground ?? this.userCardBackground,
      userCardText: userCardText ?? this.userCardText,
      userCardSecondaryText:
          userCardSecondaryText ?? this.userCardSecondaryText,
    );
  }

  @override
  ThemeExtension<CustomColors> lerp(
      ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      userListBackground:
          Color.lerp(userListBackground, other.userListBackground, t)!,
      userCardBackground:
          Color.lerp(userCardBackground, other.userCardBackground, t)!,
      userCardText: Color.lerp(userCardText, other.userCardText, t)!,
      userCardSecondaryText:
          Color.lerp(userCardSecondaryText, other.userCardSecondaryText, t)!,
    );
  }
}

// Définition du ColorScheme pour le mode clair
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF416FDF),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF6EAEE7),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  background: Color(0xFFFCFDF6),
  onBackground: Color(0xFF1A1C18),
  shadow: Color(0xFF000000),
  outlineVariant: Color(0xFFC2C8BC),
  surface: Color(0xFFF9FAF3),
  onSurface: Color(0xFF1A1C18),
);

// Définition du ColorScheme pour le mode sombre
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF416FDF),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF6EAEE7),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  background: Color(0xFF242E3E),
  onBackground: Color(0xFFF4F3FD),
  shadow: Color(0xFF000000),
  outlineVariant: Color(0xFFC2C8BC),
  surface: Color(0xFF2A3447),
  onSurface: Color(0xFFF4F3FD),
);

// Thème pour le mode clair
final lightMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: lightColorScheme,
  textTheme: GoogleFonts.poppinsTextTheme(
    // Intégration de Poppins
    ThemeData.light().textTheme,
  ),
  extensions: <ThemeExtension<dynamic>>[
    CustomColors(
      userListBackground: const Color(0xFFFCFDF6),
      userCardBackground: const Color(0xFFFFFFFF),
      userCardText: const Color(0xFF1A1C18),
      userCardSecondaryText: const Color(0xFF6C6C6C),
    ),
  ],
);

// Thème pour le mode sombre
final darkMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,
  textTheme: GoogleFonts.poppinsTextTheme(
    // Intégration de Poppins
    ThemeData.light().textTheme,
  ),
  extensions: <ThemeExtension<dynamic>>[
    CustomColors(
      userListBackground: const Color(0xFF242E3E),
      userCardBackground: const Color(0xFF2A3447),
      userCardText: const Color(0xFFF4F3FD),
      userCardSecondaryText: const Color(0xFFB8B8D2),
    ),
  ],
);
