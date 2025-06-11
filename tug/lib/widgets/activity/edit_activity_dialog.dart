// lib/widgets/activity/edit_activity_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/utils/theme/colors.dart';

class EditActivityDialog extends StatefulWidget {
  final ActivityModel activity;
  final Function(ActivityModel updatedActivity) onSave;

  const EditActivityDialog({
    super.key,
    required this.activity,
    required this.onSave,
  });

  @override
  State<EditActivityDialog> createState() => _EditActivityDialogState();
}

class _EditActivityDialogState extends State<EditActivityDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _durationController;
  late final TextEditingController _notesController;
  
  late String _valueId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the activity's data
    _nameController = TextEditingController(text: widget.activity.name);
    _durationController = TextEditingController(text: widget.activity.duration.toString());
    _notesController = TextEditingController(text: widget.activity.notes ?? '');
    _valueId = widget.activity.valueId;
    _selectedDate = widget.activity.date;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: isDarkMode ? TugColors.darkSurface : Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Form fields
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity Name
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'activity name',
                        hintText: 'what did you do?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Value Selector
                    BlocBuilder<ValuesBloc, ValuesState>(
                      builder: (context, state) {
                        final values = state is ValuesLoaded 
                            ? state.values.where((v) => v.active).toList()
                            : <ValueModel>[];
                        
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'related value',
                            hintText: 'which value does this support?',
                            border: OutlineInputBorder(),
                          ),
                          value: _valueId,
                          items: values.map((value) {
                            final valueColor = Color(
                              int.parse(value.color.substring(1), radix: 16) + 0xFF000000,
                            );
                            
                            return DropdownMenuItem(
                              value: value.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: valueColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(value.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? id) {
                            if (id != null) {
                              setState(() {
                                _valueId = id;
                              });
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Duration Input
                    TextField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'duration (minutes)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    
                    // Date Picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM d, yyyy').format(_selectedDate),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Add any additional details',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: TugButtons.primaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                        onPressed: _handleSave,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    // Basic validation
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an activity name'),
          backgroundColor: TugColors.error,
        ),
      );
      return;
    }
    
    // Parse duration
    final duration = int.tryParse(_durationController.text);
    if (duration == null || duration <= 0 || duration > 1440) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid duration (1-1440 minutes)'),
          backgroundColor: TugColors.error,
        ),
      );
      return;
    }
    
    // Get notes if any
    final notes = _notesController.text.trim().isNotEmpty 
        ? _notesController.text.trim() 
        : null;
    
    // Create updated activity model
    final updatedActivity = widget.activity.copyWith(
      name: name,
      valueId: _valueId,
      duration: duration,
      date: _selectedDate,
      notes: notes,
    );
    
    // Call the onSave callback
    widget.onSave(updatedActivity);
    
    // Close the dialog
    Navigator.pop(context);
  }
}