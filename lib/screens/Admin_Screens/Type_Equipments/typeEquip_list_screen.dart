import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Type_Equipments/edit_typeEquip.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Type_Equipments/create_typeEquip.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Type_Equipments/typeEquipDetails_screen.dart';
import 'package:helpdeskfrontend/services/typeEquip_service.dart';
import 'package:helpdeskfrontend/widgets/navbar_admin.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';

class TypeEquipmentListPage extends StatefulWidget {
  const TypeEquipmentListPage({super.key});

  @override
  _TypeEquipmentListPageState createState() => _TypeEquipmentListPageState();
}

class _TypeEquipmentListPageState extends State<TypeEquipmentListPage> {
  final TypeEquipmentService _typeEquipmentService = TypeEquipmentService();
  List<dynamic> _typeEquipments = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTypeEquipments();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _fetchTypeEquipments() async {
    try {
      final typeEquipments = await _typeEquipmentService.getAllTypeEquipment();
      setState(() {
        _typeEquipments = typeEquipments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading equipment types: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _deleteTypeEquipment(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Equipment Type'),
        content: Text('Are you sure you want to delete this equipment type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response =
            await _typeEquipmentService.deleteTypeEquipment(id: id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTypeEquipments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  List<dynamic> _filterTypeEquipments() {
    List<dynamic> filtered = _typeEquipments;

    // Apply type filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((equipment) {
        return equipment['typeEquip']?.toString().trim().toLowerCase() ==
            _selectedFilter;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((equipment) {
        final typeName = equipment['typeName'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return typeName.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final filteredTypeEquipments = _filterTypeEquipments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Types',
            style: TextStyle(color: Colors.white)),
        backgroundColor: isDarkMode ? Colors.black : Color(0xFF628ff6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? const Color(0xFF242E3E)
          : Colors.white,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateTypeEquipmentPage(),
              ),
            ).then((shouldRefresh) {
              if (shouldRefresh == true) {
                _fetchTypeEquipments();
              }
            });
          },
          backgroundColor: isDarkMode ? Colors.black : Color(0xFF628ff6),
          icon: const Icon(Icons.add, color: Colors.white, size: 24),
          label: const Text(
            'Add Type',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _fetchTypeEquipments,
        color: Colors.orange,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.orange,
                ),
              )
            : filteredTypeEquipments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.build,
                          size: 100,
                          color: themeProvider.themeMode == ThemeMode.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No equipment types found'
                              : 'No results for "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 18,
                            color: themeProvider.themeMode == ThemeMode.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildSearchBar(context),
                          const SizedBox(height: 30),
                          _buildFilterChips(context),
                          const SizedBox(height: 30),
                          ...filteredTypeEquipments.map((typeEquipment) {
                            return TypeEquipmentCard(
                              typeName: typeEquipment['typeName'],
                              typeEquip: typeEquipment['typeEquip'],
                              logo: typeEquipment['logo']?['path'],
                              themeProvider: themeProvider,
                              onEdit: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditTypeEquipmentPage(
                                    id: typeEquipment['_id'],
                                    initialTypeName: typeEquipment['typeName'],
                                    initialTypeEquip:
                                        typeEquipment['typeEquip'],
                                  ),
                                ),
                              ).then((shouldRefresh) {
                                if (shouldRefresh == true)
                                  _fetchTypeEquipments();
                              }),
                              onDelete: () =>
                                  _deleteTypeEquipment(typeEquipment['_id']),
                              onView: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TypeEquipDetailsPage(
                                    typeName: typeEquipment['typeName'],
                                    typeEquip: typeEquipment['typeEquip'],
                                    logo: typeEquipment['logo']?['path'],
                                    typeEquipmentId: typeEquipment['_id'],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: NavbarAdmin(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  // [Rest of the code remains unchanged...]
  Widget _buildSearchBar(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
        borderRadius: BorderRadius.circular(25.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (query) => setState(() => _searchQuery = query),
        decoration: InputDecoration(
          hintText: 'Search by type name...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
            fontFamily: 'Poppins',
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.white : Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 15.0,
          ),
        ),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildFilterChip('All', 'all', isDarkMode),
          _buildFilterChip('Hard', 'hard', isDarkMode),
          _buildFilterChip('Soft', 'soft', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDarkMode) {
    final bool isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.blue.shade600
                : isDarkMode
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : isDarkMode
                    ? Colors.white
                    : Colors.black,
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class TypeEquipmentCard extends StatelessWidget {
  final String typeName;
  final String typeEquip;
  final String? logo;
  final ThemeProvider themeProvider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const TypeEquipmentCard({
    Key? key,
    required this.typeName,
    required this.typeEquip,
    this.logo,
    required this.themeProvider,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeProvider.themeMode == ThemeMode.dark
            ? Colors.white.withOpacity(0.1)
            : const Color(0xFFe7eefe),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFffede6),
            backgroundImage: logo != null ? NetworkImage(logo!) : null,
            child: logo == null
                ? Icon(
                    Icons.build,
                    size: 30,
                    color: const Color(0xFFfda781),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeName,
                  style: TextStyle(
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Type: ${typeEquip.toLowerCase()}',
                  style: TextStyle(
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? const Color(0xFFB8B8D2)
                        : Colors.grey[700],
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: themeProvider.themeMode == ThemeMode.dark
                  ? Colors.white
                  : Colors.black,
              size: 24,
            ),
            onSelected: (String value) {
              if (value == 'view') onView();
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'view',
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      color: themeProvider.themeMode == ThemeMode.dark
                          ? Colors.white
                          : Colors.black,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View details',
                      style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: themeProvider.themeMode == ThemeMode.dark
                          ? Colors.white
                          : Colors.black,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: themeProvider.themeMode == ThemeMode.dark
                          ? Colors.white
                          : Colors.black,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: themeProvider.themeMode == ThemeMode.dark
                ? const Color(0xFF242E3E)
                : Colors.white,
          ),
        ],
      ),
    );
  }
}
