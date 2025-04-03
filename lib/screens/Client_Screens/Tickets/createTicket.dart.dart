import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/navbar_client.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({Key? key}) : super(key: key);

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _equipmentIdController = TextEditingController();

  String _typeTicket = 'equipment';
  List<File> _attachments = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _equipmentIdController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _attachments.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      _showError('Failed to pick files: ${e.toString()}');
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      if (mounted) {
        _showSuccess('Ticket created successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Error creating ticket: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    if (_attachments.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments:',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _attachments.map((file) {
            return Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.insert_drive_file),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.red,
                    onPressed: () => setState(() => _attachments.remove(file)),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF242E3E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? const Color(0xFF858397) : Colors.grey[600]!;
    final textFieldBackgroundColor =
        isDarkMode ? const Color(0xFF2A3447) : const Color(0xFFF5F5F5);
    final buttonColor = isDarkMode ? Colors.blue.shade800 : Colors.blue;

    // Colors for the gradient background
    final topColor =
        isDarkMode ? const Color(0xFF141218) : const Color(0xFF628ff6);
    final bottomColor =
        isDarkMode ? const Color(0xFF242e3e) : const Color(0xFFf7f9f5);
    final gradientStop = 0.15;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topColor, bottomColor],
            stops: [gradientStop, gradientStop],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'Create Ticket',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: const [ThemeToggleButton()],
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(30, 30, 30, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type Ticket Dropdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Type*',
                                style: GoogleFonts.poppins(
                                  color: hintColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color: textFieldBackgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: DropdownButtonFormField<String>(
                                  value: _typeTicket,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'equipment',
                                      child: Text('Equipment'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'service',
                                      child: Text('Service'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontSize: 14,
                                  ),
                                  validator: (value) =>
                                      value == null ? 'Required field' : null,
                                  onChanged: (value) =>
                                      setState(() => _typeTicket = value!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Title Field
                          _buildTextField(
                            label: 'Title*',
                            controller: _titleController,
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Required field'
                                : null,
                            hintColor: hintColor,
                            textColor: textColor,
                            backgroundColor: textFieldBackgroundColor,
                            icon: Icons.title,
                          ),
                          const SizedBox(height: 20),

                          // Description Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description*',
                                style: GoogleFonts.poppins(
                                  color: hintColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color: textFieldBackgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 5,
                                  style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(16),
                                    border: InputBorder.none,
                                    hintText: 'Enter ticket description...',
                                    hintStyle: TextStyle(color: hintColor),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Required field'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Equipment ID Field
                          _buildTextField(
                            label: 'Equipment ID',
                            controller: _equipmentIdController,
                            hintText: 'Only required for equipment tickets',
                            hintColor: hintColor,
                            textColor: textColor,
                            backgroundColor: textFieldBackgroundColor,
                            icon: Icons.devices,
                          ),
                          const SizedBox(height: 20),

                          // Attachments
                          _buildAttachmentPreview(),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Add Files'),
                            onPressed: _pickFiles,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Create Ticket Button
                          Center(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitTicket,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      'Create Ticket',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Cancel Button
                          Center(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                side: BorderSide(
                                  color: isDarkMode
                                      ? const Color(0xFFFFD280)
                                      : Colors.orange,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: isDarkMode
                                      ? const Color(0xFFFFD280)
                                      : Colors.orange,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavbarClient(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool obscureText = false,
    String? Function(String?)? validator,
    required Color hintColor,
    required Color textColor,
    required Color backgroundColor,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: hintColor,
            fontSize: 14,
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
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(color: hintColor),
              prefixIcon:
                  icon != null ? Icon(icon, color: hintColor, size: 20) : null,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
