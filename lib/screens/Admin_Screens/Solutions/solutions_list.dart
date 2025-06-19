import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/widgets/navbar_admin.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';
import 'package:google_fonts/google_fonts.dart';

class SolutionsListPage extends StatefulWidget {
  const SolutionsListPage({super.key});

  @override
  _SolutionsListPageState createState() => _SolutionsListPageState();
}

class _SolutionsListPageState extends State<SolutionsListPage> {
  List<dynamic> _solutions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSolutions();
  }

  Future<void> _fetchSolutions() async {
    try {
      final solutions = await TicketService.getAllSolutions();
      if (!mounted) return;
      setState(() {
        _solutions = solutions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading solutions: $e'),
        ),
      );
    }
  }

  List<dynamic> _filterSolutionsBySearch() {
    if (_searchQuery.isEmpty) return _solutions;

    return _solutions.where((solution) {
      final ticketTitle = solution['ticketTitle'].toString().toLowerCase();
      final solutionContent =
          solution['solutionContent'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return ticketTitle.contains(query) || solutionContent.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final filteredSolutions = _filterSolutionsBySearch();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Knowledge Base',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFF628ff6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      backgroundColor: isDarkMode ? const Color(0xFF242E3E) : Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchSolutions,
        color: Colors.orange,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: isDarkMode ? Colors.white : Colors.blue,
                ),
              )
            : filteredSolutions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book,
                          size: 100,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No solutions found'
                              : 'No results for "$_searchQuery"',
                          style: GoogleFonts.poppins(
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
                          _buildSearchBar(isDarkMode),
                          const SizedBox(height: 30),
                          ...filteredSolutions.map((solution) {
                            return SolutionCard(
                              ticketTitle: solution['ticketTitle'],
                              solutionContent: solution['solutionContent'],
                              category: solution['category'],
                              createdBy: solution['createdBy'],
                              themeProvider: themeProvider,
                              onViewDetails: () {
                                // Add navigation to a details page if needed
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: NavbarAdmin(
        currentIndex: 3,
        context: context,
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
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
        onChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by ticket title or solution...',
          hintStyle: GoogleFonts.poppins(
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.white : Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        ),
        style: GoogleFonts.poppins(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class SolutionCard extends StatelessWidget {
  final String ticketTitle;
  final String solutionContent;
  final String category;
  final String createdBy;
  final ThemeProvider themeProvider;
  final Function onViewDetails;

  const SolutionCard({
    Key? key,
    required this.ticketTitle,
    required this.solutionContent,
    required this.category,
    required this.createdBy,
    required this.themeProvider,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.1)
            : const Color(0xFFe7eefe),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: () => onViewDetails(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFffede6),
                child: Icon(
                  Icons.book,
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
                      ticketTitle,
                      style: GoogleFonts.poppins(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solution: $solutionContent',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: isDarkMode
                            ? const Color(0xFFB8B8D2)
                            : Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: $category | Created by: $createdBy',
                      style: GoogleFonts.poppins(
                        color: isDarkMode
                            ? const Color(0xFFB8B8D2)
                            : Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.visibility,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () => onViewDetails(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
