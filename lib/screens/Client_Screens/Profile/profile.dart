import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Profile/ChangePassword.dart';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
import 'package:helpdeskfrontend/widgets/logout_button.dart';
import 'package:helpdeskfrontend/widgets/navbar_client.dart';
import 'package:helpdeskfrontend/widgets/navbar_technicien.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  late Future<User> _futureUser;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _secondEmailController;
  late TextEditingController _aboutController;
  late TextEditingController _companyController;

  @override
  void initState() {
    super.initState();
    _futureUser = _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _secondEmailController.dispose();
    _aboutController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<User> _loadUserData() async {
    debugPrint('Starting to load user data...');
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final token = await _authService.getToken();

    debugPrint('Token: $token');
    debugPrint('Cached user_data: $userDataString');

    if (userDataString != null) {
      try {
        final userData = jsonDecode(userDataString);
        debugPrint('Parsed cached user_data: ${jsonEncode(userData)}');
        if (userData['firstName'] != null && userData['lastName'] != null) {
          final user = User.fromMap(userData);
          debugPrint('Loaded user from SharedPreferences: ${user.toMap()}');
          _initializeControllers(user);
          return user;
        } else {
          debugPrint('Invalid cached user data, clearing SharedPreferences');
          await prefs.remove('user_data');
        }
      } catch (e) {
        debugPrint('Error parsing user data from SharedPreferences: $e');
        await prefs.remove('user_data');
      }
    }

    if (token == null) {
      throw Exception('No token available');
    }
    final user = await _userService.getProfile();
    debugPrint('Fetched user from backend: ${user.toMap()}');
    await prefs.setString('user_data', jsonEncode(user.toMap()));
    _initializeControllers(user);
    return user;
  }

  void _initializeControllers(User user) {
    _firstNameController = TextEditingController(text: user.firstName ?? '');
    _lastNameController = TextEditingController(text: user.lastName ?? '');
    _emailController = TextEditingController(text: user.email ?? '');
    _phoneController = TextEditingController(text: user.phoneNumber ?? '');
    _secondEmailController =
        TextEditingController(text: user.secondEmail ?? '');
    _aboutController = TextEditingController(text: user.about ?? '');
    _companyController = TextEditingController(text: user.company ?? '');
  }

  Future<void> _toggleEdit() async {
    if (_isEditing && _formKey.currentState!.validate()) {
      try {
        final updatedData = {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'email': _emailController.text,
          'phoneNumber': _phoneController.text,
          'secondEmail': _secondEmailController.text,
          'about': _aboutController.text,
          'company': _companyController.text,
        };

        final userId = await _authService.getCurrentUserId();
        final token = await _authService.getToken();
        if (userId == null || token == null) {
          throw Exception('User ID or token missing');
        }

        final response = await http.put(
          Uri.parse('${Config.baseUrl}/user/updateUser/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(updatedData),
        );

        debugPrint('Update response status: ${response.statusCode}');
        debugPrint('Update response body: ${response.body}');

        if (response.statusCode == 200) {
          final updatedUser = await _userService.getProfile();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(updatedUser.toMap()));

          setState(() {
            _futureUser = Future.value(updatedUser);
            _initializeControllers(updatedUser);
            _isEditing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        } else {
          throw Exception('Failed to update user: ${response.body}');
        }
      } catch (e) {
        debugPrint('Error updating user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } else {
      setState(() => _isEditing = !_isEditing);
    }
  }

  Future<Uint8List?> _fetchImageBytes(String url) async {
    debugPrint('Profile: Fetching image from URL: $url');
    try {
      final response = await http.get(Uri.parse(url));
      debugPrint(
          'Profile: Image fetch response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        debugPrint(
            'Profile: Image bytes received, length: ${response.bodyBytes.length}');
        return response.bodyBytes;
      } else {
        debugPrint(
            'Profile: Image fetch failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Profile: Error fetching image: $e');
      return null;
    }
  }

  Future<String?> _getImageUrl(dynamic image) async {
    debugPrint('Profile: Processing image: $image');
    if (image == null) {
      debugPrint('Profile: Image is null');
      return null;
    }

    if (image is UserImage && image.path != null) {
      debugPrint('Profile: Image is a UserImage with path: ${image.path}');
      return image.path!.replaceFirst('http://localhost:3000', Config.baseUrl);
    }

    if (image is Map<String, dynamic>) {
      debugPrint('Profile: Image is a Map: ${image.toString()}');
      if (image['path'] != null) {
        final path = image['path'] as String;
        debugPrint('Profile: Found path in Map: $path');
        return path.replaceFirst('http://192.168.1.16:3000', Config.baseUrl);
      }
      if (image['_id'] != null) {
        debugPrint('Profile: Found _id in Map: ${image['_id']}');
        try {
          final response = await http.get(
            Uri.parse('${Config.baseUrl}/files/${image['_id']}'),
          );
          debugPrint(
              'Profile: Metadata fetch response status: ${response.statusCode}');
          debugPrint('Profile: Metadata fetch response body: ${response.body}');
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['err'] == false &&
                data['rows'] != null &&
                data['rows']['path'] != null) {
              final path = data['rows']['path'] as String;
              debugPrint('Profile: Extracted image path: $path');
              return path.replaceFirst(
                  'http://192.168.1.16:3000', Config.baseUrl);
            } else {
              debugPrint(
                  'Profile: Invalid metadata response: ${response.body}');
              return null;
            }
          } else {
            debugPrint(
                'Profile: Metadata fetch failed with status: ${response.statusCode}');
            return null;
          }
        } catch (e) {
          debugPrint('Profile: Error fetching image metadata: $e');
          return null;
        }
      }
    }

    if (image is String) {
      debugPrint('Profile: Image is a string: $image');
      if (image.startsWith('http')) {
        debugPrint('Profile: Image is a direct URL: $image');
        return image.replaceFirst('http://192.168.1.16:3000', Config.baseUrl);
      } else {
        debugPrint('Profile: Image is an ObjectId or file name: $image');
        return '${Config.baseUrl}/files/files/$image';
      }
    }

    debugPrint('Profile: Unsupported image format: ${image.runtimeType}');
    return null;
  }

  bool _isValidImageData(Uint8List bytes) {
    debugPrint(
        'Profile: Validating image data, length: ${bytes.lengthInBytes}');
    if (bytes.lengthInBytes < 8) {
      debugPrint('Profile: Image data too short: ${bytes.lengthInBytes} bytes');
      return false;
    }

    // Check for PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      debugPrint('Profile: Image is valid PNG');
      return true;
    }
    // Check for JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      debugPrint('Profile: Image is valid JPEG');
      return true;
    }
    // Check for GIF
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      debugPrint('Profile: Image is valid GIF');
      return true;
    }
    debugPrint('Profile: Image format not valid (not PNG, JPEG, or GIF)');
    return false;
  }

  Future<String?> _getSignatureUrl(dynamic signature) async {
    debugPrint('Profile: Processing signature: $signature');
    if (signature == null) {
      debugPrint('Profile: Signature is null');
      return null;
    }

    if (signature is UserFile) {
      debugPrint('Profile: Signature is a UserFile');
      if (signature.path != null) {
        debugPrint('Profile: UserFile has path: ${signature.path}');
        return signature.path;
      } else if (signature.id != null) {
        debugPrint('Profile: UserFile has no path, using id: ${signature.id}');
        try {
          final response = await http.get(
            Uri.parse('${Config.baseUrl}/files/${signature.id}'),
          );
          debugPrint(
              'Profile: Metadata fetch response status: ${response.statusCode}');
          debugPrint('Profile: Metadata fetch response body: ${response.body}');
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['err'] == false &&
                data['rows'] != null &&
                data['rows']['path'] != null) {
              final path = data['rows']['path'] as String;
              debugPrint('Profile: Extracted signature path: $path');
              return path;
            } else {
              debugPrint(
                  'Profile: Invalid metadata response: ${response.body}');
              return null;
            }
          } else {
            debugPrint(
                'Profile: Metadata fetch failed with status: ${response.statusCode}');
            return null;
          }
        } catch (e) {
          debugPrint('Profile: Error fetching signature metadata: $e');
          return null;
        }
      }
      debugPrint('Profile: UserFile has no path or id');
      return null;
    }

    if (signature is Map<String, dynamic> && signature['path'] != null) {
      debugPrint('Profile: Signature is a Map with path: ${signature['path']}');
      return signature['path'] as String;
    }

    if (signature is String && signature.startsWith('http')) {
      debugPrint('Profile: Signature is a direct URL: $signature');
      return signature;
    }

    if (signature is String) {
      debugPrint(
          'Profile: Signature is an ObjectId, fetching metadata: $signature');
      try {
        final response = await http.get(
          Uri.parse('${Config.baseUrl}/files/$signature'),
        );
        debugPrint(
            'Profile: Metadata fetch response status: ${response.statusCode}');
        debugPrint('Profile: Metadata fetch response body: ${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['err'] == false &&
              data['rows'] != null &&
              data['rows']['path'] != null) {
            final path = data['rows']['path'] as String;
            debugPrint('Profile: Extracted signature path: $path');
            return path;
          } else {
            debugPrint('Profile: Invalid metadata response: ${response.body}');
            return null;
          }
        } else {
          debugPrint(
              'Profile: Metadata fetch failed with status: ${response.statusCode}');
          return null;
        }
      } catch (e) {
        debugPrint('Profile: Error fetching signature metadata: $e');
        return null;
      }
    }

    debugPrint('Profile: Signature format not recognized');
    return null;
  }

  Widget _buildSignatureWidget(Future<String?> signatureUrlFuture) {
    debugPrint('Profile: Building signature widget');
    return FutureBuilder<String?>(
      future: signatureUrlFuture,
      builder: (context, urlSnapshot) {
        debugPrint(
            'Profile: URL FutureBuilder state: ${urlSnapshot.connectionState}');
        if (urlSnapshot.connectionState == ConnectionState.waiting) {
          debugPrint('Profile: Waiting for signature URL');
          return _buildLoadingWidget();
        }

        if (urlSnapshot.hasError) {
          debugPrint('Profile: Error in signature URL: ${urlSnapshot.error}');
          return _buildErrorWidget('Failed to load signature URL');
        }

        if (!urlSnapshot.hasData || urlSnapshot.data == null) {
          debugPrint('Profile: No signature URL data');
          return _buildErrorWidget('No signature URL available');
        }

        final signatureUrl = urlSnapshot.data!;
        debugPrint('Profile: Signature URL resolved: $signatureUrl');
        return FutureBuilder<Uint8List?>(
          future: _fetchImageBytes(signatureUrl),
          builder: (context, imageSnapshot) {
            debugPrint(
                'Profile: Image FutureBuilder state: ${imageSnapshot.connectionState}');
            if (imageSnapshot.connectionState == ConnectionState.waiting) {
              debugPrint('Profile: Waiting for image bytes');
              return _buildLoadingWidget();
            }

            if (imageSnapshot.hasError) {
              debugPrint(
                  'Profile: Error fetching image: ${imageSnapshot.error}');
              return _buildErrorWidget('Failed to load signature');
            }

            if (!imageSnapshot.hasData || imageSnapshot.data == null) {
              debugPrint('Profile: No image data received');
              return _buildErrorWidget('Failed to load signature');
            }

            final bytes = imageSnapshot.data!;
            debugPrint(
                'Profile: Image bytes received, length: ${bytes.length}');
            if (!_isValidImageData(bytes)) {
              debugPrint('Profile: Invalid image data');
              return _buildErrorWidget('Invalid signature format');
            }

            debugPrint('Profile: Rendering signature image');
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
                  debugPrint('Profile: Image display error: $error');
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
    debugPrint('Profile: Rendering loading widget');
    return Container(
      height: 100,
      width: 200,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildErrorWidget(String message) {
    debugPrint('Profile: Rendering error widget: $message');
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

  Widget _buildProfileImage(Future<String?> imageUrlFuture) {
    debugPrint('Profile: Building profile image widget');
    return FutureBuilder<String?>(
      future: imageUrlFuture,
      builder: (context, urlSnapshot) {
        debugPrint(
            'Profile: URL FutureBuilder state: ${urlSnapshot.connectionState}');
        if (urlSnapshot.connectionState == ConnectionState.waiting) {
          debugPrint('Profile: Waiting for image URL');
          return _buildLoadingWidget();
        }

        if (urlSnapshot.hasError) {
          debugPrint('Profile: Error in image URL: ${urlSnapshot.error}');
          return _buildProfileErrorWidget();
        }

        if (!urlSnapshot.hasData || urlSnapshot.data == null) {
          debugPrint('Profile: No image URL data');
          return _buildErrorWidget('Failed to load profile image');
        }

        final imageUrl = urlSnapshot.data!;
        debugPrint('Profile: Image URL resolved: $imageUrl');
        return FutureBuilder<Uint8List?>(
          future: _fetchImageBytes(imageUrl),
          builder: (context, imageSnapshot) {
            debugPrint(
                'Profile: Image FutureBuilder state: ${imageSnapshot.connectionState}');
            if (imageSnapshot.connectionState == ConnectionState.waiting) {
              debugPrint('Profile: Waiting for image bytes');
              return _buildLoadingWidget();
            }

            if (imageSnapshot.hasError) {
              debugPrint(
                  'Profile: Error fetching image: ${imageSnapshot.error}');
              return _buildErrorWidget('Failed to load profile image');
            }

            if (!imageSnapshot.hasData || imageSnapshot.data == null) {
              debugPrint('Profile: No image data received');
              return _buildErrorWidget('Failed to load profile image');
            }

            final bytes = imageSnapshot.data!;
            debugPrint(
                'Profile: Image bytes received, length: ${bytes.length}');
            if (!_isValidImageData(bytes)) {
              debugPrint('Profile: Invalid image data');
              return _buildErrorWidget('Invalid profile image format');
            }

            debugPrint('Profile: Rendering profile image');
            return Container(
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
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Profile: Image display error: $error');
                    return _buildErrorWidget('Failed to display profile image');
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileErrorWidget() {
    debugPrint('Profile: Rendering error widget');
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200],
      ),
      child: const Icon(
        Icons.person_outline,
        size: 60,
        color: Colors.grey,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    return date != null
        ? "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}"
        : 'N/A';
  }

  Widget _buildUserInfo(User user) {
    if (_isEditing) {
      return Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
              validator: (value) => value!.isEmpty ? 'Required field' : null,
            ),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
              validator: (value) => value!.isEmpty ? 'Required field' : null,
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => value!.isEmpty || !value.contains('@')
                  ? 'Invalid email'
                  : null,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            if (user.authority == 'technician') ...[
              TextFormField(
                controller: _secondEmailController,
                decoration: const InputDecoration(labelText: 'Secondary Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
            if (user.authority == 'client') ...[
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Company'),
              ),
              TextFormField(
                controller: _aboutController,
                decoration: const InputDecoration(labelText: 'About'),
                maxLines: 3,
              ),
            ],
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.email != null || user.secondEmail != null) ...[
            Text(
              'Email',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            _buildDetailItem(
              Icons.email_outlined,
              'Official',
              user.email ?? 'N/A',
              false,
            ),
            if (user.secondEmail != null)
              _buildDetailItem(
                Icons.email_outlined,
                'Personal',
                user.secondEmail!,
                false,
              ),
            const Divider(height: 30),
          ],
          _buildDetailItem(
            Icons.phone_outlined,
            'Phone',
            user.phoneNumber ?? 'N/A',
            false,
          ),
          const Divider(height: 30),
          if (user.authority == 'technician') ...[
            _buildDetailItem(
              Icons.drive_eta_outlined,
              'Driver\'s License',
              user.permisConduire ? 'Yes' : 'No',
              false,
            ),
            const Divider(height: 30),
            _buildDetailItem(
              Icons.airplanemode_active_outlined,
              'Passport',
              user.passeport ? 'Yes' : 'No',
              false,
            ),
            const Divider(height: 30),
            _buildDetailItem(
              Icons.cake_outlined,
              'Birth Date',
              _formatDate(user.birthDate),
              false,
            ),
            const Divider(height: 30),
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
            const Divider(height: 30),
          ],
          if (user.authority == 'client') ...[
            _buildDetailItem(
              Icons.business_outlined,
              'Company',
              user.company ?? 'N/A',
              false,
            ),
            const Divider(height: 30),
            _buildDetailItem(
              Icons.info_outlined,
              'About',
              user.about ?? 'N/A',
              false,
            ),
            const Divider(height: 30),
          ],
        ],
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(133, 171, 250, 1.0),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _toggleEdit,
          ),
        ],
      ),
      body: FutureBuilder<User>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            debugPrint('Error loading user: ${snapshot.error}');
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.black),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            debugPrint('No user data found');
            return const Center(
              child: Text(
                'No user data found',
                style: TextStyle(color: Colors.black),
              ),
            );
          } else {
            final user = snapshot.data!;
            final profileImageUrlFuture = _getImageUrl(user.image);

            return Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height / 4,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(133, 171, 250, 1.0),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProfileImage(profileImageUrlFuture),
                        const SizedBox(height: 20),
                        Text(
                          '${user.firstName ?? "Unknown"} ${user.lastName ?? "Unknown"}',
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
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildUserInfo(user),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Change Password',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LogoutButton(),
                ),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: FutureBuilder<User>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData ||
              snapshot.data == null) {
            return NavbarClient(
              currentIndex: 2,
              onTap: (index) {},
            );
          }
          final user = snapshot.data!;
          if (user.authority == 'technician') {
            return NavbarTechnician(
              currentIndex: 1, // Profile is index 1 in technician navbar
              context: context,
            );
          } else {
            return NavbarClient(
              currentIndex: 2,
              onTap: (index) {},
            );
          }
        },
      ),
    );
  }
}
