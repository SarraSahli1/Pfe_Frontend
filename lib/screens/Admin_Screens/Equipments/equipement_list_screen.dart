import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Equipments/create_equipement.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Equipments/edit_equipment_screen.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Equipments/equipment_details_page.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/widgets/navbar_admin.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';

class EquipmentListPage extends StatefulWidget {
  const EquipmentListPage({super.key});

  @override
  _EquipmentListPageState createState() => _EquipmentListPageState();
}

class _EquipmentListPageState extends State<EquipmentListPage> {
  final EquipmentService _equipmentService = EquipmentService();
  List<dynamic> _equipments = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchEquipments();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _fetchEquipments() async {
    try {
      final equipments = await _equipmentService.getAllEquipment();
      if (!mounted) return;
      setState(() {
        _equipments = equipments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des équipements: $e'),
        ),
      );
    }
  }

  Future<void> _deleteEquipment(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer l\'équipement'),
        content: Text('Êtes-vous sûr de vouloir supprimer cet équipement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _equipmentService.deleteEquipment(id: id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
        _fetchEquipments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  void _editEquipment(
    String id,
    String serialNumber,
    String designation,
    dynamic typeEquipment,
    String version,
    String barcode,
  ) {
    String? typeEquipmentId;
    if (typeEquipment is Map<String, dynamic>) {
      typeEquipmentId = typeEquipment['_id'];
    } else if (typeEquipment is String) {
      typeEquipmentId = typeEquipment;
    } else {
      typeEquipmentId = null;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEquipmentPage(
          id: id,
          serialNumber: serialNumber,
          designation: designation,
          version: version,
          barcode: barcode,
          typeEquipmentId: typeEquipmentId,
        ),
      ),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        _fetchEquipments();
      }
    });
  }

  void _viewEquipmentDetails(String equipmentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentDetailsPage(
          equipmentId: equipmentId,
        ),
      ),
    );
  }

  List<dynamic> _filterEquipmentsBySearch() {
    if (_searchQuery.isEmpty) return _equipments;

    return _equipments.where((equipment) {
      final serialNumber = equipment['serialNumber'].toString().toLowerCase();
      final designation = equipment['designation'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return serialNumber.contains(query) || designation.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final filteredEquipments = _filterEquipmentsBySearch();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipements'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showCreateEquipmentModal(context).then((shouldRefresh) {
                if (shouldRefresh == true) {
                  _fetchEquipments();
                }
              });
            },
          ),
          const ThemeToggleButton(),
        ],
      ),
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? const Color(0xFF242E3E)
          : Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchEquipments,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.blue,
                ),
              )
            : filteredEquipments.isEmpty
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
                              ? 'Aucun équipement trouvé'
                              : 'Aucun résultat pour "$_searchQuery"',
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
                          AutocompleteSearchInput(
                            onChanged: (query) {
                              setState(() {
                                _searchQuery = query;
                              });
                            },
                            equipments: _equipments,
                          ),
                          const SizedBox(height: 30),
                          ...filteredEquipments.map((equipment) {
                            return EquipmentCard(
                              serialNumber: equipment['serialNumber'],
                              designation: equipment['designation'],
                              themeProvider: themeProvider,
                              onEdit: () => _editEquipment(
                                equipment['_id'],
                                equipment['serialNumber'],
                                equipment['designation'],
                                equipment['TypeEquipment'],
                                equipment['version'] ?? '',
                                equipment['barcode'] ?? '',
                              ),
                              onDelete: () =>
                                  _deleteEquipment(equipment['_id']),
                              onViewDetails: () => _viewEquipmentDetails(
                                equipment['_id'],
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
}

class AutocompleteSearchInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final List<dynamic> equipments;

  const AutocompleteSearchInput({
    Key? key,
    required this.onChanged,
    required this.equipments,
  }) : super(key: key);

  @override
  _AutocompleteSearchInputState createState() =>
      _AutocompleteSearchInputState();
}

class _AutocompleteSearchInputState extends State<AutocompleteSearchInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<dynamic> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
    });
  }

  void _onSearchChanged() {
    final query = _controller.text;
    final cleanQuery = query.split(' - ').first.trim();
    widget.onChanged(cleanQuery);

    if (cleanQuery.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _suggestions = widget.equipments.where((equipment) {
        final serialNumber = equipment['serialNumber'].toString().toLowerCase();
        final designation = equipment['designation'].toString().toLowerCase();
        final searchLower = cleanQuery.toLowerCase();

        return serialNumber.contains(searchLower) ||
            designation.contains(searchLower);
      }).toList();

      _showSuggestions = _suggestions.isNotEmpty;
    });
  }

  void _selectSuggestion(dynamic equipment) {
    final searchText = equipment['serialNumber'];
    _controller.text =
        '${equipment['serialNumber']} - ${equipment['designation']}';
    widget.onChanged(searchText);
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Column(
      children: [
        Container(
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
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Search by serial number or designation...',
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
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final equipment = _suggestions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFffede6),
                    child: Icon(
                      Icons.build,
                      color: const Color(0xFFfda781),
                    ),
                  ),
                  title: Text(
                    equipment['serialNumber'],
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    equipment['designation'],
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onTap: () => _selectSuggestion(equipment),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class EquipmentCard extends StatelessWidget {
  final String serialNumber;
  final String designation;
  final ThemeProvider themeProvider;
  final Function onEdit;
  final Function onDelete;
  final Function onViewDetails;

  const EquipmentCard({
    Key? key,
    required this.serialNumber,
    required this.designation,
    required this.themeProvider,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
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
            child: Icon(
              Icons.build,
              size: 30,
              color: const Color(0xFFfda781),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SN: $serialNumber',
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
                  'Désignation: $designation',
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
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              } else if (value == 'view') {
                onViewDetails();
              }
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
                      'Voir les détails',
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
              borderRadius: BorderRadius.circular(10),
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
