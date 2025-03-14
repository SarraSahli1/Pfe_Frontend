import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/edit_typeEquip.dart';
import 'package:helpdeskfrontend/screens/create_typeEquip.dart'; // Importez la page de création
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
  String _selectedFilter = 'all'; // 'all', 'hard', 'soft'
  int _currentIndex = 0; // Pour suivre l'index actuel de la navbar

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

      print("Données récupérées: $_typeEquipments");
    } catch (e) {
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

  Future<void> _deleteTypeEquipment(String id) async {
    try {
      final response = await _typeEquipmentService.deleteTypeEquipment(id: id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'])),
      );
      _fetchTypeEquipments(); // Rafraîchir la liste après la suppression
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  void _editTypeEquipment(String id, String typeName, String typeEquip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTypeEquipmentPage(
          id: id,
          initialTypeName: typeName,
          initialTypeEquip: typeEquip,
        ),
      ),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        _fetchTypeEquipments(); // Rafraîchir la liste après la mise à jour
      }
    });
  }

  List<dynamic> _filterTypeEquipments() {
    if (_selectedFilter == 'all') return _typeEquipments;

    return _typeEquipments.where((equipment) {
      if (equipment['typeEquip'] != null) {
        return equipment['typeEquip'].toString().trim().toLowerCase() ==
            _selectedFilter;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final filteredTypeEquipments = _filterTypeEquipments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des équipements'),
        actions: [
          IconButton(
            icon: Icon(Icons.add), // Icône "+"
            onPressed: () {
              // Redirige vers la page de création
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTypeEquipmentPage(),
                ),
              ).then((shouldRefresh) {
                if (shouldRefresh == true) {
                  _fetchTypeEquipments(); // Rafraîchir la liste après la création
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
        onRefresh: _fetchTypeEquipments,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.blue,
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
                          'Aucun équipement trouvé',
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
                          const SizedBox(height: 61),
                          Text(
                            'Types d\'équipements',
                            style: TextStyle(
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? const Color(0xFFF4F3FD)
                                  : Colors.black,
                              fontSize: 24,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildFilterButton('Tous', 'all', themeProvider),
                              const SizedBox(width: 20),
                              _buildFilterButton('hard', 'hard', themeProvider),
                              const SizedBox(width: 20),
                              _buildFilterButton('soft', 'soft', themeProvider),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ...filteredTypeEquipments.map((typeEquipment) {
                            return TypeEquipmentCard(
                              typeName: typeEquipment['typeName'],
                              typeEquip: typeEquipment['typeEquip'],
                              logo: typeEquipment['logo'] != null
                                  ? typeEquipment['logo']['path']
                                  : null,
                              themeProvider: themeProvider,
                              onEdit: () => _editTypeEquipment(
                                typeEquipment['_id'],
                                typeEquipment['typeName'],
                                typeEquipment['typeEquip'],
                              ),
                              onDelete: () =>
                                  _deleteTypeEquipment(typeEquipment['_id']),
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

  Widget _buildFilterButton(
      String label, String filter, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        print("Filtre sélectionné: $_selectedFilter");
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedFilter == filter ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedFilter == filter
                ? Colors.blue
                : themeProvider.themeMode == ThemeMode.dark
                    ? Colors.white
                    : Colors.black,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _selectedFilter == filter
                ? Colors.white
                : themeProvider.themeMode == ThemeMode.dark
                    ? Colors.white
                    : Colors.black,
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
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
  final Function onEdit; // Callback pour l'édition
  final Function onDelete; // Callback pour la suppression

  const TypeEquipmentCard({
    Key? key,
    required this.typeName,
    required this.typeEquip,
    this.logo,
    required this.themeProvider,
    required this.onEdit,
    required this.onDelete,
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
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: logo != null ? NetworkImage(logo!) : null,
            child: logo == null ? Icon(Icons.build, size: 30) : null,
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
                  typeEquip,
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
                onEdit(); // Appeler la fonction d'édition
              } else if (value == 'delete') {
                onDelete(); // Appeler la fonction de suppression
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
