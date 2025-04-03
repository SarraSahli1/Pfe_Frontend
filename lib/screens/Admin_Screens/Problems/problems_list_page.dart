import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Problems/CreateProblemPage.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Problems/EditProblemPage%20.dart';
import 'package:helpdeskfrontend/services/problems_service.dart'; // Importez le service des problèmes
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart'; // Importez le bouton de thème

class ProblemsListPage extends StatefulWidget {
  final String typeEquipmentId;

  const ProblemsListPage({Key? key, required this.typeEquipmentId})
      : super(key: key);

  @override
  _ProblemsListPageState createState() => _ProblemsListPageState();
}

class _ProblemsListPageState extends State<ProblemsListPage> {
  final ProblemsService _problemsService = ProblemsService();
  List<dynamic> _problems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProblems();
  }

  Future<void> _loadProblems() async {
    try {
      final problems = await _problemsService.getAllProblems(
          typeEquipmentId: widget.typeEquipmentId);
      setState(() {
        _problems = problems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading problems: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProblem(String problemId) async {
    try {
      await _problemsService.deleteProblem(id: problemId);
      _loadProblems(); // Rafraîchir la liste après la suppression
    } catch (e) {
      print('Error deleting problem: $e');
    }
  }

  void _editProblem(String problemId, String nomProblem, String description) {
    // Naviguer vers la page d'édition du problème
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProblemPage(
          problemId: problemId,
          initialNomProblem: nomProblem,
          initialDescription: description,
        ),
      ),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        _loadProblems(); // Rafraîchir la liste après l'édition
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des problèmes'),
        actions: [
          const ThemeToggleButton(), // Bouton de changement de thème
        ],
      ),
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? const Color(0xFF242E3E)
          : Colors.white,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: themeProvider.themeMode == ThemeMode.dark
                    ? Colors.white
                    : Colors.blue,
              ),
            )
          : _problems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.report_problem,
                        size: 100,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun problème trouvé pour cet équipement.',
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Problèmes associés',
                              style: TextStyle(
                                color: themeProvider.themeMode == ThemeMode.dark
                                    ? const Color(0xFFF4F3FD)
                                    : Colors.black,
                                fontSize: 24,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add), // Bouton "+"
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateProblemPage(
                                      typeEquipmentId: widget.typeEquipmentId,
                                    ),
                                  ),
                                ).then((shouldRefresh) {
                                  if (shouldRefresh == true) {
                                    _loadProblems(); // Rafraîchir la liste après la création
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ..._problems.map((problem) {
                          return ProblemCard(
                              problemName: problem['nomProblem'],
                              problemDescription: problem['description'],
                              themeProvider: themeProvider,
                              onEdit: () => _editProblem(
                                    problem['_id'],
                                    problem['nomProblem'],
                                    problem['description'],
                                  ),
                              onDelete: () => _deleteProblem(problem['_id']));
                        }).toList(),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class ProblemCard extends StatelessWidget {
  final String problemName;
  final String problemDescription;
  final ThemeProvider themeProvider;
  final Function onEdit; // Callback pour l'édition
  final Function onDelete; // Callback pour la suppression

  const ProblemCard({
    Key? key,
    required this.problemName,
    required this.problemDescription,
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
            child: Icon(
              Icons.report_problem,
              size: 30,
              color: themeProvider.themeMode == ThemeMode.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  problemName,
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
                  problemDescription,
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
                      'Éditer',
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
                      'Supprimer',
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
