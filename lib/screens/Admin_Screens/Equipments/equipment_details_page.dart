import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/services/user_service.dart';
import 'package:intl/intl.dart';

class EquipmentDetailsPage extends StatefulWidget {
  final String equipmentId;

  const EquipmentDetailsPage({Key? key, required this.equipmentId})
      : super(key: key);

  @override
  _EquipmentDetailsPageState createState() => _EquipmentDetailsPageState();
}

class _EquipmentDetailsPageState extends State<EquipmentDetailsPage> {
  final EquipmentService _equipmentService = EquipmentService();
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> _futureEquipment;
  late Future<List<dynamic>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _futureUsers = _userService.getAllUsers();
  }

  Future<void> _fetchData() async {
    _futureEquipment =
        _equipmentService.getEquipmentDetails(id: widget.equipmentId);
  }

  Future<void> _refreshEquipment() async {
    setState(() {
      _futureEquipment =
          _equipmentService.getEquipmentDetails(id: widget.equipmentId);
    });
  }

  Future<void> _unassignEquipment() async {
    try {
      await _equipmentService.unassignEquipment(
          equipmentId: widget.equipmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipment unassigned successfully')),
        );
        _refreshEquipment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unassigning equipment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Equipment Details',
          style: TextStyle(color: colorScheme.onPrimary),
        ),
        backgroundColor: colorScheme.primary,
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _futureEquipment,
            builder: (context, equipmentSnapshot) {
              if (equipmentSnapshot.connectionState != ConnectionState.done ||
                  !equipmentSnapshot.hasData) {
                return const SizedBox.shrink();
              }

              final isAssigned = equipmentSnapshot.data!['assigned'] == true;

              return FutureBuilder<List<dynamic>>(
                future: _futureUsers,
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState != ConnectionState.done ||
                      !userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  return IconButton(
                    icon: Icon(
                        isAssigned ? Icons.person_remove : Icons.person_add),
                    onPressed: () => isAssigned
                        ? _unassignEquipment()
                        : _showAssignDialog(context, userSnapshot.data!),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEquipment,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _futureEquipment,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No data found'));
            } else {
              final equipment = snapshot.data!;
              final typeEquipment = equipment['TypeEquipment'] ?? {};
              final owner = equipment['owner'] ?? {};
              final inventoryDate = equipment['inventoryDate'] != null
                  ? DateTime.parse(equipment['inventoryDate'])
                  : null;
              final isAssigned = equipment['assigned'] == true;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard(
                      children: [
                        _buildDetailItem('Serial Number:',
                            equipment['serialNumber'] ?? 'Not specified'),
                        _buildDetailItem('Designation:',
                            equipment['designation'] ?? 'Not specified'),
                        _buildDetailItem('Version:',
                            equipment['version'] ?? 'Not specified'),
                        _buildDetailItem('Barcode:',
                            equipment['barcode'] ?? 'Not specified'),
                        _buildDetailItem('Status:',
                            isAssigned ? 'Assigned' : 'Not assigned'),
                        _buildDetailItem(
                            'Inventory Date:',
                            inventoryDate != null
                                ? dateFormat.format(inventoryDate)
                                : 'Not specified'),
                        _buildDetailItem(
                            'Reference:', equipment['reference'] ?? 'OPM_APP'),
                      ],
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 20),
                    _buildDetailCard(
                      title: 'Equipment Type',
                      children: [
                        _buildDetailItem('Name:',
                            typeEquipment['typeName'] ?? 'Not specified'),
                        if (typeEquipment['description'] != null)
                          _buildDetailItem(
                              'Description:', typeEquipment['description']),
                      ],
                      colorScheme: colorScheme,
                    ),
                    if (owner.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDetailCard(
                        title: 'Owner',
                        children: [
                          _buildDetailItem(
                              'Company:', owner['company'] ?? 'Not specified'),
                          if (owner['email'] != null)
                            _buildDetailItem('Email:', owner['email']),
                          if (owner['phone'] != null)
                            _buildDetailItem('Phone:', owner['phone']),
                        ],
                        colorScheme: colorScheme,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: FutureBuilder<List<dynamic>>(
                        future: _futureUsers,
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (userSnapshot.hasError) {
                            return Text(
                                'Error loading users: ${userSnapshot.error}');
                          }
                          if (!userSnapshot.hasData ||
                              userSnapshot.data!.isEmpty) {
                            return const Text('No users available');
                          }

                          return ElevatedButton(
                            onPressed: isAssigned
                                ? _unassignEquipment
                                : () => _showAssignDialog(
                                    context, userSnapshot.data!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isAssigned ? Colors.red : colorScheme.primary,
                            ),
                            child: Text(isAssigned
                                ? 'Unassign Owner'
                                : 'Assign Equipment'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _showAssignDialog(
      BuildContext context, List<dynamic> users) async {
    String? selectedUserId;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Equipment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select a user to assign this equipment to:'),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedUserId,
                  hint: const Text('Select User'),
                  items: users.map((user) {
                    return DropdownMenuItem<String>(
                      value: user['_id'],
                      child: Text(
                          '${user['firstName']} ${user['lastName']} (${user['email']})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedUserId = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedUserId != null) {
                  try {
                    await _equipmentService.assignEquipmentToUser(
                      equipmentId: widget.equipmentId,
                      userId: selectedUserId!,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Equipment assigned successfully')),
                      );
                      _refreshEquipment();
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error assigning equipment: $e')),
                      );
                    }
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a user')),
                    );
                  }
                }
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailCard({
    String? title,
    required List<Widget> children,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Divider(),
              const SizedBox(height: 8),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
