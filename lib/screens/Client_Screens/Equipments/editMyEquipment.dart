import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/services/typeEquip_service.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/navbar_client.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';

class EditMyEquipment extends StatefulWidget {
  final String id;
  final String serialNumber;
  final String designation;
  final String version;
  final String barcode;
  final DateTime? inventoryDate;
  final bool assigned;
  final String? typeEquipmentId;
  final String reference;

  const EditMyEquipment({
    Key? key,
    required this.id,
    required this.serialNumber,
    required this.designation,
    required this.version,
    required this.barcode,
    this.inventoryDate,
    this.assigned = false,
    this.typeEquipmentId,
    this.reference = 'OPM_APP',
  }) : super(key: key);

  @override
  _EditMyEquipmentState createState() => _EditMyEquipmentState();
}

class _EditMyEquipmentState extends State<EditMyEquipment> {
  final _formKey = GlobalKey<FormState>();
  final EquipmentService _equipmentService = EquipmentService();
  final TypeEquipmentService _typeEquipmentService = TypeEquipmentService();

  late TextEditingController _serialNumberController;
  late TextEditingController _designationController;
  late TextEditingController _versionController;
  late TextEditingController _barcodeController;

  String? _selectedTypeEquipmentId;
  List<dynamic> _equipmentTypes = [];
  bool _isLoading = false;
  DateTime? _selectedDate;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _serialNumberController = TextEditingController(text: widget.serialNumber);
    _designationController = TextEditingController(text: widget.designation);
    _versionController = TextEditingController(text: widget.version);
    _barcodeController = TextEditingController(text: widget.barcode);
    _selectedTypeEquipmentId = widget.typeEquipmentId;
    _selectedDate = widget.inventoryDate;

    _fetchEquipmentTypes();
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _designationController.dispose();
    _versionController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchEquipmentTypes() async {
    setState(() => _isLoading = true);
    try {
      final types = await _typeEquipmentService.getAllTypeEquipment();
      setState(() => _equipmentTypes = types);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading types: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
        final blueColor = const Color(0xFF628FF6);

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDarkMode
                ? ColorScheme.dark(
                    primary: blueColor,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                    primaryContainer: blueColor.withOpacity(0.2),
                    onPrimaryContainer: blueColor,
                    surface: const Color(0xFF242E3E),
                  )
                : ColorScheme.light(
                    primary: blueColor,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                    primaryContainer: blueColor.withOpacity(0.2),
                    onPrimaryContainer: blueColor,
                  ),
            dialogTheme: DialogTheme(
              backgroundColor:
                  isDarkMode ? const Color(0xFF2A3447) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: blueColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _updateEquipment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await _equipmentService.updateEquipment(
          id: widget.id,
          data: {
            'serialNumber': _serialNumberController.text,
            'designation': _designationController.text,
            'version': _versionController.text,
            'barcode': _barcodeController.text,
            'inventoryDate': _selectedDate?.toIso8601String(),
            'TypeEquipment': _selectedTypeEquipmentId,
            'reference': widget.reference,
            'assigned': widget.assigned,
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
        setState(() => _isLoading = false);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    // Couleurs
    final backgroundColor = isDarkMode ? const Color(0xFF242E3E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? const Color(0xFF858397) : Colors.black54;
    final textFieldBackgroundColor =
        isDarkMode ? const Color(0xFF2A3447) : const Color(0xFFF5F5F5);
    final buttonColor = isDarkMode ? Colors.blue[800] : Colors.blue;
    final cancelButtonColor =
        isDarkMode ? const Color(0xFFFFD280) : Colors.orange;

    // Dégradé pour l'arrière-plan
    final topColor =
        isDarkMode ? const Color(0xFF141218) : const Color(0xFF628FF6);
    final bottomColor =
        isDarkMode ? const Color(0xFF242E3E) : const Color(0xFFF7F9F5);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topColor, bottomColor],
            stops: [0.15, 0.15],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar transparent
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'Edit Equipment',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: const [ThemeToggleButton()],
              ),

              // Contenu principal
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
                          // Serial Number
                          _buildTextField(
                            label: 'Serial Number',
                            controller: _serialNumberController,
                            hintColor: hintColor,
                            textColor: textColor,
                            backgroundColor: textFieldBackgroundColor,
                            icon: Icons.numbers,
                          ),
                          const SizedBox(height: 15),

                          // Designation (required)
                          _buildTextField(
                            label: 'Designation*',
                            controller: _designationController,
                            validator: (value) => value!.isEmpty
                                ? "This field is required"
                                : null,
                            hintColor: hintColor,
                            textColor: textColor,
                            backgroundColor: textFieldBackgroundColor,
                            icon: Icons.description,
                          ),
                          const SizedBox(height: 15),

                          // Version
                          _buildTextField(
                            label: 'Version',
                            controller: _versionController,
                            hintColor: hintColor,
                            textColor: textColor,
                            backgroundColor: textFieldBackgroundColor,
                            icon: Icons.code,
                          ),
                          const SizedBox(height: 15),

                          // Barcode
                          _buildTextField(
                            label: 'Barcode',
                            controller: _barcodeController,
                            hintColor: hintColor,
                            textColor: textColor,
                            backgroundColor: textFieldBackgroundColor,
                            icon: Icons.qr_code,
                          ),
                          const SizedBox(height: 20),

                          // Inventory Date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inventory Date',
                                style: GoogleFonts.poppins(
                                  color: hintColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: textFieldBackgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          color: hintColor, size: 20),
                                      const SizedBox(width: 16),
                                      Text(
                                        _selectedDate == null
                                            ? 'Select date'
                                            : '${_selectedDate!.toLocal()}'
                                                .split(' ')[0],
                                        style: GoogleFonts.poppins(
                                          color: _selectedDate == null
                                              ? hintColor
                                              : textColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Equipment Type Dropdown
                          Text(
                            'Equipment Type*',
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonFormField<String>(
                              value: _selectedTypeEquipmentId,
                              decoration: const InputDecoration(
                                  border: InputBorder.none),
                              items: _equipmentTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type['_id'],
                                  child: Text(
                                    type['typeName'] ?? 'Unknown type',
                                    style: GoogleFonts.poppins(
                                      color: textColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(
                                  () => _selectedTypeEquipmentId = value),
                              validator: (value) =>
                                  value == null ? 'Please select a type' : null,
                              dropdownColor: textFieldBackgroundColor,
                              icon:
                                  Icon(Icons.arrow_drop_down, color: hintColor),
                              style: GoogleFonts.poppins(
                                  color: textColor, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Save Button
                          Center(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateEquipment,
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
                                      'Save Changes',
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
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                side: BorderSide(
                                  color: cancelButtonColor,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: cancelButtonColor,
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
    bool obscureText = false,
    String? Function(String?)? validator,
    required Color hintColor,
    required Color textColor,
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
