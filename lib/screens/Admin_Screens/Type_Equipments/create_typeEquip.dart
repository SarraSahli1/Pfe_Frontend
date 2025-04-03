import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateTypeEquipmentPage extends StatefulWidget {
  @override
  _CreateTypeEquipmentPageState createState() =>
      _CreateTypeEquipmentPageState();
}

class _CreateTypeEquipmentPageState extends State<CreateTypeEquipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _typeNameController = TextEditingController();
  final _typeEquipController = TextEditingController();
  File? _logoFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _logoFile = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _logoFile != null) {
      try {
        // Envoyez les données à l'API

        // Affichez un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('TypeEquipment créé avec succès!')),
        );

        // Réinitialisez le formulaire
        _typeNameController.clear();
        _typeEquipController.clear();
        setState(() {
          _logoFile = null;
        });
      } catch (e) {
        // Affichez un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Veuillez remplir tous les champs et sélectionner une image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un TypeEquipment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _typeNameController,
                decoration: InputDecoration(labelText: 'Nom du type'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _typeEquipController,
                decoration: InputDecoration(labelText: 'Type d\'équipement'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un type d\'équipement';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _logoFile == null
                  ? Text('Aucune image sélectionnée')
                  : Image.file(_logoFile!, height: 100),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Sélectionner une image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Créer TypeEquipment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _typeNameController.dispose();
    _typeEquipController.dispose();
    super.dispose();
  }
}
