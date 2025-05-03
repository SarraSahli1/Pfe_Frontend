import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:intl/intl.dart';

class SolutionPage extends StatefulWidget {
  final String ticketId;
  final String solutionId;
  final String token;
  final String currentUserId;

  const SolutionPage({
    Key? key,
    required this.ticketId,
    required this.solutionId,
    required this.token,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<SolutionPage> createState() => _SolutionPageState();
}

class _SolutionPageState extends State<SolutionPage> {
  late Future<Map<String, dynamic>> _solutionFuture;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  bool _isValidating = false;

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

  Future<void> _validateSolution() async {
    if (_isValidating) return;

    setState(() {
      _isValidating = true;
    });

    try {
      final result = await TicketService.validateSolution(
        ticketId: widget.ticketId,
        token: widget.token,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Solution validée avec succès'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _loadSolution();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  Widget _buildValidationButton(bool isValid) {
    if (isValid) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ElevatedButton.icon(
        onPressed: _isValidating ? null : _validateSolution,
        icon: _isValidating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check_circle_outline, size: 24),
        label: Text(
          _isValidating ? 'Validation en cours...' : 'Valider cette solution',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildSolutionStatus(bool isValid) {
    return Chip(
      label: Text(
        isValid ? 'Validée' : 'En attente',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isValid ? Colors.green : Colors.orange,
      avatar: Icon(
        isValid ? Icons.check : Icons.access_time,
        color: Colors.white,
        size: 18,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Color(0xFF141218), Color(0xFF242E3E)]
                : [Color(0xFF628FF6).withOpacity(0.8), Color(0xFFF7F9F5)],
            stops: [0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Détails de la Solution',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white, size: 28),
                      onPressed: _loadSolution,
                      tooltip: 'Rafraîchir',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color(0xFF242E3E) : Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _solutionFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 60, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                'Erreur de chargement',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32.0),
                                child: Text(
                                  '${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadSolution,
                                icon: Icon(Icons.refresh, size: 20),
                                label: Text('Réessayer',
                                    style: GoogleFonts.poppins(fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
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
                              Icon(Icons.info_outline,
                                  size: 60, color: Colors.blue),
                              SizedBox(height: 16),
                              Text(
                                'Aucune donnée disponible',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final solution = snapshot.data!;
                      final isValid = solution['valid'] ?? false;

                      return Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Card
                                  Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    color: isDarkMode
                                        ? Color(0xFF3A4352)
                                        : Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Solution #${solution['_id']?.substring(0, 6) ?? ''}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                              _buildSolutionStatus(isValid),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Pour le ticket #${solution['ticketNumber'] ?? 'N/A'}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  // Solution Content
                                  Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    color: isDarkMode
                                        ? Color(0xFF3A4352)
                                        : Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.description,
                                                  color: Colors.orange,
                                                  size: 24),
                                              SizedBox(width: 8),
                                              Text(
                                                'Description de la solution',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Divider(
                                              color: isDarkMode
                                                  ? Colors.grey[600]
                                                  : Colors.grey[300]),
                                          SizedBox(height: 12),
                                          Text(
                                            solution['content'] ??
                                                'Aucun contenu disponible',
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  // Metadata
                                  Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    color: isDarkMode
                                        ? Color(0xFF3A4352)
                                        : Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Détails techniques',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Divider(
                                              color: isDarkMode
                                                  ? Colors.grey[600]
                                                  : Colors.grey[300]),
                                          SizedBox(height: 8),
                                          _buildInfoRow(
                                            context,
                                            'Créée le:',
                                            solution['createdAt'] != null
                                                ? _dateFormat.format(
                                                    DateTime.parse(
                                                        solution['createdAt']))
                                                : 'Date inconnue',
                                          ),
                                          _buildInfoRow(
                                            context,
                                            'Mise à jour:',
                                            solution['updatedAt'] != null
                                                ? _dateFormat.format(
                                                    DateTime.parse(
                                                        solution['updatedAt']))
                                                : 'Date inconnue',
                                          ),
                                          _buildInfoRow(
                                            context,
                                            'Validée le:',
                                            solution['validatedAt'] != null
                                                ? _dateFormat.format(
                                                    DateTime.parse(solution[
                                                        'validatedAt']))
                                                : 'Non validée',
                                            valueColor:
                                                solution['validatedAt'] != null
                                                    ? Colors.green
                                                    : Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildValidationButton(isValid),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color:
                    valueColor ?? (isDarkMode ? Colors.white : Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
