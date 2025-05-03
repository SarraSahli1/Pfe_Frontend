import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';

class EquipmentDetailsPage extends StatefulWidget {
  final String equipmentId;

  const EquipmentDetailsPage({Key? key, required this.equipmentId})
      : super(key: key);

  @override
  _EquipmentDetailsPageState createState() => _EquipmentDetailsPageState();
}

class _EquipmentDetailsPageState extends State<EquipmentDetailsPage> {
  final EquipmentService _equipmentService = EquipmentService();
  late Future<Map<String, dynamic>> _futureEquipment;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    _futureEquipment =
        _equipmentService.getEquipmentDetails(id: widget.equipmentId);
  }

  Future<void> _refreshEquipment() async {
    setState(() {
      _futureEquipment =
          _equipmentService.getEquipmentDetails(id: widget.equipmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF242E3E) : Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Equipment Details',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode
            ? Colors.black
            : const Color.fromRGBO(133, 171, 250, 1.0),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEquipment,
        color: isDarkMode ? Colors.white : const Color(0xFFfda781),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _futureEquipment,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: isDarkMode
                      ? Colors.white
                      : const Color.fromRGBO(133, 171, 250, 1.0),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.inter(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Text(
                  'No data found',
                  style: GoogleFonts.inter(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              );
            } else {
              final equipment = snapshot.data!;
              final typeEquipment = equipment['TypeEquipment'] ?? {};
              final owner = equipment['owner'] ?? {};
              final inventoryDate = equipment['inventoryDate'] != null
                  ? DateTime.parse(equipment['inventoryDate'])
                  : null;
              final isAssigned = equipment['assigned'] == true;

              return Column(
                children: [
                  // Reduced Header Section
                  Container(
                    height: screenHeight / 6, // Reduced height
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1A2232)
                          : const Color.fromRGBO(133, 171, 250, 1.0),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Designation only (icon removed)
                          Text(
                            equipment['designation'] ?? 'No designation',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isAssigned
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isAssigned ? 'Assigned' : 'Not assigned',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Details Section
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information
                          Text(
                            'Basic Information',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildDetailItem(
                            Icons.confirmation_number_outlined,
                            'Serial Number',
                            equipment['serialNumber'] ?? 'Not specified',
                            isDarkMode,
                          ),
                          _buildDetailItem(
                            Icons.code_outlined,
                            'Version',
                            equipment['version'] ?? 'Not specified',
                            isDarkMode,
                          ),
                          _buildDetailItem(
                            Icons.qr_code_outlined,
                            'Barcode',
                            equipment['barcode'] ?? 'Not specified',
                            isDarkMode,
                          ),
                          _buildDetailItem(
                            Icons.calendar_today_outlined,
                            'Inventory Date',
                            inventoryDate != null
                                ? dateFormat.format(inventoryDate)
                                : 'Not specified',
                            isDarkMode,
                          ),
                          const Divider(height: 30),
                          // Equipment Type
                          Text(
                            'Equipment Type',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildDetailItem(
                            Icons.category_outlined,
                            'Name',
                            typeEquipment['typeName'] ?? 'Not specified',
                            isDarkMode,
                          ),
                          if (typeEquipment['description'] != null)
                            _buildDetailItem(
                              Icons.description_outlined,
                              'Description',
                              typeEquipment['description'],
                              isDarkMode,
                            ),
                          const Divider(height: 30),
                          // Owner Information (if assigned)
                          if (owner.isNotEmpty) ...[
                            Text(
                              'Owner Information',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildDetailItem(
                              Icons.business_outlined,
                              'Company',
                              owner['company'] ?? 'Not specified',
                              isDarkMode,
                            ),
                            if (owner['email'] != null)
                              _buildDetailItem(
                                Icons.email_outlined,
                                'Email',
                                owner['email'],
                                isDarkMode,
                              ),
                            if (owner['phone'] != null)
                              _buildDetailItem(
                                Icons.phone_outlined,
                                'Phone',
                                owner['phone'],
                                isDarkMode,
                              ),
                            const Divider(height: 30),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      IconData icon, String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
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
      ),
    );
  }
}
