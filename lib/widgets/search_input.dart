import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';

class SearchInput extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final TextEditingController? controller;

  const SearchInput({
    Key? key,
    this.onChanged,
    this.placeholder = 'Search equipment...',
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              fontFamily: 'Poppins',
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDarkMode ? Colors.white : Colors.grey[600],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 15.0,
            ),
          ),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
