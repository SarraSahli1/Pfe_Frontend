import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/services/problems_service.dart'; // Importez le service des problèmes

class EditProblemPage extends StatefulWidget {
  final String problemId;
  final String initialNomProblem;
  final String initialDescription;

  const EditProblemPage({
    Key? key,
    required this.problemId,
    required this.initialNomProblem,
    required this.initialDescription,
  }) : super(key: key);

  @override
  _EditProblemPageState createState() => _EditProblemPageState();
}

class _EditProblemPageState extends State<EditProblemPage> {
  final ProblemsService _problemsService = ProblemsService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomProblemController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec les valeurs actuelles du problème
    _nomProblemController =
        TextEditingController(text: widget.initialNomProblem);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    // Nettoyer les contrôleurs
    _nomProblemController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateProblem() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _problemsService.updateProblem(
          id: widget.problemId,
          nomProblem: _nomProblemController.text,
          description: _descriptionController.text,
        );
        // Retourner à la page précédente avec un indicateur de rafraîchissement
        Navigator.pop(context, true);
      } catch (e) {
        // Afficher une erreur en cas d'échec
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de la mise à jour du problème: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Éditer le problème'),
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
                onPressed: _updateProblem,
                child: Text('Enregistrer les modifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
