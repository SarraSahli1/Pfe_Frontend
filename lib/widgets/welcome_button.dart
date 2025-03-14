import 'package:flutter/material.dart';

class WelcomeButton extends StatelessWidget {
  const WelcomeButton({
    super.key,
    required this.buttonText,
    required this.onTap,
    this.color = Colors.blue, // Default color
    this.textColor = Colors.white, // Default text color
  });

  final String buttonText; // Required parameter
  final VoidCallback onTap; // Use VoidCallback instead of Widget
  final Color color; // Optional with default value
  final Color textColor; // Optional with default value

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Use the provided onTap callback
      child: Container(
        padding: const EdgeInsets.all(30.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
          ),
        ),
        child: Text(
          buttonText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
