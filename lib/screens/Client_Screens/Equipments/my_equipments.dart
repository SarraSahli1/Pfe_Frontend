import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Equipments/choose_equipment_type.dart';
import 'package:helpdeskfrontend/screens/Client_Screens/Equipments/editMyEquipment.dart';
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

  Future<void> _deleteEquipment(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Equipment',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this equipment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        final response = await _equipmentService.deleteEquipment(id: id);
        _showSuccessSnackBar(response['message']);
        await _fetchMyEquipment();
      } catch (e) {
        _showErrorSnackBar('Error while deleting: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _editEquipment(dynamic equipment) {
    final typeEquipment = equipment['TypeEquipment'];
    String? typeEquipmentId;

    if (typeEquipment is Map<String, dynamic>) {
      typeEquipmentId = typeEquipment['_id'];
    } else if (typeEquipment is String) {
      typeEquipmentId = typeEquipment;
    }

    DateTime? inventoryDate;
    if (equipment['inventoryDate'] != null) {
      inventoryDate = DateTime.tryParse(equipment['inventoryDate']);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMyEquipment(
          id: equipment['_id'],
          serialNumber: equipment['serialNumber'] ?? '',
          designation: equipment['designation'] ?? '',
          version: equipment['version'] ?? '',
          barcode: equipment['barcode'] ?? '',
          inventoryDate: inventoryDate,
          typeEquipmentId: typeEquipmentId,
          reference: equipment['reference'] ?? 'OPM_APP',
        ),
      ),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) _fetchMyEquipment();
    });
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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

    return Card(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    equipment['designation']?.toString() ?? 'Not specified',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: isDarkMode ? Colors.white : Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editEquipment(equipment);
                    } else if (value == 'view') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewEquipmentPage(
                            equipmentId: equipment['_id'],
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      _deleteEquipment(equipment['_id']);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    // Calculate the height of the top section (header + search + filter chips)
    // The filter circles are at height 120, and we want the divider at their middle (60)
    // Total height before the filter chips:
    // - AppBar (~56) + padding (16) + search field (~60) + filter title (16+8) = ~140
    // So the gradient stop should be at (140 + 60) / total height
    // Since we don't know total height, we'll estimate based on typical screen size
    // For a typical screen of ~800px, this would be ~200/800 = 0.25
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
                                SizedBox(height: 8),
                                if (_searchController.text.isEmpty &&
                                    _selectedTypeId == null)
                                  ElevatedButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ChooseEquipmentType()),
                                    ).then((_) => _fetchMyEquipment()),
                                    child: Text('Add Equipment'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChooseEquipmentType()),
        ).then((_) => _fetchMyEquipment()),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.orange,
        elevation: 4,
        tooltip: 'Add Equipment',
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
