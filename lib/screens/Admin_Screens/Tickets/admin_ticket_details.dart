import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/models/technicien.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/services/ticket_service.dart';
import 'package:helpdeskfrontend/services/technicien_service.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
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

  Widget _buildEquipmentItem(String equipmentId) {
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
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(
                        height: 2,
                        width: 100,
                        child: LinearProgressIndicator(),
                      ),
                    if (snapshot.hasError)
                      Text(
                        'Tapez pour réessayer',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
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
                    color: Theme.of(context).colorScheme.error,
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Ticket'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: FutureBuilder<Ticket>(
        future: _ticketFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: ErrorWidget(
                error: snapshot.error.toString(),
                onRetry: _loadData,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Aucune donnée de ticket disponible'),
            );
          }

          final ticket = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            _buildTicketHeader(ticket, theme),
                            const SizedBox(height: 24),
                            _buildClientSection(ticket, theme),
                            const SizedBox(height: 24),
                            _buildTicketDetailsSection(ticket, theme),
                            if ((ticket.technicienIds ?? []).isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildTechniciansSection(ticket, theme),
                            ],
                            if ((ticket.equipmentHardIds ?? []).isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildEquipmentSection(
                                'Matériel',
                                ticket.equipmentHardIds!,
                                Icons.computer,
                                theme,
                              ),
                            ],
                            if ((ticket.equipmentSoftIds ?? []).isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildEquipmentSection(
                                'Logiciel',
                                ticket.equipmentSoftIds!,
                                Icons.phone_android,
                                theme,
                              ),
                            ],
                            if ((ticket.fileUrls ?? []).isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildAttachmentsSection(ticket, theme),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_shouldShowAssignButton(ticket))
                _buildAssignTechnicianSection(theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTicketHeader(Ticket ticket, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ticket.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(ticket.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(ticket.status),
                  width: 1.5,
                ),
              ),
              child: Text(
                ticket.status,
                style: TextStyle(
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
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                style: theme.textTheme.bodyMedium,
                maxLines: _isExpandedDescription ? null : 3,
                overflow: _isExpandedDescription ? null : TextOverflow.ellipsis,
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
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClientSection(Ticket ticket, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Client',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingClient)
            const Center(child: CircularProgressIndicator())
          else if (_client == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Informations client non disponibles'),
                if (ticket.clientId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ID Client: ${ticket.clientId}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _loadClientInfo(ticket.clientId),
                  child: const Text('Réessayer'),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_client!.firstName} ${_client!.lastName}',
                  style: theme.textTheme.titleMedium,
                ),
                if (_client!.email != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _client!.email!,
                        style: theme.textTheme.bodyMedium,
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
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _client!.phoneNumber!,
                        style: theme.textTheme.bodyMedium,
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

  Widget _buildTicketDetailsSection(Ticket ticket, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Détails du Ticket',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailItem(
            label: 'Type',
            value: ticket.typeTicket,
            icon: Icons.category,
            theme: theme,
          ),
          _DetailItem(
            label: 'Créé le',
            value:
                DateFormat('dd MMM yyyy • HH:mm').format(ticket.creationDate),
            icon: Icons.calendar_today,
            theme: theme,
          ),
          if (ticket.assignedDate != null)
            _DetailItem(
              label: 'Assigné le',
              value: DateFormat('dd MMM yyyy • HH:mm')
                  .format(ticket.assignedDate!),
              icon: Icons.person_add,
              theme: theme,
            ),
          if (ticket.resolvedDate != null)
            _DetailItem(
              label: 'Résolu le',
              value: DateFormat('dd MMM yyyy • HH:mm')
                  .format(ticket.resolvedDate!),
              icon: Icons.check_circle,
              theme: theme,
            ),
          if (ticket.closedDate != null)
            _DetailItem(
              label: 'Fermé le',
              value:
                  DateFormat('dd MMM yyyy • HH:mm').format(ticket.closedDate!),
              icon: Icons.lock_clock,
              theme: theme,
            ),
        ],
      ),
    );
  }

  Widget _buildTechniciansSection(Ticket ticket, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.engineering,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Techniciens Assignés',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.email,
                                size: 16,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tech.email,
                                style: theme.textTheme.bodyMedium,
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
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tech.phoneNumber!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ] else ...[
                          Text(
                            'Technicien ID: $techId',
                            style: theme.textTheme.bodyMedium,
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
      String title, List<String> equipmentIds, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...equipmentIds
              .map((equipmentId) => _buildEquipmentItem(equipmentId)),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(Ticket ticket, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Pièces Jointes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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
                      avatar: const Icon(Icons.attach_file, size: 18),
                      label: Text(
                        file.split('/').last.length > 20
                            ? '${file.split('/').last.substring(0, 20)}...'
                            : file.split('/').last,
                      ),
                      onDeleted: () => _downloadAttachment(file),
                      deleteIcon: const Icon(Icons.download),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignTechnicianSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ASSIGNER UN TECHNICIEN',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Sélectionner un technicien',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            value: _selectedTechnicianId,
            items: _technicians.map((tech) {
              return DropdownMenuItem(
                value: tech.id,
                child: Text(
                  tech.fullName,
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTechnicianId = value;
              });
            },
            style: theme.textTheme.bodyMedium,
            dropdownColor: theme.colorScheme.surface,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
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
                : const Text('ASSIGNER LE TECHNICIEN'),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Not Assigned':
        return Colors.orange;
      case 'Assigned':
        return Colors.blue;
      case 'In Progress':
        return Colors.blueAccent;
      case 'Resolved':
        return Colors.green;
      case 'Closed':
        return Colors.green.shade600;
      case 'Expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final ThemeData theme;

  const _DetailItem({
    required this.label,
    required this.value,
    this.icon,
    required this.theme,
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
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
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

  const ErrorWidget({
    required this.error,
    required this.onRetry,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
