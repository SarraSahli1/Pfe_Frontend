import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;

  const UserDetailsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final UserService _userService = UserService();
  late Future<User> _futureUser;

  @override
  void initState() {
    super.initState();
    _futureUser = _userService.getUserById(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? const Color.fromRGBO(133, 171, 250, 1.0) // Light blue for dark mode
          : Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'User Details',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(133, 171, 250, 1.0), // Light blue
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(), // Theme toggle button
        ],
      ),
      body: FutureBuilder<User>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: themeProvider.themeMode == ThemeMode.dark
                    ? Colors.white
                    : const Color.fromRGBO(133, 171, 250, 1.0), // Light blue
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'No user data found',
                style: TextStyle(
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            );
          } else {
            final user = snapshot.data!;
            final imageUrl = _getImageUrl(user.image);

            return Column(
              children: [
                // Top Card (1/3 of the screen)
                Container(
                  height: screenHeight / 4,
                  decoration: BoxDecoration(
                    color:
                        const Color.fromRGBO(133, 171, 250, 1.0), // Light blue
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profile Image
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 0,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person_outline, // Outlined icon
                                  size: 60,
                                  color:
                                      themeProvider.themeMode == ThemeMode.dark
                                          ? Colors.white
                                          : Colors.grey[600],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Name
                        Text(
                          '${user.firstName ?? "N/A"} ${user.lastName ?? "N/A"}',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Text color changed to white
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Role (moved here, smaller and not bold)
                        Text(
                          user.authority ?? 'N/A',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom Section (2/3 of the screen)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align to the left
                      children: _buildInfoSection(
                        context,
                        user: user,
                        themeProvider: themeProvider,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // Method to build the user info section
  List<Widget> _buildInfoSection(
    BuildContext context, {
    required User user,
    required ThemeProvider themeProvider,
  }) {
    final infoItems = [
      if (user.email != null || user.secondEmail != null)
        {
          'label': 'Email',
          'values': [
            {
              'type': 'Official',
              'value': user.email ?? 'N/A',
              'icon': Icons.email_outlined
            },
            if (user.secondEmail != null)
              {
                'type': 'Personal',
                'value': user.secondEmail!,
                'icon': Icons.email_outlined
              },
          ],
        },
      {
        'label': 'Phone',
        'value': user.phoneNumber ?? 'N/A',
        'icon': Icons.phone_outlined
      },
      if (user.authority == 'technician') ..._buildTechnicianDetails(user),
      if (user.authority == 'client') ..._buildClientDetails(user),
    ];

    return infoItems.map((item) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title (bold)
          Text(
            item['label']!,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeProvider.themeMode == ThemeMode.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          // Handle Email and Secondary Email
          if (item['label'] == 'Email')
            ...(item['values'] as List<Map<String, dynamic>>).map((email) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        email['icon'] as IconData? ??
                            Icons.info_outline, // Outlined icon
                        size: 20,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email['type']!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors
                                  .grey, // Grey for "Official" and "Personal"
                            ),
                          ),
                          Text(
                            email['value']!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? Colors.white // White in dark mode
                                  : Colors.black, // Black in light mode
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }).toList(),
          // Handle other fields
          if (item['label'] != 'Email')
            Row(
              children: [
                Icon(
                  item['icon'] as IconData? ??
                      Icons.info_outline, // Outlined icon
                  size: 20,
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['value']!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white // White in dark mode
                            : Colors.black, // Black in light mode
                      ),
                    ),
                  ],
                ),
              ],
            ),
          // Add a subtle grey horizontal line
          if (item != infoItems.last)
            Divider(
              color: themeProvider.themeMode == ThemeMode.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[300],
              thickness: 1,
              height: 30,
            ),
        ],
      );
    }).toList();
  }

  // Method to build technician-specific details
  List<Map<String, dynamic>> _buildTechnicianDetails(User user) {
    return [
      {
        'label': 'Driver\'s License',
        'value': user.permisConduire ? 'Yes' : 'No',
        'icon': Icons.drive_eta_outlined
      },
      {
        'label': 'Passport',
        'value': user.passeport ? 'Yes' : 'No',
        'icon': Icons.airplanemode_active_outlined
      },
      {
        'label': 'Birth Date',
        'value': _formatDate(user.birthDate),
        'icon': Icons.cake_outlined
      },
      {
        'label': 'Signature',
        'value': user.signature ?? 'N/A',
        'icon': Icons.brush_outlined
      },
    ];
  }

  // Method to build client-specific details
  List<Map<String, dynamic>> _buildClientDetails(User user) {
    return [
      {
        'label': 'Company',
        'value': user.company ?? 'N/A',
        'icon': Icons.business_outlined
      },
      {
        'label': 'About',
        'value': user.about ?? 'N/A',
        'icon': Icons.info_outlined
      },
      {
        'label': 'Folder ID',
        'value': user.folderId ?? 'N/A',
        'icon': Icons.folder_outlined
      },
    ];
  }

  // Method to format dates
  String _formatDate(DateTime? date) {
    return date != null ? date.toLocal().toString() : 'N/A';
  }

  // Method to get the image URL
  String _getImageUrl(UserImage? image) {
    if (image == null || image.path == null) {
      return 'https://placehold.co/200x200/4299e1/4299e1'; // Fallback URL
    }
    return image.path!.replaceFirst(
      'http://localhost:3000',
      'http://192.168.1.16:3000',
    );
  }
}
