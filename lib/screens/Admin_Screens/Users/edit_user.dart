import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';

class EditUserScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditUserScreen({Key? key, required this.userId, required this.userData})
      : super(key: key);

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _secondEmailController;
  late TextEditingController _signatureController;
  late TextEditingController _companyController;
  late TextEditingController _aboutController;
  late TextEditingController _birthDateController;

  bool _valid = true;
  File? _imageFile;
  DateTime? _birthDate;
  bool _hasPassport = false;
  bool _hasDriverLicense = false;
  File? _signatureFile;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(
      text: widget.userData['firstName']?.toString() ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.userData['lastName']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.userData['email']?.toString() ?? '',
    );
    _phoneNumberController = TextEditingController(
      text: widget.userData['phoneNumber']?.toString() ?? '',
    );
    _secondEmailController = TextEditingController(
      text: widget.userData['secondEmail']?.toString() ?? '',
    );
    _signatureController = TextEditingController(
      text: widget.userData['signature']?.toString() ?? '',
    );
    _companyController = TextEditingController(
      text: widget.userData['company']?.toString() ?? '',
    );
    _aboutController = TextEditingController(
      text: widget.userData['about']?.toString() ?? '',
    );
    _birthDateController = TextEditingController(
      text: widget.userData['birthDate'] != null
          ? DateTime.parse(widget.userData['birthDate'].toString())
              .toLocal()
              .toString()
              .split(' ')[0]
          : '',
    );

    if (widget.userData['authority'] == 'technician') {
      _birthDate = widget.userData['birthDate'] != null
          ? DateTime.parse(widget.userData['birthDate'].toString())
          : null;
      _hasPassport = widget.userData['passeport'] ?? false;
      _hasDriverLicense = widget.userData['permisConduire'] ?? false;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _secondEmailController.dispose();
    _signatureController.dispose();
    _companyController.dispose();
    _aboutController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickSignature() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _signatureFile = File(pickedFile.path);
        _signatureController.text = pickedFile.path.split('/').last;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final userData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneNumberController.text,
        'valid': _valid,
      };

      http.MultipartFile? profilePictureFile;
      http.MultipartFile? signatureFile;

      if (_imageFile != null) {
        profilePictureFile = await http.MultipartFile.fromPath(
          'profilePicture',
          _imageFile!.path,
          contentType: MediaType('image', 'jpeg'),
        );
      }

      if (widget.userData['authority'] == 'technician' &&
          _signatureFile != null) {
        signatureFile = await http.MultipartFile.fromPath(
          'signature',
          _signatureFile!.path,
          contentType: MediaType('image', 'jpeg'),
        );
      }

      try {
        Map<String, dynamic> response;
        if (widget.userData['authority'] == 'technician') {
          userData['secondEmail'] = _secondEmailController.text;
          userData['birthDate'] = _birthDate?.toIso8601String() as Object;
          userData['passeport'] = _hasPassport;
          userData['permisConduire'] = _hasDriverLicense;

          response = await _userService.updateTechnician(
            widget.userId,
            userData,
            profilePicture: profilePictureFile,
            signature: signatureFile,
          );
        } else if (widget.userData['authority'] == 'client') {
          userData['company'] = _companyController.text;
          userData['about'] = _aboutController.text;

          response = await _userService.updateClient(
            widget.userId,
            userData,
            profilePicture: profilePictureFile,
          );
        } else {
          response = await _userService.updateUser(
            widget.userId,
            userData,
            image: profilePictureFile,
          );
        }

        if (response['data'] != null && response['data']['image'] != null) {
          setState(() {
            widget.userData['image'] = response['data']['image']['path'];
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User updated successfully: ${response['message']}'),
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF242E3E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? const Color(0xFF858397) : Colors.black54;
    final textFieldBackgroundColor =
        isDarkMode ? const Color(0xFF2A3447) : const Color(0xFFF5F5F5);

    final imagePath = widget.userData['image'] != null
        ? widget.userData['image']['path']
        : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? Colors.black
            : const Color.fromRGBO(133, 171, 250, 1.0), // Match AdminUsersList
        elevation: 0, // Match AdminUsersList
        title: Text(
          'Edit User',
          style: GoogleFonts.poppins(
            color: Colors.white, // Match AdminUsersList, simplified
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme:
            const IconThemeData(color: Colors.white), // Match AdminUsersList
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.save,
                color: Colors.white), // Match AdminUsersList
            onPressed: _submitForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: _imageFile != null
                            ? ClipOval(
                                child: Image.file(
                                  _imageFile!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (imagePath != null
                                ? ClipOval(
                                    child: Image.network(
                                      imagePath,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  )),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'First Name',
                      controller: _firstNameController,
                      validator: (value) =>
                          value!.isEmpty ? "Enter first name" : null,
                      hintColor: hintColor,
                      textColor: textColor,
                      backgroundColor: textFieldBackgroundColor,
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      label: 'Last Name',
                      controller: _lastNameController,
                      validator: (value) =>
                          value!.isEmpty ? "Enter last name" : null,
                      hintColor: hintColor,
                      textColor: textColor,
                      backgroundColor: textFieldBackgroundColor,
                      icon: Icons.person,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                validator: (value) => value!.isEmpty ? "Enter email" : null,
                hintColor: hintColor,
                textColor: textColor,
                backgroundColor: textFieldBackgroundColor,
                icon: Icons.email,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'Phone Number',
                controller: _phoneNumberController,
                hintColor: hintColor,
                textColor: textColor,
                backgroundColor: textFieldBackgroundColor,
                icon: Icons.phone,
              ),
              const SizedBox(height: 15),
              if (widget.userData['authority'] == 'technician') ...[
                _buildTextField(
                  label: 'Second Email',
                  controller: _secondEmailController,
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                  icon: Icons.email,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  label: 'Date de Naissance',
                  controller: _birthDateController,
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                  icon: Icons.calendar_today,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  label: 'Signature',
                  controller: _signatureController,
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                  icon: Icons.edit,
                  readOnly: true,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.attach_file, color: hintColor),
                    onPressed: _pickSignature,
                  ),
                ),
                const SizedBox(height: 15),
                if (_signatureFile != null)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.file(
                      _signatureFile!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(height: 15),
                _buildSwitchField(
                  label: 'Has Passport',
                  value: _hasPassport,
                  onChanged: (value) => setState(() => _hasPassport = value),
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                ),
                const SizedBox(height: 15),
                _buildSwitchField(
                  label: 'Has Driver License',
                  value: _hasDriverLicense,
                  onChanged: (value) =>
                      setState(() => _hasDriverLicense = value),
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                ),
              ],
              if (widget.userData['authority'] == 'client') ...[
                _buildTextField(
                  label: 'Company',
                  controller: _companyController,
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                  icon: Icons.business,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  label: 'About',
                  controller: _aboutController,
                  hintColor: hintColor,
                  textColor: textColor,
                  backgroundColor: textFieldBackgroundColor,
                  icon: Icons.info,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    String? Function(String?)? validator,
    required Color hintColor,
    required Color textColor,
    Widget? suffixIcon,
    Color? backgroundColor,
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: hintColor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              filled: false,
              prefixIcon: icon != null ? Icon(icon, color: hintColor) : null,
              suffixIcon: suffixIcon,
            ),
            validator: validator,
            readOnly: readOnly,
            onTap: onTap,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color hintColor,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: hintColor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              value ? 'Yes' : 'No',
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey[300],
          ),
        ),
      ],
    );
  }
}
