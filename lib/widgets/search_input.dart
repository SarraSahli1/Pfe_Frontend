import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/theme/theme.dart';

class SearchInput extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final TextEditingController? controller;

  const SearchInput({
    Key? key,
    this.onChanged,
    this.placeholder = 'Find User',
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 640;

    // Récupérer les couleurs personnalisées du thème
    final customColors = Theme.of(context).extension<CustomColors>();

    return Container(
      width: isSmallScreen ? double.infinity : 335,
      height: isSmallScreen ? 40 : 48,
      constraints: const BoxConstraints(maxWidth: 335),
      decoration: BoxDecoration(
        color: customColors?.userCardBackground ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: customColors?.userCardSecondaryText ??
                Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: customColors?.userCardText ??
                    Theme.of(context).colorScheme.onSurface,
                fontSize: isSmallScreen ? 13 : 14,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: customColors?.userCardSecondaryText ??
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: isSmallScreen ? 13 : 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
