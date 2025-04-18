// A dedicated dialog widget for editing values
// You can add this to a new file like lib/widgets/values/edit_value_dialog.dart

import 'package:flutter/material.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/widgets/common/tug_text_field.dart';
import 'package:tug/widgets/values/color_picker.dart';

class EditValueDialog extends StatefulWidget {
  final ValueModel value;
  final Function(ValueModel updatedValue) onSave;

  const EditValueDialog({
    Key? key,
    required this.value,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditValueDialog> createState() => _EditValueDialogState();
}

class _EditValueDialogState extends State<EditValueDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late double _importance;
  late String _color;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the value's data
    _nameController = TextEditingController(text: widget.value.name);
    _descriptionController = TextEditingController(text: widget.value.description);
    _importance = widget.value.importance.toDouble();
    _color = widget.value.color;
  }

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Value'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TugTextField(
              label: 'Value',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Importance: ${_importance.round()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _importance,
              min: 1,
              max: 5,
              divisions: 4,
              label: _importance.round().toString(),
              activeColor: TugColors.primaryPurple,
              onChanged: (value) {
                setState(() {
                  _importance = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TugTextField(
              label: 'Description (Optional)',
              controller: _descriptionController,
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ColorPicker(
              selectedColor: _color,
              onColorSelected: (newColor) {
                setState(() {
                  _color = newColor;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: TugButtons.primaryButtonStyle,
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              final updatedValue = widget.value.copyWith(
                name: _nameController.text.trim(),
                importance: _importance.round(),
                description: _descriptionController.text.trim(),
                color: _color,
              );
              
              // Call the onSave callback with the updated value
              widget.onSave(updatedValue);
              
              // Close the dialog
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}