import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/models/technicien.dart';
import 'package:helpdeskfrontend/models/user.dart';
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
          content: Text('Failed to load client: ${e.toString()}'),
          duration: const Duration(seconds: 2),
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
          content: Text('Failed to load technicians: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
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
        const SnackBar(content: Text('Technician assigned successfully!')),
      );

      _loadTicket();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isAssigning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<Ticket>(
        future: _ticketFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load ticket',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No ticket data available'));
          }

          final ticket = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildTicketDetails(ticket),
                ),
              ),
              if (_shouldShowAssignButton(ticket))
                _buildAssignTechnicianSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAssignTechnicianSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ASSIGN TECHNICIAN',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Select Technician',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            value: _selectedTechnicianId,
            items: _technicians.map((tech) {
              return DropdownMenuItem(
                value: tech.id,
                child: Text(tech.fullName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTechnicianId = value;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
                : const Text('ASSIGN TECHNICIAN'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetails(Ticket ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Status
        Row(
          children: [
            Expanded(
              child: Text(
                ticket.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(ticket.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(ticket.status),
                  width: 1,
                ),
              ),
              child: Text(
                ticket.status,
                style: TextStyle(
                  color: _getStatusColor(ticket.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Ticket ID: ${ticket.id}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        const Divider(height: 40),

        // Client Information
        _buildSectionHeader('CLIENT INFORMATION'),
        const SizedBox(height: 12),
        _buildClientInfoSection(ticket),
        const Divider(height: 40),

        // Ticket Details
        _buildSectionHeader('TICKET DETAILS'),
        const SizedBox(height: 12),
        _DetailItem(
          label: 'Type',
          value: ticket.typeTicket,
          icon: Icons.category,
        ),
        _DetailItem(
          label: 'Description',
          value: ticket.description,
          icon: Icons.description,
        ),
        _DetailItem(
          label: 'Created',
          value: DateFormat('MMM d, y • h:mm a').format(ticket.creationDate),
          icon: Icons.calendar_today,
        ),
        if (ticket.assignedDate != null)
          _DetailItem(
            label: 'Assigned',
            value: DateFormat('MMM d, y • h:mm a').format(ticket.assignedDate!),
            icon: Icons.person_add,
          ),
        if (ticket.resolvedDate != null)
          _DetailItem(
            label: 'Resolved',
            value: DateFormat('MMM d, y • h:mm a').format(ticket.resolvedDate!),
            icon: Icons.check_circle,
          ),
        if (ticket.closedDate != null)
          _DetailItem(
            label: 'Closed',
            value: DateFormat('MMM d, y • h:mm a').format(ticket.closedDate!),
            icon: Icons.lock_clock,
          ),
        if (ticket.technicienIds != null &&
            ticket.technicienIds!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTechnicianInfoSection(ticket.technicienIds!),
        ],

        // Equipment Sections
        if ((ticket.equipmentHardIds ?? []).isNotEmpty) ...[
          const Divider(height: 40),
          _buildSectionHeader('HARDWARE EQUIPMENT'),
          const SizedBox(height: 12),
          ...ticket.equipmentHardIds!.map((e) => _buildEquipmentItem(e)),
        ],
        if ((ticket.equipmentSoftIds ?? []).isNotEmpty) ...[
          const Divider(height: 40),
          _buildSectionHeader('SOFTWARE EQUIPMENT'),
          const SizedBox(height: 12),
          ...ticket.equipmentSoftIds!.map((e) => _buildEquipmentItem(e)),
        ],

        // Attachments
        if ((ticket.fileUrls ?? []).isNotEmpty) ...[
          const Divider(height: 40),
          _buildSectionHeader('ATTACHMENTS'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ticket.fileUrls!
                .map((file) => ActionChip(
                      avatar: const Icon(Icons.attach_file, size: 18),
                      label: Text(
                        file.split('/').last.length > 20
                            ? '${file.split('/').last.substring(0, 20)}...'
                            : file.split('/').last,
                      ),
                      onPressed: () => _downloadAttachment(file),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
    );
  }

  Widget _buildClientInfoSection(Ticket ticket) {
    if (_isLoadingClient) {
      return const Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Loading client information...'),
        ],
      );
    }

    if (_client == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Client information not available'),
          if (ticket.clientId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Client ID: ${ticket.clientId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _loadClientInfo(ticket.clientId),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_client!.firstName} ${_client!.lastName}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (_client!.email != null) ...[
          const SizedBox(height: 4),
          Text(
            _client!.email!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if (_client!.phoneNumber != null) ...[
          const SizedBox(height: 4),
          Text(
            _client!.phoneNumber!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _buildTechnicianInfoSection(List<dynamic> technicianIds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ASSIGNED TECHNICIANS'),
        const SizedBox(height: 12),
        ...technicianIds.map((techId) => FutureBuilder<Technicien?>(
              future: _getTechnicianDetails(techId),
              builder: (context, snapshot) {
                final tech = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tech != null) ...[
                        Text(
                          tech.fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        ...[
                          const SizedBox(height: 4),
                          Text(
                            tech.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (tech.phoneNumber != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            tech.phoneNumber!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ] else if (techId != null) ...[
                        Text(
                          'Technician ID: $techId',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                );
              },
            )),
      ],
    );
  }

  Widget _buildEquipmentItem(String equipment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8),
          const SizedBox(width: 12),
          Expanded(child: Text(equipment)),
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
    // Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading $fileUrl')),
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

  const _DetailItem({
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
