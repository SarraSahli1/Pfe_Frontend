import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/navbar_technicien.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/services/problems_service.dart';
import 'package:flutter/foundation.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({Key? key}) : super(key: key);

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _otherProblemController = TextEditingController();

  String _typeTicket = 'equipment';
  List<File> _attachments = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  int _selectedIndex = 0;

  // Equipment related variables
  List<dynamic> _userEquipment = [];
  dynamic _selectedEquipment;
  bool _isLoadingEquipment = false;

  // Problem related variables
  List<dynamic> _equipmentProblems = [];
  String? _selectedProblemId;
  bool _isLoadingProblems = false;
  bool _showOtherProblemField = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUserEquipment();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _otherProblemController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserEquipment() async {
    if (!mounted) return;

    setState(() => _isLoadingEquipment = true);

    try {
      final equipment = await EquipmentService.getMyEquipment();
      if (mounted) {
        setState(() {
          _userEquipment = equipment;
          debugPrint('Equipment data: ${equipment.toString()}');
          if (equipment.isNotEmpty) {
            _selectedEquipment = equipment[0];
            final typeEquipmentId = _selectedEquipment['TypeEquipment']?['_id'];
            debugPrint('Selected equipment typeEquipmentId: $typeEquipmentId');
            if (typeEquipmentId != null && typeEquipmentId is String) {
              _fetchEquipmentProblems(typeEquipmentId);
            } else {
              debugPrint('No valid TypeEquipment _id for initial equipment');
              _equipmentProblems = [
                {'_id': 'other', 'nomProblem': 'Autre (précisez)'}
              ];
            }
          } else {
            debugPrint('No equipment found for user');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load equipment: ${e.toString()}');
        debugPrint('Equipment fetch error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingEquipment = false);
      }
    }
  }

  Future<void> _fetchEquipmentProblems(String typeEquipmentId) async {
    if (!mounted) return;

    setState(() {
      _isLoadingProblems = true;
      _selectedProblemId = null;
      _showOtherProblemField = false;
      _equipmentProblems = [];
    });

    try {
      debugPrint('Fetching problems for typeEquipmentId: $typeEquipmentId');
      final problems = await ProblemsService().getAllProblems(
        typeEquipmentId: typeEquipmentId,
      );

      if (mounted) {
        setState(() {
          _equipmentProblems = problems;
          debugPrint('Problems fetched: ${problems.length} problems');
          if (problems.isEmpty) {
            debugPrint(
                'No problems found for typeEquipmentId: $typeEquipmentId');
          }
          // Add "Other" option
          _equipmentProblems.add({
            '_id': 'other',
            'nomProblem': 'Autre (précisez)',
          });
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load problems: ${e.toString()}');
        debugPrint('Problems fetch error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProblems = false);
      }
    }
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

    // Additional validation for equipment tickets
    if (_typeTicket == 'equipment') {
      if (_selectedEquipment == null) {
        _showError('Please select an equipment');
        return;
      }
      if (_selectedProblemId == null) {
        _showError('Please select a problem');
        return;
      }
      if (_selectedProblemId == 'other' &&
          _otherProblemController.text.isEmpty) {
        _showError('Please describe your problem');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Prepare file paths from _attachments
      final filePaths = _attachments.map((file) => file.path).toList();

      // Get title from problem (for equipment tickets) or description (for service tickets)
      final title = _typeTicket == 'equipment'
          ? (_selectedProblemId == 'other'
              ? _otherProblemController.text.trim()
              : _equipmentProblems.firstWhere(
                  (p) => p['_id'] == _selectedProblemId)['nomProblem'])
          : _descriptionController.text.trim();

      // Call the TicketService.createTicket method
      final result = await TicketService.createTicket(
        title: title,
        description: _descriptionController.text.trim(),
        typeTicket: _typeTicket,
        equipmentId:
            _typeTicket == 'equipment' ? _selectedEquipment['_id'] : null,
        filePaths: filePaths.isNotEmpty ? filePaths : null,
      );

      if (mounted) {
        if (result['success'] == true) {
          _showSuccess('Ticket created successfully');
          Navigator.pop(context, true);
        } else {
          _showError(result['message'] ?? 'Failed to create ticket');
        }
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

  Widget _buildEquipmentDropdown() {
    if (_isLoadingEquipment) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userEquipment.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No equipment available',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<dynamic>(
          isExpanded: true,
          value: _selectedEquipment,
          items: _userEquipment.map((equipment) {
            return DropdownMenuItem<dynamic>(
              value: equipment,
              child: Text(
                equipment['designation'] ?? 'Unnamed Equipment',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedEquipment = value;
              final typeEquipmentId = value['TypeEquipment']?['_id'];
              debugPrint(
                  'Equipment changed, new equipment: ${value.toString()}');
              if (typeEquipmentId != null && typeEquipmentId is String) {
                _fetchEquipmentProblems(typeEquipmentId);
              } else {
                _showError(
                    'Selected equipment has no valid type. Please select "Other" to describe your issue.');
                _equipmentProblems = [
                  {'_id': 'other', 'nomProblem': 'Autre (précisez)'}
                ];
                _selectedProblemId = 'other';
                _showOtherProblemField = true;
              }
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Select the equipment related to your issue',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProblemSelector() {
    if (_isLoadingProblems) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_equipmentProblems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No problems found for this equipment type. Please select "Other" to describe your issue.',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Problem*',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedProblemId,
            hint: Text(
              'Select a problem',
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            items: _equipmentProblems.map((problem) {
              return DropdownMenuItem<String>(
                value: problem['_id'],
                child: Text(
                  problem['nomProblem'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProblemId = value;
                _showOtherProblemField = value == 'other';
                debugPrint('Selected problem: $value');
              });
            },
          ),
        ),
        if (_showOtherProblemField) ...[
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Describe your problem*',
            controller: _otherProblemController,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please describe your problem' : null,
            hintColor: Colors.grey[600]!,
            textColor: Theme.of(context).textTheme.bodyLarge!.color!,
            backgroundColor: Theme.of(context).cardColor,
            icon: Icons.description,
          ),
        ],
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
                                  onChanged: (value) {
                                    setState(() {
                                      _typeTicket = value!;
                                      if (value == 'service') {
                                        _selectedProblemId = null;
                                        _showOtherProblemField = false;
                                        _equipmentProblems = [];
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Equipment Dropdown (only shown for equipment tickets)
                          if (_typeTicket == 'equipment') ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Equipment*',
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: _buildEquipmentDropdown(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Problem Selector (only shown for equipment tickets)
                          if (_typeTicket == 'equipment') ...[
                            Container(
                              decoration: BoxDecoration(
                                color: textFieldBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: _buildProblemSelector(),
                            ),
                            const SizedBox(height: 20),
                          ],

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

                          // Attachments
                          _buildAttachmentPreview(),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.attach_file,
                                color: Colors.white),
                            label: const Text('Add Files'),
                            onPressed: _pickFiles,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: Colors.white,
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
                                foregroundColor: Colors.white,
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
      bottomNavigationBar: NavbarTechnician(
        currentIndex: _selectedIndex,
        context: context, // Added context parameter to match admin style
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
