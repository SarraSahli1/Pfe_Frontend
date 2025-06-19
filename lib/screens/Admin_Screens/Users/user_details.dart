import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:helpdeskfrontend/widgets/navbar_admin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

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
  bool _showDetails = true;

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

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF628ff6),
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
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(Future<User> futureUser) {
    return FutureBuilder<User>(
      future: futureUser,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final user = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.email != null || user.secondEmail != null) ...[
              const SizedBox(height: 10),
              _buildDetailItem(
                Icons.email_outlined,
                'Email',
                user.email ?? 'N/A',
              ),
              if (user.secondEmail != null)
                _buildDetailItem(
                  Icons.email_outlined,
                  'Personal',
                  user.secondEmail!,
                ),
              const Divider(height: 30, color: Colors.grey),
            ],
            _buildDetailItem(
              Icons.phone_outlined,
              'Phone',
              user.phoneNumber ?? 'N/A',
            ),
            const Divider(height: 30, color: Colors.grey),
            if (user.authority == 'technician') ...[
              _buildDetailItem(
                Icons.drive_eta_outlined,
                'Driver\'s License',
                user.permisConduire ? 'Yes' : 'No',
              ),
              const Divider(height: 30, color: Colors.grey),
              _buildDetailItem(
                Icons.airplanemode_active_outlined,
                'Passport',
                user.passeport ? 'Yes' : 'No',
              ),
              const Divider(height: 30, color: Colors.grey),
              _buildDetailItem(
                Icons.cake_outlined,
                'Birth Date',
                _formatDate(user.birthDate),
              ),
              const Divider(height: 30, color: Colors.grey),
              Text(
                'Signature',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              _buildSignatureWidget(_getSignatureUrl(user.signature)),
              const SizedBox(height: 20),
            ],
            if (user.authority == 'client') ...[
              _buildDetailItem(
                Icons.business_outlined,
                'Company',
                user.company ?? 'N/A',
              ),
              const Divider(height: 30, color: Colors.grey),
              _buildDetailItem(
                Icons.info_outlined,
                'About',
                user.about ?? 'N/A',
              ),
              const Divider(height: 30, color: Colors.grey),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEquipmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ElevatedButton(
            onPressed: () {
              _showAssignEquipmentDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF628ff6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Assign Equipment',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _isLoadingUserEquipment
            ? const Center(child: CircularProgressIndicator())
            : _userEquipmentError != null
                ? Text(
                    'Error: $_userEquipmentError',
                    style: const TextStyle(color: Colors.red),
                  )
                : _userEquipment.isEmpty
                    ? Text(
                        'No equipment assigned',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _userEquipment.length,
                        itemBuilder: (context, index) {
                          final equipment = _userEquipment[index];
                          return ListTile(
                            leading: Icon(
                              Icons.devices_other,
                              size: 24,
                              color: const Color(0xFF628ff6),
                            ),
                            title: Text(
                              equipment['designation'] ?? 'No designation',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              equipment['serialNumber'] ?? 'No serial number',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        },
                      ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'User Details',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF628ff6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Blue Top Section
          Container(
            color: const Color(0xFF628ff6),
            width: double.infinity,
            child: FutureBuilder<User>(
              future: _futureUser,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return Center(
                    child: Text(
                      'No user data found',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  );
                } else {
                  final user = snapshot.data!;
                  final profileImageUrl = _getImageUrl(user.image) ??
                      'https://placehold.co/200x200/ffffff/628ff6?text=${user.firstName?.substring(0, 1)}${user.lastName?.substring(0, 1)}';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
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
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '${user.firstName ?? "N/A"} ${user.lastName ?? "N/A"}',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user.authority ?? 'N/A',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          // White Bottom Section with Binder Tabs
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Binder Tabs
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFf5f5f5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Details Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showDetails = true),
                            child: Container(
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: _showDetails
                                    ? Colors.white
                                    : const Color(0xFFf5f5f5),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                ),
                                boxShadow: _showDetails
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _showDetails
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'Details',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: _showDetails
                                            ? const Color(0xFF628ff6)
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Equipment Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showDetails = false),
                            child: Container(
                              margin: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color: !_showDetails
                                    ? Colors.white
                                    : const Color(0xFFf5f5f5),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(20),
                                ),
                                boxShadow: !_showDetails
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: !_showDetails
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'Equipment',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: !_showDetails
                                            ? const Color(0xFF628ff6)
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content Area (Page)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _showDetails
                            ? _buildDetailsSection(
                                Future.value(_futureUser).then((user) => user))
                            : _buildEquipmentSection(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavbarAdmin(currentIndex: 2, context: context),
    );
  }
}
