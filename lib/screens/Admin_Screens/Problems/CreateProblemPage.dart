import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helpdeskfrontend/services/problems_service.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';
import 'package:helpdeskfrontend/widgets/theme_toggle_button.dart';

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
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _problemsService.createProblem(
          nomProblem: _nomProblemController.text,
          description: _descriptionController.text,
          typeEquipmentId: widget.typeEquipmentId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Problem created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating problem: $e'),
            backgroundColor: Colors.orange,
          ),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF242E3E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? const Color(0xFF858397) : Colors.black54;
    final textFieldBackgroundColor =
        isDarkMode ? const Color(0xFF2A3447) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Create New Problem',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFF628ff6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? Colors.white : Colors.blue,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Problem Name Field
                    _buildTextField(
                      label: 'Problem Name*',
                      controller: _nomProblemController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a problem name';
                        }
                        return null;
                      },
                      hintColor: hintColor,
                      textColor: textColor,
                      backgroundColor: textFieldBackgroundColor,
                      icon: Icons.report_problem,
                    ),
                    const SizedBox(height: 20),

                    // Description Field
                    _buildTextArea(
                      label: 'Description*',
                      controller: _descriptionController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                      hintColor: hintColor,
                      textColor: textColor,
                      backgroundColor: textFieldBackgroundColor,
                      icon: Icons.description,
                    ),
                    const SizedBox(height: 30),

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode ? Colors.blue.shade800 : Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : Text(
                                'Create Problem',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    required Color hintColor,
    required Color textColor,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: hintColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: hintColor),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    required Color hintColor,
    required Color textColor,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: hintColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 14,
            ),
            maxLines: 5,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: hintColor),
              alignLabelWithHint: true,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nomProblemController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
