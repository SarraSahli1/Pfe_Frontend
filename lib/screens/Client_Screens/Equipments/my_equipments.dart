import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Equipments/viewEquipmentDetail.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/services/typeEquip_service.dart';
import 'package:helpdeskfrontend/widgets/navbar_client.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';

class MyEquipmentPage extends StatefulWidget {
  @override
  _MyEquipmentPageState createState() => _MyEquipmentPageState();
}

class _MyEquipmentPageState extends State<MyEquipmentPage> {
  final EquipmentService _equipmentService = EquipmentService();
  final TypeEquipmentService _typeEquipmentService = TypeEquipmentService();
  List<dynamic> _equipmentList = [];
  List<dynamic> _filteredEquipmentList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  String? _selectedTypeId;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchMyEquipment();
    _searchController.addListener(_applyFilters);
  }

  List<dynamic> _getUniqueEquipmentTypes() {
    final types = <dynamic>[];
    final seenIds = <String>{};

    for (var equipment in _equipmentList) {
      try {
        final type = equipment['TypeEquipment'];
        if (type == null || type is! Map) continue;

        final typeId = type['_id']?.toString();
        if (typeId == null || seenIds.contains(typeId)) continue;

        seenIds.add(typeId);
        types.add(type);
      } catch (e) {
        debugPrint('Error processing equipment: $e');
      }
    }

    return types;
  }

  void _applyFilters() {
    setState(() {
      _filteredEquipmentList = _equipmentList.where((equipment) {
        final matchesSearch = _searchController.text.isEmpty ||
            (equipment['designation']?.toString().toLowerCase() ?? '')
                .contains(_searchController.text.toLowerCase()) ||
            (equipment['serialNumber']?.toString().toLowerCase() ?? '')
                .contains(_searchController.text.toLowerCase()) ||
            (equipment['barcode']?.toString().toLowerCase() ?? '')
                .contains(_searchController.text.toLowerCase());

        final matchesType = _selectedTypeId == null ||
            (equipment['TypeEquipment'] is Map
                ? equipment['TypeEquipment']['_id'] == _selectedTypeId
                : equipment['TypeEquipment'] == _selectedTypeId);

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  Future<void> _fetchMyEquipment() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('No token found');

      final equipment = await EquipmentService.getMyEquipment();
      final allTypes = await _typeEquipmentService.getAllTypeEquipment();

      final typeMap = <String, dynamic>{};
      for (var type in allTypes) {
        final typeId = type['_id']?.toString();
        if (typeId != null) {
          typeMap[typeId] = type;
        }
      }

      final enrichedEquipment = equipment.map((eq) {
        final type = eq['TypeEquipment'];
        if (type is String) {
          eq['TypeEquipment'] = typeMap[type];
        } else if (type is Map) {
          final typeId = type['_id']?.toString();
          if (typeId != null && typeMap.containsKey(typeId)) {
            eq['TypeEquipment'] = typeMap[typeId];
          }
        }
        return eq;
      }).toList();

      setState(() {
        _equipmentList = enrichedEquipment;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching equipment: $e');
      _showErrorSnackBar('Failed to load equipment: ${e.toString()}');
    }
  }

  Widget _buildTypeFilterChips() {
    final uniqueTypes = _getUniqueEquipmentTypes();
    if (uniqueTypes.isEmpty) return SizedBox.shrink();

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8.0),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: uniqueTypes.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = _selectedTypeId == null;
                return Container(
                  width: 80,
                  margin: EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTypeId = null;
                        _applyFilters();
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          color: isDarkMode ? Colors.grey[800] : Colors.white,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orange
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(35),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.all_inclusive,
                                size: 30,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'All',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final type = uniqueTypes[index - 1];
              final typeName = type['typeName']?.toString() ?? 'Unknown';
              final typeId = type['_id']?.toString();
              final logo = type['logo'];
              final isSelected = _selectedTypeId == typeId;
              final logoUrl = (logo is Map) ? logo['path']?.toString() : null;

              return Container(
                width: 80,
                margin: EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTypeId = isSelected ? null : typeId;
                      _applyFilters();
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            color: Colors.white,
                            child: Container(
                              width: 70,
                              height: 70,
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.orange
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(35),
                              ),
                              child: logoUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(35),
                                      child: Image.network(
                                        logoUrl,
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (context, child, progress) {
                                          return progress == null
                                              ? child
                                              : Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ));
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(Icons.build,
                                              size: 30,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black);
                                        },
                                      ),
                                    )
                                  : Icon(Icons.build,
                                      size: 30,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.remove,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        typeName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(BuildContext context, dynamic equipment) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final typeEquipment = equipment['TypeEquipment'];
    final typeName = typeEquipment != null
        ? typeEquipment['typeName']?.toString() ?? 'Unknown type'
        : 'Unknown type';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewEquipmentPage(
              equipmentId: equipment['_id'],
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 16.0),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        color: isDarkMode ? Color(0xFF3A4352) : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                equipment['designation']?.toString() ?? 'Not specified',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Divider(color: Colors.grey[400], height: 20),
              Row(
                children: [
                  Text(
                    'Serial Number: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    equipment['serialNumber']?.toString() ?? 'Not specified',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Type: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    typeName,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              if (equipment['barcode']?.toString().isNotEmpty ?? false)
                Column(
                  children: [
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Barcode: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                        Text(
                          equipment['barcode']?.toString() ?? 'Not specified',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final gradientStop = 0.30;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Color(0xFF141218), Color(0xFF242e3e)] // Dark mode colors
                : [Color(0xFF628ff6), Color(0xFFf7f9f5)], // Light mode colors
            stops: [gradientStop, gradientStop], // Adjusted stop position
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Equipments',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    ThemeToggleButton(),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color(0xFF3A4352) : Colors.white,
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search equipment...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDarkMode ? Colors.white : Colors.grey[600],
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 15.0,
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              _buildTypeFilterChips(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      )
                    : _filteredEquipmentList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.devices_other,
                                  size: 60,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty &&
                                          _selectedTypeId == null
                                      ? 'No equipment found'
                                      : 'No results for your search',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchMyEquipment,
                            color: Colors.orange,
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: _filteredEquipmentList.length,
                              itemBuilder: (context, index) =>
                                  _buildEquipmentCard(
                                context,
                                _filteredEquipmentList[index],
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

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }
}
