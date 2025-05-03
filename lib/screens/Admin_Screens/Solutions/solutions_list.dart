import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/widgets/navbar_admin.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';

class SolutionsListPage extends StatefulWidget {
  const SolutionsListPage({super.key});

  @override
  _SolutionsListPageState createState() => _SolutionsListPageState();
}

class _SolutionsListPageState extends State<SolutionsListPage> {
  List<dynamic> _solutions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSolutions();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
    final filteredSolutions = _filterSolutionsBySearch();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base'),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? const Color(0xFF242E3E)
          : Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchSolutions,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.blue,
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
                          color: themeProvider.themeMode == ThemeMode.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No solutions found'
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
                          AutocompleteSearchInput(
                            onChanged: (query) {
                              setState(() {
                                _searchQuery = query;
                              });
                            },
                            solutions: _solutions,
                          ),
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
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AutocompleteSearchInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final List<dynamic> solutions;

  const AutocompleteSearchInput({
    Key? key,
    required this.onChanged,
    required this.solutions,
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
      _suggestions = widget.solutions.where((solution) {
        final ticketTitle = solution['ticketTitle'].toString().toLowerCase();
        final solutionContent =
            solution['solutionContent'].toString().toLowerCase();
        final searchLower = cleanQuery.toLowerCase();

        return ticketTitle.contains(searchLower) ||
            solutionContent.contains(searchLower);
      }).toList();

      _showSuggestions = _suggestions.isNotEmpty;
    });
  }

  void _selectSuggestion(dynamic solution) {
    final searchText = solution['ticketTitle'];
    _controller.text =
        '${solution['ticketTitle']} - ${solution['solutionContent']}';
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
              hintText: 'Search by ticket title or solution...',
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
                final solution = _suggestions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFffede6),
                    child: Icon(
                      Icons.book,
                      color: const Color(0xFFfda781),
                    ),
                  ),
                  title: Text(
                    solution['ticketTitle'],
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    solution['solutionContent'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  onTap: () => _selectSuggestion(solution),
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
                  style: TextStyle(
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Solution: $solutionContent',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? const Color(0xFFB8B8D2)
                        : Colors.grey[700],
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Category: $category | Created by: $createdBy',
                  style: TextStyle(
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? const Color(0xFFB8B8D2)
                        : Colors.grey[600],
                    fontSize: 10,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.visibility,
              color: themeProvider.themeMode == ThemeMode.dark
                  ? Colors.white
                  : Colors.black,
            ),
            onPressed: () => onViewDetails(),
          ),
        ],
      ),
    );
  }
}
