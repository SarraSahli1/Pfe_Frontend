import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/models/technicien.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/services/technicien_service.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/navbar_admin.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminTicketDetailsPage extends StatefulWidget {
  final String ticketId;

  const AdminTicketDetailsPage({Key? key, required this.ticketId})
      : super(key: key);

  @override
  State<AdminTicketDetailsPage> createState() => _AdminTicketDetailsPageState();
}

class _AdminTicketDetailsPageState extends State<AdminTicketDetailsPage> {
  late Future<Ticket> _ticketFuture;
  String? _selectedTechnicianId;
  List<Technicien> _technicians = [];
  bool _isAssigning = false;
  User? _client;
  bool _isLoadingClient = false;
  bool _isExpandedDescription = false;
  final Map<String, Map<String, dynamic>> _equipmentCache = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _loadTicket();
    _loadTechnicians();
  }

  void _loadTicket() {
    setState(() {
      _ticketFuture = TicketService.getAdminTicketDetails(widget.ticketId)
          .then((ticket) async {
        await _loadClientInfo(ticket.clientId);
        return ticket;
      }).catchError((error) {
        throw error;
      });
    });
  }

  Future<void> _loadClientInfo(String clientId) async {
    if (clientId.isEmpty) return;

    setState(() {
      _isLoadingClient = true;
    });
    try {
      final client = await UserService().getUserById(clientId);
      setState(() {
        _client = client;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec du chargement du client: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoadingClient = false;
      });
    }
  }

  Future<void> _loadTechnicians() async {
    try {
      final technicians = await TechnicienService.getTechnicians();
      setState(() {
        _technicians = technicians;
        if (technicians.isNotEmpty) {
          _selectedTechnicianId = technicians.first.id;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec du chargement des techniciens: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _getEquipmentDetails(String equipmentId) async {
    if (_equipmentCache.containsKey(equipmentId)) {
      return _equipmentCache[equipmentId]!;
    }

    try {
      final details =
          await EquipmentService().getEquipmentDetails(id: equipmentId);
      _equipmentCache[equipmentId] = details;
      return details;
    } catch (e) {
      debugPrint('Error fetching equipment details: $e');
      return {'designation': equipmentId};
    }
  }

  bool _shouldShowAssignButton(Ticket ticket) {
    return ticket.status != 'Assigned' &&
        ticket.status != 'Closed' &&
        ticket.status != 'Resolved' &&
        _technicians.isNotEmpty &&
        (ticket.technicienIds == null || ticket.technicienIds!.isEmpty);
  }

  Future<void> _assignTechnician() async {
    if (_selectedTechnicianId == null) return;

    setState(() {
      _isAssigning = true;
    });

    try {
      await TicketService.assignTechnicianToTicket(
        ticketId: widget.ticketId,
        technicienId: _selectedTechnicianId!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Technicien assigné avec succès!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _loadTicket();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isAssigning = false;
      });
    }
  }

  Widget _buildEquipmentItem(String equipmentId, bool isDarkMode) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getEquipmentDetails(equipmentId),
      builder: (context, snapshot) {
        String displayText;
        if (snapshot.hasError) {
          displayText = 'Erreur de chargement ($equipmentId)';
        } else if (snapshot.hasData) {
          displayText = snapshot.data!['designation'] ?? equipmentId;
        } else {
          displayText = equipmentId;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      SizedBox(
                        height: 2,
                        width: 100,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.white : Colors.blue,
                          ),
                        ),
                      ),
                    if (snapshot.hasError)
                      Text(
                        'Tapez pour réessayer',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
              if (snapshot.hasError)
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 18,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    setState(() {
                      _equipmentCache.remove(equipmentId);
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails du Ticket',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFF628ff6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
            color: Colors.white,
          ),
        ],
      ),
      backgroundColor: isDarkMode ? const Color(0xFF242E3E) : Colors.white,
      body: FutureBuilder<Ticket>(
        future: _ticketFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: ErrorWidget(
                error: snapshot.error.toString(),
                onRetry: _loadData,
                isDarkMode: isDarkMode,
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'Aucune donnée de ticket disponible',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
            );
          }

          final ticket = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildTicketHeader(ticket, isDarkMode),
                        const SizedBox(height: 24),
                        _buildClientSection(ticket, isDarkMode),
                        if ((ticket.technicienIds ?? []).isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildTechniciansSection(ticket, isDarkMode),
                        ],
                        if ((ticket.equipmentHardIds ?? []).isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildEquipmentSection(
                            'Matériel',
                            ticket.equipmentHardIds!,
                            Icons.computer,
                            isDarkMode,
                          ),
                        ],
                        if ((ticket.equipmentSoftIds ?? []).isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildEquipmentSection(
                            'Logiciel',
                            ticket.equipmentSoftIds!,
                            Icons.phone_android,
                            isDarkMode,
                          ),
                        ],
                        if ((ticket.fileUrls ?? []).isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildAttachmentsSection(ticket, isDarkMode),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              if (_shouldShowAssignButton(ticket))
                _buildAssignTechnicianSection(isDarkMode),
            ],
          );
        },
      ),
      bottomNavigationBar: NavbarAdmin(currentIndex: 3, context: context),
    );
  }

  Widget _buildTicketHeader(Ticket ticket, bool isDarkMode) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(ticket.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(ticket.status),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  ticket.status,
                  style: GoogleFonts.poppins(
                    color: _getStatusColor(ticket.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${ticket.id}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailItem(
                label: 'Description',
                value: ticket.description,
                icon: Icons.description,
                isDarkMode: isDarkMode,
              ),
              if (ticket.description.length > 100) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpandedDescription = !_isExpandedDescription;
                      });
                    },
                    child: Text(
                      _isExpandedDescription ? 'Voir moins' : 'Voir plus',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _DetailItem(
                label: 'Type',
                value: ticket.typeTicket,
                icon: Icons.category,
                isDarkMode: isDarkMode,
              ),
              _DetailItem(
                label: 'Créé le',
                value: DateFormat('dd MMM yyyy • HH:mm')
                    .format(ticket.creationDate),
                icon: Icons.calendar_today,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection(Ticket ticket, bool isDarkMode) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                size: 20,
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Client',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingClient)
            Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
            )
          else if (_client == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations client non disponibles',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                if (ticket.clientId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ID Client: ${ticket.clientId}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _loadClientInfo(ticket.clientId),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: isDarkMode ? Colors.white : Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Réessayer',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.blue,
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_client!.firstName} ${_client!.lastName}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (_client!.email != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 16,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _client!.email!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ],
                if (_client!.phoneNumber != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _client!.phoneNumber!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTicketDetailsSection(Ticket ticket, bool isDarkMode) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                size: 20,
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Détails du Ticket',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ticket.assignedDate != null)
            _DetailItem(
              label: 'Assigné le',
              value: DateFormat('dd MMM yyyy • HH:mm')
                  .format(ticket.assignedDate!),
              icon: Icons.person_add,
              isDarkMode: isDarkMode,
            ),
          if (ticket.resolvedDate != null)
            _DetailItem(
              label: 'Résolu le',
              value: DateFormat('dd MMM yyyy • HH:mm')
                  .format(ticket.resolvedDate!),
              icon: Icons.check_circle,
              isDarkMode: isDarkMode,
            ),
          if (ticket.closedDate != null)
            _DetailItem(
              label: 'Fermé le',
              value:
                  DateFormat('dd MMM yyyy • HH:mm').format(ticket.closedDate!),
              icon: Icons.lock_clock,
              isDarkMode: isDarkMode,
            ),
        ],
      ),
    );
  }

  Widget _buildTechniciansSection(Ticket ticket, bool isDarkMode) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.engineering,
                size: 20,
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Techniciens Assignés',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ticket.technicienIds!.map((techId) => FutureBuilder<Technicien?>(
                future: _getTechnicianDetails(techId),
                builder: (context, snapshot) {
                  final tech = snapshot.data;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tech != null) ...[
                          Text(
                            tech.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.email,
                                size: 16,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tech.email,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          if (tech.phoneNumber != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tech.phoneNumber!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ] else ...[
                          Text(
                            'Technicien ID: $techId',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection(
      String title, List<String> equipmentIds, IconData icon, bool isDarkMode) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...equipmentIds.map(
              (equipmentId) => _buildEquipmentItem(equipmentId, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(Ticket ticket, bool isDarkMode) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: 20,
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Pièces Jointes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ticket.fileUrls!
                .map((file) => Chip(
                      avatar: Icon(
                        Icons.attach_file,
                        size: 18,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                      label: Text(
                        file.split('/').last.length > 20
                            ? '${file.split('/').last.substring(0, 20)}...'
                            : file.split('/').last,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                      onDeleted: () => _downloadAttachment(file),
                      deleteIcon: Icon(
                        Icons.download,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                      backgroundColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignTechnicianSection(bool isDarkMode) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF3A4352) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ASSIGNER UN TECHNICIEN',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.blue,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Sélectionner un technicien',
              labelStyle: GoogleFonts.poppins(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.white70 : Colors.grey[400]!,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            ),
            value: _selectedTechnicianId,
            items: _technicians.map((tech) {
              return DropdownMenuItem(
                value: tech.id,
                child: Text(
                  tech.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTechnicianId = value;
              });
            },
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: _isAssigning ? null : _assignTechnician,
            child: _isAssigning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'ASSIGNER LE TECHNICIEN',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<Technicien?> _getTechnicianDetails(dynamic techId) async {
    if (techId == null) return null;
    try {
      return await TechnicienService.getTechnicianById(techId.toString());
    } catch (e) {
      return null;
    }
  }

  void _downloadAttachment(String fileUrl) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Téléchargement de $fileUrl'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Not Assigned':
        return const Color.fromARGB(255, 235, 203, 129); // Light pastel yellow
      case 'Assigned':
        return const Color(0xFFA1C7ED); // Light blue
      case 'In Progress':
        return const Color(0xFFE3F2FD); // Pastel blue
      case 'Resolved':
        return const Color(0xFFA6D490); // Light green
      case 'Closed':
        return const Color(0xFFE0F7F6); // Mint pastel
      case 'Expired':
        return const Color(0xFFFFEBEE); // Light pastel red
      default:
        return const Color(0xFFFAFAFA); // Off-white
    }
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool isDarkMode;

  const _DetailItem({
    required this.label,
    required this.value,
    this.icon,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isDarkMode;

  const ErrorWidget({
    required this.error,
    required this.onRetry,
    required this.isDarkMode,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDarkMode ? Colors.white : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.white : Colors.blue,
              foregroundColor: isDarkMode ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onRetry,
            child: Text(
              'Réessayer',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
