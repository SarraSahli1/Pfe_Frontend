import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/services/typeEquip_service.dart';
import 'package:helpdeskfrontend/services/equipement_service.dart';

class CreateEquipmentPage extends StatefulWidget {
  @override
  _CreateEquipmentPageState createState() => _CreateEquipmentPageState();
}

class _CreateEquipmentPageState extends State<CreateEquipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentService = EquipmentService();
  final _typeEquipmentService = TypeEquipmentService();

  // Form fields
  String _serialNumber = '';
  String _designation = '';
  String _version = '';
  String _barcode = '';
  DateTime? _inventoryDate;
  String? _selectedTypeEquipmentId;
  List<dynamic> _equipmentTypes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTypeEquipment();
  }

  Future<void> _loadTypeEquipment() async {
    try {
      final typeEquipmentList =
          await _typeEquipmentService.getAllTypeEquipment();
      setState(() {
        _equipmentTypes = typeEquipmentList;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading equipment types: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final equipmentData = {
          'designation': _designation,
          'serialNumber': _serialNumber,
          'version': _version,
          'barcode': _barcode,
          'inventoryDate': _inventoryDate?.toIso8601String(),
          'assigned':
              false, // Default to false since owner will be assigned separately
          'TypeEquipment': _selectedTypeEquipmentId,
          'reference': 'OPM_APP',
        };

        await _equipmentService.createEquipment(
          data: equipmentData,
          serialNumber: _serialNumber.isNotEmpty ? _serialNumber : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Equipment created successfully!')),
        );

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating equipment: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _inventoryDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create New Equipment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration:
                    InputDecoration(labelText: 'Serial Number (optional)'),
                onSaved: (value) => _serialNumber = value ?? '',
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Designation*'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter designation';
                  }
                  return null;
                },
                onSaved: (value) => _designation = value!,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Version'),
                onSaved: (value) => _version = value ?? '',
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Barcode'),
                onSaved: (value) => _barcode = value ?? '',
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(_inventoryDate == null
                    ? 'Select Inventory Date (optional)'
                    : 'Inventory Date: ${_inventoryDate!.toLocal().toString().split(' ')[0]}'),
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Equipment Type*'),
                value: _selectedTypeEquipmentId,
                items: _equipmentTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['_id'],
                    child: Text(type['typeName']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTypeEquipmentId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an equipment type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Create Equipment'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> showCreateEquipmentModal(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => CreateEquipmentPage(),
  ).then((value) => value ?? false);
}
