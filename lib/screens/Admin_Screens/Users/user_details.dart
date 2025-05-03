import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserDetailsScreen extends StatefulWidget {
  final String userId;

  const UserDetailsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final UserService _userService = UserService();
  final EquipmentService _equipmentService = EquipmentService();
  late Future<User> _futureUser;
  List<dynamic> _unassignedEquipment = [];
  List<dynamic> _userEquipment = [];
  bool _isLoadingEquipment = false;
  bool _isLoadingUserEquipment = false;
  String? _equipmentError;
  String? _userEquipmentError;

  @override
  void initState() {
    super.initState();
    _futureUser = _userService.getUserById(widget.userId);
    _loadUserEquipment();
  }

  Future<void> _loadUnassignedEquipment() async {
    setState(() {
      _isLoadingEquipment = true;
      _equipmentError = null;
    });
    try {
      final equipment = await _equipmentService.getUnassignedEquipment();
      setState(() {
        _unassignedEquipment = equipment;
        _isLoadingEquipment = false;
      });
    } catch (e) {
      setState(() {
        _equipmentError = e.toString();
        _isLoadingEquipment = false;
      });
    }
  }

  Future<void> _loadUserEquipment() async {
    setState(() {
      _isLoadingUserEquipment = true;
      _userEquipmentError = null;
    });
    try {
      final equipment = await _equipmentService.getUserEquipment(widget.userId);
      setState(() {
        _userEquipment = equipment;
        _isLoadingUserEquipment = false;
      });
    } catch (e) {
      setState(() {
        _userEquipmentError = e.toString();
        _isLoadingUserEquipment = false;
      });
    }
  }

  Future<void> _assignEquipment(String equipmentId) async {
    try {
      await _equipmentService.assignEquipmentToUser(equipmentId, widget.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipment assigned successfully!')),
      );
      setState(() {
        _futureUser = _userService.getUserById(widget.userId);
        _unassignedEquipment = [];
        _loadUserEquipment();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign equipment: ${e.toString()}')),
      );
    }
  }

  void _showAssignEquipmentDialog() async {
    await _loadUnassignedEquipment();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Equipment'),
          content: SizedBox(
            width: double.maxFinite,
            child: _isLoadingEquipment
                ? const Center(child: CircularProgressIndicator())
                : _equipmentError != null
                    ? Text('Error: $_equipmentError')
                    : _unassignedEquipment.isEmpty
                        ? const Text('No unassigned equipment available')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _unassignedEquipment.length,
                            itemBuilder: (context, index) {
                              final equipment = _unassignedEquipment[index];
                              return ListTile(
                                title: Text(
                                  equipment['designation'] ?? 'No designation',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _assignEquipment(equipment['_id']);
                                },
                              );
                            },
                          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<Uint8List?> _fetchImageBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _getSignatureUrl(dynamic signature) async {
    if (signature == null) return null;

    if (signature is UserFile) {
      if (signature.path != null) return signature.path;
      if (signature.id != null) {
        try {
          final response = await http.get(
            Uri.parse('${Config.baseUrl}/files/${signature.id}'),
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['err'] == false && data['rows']?['path'] != null) {
              return data['rows']['path'] as String;
            }
          }
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    if (signature is Map<String, dynamic> && signature['path'] != null) {
      return signature['path'] as String;
    }

    if (signature is String && signature.startsWith('http')) {
      return signature;
    }

    if (signature is String) {
      try {
        final response = await http.get(
          Uri.parse('${Config.baseUrl}/files/$signature'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['err'] == false && data['rows']?['path'] != null) {
            return data['rows']['path'] as String;
          }
        }
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  String? _getImageUrl(dynamic image) {
    if (image == null) return null;
    if (image is String) return '${Config.baseUrl}/files/files/$image';
    if (image is UserImage && image.path != null) {
      return image.path!.replaceFirst('http://localhost:3000', Config.baseUrl);
    }
    return null;
  }

  bool _isValidImageData(Uint8List bytes) {
    if (bytes.lengthInBytes < 8) return false;
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) return true;
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;
    return false;
  }

  Widget _buildSignatureWidget(Future<String?> signatureUrlFuture) {
    return FutureBuilder<String?>(
      future: signatureUrlFuture,
      builder: (context, urlSnapshot) {
        if (urlSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }
        if (urlSnapshot.hasError ||
            !urlSnapshot.hasData ||
            urlSnapshot.data == null) {
          return _buildErrorWidget('No signature available');
        }

        final signatureUrl = urlSnapshot.data!;
        return FutureBuilder<Uint8List?>(
          future: _fetchImageBytes(signatureUrl),
          builder: (context, imageSnapshot) {
            if (imageSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            }
            if (imageSnapshot.hasError ||
                !imageSnapshot.hasData ||
                imageSnapshot.data == null) {
              return _buildErrorWidget('Failed to load signature');
            }

            final bytes = imageSnapshot.data!;
            if (!_isValidImageData(bytes)) {
              return _buildErrorWidget('Invalid signature format');
            }

            return Container(
              height: 100,
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Colors.white,
              ),
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorWidget('Display error');
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 100,
      width: 200,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      height: 100,
      width: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 24),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    return date != null
        ? "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}"
        : 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF242E3E) : Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'User Details',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode
            ? Colors.black
            : const Color.fromRGBO(133, 171, 250, 1.0),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: FutureBuilder<User>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: isDarkMode
                    ? Colors.white
                    : const Color.fromRGBO(133, 171, 250, 1.0),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'No user data found',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            );
          } else {
            final user = snapshot.data!;
            final profileImageUrl = _getImageUrl(user.image) ??
                'https://placehold.co/200x200/4299e1/4299e1';

            return Column(
              children: [
                // Profile Header
                Container(
                  height: screenHeight / 4,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1A2232)
                        : const Color.fromRGBO(133, 171, 250, 1.0),
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
                            border: Border.all(width: 0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.network(
                              profileImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person_outline,
                                  size: 60,
                                  color: isDarkMode
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
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Role
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
                // Details Section
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email
                        if (user.email != null || user.secondEmail != null) ...[
                          Text(
                            'Email',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildDetailItem(
                            Icons.email_outlined,
                            'Official',
                            user.email ?? 'N/A',
                            isDarkMode,
                          ),
                          if (user.secondEmail != null)
                            _buildDetailItem(
                              Icons.email_outlined,
                              'Personal',
                              user.secondEmail!,
                              isDarkMode,
                            ),
                          const Divider(height: 30),
                        ],
                        // Phone
                        _buildDetailItem(
                          Icons.phone_outlined,
                          'Phone',
                          user.phoneNumber ?? 'N/A',
                          isDarkMode,
                        ),
                        const Divider(height: 30),
                        // Technician Specific Details
                        if (user.authority == 'technician') ...[
                          _buildDetailItem(
                            Icons.drive_eta_outlined,
                            'Driver\'s License',
                            user.permisConduire ? 'Yes' : 'No',
                            isDarkMode,
                          ),
                          const Divider(height: 30),
                          _buildDetailItem(
                            Icons.airplanemode_active_outlined,
                            'Passport',
                            user.passeport ? 'Yes' : 'No',
                            isDarkMode,
                          ),
                          const Divider(height: 30),
                          _buildDetailItem(
                            Icons.cake_outlined,
                            'Birth Date',
                            _formatDate(user.birthDate),
                            isDarkMode,
                          ),
                          const Divider(height: 30),
                          // Signature
                          Text(
                            'Signature',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildSignatureWidget(
                              _getSignatureUrl(user.signature)),
                          const SizedBox(height: 20),
                        ],
                        // Client Specific Details
                        if (user.authority == 'client') ...[
                          _buildDetailItem(
                            Icons.business_outlined,
                            'Company',
                            user.company ?? 'N/A',
                            isDarkMode,
                          ),
                          const Divider(height: 30),
                          _buildDetailItem(
                            Icons.info_outlined,
                            'About',
                            user.about ?? 'N/A',
                            isDarkMode,
                          ),
                          const Divider(height: 30),
                        ],
                        // Assign Equipment Button
                        ElevatedButton(
                          onPressed: () {
                            _showAssignEquipmentDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDarkMode ? Colors.blue[800] : Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            'Assign Equipment',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // User Equipment List
                        Text(
                          'Assigned Equipment',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _isLoadingUserEquipment
                            ? const Center(child: CircularProgressIndicator())
                            : _userEquipmentError != null
                                ? Text(
                                    'Error: $_userEquipmentError',
                                    style: TextStyle(color: Colors.red),
                                  )
                                : _userEquipment.isEmpty
                                    ? Text(
                                        'No equipment assigned',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _userEquipment.length,
                                        itemBuilder: (context, index) {
                                          final equipment =
                                              _userEquipment[index];
                                          return Card(
                                            elevation: 2,
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            color: isDarkMode
                                                ? const Color(0xFF2D3748)
                                                : Colors.white,
                                            child: ListTile(
                                              title: Text(
                                                equipment['designation'] ??
                                                    'No designation',
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.normal,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                              subtitle: Text(
                                                equipment['serialNumber'] ??
                                                    'No serial number',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                      ],
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

  Widget _buildDetailItem(
      IconData icon, String label, String value, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
