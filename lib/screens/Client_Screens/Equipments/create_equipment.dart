import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/navbar_client.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';

class CreateEquipmentPage extends StatefulWidget {
  final String typeEquipmentId;
  final String typeEquipmentName;

  const CreateEquipmentPage({
    Key? key,
    required this.typeEquipmentId,
    required this.typeEquipmentName,
  }) : super(key: key);

  @override
  _CreateEquipmentPageState createState() => _CreateEquipmentPageState();
}

class _CreateEquipmentPageState extends State<CreateEquipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _serialNumberController = TextEditingController();
  final _designationController = TextEditingController();
  final _versionController = TextEditingController();
  final _barcodeController = TextEditingController();
  DateTime? _inventoryDate;
  bool _isLoading = false;
  int _selectedIndex = 0;
  final EquipmentService _equipmentService = EquipmentService();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Add navigation logic here based on index
    });
  }

  Future<void> _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final token = await AuthService().getToken();
        if (token == null) {
          throw Exception('Token non trouvé. Veuillez vous reconnecter.');
        }

        await _equipmentService.createmyEquipment(
          serialNumber: _serialNumberController.text,
          designation: _designationController.text,
          version:
              _versionController.text.isEmpty ? null : _versionController.text,
          barcode:
              _barcodeController.text.isEmpty ? null : _barcodeController.text,
          inventoryDate: _inventoryDate,
          typeEquipmentId: widget.typeEquipmentId,
          token: token,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Équipement créé avec succès!')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _inventoryDate ?? DateTime.now(),
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
                    // Version dark
                    primary: blueColor,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                    primaryContainer: blueColor.withOpacity(0.2),
                    onPrimaryContainer: blueColor,
                    surface: const Color(0xFF242E3E),
                  )
                : ColorScheme.light(
                    // Version light
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

    if (picked != null) {
      setState(() => _inventoryDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF242E3E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? const Color(0xFF858397) : Colors.black;
    final textFieldBackgroundColor =
        isDarkMode ? const Color(0xFF2A3447) : const Color(0xFFF5F5F5);
    final buttonColor = isDarkMode ? Colors.blue[800] : Colors.blue;

    // Colors for the gradient background
    final topColor =
        isDarkMode ? const Color(0xFF141218) : const Color(0xFF628ff6);
    final bottomColor =
        isDarkMode ? const Color(0xFF242e3e) : const Color(0xFFf7f9f5);
    final gradientStop = 0.15; // Adjust this to position the divider

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
              // AppBar with transparent background
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'Create ${widget.typeEquipmentName}',
                  style: GoogleFonts.poppins(
                    color:
                        Colors.white, // Always white on the colored background
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
                                      Icon(
                                        Icons.calendar_today,
                                        color: hintColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        _inventoryDate == null
                                            ? 'Select date'
                                            : '${_inventoryDate!.toLocal()}'
                                                .split(' ')[0],
                                        style: GoogleFonts.poppins(
                                          color: _inventoryDate == null
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
                          const SizedBox(height: 30),

                          // Create Equipment Button
                          Center(
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _submitForm(context),
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
                                      'Create Equipment',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Cancel Button - Updated version
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
                                      ? Color(0xFFFFD280)
                                      : Colors.orange,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: isDarkMode
                                      ? Color(0xFFFFD280)
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

  @override
  void dispose() {
    _serialNumberController.dispose();
    _designationController.dispose();
    _versionController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }
}
