import 'dart:io';
import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/services/typeEquip_service.dart';
import 'package:image_picker/image_picker.dart';

class EditTypeEquipmentPage extends StatefulWidget {
  final String id;
  final String initialTypeName;
  final String initialTypeEquip;
  final String? initialLogoPath; // Chemin du logo actuel

  const EditTypeEquipmentPage({
    Key? key,
    required this.id,
    required this.initialTypeName,
    required this.initialTypeEquip,
    this.initialLogoPath,
  }) : super(key: key);

  @override
  _EditTypeEquipmentPageState createState() => _EditTypeEquipmentPageState();
}

class _EditTypeEquipmentPageState extends State<EditTypeEquipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _typeNameController = TextEditingController();
  final _typeEquipController = TextEditingController();
  final TypeEquipmentService _typeEquipmentService = TypeEquipmentService();
  File? _logoFile; // Nouveau fichier logo sélectionné
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec les valeurs actuelles
    _typeNameController.text = widget.initialTypeName;
    _typeEquipController.text = widget.initialTypeEquip;
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _logoFile = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _updateTypeEquipment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _typeEquipmentService.updateTypeEquipment(
          id: widget.id,
          typeName: _typeNameController.text,
          typeEquip: _typeEquipController.text,
          logoFile: _logoFile, // Nouveau fichier logo (optionnel)
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );

        // Retourner à la page précédente après la mise à jour
        if (mounted) {
          Navigator.pop(
              context, true); // Rafraîchir la liste après la mise à jour
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'équipement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Champ pour le nom du type
              TextFormField(
                controller: _typeNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du type',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Champ pour le type d'équipement
              TextFormField(
                controller: _typeEquipController,
                decoration: const InputDecoration(
                  labelText: 'Type d\'équipement',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Sélection du logo
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _logoFile != null
                      ? FileImage(_logoFile!) // Nouveau logo sélectionné
                      : (widget.initialLogoPath != null
                          ? NetworkImage(widget.initialLogoPath!) // Logo actuel
                          : null),
                  child: _logoFile == null && widget.initialLogoPath == null
                      ? const Icon(Icons.add_a_photo, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Bouton pour enregistrer
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _updateTypeEquipment,
                      child: const Text('Enregistrer'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
