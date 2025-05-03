import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Problems/CreateProblemPage.dart';
import 'package:helpdeskfrontend/screens/Admin_Screens/Problems/EditProblemPage%20.dart';
import 'package:helpdeskfrontend/services/problems_service.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';

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
  String _searchQuery = '';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading problems: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _deleteProblem(String problemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Problem'),
        content: const Text('Are you sure you want to delete this problem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _problemsService.deleteProblem(id: problemId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Problem deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProblems();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting problem: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _editProblem(String problemId, String nomProblem, String description) {
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
        _loadProblems();
      }
    });
  }

  List<dynamic> _filterProblems() {
    if (_searchQuery.isEmpty) return _problems;

    return _problems.where((problem) {
      final problemName = problem['nomProblem'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return problemName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final filteredProblems = _filterProblems();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Problems List', style: TextStyle(color: Colors.white)),
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFF628ff6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      backgroundColor: isDarkMode ? const Color(0xFF242E3E) : Colors.white,
      floatingActionButton: FloatingActionButton.extended(
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
              _loadProblems();
            }
          });
        },
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFF628ff6),
        icon: const Icon(Icons.add, color: Colors.white, size: 24),
        label: const Text(
          'Add Problem',
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _loadProblems,
        color: Colors.orange,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: isDarkMode ? Colors.white : Colors.orange,
                ),
              )
            : filteredProblems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.report_problem,
                          size: 100,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No problems found for this equipment'
                              : 'No results for "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDarkMode ? Colors.white : Colors.black,
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
                          Text(
                            'Associated Problems',
                            style: TextStyle(
                              color: isDarkMode
                                  ? const Color(0xFFF4F3FD)
                                  : Colors.black,
                              fontSize: 24,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ...filteredProblems.map((problem) {
                            return ProblemCard(
                              problemName: problem['nomProblem'],
                              problemDescription: problem['description'],
                              themeProvider: themeProvider,
                              onEdit: () => _editProblem(
                                problem['_id'],
                                problem['nomProblem'],
                                problem['description'],
                              ),
                              onDelete: () => _deleteProblem(problem['_id']),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

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
          hintText: 'Search by problem name...',
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
}

class ProblemCard extends StatelessWidget {
  final String problemName;
  final String problemDescription;
  final ThemeProvider themeProvider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode
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
              Icons.report_problem,
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
                  problemName,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  problemDescription,
                  style: TextStyle(
                    color:
                        isDarkMode ? const Color(0xFFB8B8D2) : Colors.grey[700],
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
              color: isDarkMode ? Colors.white : Colors.black,
              size: 24,
            ),
            onSelected: (String value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: isDarkMode ? Colors.white : Colors.black,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
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
                      color: isDarkMode ? Colors.white : Colors.black,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
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
            color: isDarkMode ? const Color(0xFF242E3E) : Colors.white,
          ),
        ],
      ),
    );
  }
}
