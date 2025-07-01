// lib/widgets/vices/edit_vice_dialog.dart
import 'package:flutter/material.dart';
import '../../models/vice_model.dart';
import '../../utils/theme/colors.dart';
import '../../widgets/common/tug_text_field.dart';
import 'vice_color_picker.dart';

class EditViceDialog extends StatefulWidget {
  final ViceModel vice;
  final Function(ViceModel) onSave;

  const EditViceDialog({
    super.key,
    required this.vice,
    required this.onSave,
  });

  @override
  State<EditViceDialog> createState() => _EditViceDialogState();
}

class _EditViceDialogState extends State<EditViceDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late double _severity;
  late String _selectedColor;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vice.name);
    _descriptionController = TextEditingController(text: widget.vice.description);
    _severity = widget.vice.severity.toDouble();
    _selectedColor = widget.vice.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveVice() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedVice = widget.vice.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        severity: _severity.round(),
        color: _selectedColor,
        updatedAt: DateTime.now(),
      );
      
      widget.onSave(updatedVice);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'edit vice',
        style: TextStyle(
          color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.viceGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TugTextField(
                label: 'vice name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please enter a name';
                  }
                  if (value.length < 2) {
                    return 'name too short';
                  }
                  if (value.length > 30) {
                    return 'name too long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'severity level',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                ),
              ),
              Slider(
                value: _severity,
                min: 1,
                max: 5,
                divisions: 4,
                label: '${_severity.round()} - ${ViceModel(name: '', severity: _severity.round(), color: '').severityDescription}',
                activeColor: TugColors.getSeverityColor(_severity.round()),
                onChanged: (value) {
                  setState(() {
                    _severity = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TugTextField(
                label: 'description (optional)',
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'color',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ViceColorPicker(
                selectedColor: _selectedColor,
                onColorSelected: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'cancel',
            style: TextStyle(
              color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _saveVice,
          style: ElevatedButton.styleFrom(
            backgroundColor: TugColors.viceGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('save'),
        ),
      ],
    );
  }
}