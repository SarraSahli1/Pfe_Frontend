import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';
import 'package:helpdeskfrontend/services/user_service.dart';

class AssignEquipmentButton extends StatefulWidget {
  final String equipmentId;

  const AssignEquipmentButton({Key? key, required this.equipmentId})
      : super(key: key);

  @override
  _AssignEquipmentButtonState createState() => _AssignEquipmentButtonState();
}

class _AssignEquipmentButtonState extends State<AssignEquipmentButton> {
  final UserService _userService = UserService();
  final EquipmentService _equipmentService = EquipmentService();
  List<User> _users = [];
  User? _selectedUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users.map((userData) => User.fromMap(userData)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

  Future<void> _assignEquipment() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _equipmentService.assignEquipmentToUser(
        equipmentId: widget.equipmentId,
        userId: _selectedUser?.id ?? '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipment assigned successfully')),
      );
      Navigator.of(context).pop(true); // Close dialog and return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign equipment: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showAssignmentDialog(context),
      child: const Text('Assign Equipment'),
    );
  }

  Future<void> _showAssignmentDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Equipment'),
        content: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<User>(
                    value: _selectedUser,
                    hint: const Text('Select a user'),
                    items: _users.map((user) {
                      return DropdownMenuItem<User>(
                        value: user,
                        child: Text(
                            '${user.firstName} ${user.lastName} (${user.email})'),
                      );
                    }).toList(),
                    onChanged: (user) => setState(() => _selectedUser = user),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _assignEquipment,
                    child: const Text('Assign'),
                  ),
                ],
              ),
      ),
    );
  }
}
