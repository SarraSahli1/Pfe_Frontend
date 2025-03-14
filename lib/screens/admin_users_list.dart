import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/screens/edit_user.dart';
import 'package:helpdeskfrontend/screens/pending_users_screen.dart';
import 'package:helpdeskfrontend/widgets/navbar_admin.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/screens/user_details.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
import 'package:helpdeskfrontend/widgets/search_input.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';

class AdminUsersList extends StatefulWidget {
  const AdminUsersList({super.key});

  @override
  State<AdminUsersList> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsersList> {
  final UserService _userService = UserService();
  late Future<List<dynamic>> _futureUsers;
  String _selectedRole = 'all';

  int _currentIndex = 0; // Pour suivre l'index actuel de la navbar

  void refreshUserList() {
    setState(() {
      _futureUsers = _userService.getAllUsers();
    });
  }

  @override
  void initState() {
    super.initState();
    _futureUsers = _userService.getAllUsers();
  }

  List<dynamic> _filterUsersByRole(List<dynamic> users, String role) {
    if (role == 'all') return users;
    return users.where((user) => user['authority'] == role).toList();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Ajoutez ici la logique pour naviguer entre les écrans
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users List'),
        actions: [
          IconButton(
            icon: const Icon(Icons
                .pending_actions), // Icône pour les utilisateurs en attente
            onPressed: () {
              // Naviguer vers PendingUsersScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PendingUsersScreen(),
                ),
              );
            },
          ),
          const ThemeToggleButton(), // Bouton de bascule de thème existant
        ],
      ),
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? const Color(0xFF242E3E)
          : Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _futureUsers = _userService.getAllUsers();
          });
        },
        child: FutureBuilder<List<dynamic>>(
          future: _futureUsers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(
                      color: themeProvider.themeMode == ThemeMode.dark
                          ? Colors.white
                          : Colors.blue));
            } else if (snapshot.hasError) {
              return Center(
                  child: Text('Erreur: ${snapshot.error}',
                      style: TextStyle(
                          color: themeProvider.themeMode == ThemeMode.dark
                              ? Colors.white
                              : Colors.black)));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people,
                        size: 100,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black),
                    const SizedBox(height: 16),
                    Text('Aucun utilisateur trouvé',
                        style: TextStyle(
                            fontSize: 18,
                            color: themeProvider.themeMode == ThemeMode.dark
                                ? Colors.white
                                : Colors.black)),
                  ],
                ),
              );
            } else {
              final users = _filterUsersByRole(snapshot.data!, _selectedRole);

              return SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 61),
                      Text('Users',
                          style: TextStyle(
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? const Color(0xFFF4F3FD)
                                  : Colors.black,
                              fontSize: 24,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 15),
                      const SearchInput(),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildFilterButton('All', 'all'),
                          const SizedBox(width: 20),
                          _buildFilterButton('Techniciens', 'technician'),
                          const SizedBox(width: 20),
                          _buildFilterButton('Clients', 'client'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ...users.map((user) {
                        final imageId = user['image'];
                        return FutureBuilder<Map<String, dynamic>>(
                          future: _userService.getFileInfo(imageId),
                          builder: (context, fileSnapshot) {
                            if (fileSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                  child: CircularProgressIndicator(
                                      color: themeProvider.themeMode ==
                                              ThemeMode.dark
                                          ? Colors.white
                                          : Colors.blue));
                            } else if (fileSnapshot.hasError) {
                              return Center(
                                  child: Text(
                                      'Erreur de chargement de l\'image',
                                      style: TextStyle(
                                          color: themeProvider.themeMode ==
                                                  ThemeMode.dark
                                              ? Colors.white
                                              : Colors.black)));
                            } else if (!fileSnapshot.hasData ||
                                fileSnapshot.data!['rows'] == null) {
                              return const SizedBox();
                            } else {
                              final fileInfo = fileSnapshot.data!['rows'];
                              final imageUrl = fileInfo['path'].replaceFirst(
                                  'http://localhost:3000',
                                  'http://192.168.1.18:3000');
                              return UserCard(
                                name:
                                    '${user['firstName']} ${user['lastName']}',
                                email: user['email'],
                                role: user['authority'],
                                imageUrl: imageUrl,
                                userId: user['_id'],
                                userEmail: user['email'],
                                userService: _userService,
                                themeProvider: themeProvider,
                              );
                            }
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
      bottomNavigationBar: NavbarAdmin(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ), // Ajoutez la navbar ici
    );
  }

  Widget _buildFilterButton(String label, String role) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedRole == role ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _selectedRole == role
                  ? Colors.blue
                  : themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black),
        ),
        child: Text(label,
            style: TextStyle(
                color: _selectedRole == role
                    ? Colors.white
                    : themeProvider.themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String imageUrl;
  final String userId;
  final String userEmail;
  final UserService userService;
  final ThemeProvider themeProvider;

  const UserCard({
    Key? key,
    required this.name,
    required this.email,
    required this.role,
    required this.imageUrl,
    required this.userId,
    required this.userEmail,
    required this.userService,
    required this.themeProvider,
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
            backgroundImage: NetworkImage(imageUrl),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500)),
                Text(email,
                    style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? const Color(0xFFB8B8D2)
                            : Colors.grey[700],
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400)),
                Text('Rôle: $role',
                    style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.lightBlue
                            : Colors.blue,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: themeProvider.themeMode == ThemeMode.dark
                    ? Colors.white
                    : Colors.black,
                size: 24),
            onSelected: (String value) async {
              switch (value) {
                case 'edit':
                  final User user = await userService.getUserById(userId);
                  final Map<String, dynamic> userData = user.toMap();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditUserScreen(
                        userId: userId,
                        userData: userData,
                      ),
                    ),
                  );
                  break;
                case 'delete':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete User'),
                      content:
                          Text('Are you sure you want to delete this user?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      final response = await userService.deleteUser(userEmail);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(response['message'])),
                      );

                      if (context.mounted) {
                        final adminUsersListState =
                            context.findAncestorStateOfType<_AdminUsersState>();
                        adminUsersListState?.refreshUserList();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting user: $e')),
                      );
                    }
                  }
                  break;
                case 'see':
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserDetailsScreen(userId: userId),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                        size: 18),
                    const SizedBox(width: 8),
                    Text('Edit',
                        style: TextStyle(
                            color: themeProvider.themeMode == ThemeMode.dark
                                ? Colors.white
                                : Colors.black,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                        size: 18),
                    const SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(
                            color: themeProvider.themeMode == ThemeMode.dark
                                ? Colors.white
                                : Colors.black,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'see',
                child: Row(
                  children: [
                    Icon(Icons.visibility,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                        size: 18),
                    const SizedBox(width: 8),
                    Text('See',
                        style: TextStyle(
                            color: themeProvider.themeMode == ThemeMode.dark
                                ? Colors.white
                                : Colors.black,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500)),
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
