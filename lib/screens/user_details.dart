import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:provider/provider.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;

  const UserDetailsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final UserService _userService = UserService();
  late Future<User> _futureUser;

  @override
  void initState() {
    super.initState();
    _futureUser = _userService.getUserById(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? const Color(0xFF242E3E)
          : Colors.white,
      appBar: AppBar(
        title: Text(
          'Détails de l\'utilisateur',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeProvider.themeMode == ThemeMode.dark
            ? const Color(0xFF242E3E)
            : Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(), // Bouton de bascule de thème
        ],
      ),
      body: FutureBuilder<User>(
        future: _futureUser,
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
                'Erreur : ${snapshot.error}',
                style: TextStyle(
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Aucune donnée utilisateur trouvée',
                style: TextStyle(
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            );
          } else {
            final user = snapshot.data!;
            final imageUrl = _getImageUrl(user.image);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: BoxDecoration(
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      // Avatar circulaire
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE8EAED),
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 60,
                                color: themeProvider.themeMode == ThemeMode.dark
                                    ? Colors.white
                                    : Colors.grey[600],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Détails de l'utilisateur
                      _buildInfoSection(
                        context,
                        user: user,
                        themeProvider: themeProvider,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // Méthode pour construire la section des informations de l'utilisateur
  Widget _buildInfoSection(
    BuildContext context, {
    required User user,
    required ThemeProvider themeProvider,
  }) {
    final infoItems = [
      {
        'label': 'Nom',
        'value': '${user.firstName ?? "N/A"} ${user.lastName ?? "N/A"}'
      },
      {'label': 'Email', 'value': user.email ?? 'N/A'},
      {'label': 'Rôle', 'value': user.authority ?? 'N/A'},
      {'label': 'Téléphone', 'value': user.phoneNumber ?? 'N/A'},
      if (user.authority == 'technician') ..._buildTechnicianDetails(user),
      if (user.authority == 'client') ..._buildClientDetails(user),
    ];

    return Column(
      children: infoItems.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 150,
                child: Text(
                  item['label']!,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                child: item['label'] ==
                        'Signature (Image)' // Vérifiez si c'est la signature
                    ? Image.network(
                        item['value']!, // URL de l'image de signature
                        width: 150, // Ajustez la largeur selon vos besoins
                        height: 50, // Ajustez la hauteur selon vos besoins
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            'Erreur de chargement de l\'image',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          );
                        },
                      )
                    : Text(
                        item['value']!,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: themeProvider.themeMode == ThemeMode.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Méthode pour construire les détails spécifiques au technicien
  List<Map<String, String>> _buildTechnicianDetails(User user) {
    return [
      {'label': 'Email secondaire', 'value': user.secondEmail ?? 'N/A'},
      {
        'label': 'Permis de conduire',
        'value': user.permisConduire ? 'Oui' : 'Non'
      },
      {'label': 'Passeport', 'value': user.passeport ? 'Oui' : 'Non'},
      {'label': 'Date de naissance', 'value': _formatDate(user.birthDate)},
      {'label': 'Date d\'expiration', 'value': _formatDate(user.expiredAt)},
      {
        'label': 'Signature',
        'value': (user.signature ?? 'N/A').toString()
      }, // Conservez cette ligne si vous voulez afficher le texte
      {
        'label': 'Signature (Image)',
        'value': (user.signature ?? 'N/A').toString()
      }, // Ajoutez cette ligne pour l'URL de l'image
    ];
  }

  // Méthode pour construire les détails spécifiques au client
  List<Map<String, String>> _buildClientDetails(User user) {
    return [
      {'label': 'Entreprise', 'value': user.company ?? 'N/A'},
      {'label': 'À propos', 'value': user.about ?? 'N/A'},
      {'label': 'ID du dossier', 'value': user.folderId ?? 'N/A'},
    ];
  }

  // Méthode pour formater les dates
  String _formatDate(DateTime? date) {
    return date != null ? date.toLocal().toString() : 'N/A';
  }

  // Méthode pour obtenir l'URL de l'image
  String _getImageUrl(UserImage? image) {
    if (image == null || image.path == null) {
      return 'https://placehold.co/200x200/4299e1/4299e1'; // URL de secours
    }
    return image.path!.replaceFirst(
      'http://localhost:3000',
      'http://192.168.1.18:3000',
    );
  }
}
