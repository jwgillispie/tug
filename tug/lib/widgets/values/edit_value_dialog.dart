// A dedicated dialog widget for editing values
// You can add this to a new file like lib/widgets/values/edit_value_dialog.dart

import 'package:flutter/material.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/widgets/common/tug_text_field.dart';
import 'package:tug/widgets/values/color_picker.dart';
import 'package:tug/services/app_mode_service.dart';

class EditValueDialog extends StatefulWidget {
  final ValueModel value;
  final Function(ValueModel updatedValue) onSave;

  const EditValueDialog({
    super.key,
    required this.value,
    required this.onSave,
  });

  @override
  State<EditValueDialog> createState() => _EditValueDialogState();
}

class _EditValueDialogState extends State<EditValueDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late double _importance;
  late String _color;
  final AppModeService _appModeService = AppModeService();
  AppMode _currentMode = AppMode.valuesMode;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the value's data
    _nameController = TextEditingController(text: widget.value.name);
    _descriptionController = TextEditingController(text: widget.value.description);
    _importance = widget.value.importance.toDouble();
    _color = widget.value.color;
    _currentMode = _appModeService.currentMode;
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (isDarkMode ? TugColors.darkSurface : Colors.white),
              (isDarkMode ? TugColors.darkSurface : Colors.white).withValues(alpha: 0.95),
            ],
          ),
          border: Border.all(
            color: TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode).withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode).withValues(alpha: 0.1),
              blurRadius: 32,
              offset: const Offset(0, 16),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _currentMode == AppMode.vicesMode
                          ? [TugColors.viceGreen.withValues(alpha: 0.2), TugColors.viceGreenLight.withValues(alpha: 0.1)]
                          : [TugColors.primaryPurple.withValues(alpha: 0.2), TugColors.primaryPurpleLight.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit ${_currentMode == AppMode.vicesMode ? 'Vice' : 'Value'}',
                        style: TextStyle(
                          color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'Customize your ${_currentMode == AppMode.vicesMode ? 'vice' : 'value'} details',
                        style: TextStyle(
                          color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            
            // Content area
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            TugTextField(
              label: 'value',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please enter a value';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'importance: ${_importance.round()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _importance,
              min: 1,
              max: 5,
              divisions: 4,
              label: _importance.round().toString(),
              activeColor: TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode),
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
              'color',
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
        
        const SizedBox(height: 32),
        
        // Enhanced action buttons
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode).withValues(alpha: 0.3),
                  ),
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: _currentMode == AppMode.vicesMode
                        ? [TugColors.viceGreen, TugColors.viceGreenDark]
                        : [TugColors.primaryPurple, TugColors.primaryPurpleDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TugColors.getPrimaryColor(_currentMode == AppMode.vicesMode).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
      ),
    );
  }
}