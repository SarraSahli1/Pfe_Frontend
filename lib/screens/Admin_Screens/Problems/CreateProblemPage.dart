import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/services/problems_service.dart'; // Importez le service des problèmes

class CreateProblemPage extends StatefulWidget {
  final String typeEquipmentId;

  const CreateProblemPage({Key? key, required this.typeEquipmentId})
      : super(key: key);

  @override
  _CreateProblemPageState createState() => _CreateProblemPageState();
}

class _CreateProblemPageState extends State<CreateProblemPage> {
  final ProblemsService _problemsService = ProblemsService();
  final _formKey = GlobalKey<FormState>();
  final _nomProblemController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un problème'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomProblemController,
                decoration: InputDecoration(labelText: 'Nom du problème'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom de problème';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await _problemsService.createProblem(
                        nomProblem: _nomProblemController.text,
                        description: _descriptionController.text,
                        typeEquipmentId: widget.typeEquipmentId,
                      );
                      Navigator.pop(context,
                          true); // Retourner à la liste avec un rafraîchissement
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                },
                child: Text('Créer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
