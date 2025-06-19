import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Users/edit_user.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Users/pending_users_screen.dart';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:helpdeskfrontend/widgets/navbar_admin.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Users/user_details.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
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
  String _searchQuery = '';
  List<dynamic> _allUsers = [];

  void refreshUserList() {
    setState(() {
      _futureUsers = _userService.getAllUsers().then((users) {
        _allUsers = users;
        return users;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _futureUsers = _userService.getAllUsers().then((users) {
      _allUsers = users;
      return users;
    });
  }

  List<dynamic> _filterUsersByRole(List<dynamic> users, String role) {
    final filteredUsers =
        users.where((user) => user['authority'] != 'admin').toList();

    if (role == 'all') return filteredUsers;
    return filteredUsers.where((user) => user['authority'] == role).toList();
  }

  List<dynamic> _filterUsersBySearch(List<dynamic> users, String query) {
    if (query.isEmpty) return users;

    return users.where((user) {
      final firstName = user['firstName']?.toLowerCase() ?? '';
      final lastName = user['lastName']?.toLowerCase() ?? '';
      final fullName = '$firstName $lastName';
      final searchLower = query.toLowerCase();

      return firstName.contains(searchLower) ||
          lastName.contains(searchLower) ||
          fullName.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users List', style: TextStyle(color: Colors.white)),
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFF628ff6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.pending_actions, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PendingUsersScreen(),
                ),
              );
            },
          ),
          const ThemeToggleButton(),
        ],
      ),
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? const Color(0xFF242E3E)
          : Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _futureUsers = _userService.getAllUsers().then((users) {
              _allUsers = users;
              return users;
            });
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
              final roleFilteredUsers =
                  _filterUsersByRole(snapshot.data!, _selectedRole);
              final filteredUsers =
                  _filterUsersBySearch(roleFilteredUsers, _searchQuery);

              return SingleChildScrollView(
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
                        users: _allUsers,
                      ),
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
                      ...filteredUsers.map((user) {
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
                                  'http://localhost:3000', Config.baseUrl);
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
                                isSelected:
                                    false, // Ajout de la propriété isSelected
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
        currentIndex: 1,
        context: context,
      ),
    );
  }

  Widget _buildFilterButton(String label, String role) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedRole = role),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedRole == role
                  ? isDarkMode
                      ? Colors.blue.shade800
                      : Colors.blue
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedRole == role
                    ? isDarkMode
                        ? Colors.blue.shade600
                        : Colors.blue
                    : isDarkMode
                        ? Colors.white
                        : Colors.black,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: _selectedRole == role
                    ? Colors.white
                    : isDarkMode
                        ? Colors.white
                        : Colors.black,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        // Indicateur de sélection sous le bouton
        if (_selectedRole == role)
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue.shade600 : Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}

class AutocompleteSearchInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final List<dynamic> users;

  const AutocompleteSearchInput({
    Key? key,
    required this.onChanged,
    required this.users,
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
    widget.onChanged(query);

    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _suggestions = widget.users.where((user) {
        final firstName = user['firstName']?.toLowerCase() ?? '';
        final lastName = user['lastName']?.toLowerCase() ?? '';
        final fullName = '$firstName $lastName';
        final searchLower = query.toLowerCase();

        return firstName.contains(searchLower) ||
            lastName.contains(searchLower) ||
            fullName.contains(searchLower);
      }).toList();

      _showSuggestions = _suggestions.isNotEmpty;
    });
  }

  void _selectSuggestion(dynamic user) {
    final fullName = '${user['firstName']} ${user['lastName']}';
    _controller.text = fullName;
    widget.onChanged(fullName);
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
              hintText: 'Search users...',
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
                final user = _suggestions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['image']?['path'] ?? ''),
                  ),
                  title: Text(
                    '${user['firstName']} ${user['lastName']}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  subtitle: Text(
                    user['email'],
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onTap: () => _selectSuggestion(user),
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

class UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String imageUrl;
  final String userId;
  final String userEmail;
  final UserService userService;
  final ThemeProvider themeProvider;
  final bool isSelected;

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
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        border: isSelected
            ? Border(
                left: BorderSide(
                  color: isDarkMode ? Colors.blue.shade600 : Colors.blue,
                  width: 4,
                ),
              )
            : null,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserDetailsScreen(userId: userId),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? isSelected
                      ? Colors.blue.shade900.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1)
                  : isSelected
                      ? Colors.blue.shade100
                      : const Color(0xFFe7eefe),
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
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500)),
                      Text(email,
                          style: TextStyle(
                              color: isDarkMode
                                  ? const Color(0xFFB8B8D2)
                                  : Colors.grey[700],
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400)),
                      Text('Rôle: $role',
                          style: TextStyle(
                              color:
                                  isDarkMode ? Colors.lightBlue : Colors.blue,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: isDarkMode ? Colors.white : Colors.black,
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
                            content: Text(
                                'Are you sure you want to delete this user?'),
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
                            final response =
                                await userService.deleteUser(userEmail);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response['message'])),
                            );

                            if (context.mounted) {
                              final adminUsersListState = context
                                  .findAncestorStateOfType<_AdminUsersState>();
                              adminUsersListState?.refreshUserList();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error deleting user: $e')),
                            );
                          }
                        }
                        break;
                      case 'see':
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserDetailsScreen(userId: userId),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit,
                              color: isDarkMode ? Colors.white : Colors.black,
                              size: 18),
                          const SizedBox(width: 8),
                          Text('Edit',
                              style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
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
                              color: isDarkMode ? Colors.white : Colors.black,
                              size: 18),
                          const SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
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
                              color: isDarkMode ? Colors.white : Colors.black,
                              size: 18),
                          const SizedBox(width: 8),
                          Text('See',
                              style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
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
                  color: isDarkMode ? const Color(0xFF242E3E) : Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
