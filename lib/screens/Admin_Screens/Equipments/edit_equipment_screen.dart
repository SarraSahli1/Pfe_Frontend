import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/services/typeEquip_service.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';

class EditEquipmentPage extends StatefulWidget {
  final String id;
  final String serialNumber;
  final String designation;
  final String version;
  final String barcode;
  final DateTime? inventoryDate;
  final bool assigned;
  final String? typeEquipmentId;
  final String? ownerId;

  const EditEquipmentPage({
    Key? key,
    required this.id,
    required this.serialNumber,
    required this.designation,
    required this.version,
    required this.barcode,
    this.inventoryDate,
    this.assigned = false,
    this.typeEquipmentId,
    this.ownerId,
  }) : super(key: key);

  @override
  _EditEquipmentPageState createState() => _EditEquipmentPageState();
}

class _EditEquipmentPageState extends State<EditEquipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final EquipmentService _equipmentService = EquipmentService();
  final TypeEquipmentService _typeEquipmentService = TypeEquipmentService();

  late TextEditingController _serialNumberController;
  late TextEditingController _designationController;
  late TextEditingController _versionController;
  late TextEditingController _barcodeController;
  DateTime? _inventoryDate;
  late bool _assigned;
  String? _selectedTypeEquipmentId;
  List<dynamic> _equipmentTypes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _serialNumberController = TextEditingController(text: widget.serialNumber);
    _designationController = TextEditingController(text: widget.designation);
    _versionController = TextEditingController(text: widget.version);
    _barcodeController = TextEditingController(text: widget.barcode);
    _inventoryDate = widget.inventoryDate;
    _assigned = widget.assigned;
    _selectedTypeEquipmentId = widget.typeEquipmentId;

    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _fetchEquipmentTypes();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEquipmentTypes() async {
    try {
      List<dynamic> types = await _typeEquipmentService.getAllTypeEquipment();
      setState(() {
        _equipmentTypes = types;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading equipment types: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _inventoryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _inventoryDate) {
      setState(() {
        _inventoryDate = picked;
      });
    }
  }

  Future<void> _updateEquipment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _equipmentService.updateEquipment(
          id: widget.id,
          data: {
            'serialNumber': _serialNumberController.text,
            'designation': _designationController.text,
            'version': _versionController.text,
            'barcode': _barcodeController.text,
            'inventoryDate': _inventoryDate?.toIso8601String(),
            'assigned': _assigned,
            'TypeEquipment': _selectedTypeEquipmentId,
            'reference': 'OPM_APP',
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating equipment: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _designationController.dispose();
    _versionController.dispose();
    _barcodeController.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Equipment',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Color(0xFF628ff6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 30, 30, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      label: 'Serial Number',
                      controller: _serialNumberController,
                      hintColor: hintColor,
                      textColor: textColor,
                      backgroundColor: textFieldBackgroundColor,
                      icon: Icons.confirmation_number,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      label: 'Designation*',
                      controller: _designationController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required';
                        }
                        return null;
                      },
                      hintColor: hintColor,
                      textColor: textColor,
                      backgroundColor: textFieldBackgroundColor,
                      icon: Icons.description,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      label: 'Version',
                      controller: _versionController,
                      hintColor: hintColor,
                      textColor: textColor,
                      backgroundColor: textFieldBackgroundColor,
                      icon: Icons.code,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      label: 'Barcode',
                      controller: _barcodeController,
                      hintColor: hintColor,
                      textColor: textColor,
                      backgroundColor: textFieldBackgroundColor,
                      icon: Icons.qr_code,
                    ),
                    const SizedBox(height: 15),
                    // Updated Date Field with same background
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventory Date',
                          style: GoogleFonts.poppins(
                            color: hintColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: textFieldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text(
                              _inventoryDate == null
                                  ? 'Select inventory date'
                                  : 'Date: ${_inventoryDate!.toLocal().toString().split(' ')[0]}',
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            trailing:
                                Icon(Icons.calendar_today, color: hintColor),
                            onTap: () => _selectDate(context),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Updated Assigned Field with same background
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assigned',
                          style: GoogleFonts.poppins(
                            color: hintColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: textFieldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              _assigned ? 'Yes' : 'No',
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            value: _assigned,
                            onChanged: (bool value) {
                              setState(() {
                                _assigned = value;
                              });
                            },
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Equipment Type*',
                          style: GoogleFonts.poppins(
                            color: hintColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: textFieldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedTypeEquipmentId,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                              prefixIcon:
                                  Icon(Icons.category, color: hintColor),
                            ),
                            items: _equipmentTypes.map((typeEquipment) {
                              return DropdownMenuItem<String>(
                                value: typeEquipment['_id'],
                                child: Text(
                                  typeEquipment['typeName'],
                                  style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTypeEquipmentId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a type';
                              }
                              return null;
                            },
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateEquipment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF628ff6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
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
          ),
        ),
      ],
    );
  }
}
