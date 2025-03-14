import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
import 'package:helpdeskfrontend/theme/theme.dart';

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
  late TextEditingController _folderIdController;

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
    // Log userData to debug its structure
    print('User Data: ${widget.userData}');

    // Initialize controllers with null checks and default values
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
    _folderIdController = TextEditingController(
      text: widget.userData['folderId']?.toString() ?? '',
    );

    // Handle technician-specific fields
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
    _folderIdController.dispose();
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
          'profilePicture', // Match backend field name
          _imageFile!.path,
          contentType: MediaType('image', 'jpeg'),
        );
      }

      if (widget.userData['authority'] == 'technician' &&
          _signatureFile != null) {
        signatureFile = await http.MultipartFile.fromPath(
          'signature', // Match backend field name
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
          userData['folderId'] = _folderIdController.text;

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
    final customColors = Theme.of(context).extension<CustomColors>();

    // Extract image path from the image map
    final imagePath = widget.userData['image'] != null
        ? widget.userData['image']['path']
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit User'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (imagePath != null ? NetworkImage(imagePath) : null),
                  child: _imageFile == null && imagePath == null
                      ? Icon(Icons.add_a_photo, size: 40)
                      : null,
                ),
              ),
              SizedBox(height: 20),
              _buildTextFormField(
                controller: _firstNameController,
                labelText: 'First Name',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a first name' : null,
              ),
              _buildTextFormField(
                controller: _lastNameController,
                labelText: 'Last Name',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a last name' : null,
              ),
              _buildTextFormField(
                controller: _emailController,
                labelText: 'Email',
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? 'Please enter a valid email'
                    : null,
              ),
              _buildTextFormField(
                controller: _phoneNumberController,
                labelText: 'Phone Number',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a phone number' : null,
              ),
              CheckboxListTile(
                title: Text('Valid'),
                value: _valid,
                onChanged: (value) => setState(() => _valid = value ?? true),
              ),
              if (widget.userData['authority'] == 'technician') ...[
                _buildTextFormField(
                  controller: _secondEmailController,
                  labelText: 'Second Email',
                ),
                ListTile(
                  title: Text(
                    _birthDate == null
                        ? 'Select Birth Date'
                        : 'Birth Date: ${_birthDate!.toLocal().toString().split(' ')[0]}',
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),
                _buildTextFormField(
                  controller: _signatureController,
                  labelText: 'Signature',
                ),
                ElevatedButton(
                  onPressed: _pickSignature,
                  child: Text('Pick Signature'),
                ),
                if (_signatureFile != null)
                  Image.file(
                    _signatureFile!,
                    height: 100,
                    width: 100,
                  ),
                SwitchListTile(
                  title: Text('Has Passport'),
                  value: _hasPassport,
                  onChanged: (value) => setState(() => _hasPassport = value),
                ),
                SwitchListTile(
                  title: Text('Has Driver License'),
                  value: _hasDriverLicense,
                  onChanged: (value) =>
                      setState(() => _hasDriverLicense = value),
                ),
              ],
              if (widget.userData['authority'] == 'client') ...[
                _buildTextFormField(
                  controller: _companyController,
                  labelText: 'Company',
                ),
                _buildTextFormField(
                  controller: _aboutController,
                  labelText: 'About',
                ),
                _buildTextFormField(
                  controller: _folderIdController,
                  labelText: 'Folder ID',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
