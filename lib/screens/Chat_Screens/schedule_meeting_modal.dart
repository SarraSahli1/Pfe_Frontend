import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:helpdeskfrontend/provider/theme_provider.dart';

class ScheduleMeetingModal extends StatefulWidget {
  final Function(DateTime, int, String?) onSchedule;

  const ScheduleMeetingModal({required this.onSchedule, Key? key})
      : super(key: key);

  @override
  _ScheduleMeetingModalState createState() => _ScheduleMeetingModalState();
}

class _ScheduleMeetingModalState extends State<ScheduleMeetingModal> {
  DateTime? _selectedDateTime;
  int _duration = 30;
  final TextEditingController _messageController = TextEditingController();

  Future<void> _selectDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF242E3E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Schedule Meeting',
        style: GoogleFonts.poppins(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                _selectedDateTime == null
                    ? 'Select Date & Time'
                    : DateFormat('MMM dd, yyyy HH:mm')
                        .format(_selectedDateTime!),
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDateTime(context),
            ),
            DropdownButton<int>(
              value: _duration,
              items: [15, 30, 45, 60].map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(
                    '$duration minutes',
                    style: GoogleFonts.poppins(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && mounted) {
                  setState(() {
                    _duration = value;
                  });
                }
              },
              isExpanded: true,
            ),
            TextField(
              controller: _messageController,
              style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Optional message',
                hintStyle: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white54 : Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode
                    ? const Color(0xFF3A4352)
                    : const Color(0xFFF2F4F5),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedDateTime == null
              ? null
              : () {
                  widget.onSchedule(
                    _selectedDateTime!,
                    _duration,
                    _messageController.text.isEmpty
                        ? null
                        : _messageController.text,
                  );
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF628ff6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Schedule',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
