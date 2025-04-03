import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
import 'package:provider/provider.dart';

class PendingUsersScreen extends StatefulWidget {
  const PendingUsersScreen({super.key});

  @override
  State<PendingUsersScreen> createState() => _PendingUsersScreenState();
}

class _PendingUsersScreenState extends State<PendingUsersScreen> {
  final UserService _userService = UserService();
  late Future<List<User>> _futurePendingUsers;

  @override
  void initState() {
    super.initState();
    _futurePendingUsers = _userService.getPendingUsers();
  }

  void _refreshPendingUsers() {
    setState(() {
      _futurePendingUsers = _userService.getPendingUsers();
    });
  }

  Future<void> _validateUser(String userId) async {
    try {
      await _userService.validateUser(userId);
      _refreshPendingUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur validé avec succès')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la validation: $error')),
      );
    }
  }

  Future<void> _rejectUser(String userId) async {
    try {
      await _userService.rejectUser(userId);
      _refreshPendingUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur rejeté avec succès')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du rejet: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs en Attente'),
      ),
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? const Color(0xFF242E3E)
          : Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshPendingUsers();
        },
        child: FutureBuilder<List<User>>(
          future: _futurePendingUsers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.blue,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erreur: ${snapshot.error}',
                  style: TextStyle(
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people,
                      size: 100,
                      color: themeProvider.themeMode == ThemeMode.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun utilisateur en attente',
                      style: TextStyle(
                        fontSize: 18,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              final pendingUsers = snapshot.data!;

              return SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      ...pendingUsers.map((user) {
                        final imageUrl = user.image
                            ?.path; // Directly use the path from the User object

                        // Check if imageUrl is null or empty
                        if (imageUrl == null || imageUrl.isEmpty) {
                          return const SizedBox(); // No valid image, return an empty widget
                        }

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
                                    Text(
                                      '${user.firstName} ${user.lastName}',
                                      style: TextStyle(
                                        color: themeProvider.themeMode ==
                                                ThemeMode.dark
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${user.email}',
                                      style: TextStyle(
                                        color: themeProvider.themeMode ==
                                                ThemeMode.dark
                                            ? const Color(0xFFB8B8D2)
                                            : Colors.grey[700],
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      'Rôle: ${user.authority}',
                                      style: TextStyle(
                                        color: themeProvider.themeMode ==
                                                ThemeMode.dark
                                            ? Colors.lightBlue
                                            : Colors.blue,
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    onPressed: () => _validateUser(user.id!),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () => _rejectUser(user.id!),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
    );
  }
}
