import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:intl/intl.dart';
import 'package:helpdeskfrontend/screens/Technicien_Screens/create_solution_page.dart';
import 'package:google_fonts/google_fonts.dart';

class SolutionDetailsPage extends StatefulWidget {
  final String ticketId;
  final String solutionId;
  final String token;
  final String currentUserId;

  const SolutionDetailsPage({
    Key? key,
    required this.ticketId,
    required this.solutionId,
    required this.token,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<SolutionDetailsPage> createState() => _SolutionDetailsPageState();
}

class _SolutionDetailsPageState extends State<SolutionDetailsPage> {
  late Future<Map<String, dynamic>> _solutionFuture;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadSolution();
  }

  void _loadSolution() {
    setState(() {
      _solutionFuture = TicketService.getSolutionDetails(
        solutionId: widget.solutionId,
        token: widget.token,
      );
    });
  }

  Future<void> _editSolution(String currentSolution) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSolutionPage(
          ticketId: widget.ticketId,
          solutionId: widget.solutionId,
          token: widget.token,
          currentUserId: widget.currentUserId,
          initialSolution: currentSolution,
        ),
      ),
    );

    if (result == true) {
      _loadSolution();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solution mise à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails de la Solution',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSolution,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final snapshot = await _solutionFuture;
              if (snapshot.isNotEmpty) {
                final currentSolution = snapshot['content'] ?? '';
                _editSolution(currentSolution);
              }
            },
            tooltip: 'Modifier la Solution',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _solutionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSolution,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune donnée disponible',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          final solution = snapshot.data!;
          final isValid = solution['valid'] ?? false;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with ticket info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isValid ? Icons.check_circle : Icons.info,
                          color: isValid ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Solution pour le ticket #${solution['ticketNumber'] ?? 'N/A'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Statut: ${isValid ? 'Validée' : 'Non validée'}',
                                style: TextStyle(
                                  color: isValid ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Solution content card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Contenu de la solution',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            solution['content'] ?? 'Aucun contenu disponible',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Metadata section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            context,
                            'Créée le:',
                            solution['createdAt'] != null
                                ? _dateFormat.format(
                                    DateTime.parse(solution['createdAt']))
                                : 'Date inconnue',
                          ),
                          _buildInfoRow(
                            context,
                            'Modifiée le:',
                            solution['updatedAt'] != null
                                ? _dateFormat.format(
                                    DateTime.parse(solution['updatedAt']))
                                : 'Non modifiée',
                          ),
                          _buildInfoRow(
                            context,
                            'Validée:',
                            isValid ? 'Oui' : 'Non',
                            valueColor: isValid ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Edit button at bottom
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier cette solution'),
                      onPressed: () async {
                        final currentSolution = solution['content'] ?? '';
                        _editSolution(currentSolution);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color:
                    valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
