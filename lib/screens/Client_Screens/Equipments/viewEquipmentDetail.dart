import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/navbar_client.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ViewEquipmentPage extends StatefulWidget {
  final String equipmentId;

  const ViewEquipmentPage({Key? key, required this.equipmentId})
      : super(key: key);

  @override
  _ViewEquipmentPageState createState() => _ViewEquipmentPageState();
}

class _ViewEquipmentPageState extends State<ViewEquipmentPage> {
  final EquipmentService _equipmentService = EquipmentService();
  Map<String, dynamic>? _equipmentDetails;
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchEquipmentDetails();
  }

  Future<void> _fetchEquipmentDetails() async {
    try {
      final response =
          await _equipmentService.getEquipmentDetails(id: widget.equipmentId);

      // Normalize TypeEquipment data
      if (response['TypeEquipment'] is String) {
        response['TypeEquipment'] = {
          '_id': response['TypeEquipment'],
          'typeName': 'Unknown Type'
        };
      } else if (response['TypeEquipment'] == null) {
        response['TypeEquipment'] = {'typeName': 'Unknown Type'};
      }

      setState(() {
        _equipmentDetails = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load details: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Error loading equipment: $e');
    }
  }

  String _getSafeString(Map? map, String key) {
    if (map == null) return 'Not specified';
    final value = map[key];
    return value?.toString() ?? 'Not specified';
  }

  Map? _getSafeMap(Map? map, String key) {
    if (map == null) return null;
    final value = map[key];
    return value is Map ? value : null;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not specified';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateString;
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
    final backgroundColor =
        isDarkMode ? const Color(0xFF242E3E) : const Color(0xFF628FF6);
    final cardColor = isDarkMode ? const Color(0xFF2A3447) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final labelColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final dividerColor = isDarkMode ? Colors.grey[600] : Colors.grey[300];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar avec bouton retour
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Bouton retour en blanc
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Equipment Details',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const ThemeToggleButton(),
                  ],
                ),
              ),

              // Contenu principal
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              isDarkMode ? Colors.white : Colors.blue),
                        ),
                      )
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Text(
                              _errorMessage,
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                          )
                        : Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 600,
                                ),
                                child: _buildEquipmentCard(
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  labelColor: labelColor,
                                  dividerColor: dividerColor ?? Colors.grey,
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

  Widget _buildEquipmentCard({
    required Color cardColor,
    required Color textColor,
    required Color? labelColor,
    required Color dividerColor,
  }) {
    final typeEquipment = _getSafeMap(_equipmentDetails, 'TypeEquipment');

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Designation (prominently placed)
            Text(
              _getSafeString(_equipmentDetails, 'designation'),
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),

            // Equipment Type (below designation)
            Text(
              'Type: ${_getSafeString(typeEquipment, 'typeName')}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Equipment Details
            _buildDetailRow(
              label: 'Serial Number',
              value: _getSafeString(_equipmentDetails, 'serialNumber'),
              labelColor: labelColor,
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              label: 'Version',
              value: _getSafeString(_equipmentDetails, 'version'),
              labelColor: labelColor,
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              label: 'Barcode',
              value: _getSafeString(_equipmentDetails, 'barcode'),
              labelColor: labelColor,
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              label: 'Inventory Date',
              value: _formatDate(_equipmentDetails?['inventoryDate']),
              labelColor: labelColor,
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              label: 'Status',
              value: _equipmentDetails?['assigned'] == true
                  ? 'Assigned'
                  : 'Available',
              labelColor: labelColor,
              textColor: textColor,
            ),

            // Additional Info (if exists)
            if (_getSafeString(_equipmentDetails, 'additionalInfo')
                    .isNotEmpty &&
                _getSafeString(_equipmentDetails, 'additionalInfo') !=
                    'Not specified')
              Column(
                children: [
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  Text(
                    'Additional Information',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getSafeString(_equipmentDetails, 'additionalInfo'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required Color? labelColor,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
