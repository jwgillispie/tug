// lib/widgets/activity/activity_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/widgets/values/streak_celebration.dart';

class ActivityFormWidget extends StatefulWidget {
  final Function(String name, String valueId, int duration, DateTime date,
      String? notes) onSave;
  final bool isLoading;

  const ActivityFormWidget({
    Key? key,
    required this.onSave,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<ActivityFormWidget> createState() => _ActivityFormWidgetState();
}

class _ActivityFormWidgetState extends State<ActivityFormWidget> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedValueId;
  DateTime _selectedDate = DateTime.now();
  bool _showDurationPresets = true;
  bool _showStreakCelebration = false;
  String _streakValueName = '';
  int _streakCount = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedValueId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a value'),
            backgroundColor: TugColors.error,
          ),
        );
        return;
      }

      final name = _nameController.text.trim();
      final duration = int.tryParse(_durationController.text) ?? 0;
      final notes =
          _notesController.text.isEmpty ? null : _notesController.text;

      // Load streak stats for the selected value to see if we need to show a celebration
      context.read<ValuesBloc>().add(LoadStreakStats(valueId: _selectedValueId));
      
      // After creating the activity, wait for it to be processed, then check streak milestones
      Future.delayed(const Duration(milliseconds: 1000), () {
        final valuesState = context.read<ValuesBloc>().state;
        if (valuesState is ValuesLoaded) {
          final selectedValue = valuesState.values.firstWhere(
            (v) => v.id == _selectedValueId,
            orElse: () => const ValueModel(
              name: '', 
              importance: 1, 
              color: '#7C3AED'
            ),
          );
          
          // Check if we should celebrate a streak milestone
          if (selectedValue.currentStreak > 0 && 
              (selectedValue.currentStreak == 7 || 
               selectedValue.currentStreak == 30 || 
               selectedValue.currentStreak == 100 ||
               selectedValue.currentStreak == 365)) {
            setState(() {
              _streakValueName = selectedValue.name;
              _streakCount = selectedValue.currentStreak;
              _showStreakCelebration = true;
            });
          }
        }
      });

      widget.onSave(name, _selectedValueId!, duration, _selectedDate, notes);
    }
  }
  
  void _dismissStreakCelebration() {
    setState(() {
      _showStreakCelebration = false;
    });
  }

  void _selectDuration(int minutes) {
    setState(() {
      _durationController.text = minutes.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocBuilder<ValuesBloc, ValuesState>(
          builder: (context, state) {
            final values = state is ValuesLoaded
                ? state.values.where((v) => v.active).toList()
                : <ValueModel>[];

            // Set default selected value ID if values are available and no value is selected yet
            if (values.isNotEmpty && _selectedValueId == null) {
              _selectedValueId = values.first.id;
            }

            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Activity Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Activity Name',
                  hintText: 'What did you do?',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an activity name';
                  }
                  if (value.length < 2) {
                    return 'Activity name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Value Selector
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Related Value',
                  hintText: 'Which value does this support?',
                  border: OutlineInputBorder(),
                ),
                value: _selectedValueId,
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
                  setState(() {
                    _selectedValueId = id;
                    debugPrint(
                        'Selected value for activity: $_selectedValueId');
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Duration Input
              if (_showDurationPresets) ...[
                const Text(
                  'Duration (minutes):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Duration presets
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [15, 30, 45, 60, 90, 120].map((minutes) {
                    return ActionChip(
                      label: Text('$minutes min'),
                      onPressed: () => _selectDuration(minutes),
                      backgroundColor:
                          _durationController.text == minutes.toString()
                              ? TugColors.primaryPurple
                              : null,
                      labelStyle: TextStyle(
                        color: _durationController.text == minutes.toString()
                            ? Colors.white
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Duration',
                          hintText: 'Minutes',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter duration';
                          }
                          final minutes = int.tryParse(value);
                          if (minutes == null || minutes <= 0) {
                            return 'Enter a valid number of minutes';
                          }
                          if (minutes > 1440) {
                            return 'Maximum 24 hours (1440 minutes)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showDurationPresets = false;
                        });
                      },
                      child: const Text('More Options'),
                    ),
                  ],
                ),
              ],

              if (!_showDurationPresets) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter duration';
                          }
                          final minutes = int.tryParse(value);
                          if (minutes == null || minutes <= 0) {
                            return 'Enter a valid number of minutes';
                          }
                          if (minutes > 1440) {
                            return 'Maximum 24 hours (1440 minutes)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 30),
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
                            labelText: 'Date',
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
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showDurationPresets = true;
                    });
                  },
                  child: const Text('Simple View'),
                ),
              ],

              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional details',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: TugButtons.primaryButtonStyle,
                  onPressed: widget.isLoading ? null : _handleSave,
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Activity'),
                ),
              ),
            ],
          ),
        );
          },
        ),
        
        // Show streak celebration overlay if needed
        if (_showStreakCelebration)
          StreakCelebration(
            valueName: _streakValueName,
            streakCount: _streakCount,
            onDismiss: _dismissStreakCelebration,
          ),
      ],
    );
  }
}
