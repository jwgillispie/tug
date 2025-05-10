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
    super.key,
    required this.onSave,
    this.isLoading = false,
  });

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
            // Important: Don't use setState during build phase
            if (values.isNotEmpty && _selectedValueId == null) {
              // Direct assignment is safe here as we're just initializing the value
              _selectedValueId = values.first.id;

              // Schedule setState for after the build is complete
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    // This will trigger a rebuild in the next frame
                  });
                }
              });
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
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

                  // Value Selector - Improved to clearly show the selected value
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Related Value',
                      hintText: 'Which value does this support?',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    isExpanded: true, // Important for preventing overflow
                    icon: const Icon(Icons.arrow_drop_down_circle),
                    menuMaxHeight: 300, // Set max height for dropdown menu
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    value: _selectedValueId,
                    selectedItemBuilder: (context) {
                      // This builds what shows when an item is selected in the dropdown
                      return values.map((value) {
                        final valueColor = Color(
                          int.parse(value.color.substring(1), radix: 16) + 0xFF000000,
                        );

                        // Make the selected item clearly visible with color and name
                        return Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: valueColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                value.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).brightness == Brightness.light
                                      ? Colors.black87
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                    items: values.map((value) {
                      final valueColor = Color(
                        int.parse(value.color.substring(1), radix: 16) + 0xFF000000,
                      );

                      return DropdownMenuItem<String>(
                        value: value.id,
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
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
                                Expanded(
                                  child: Text(
                                    value.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2, // Allow up to 2 lines for longer or all-caps text
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.2, // Tighter line height for better fit
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? id) {
                      setState(() {
                        _selectedValueId = id;
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

                    // Duration presets - contained in a SizedBox with specified width for better layout control
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.start,
                        children: [15, 30, 45, 60, 90, 120].map((minutes) {
                          return ActionChip(
                            label: Text(
                              '$minutes min',
                              style: TextStyle(
                                fontSize: 13,
                                color: _durationController.text == minutes.toString()
                                    ? Colors.white
                                    : Theme.of(context).brightness == Brightness.light
                                        ? TugColors.lightTextPrimary
                                        : TugColors.darkTextPrimary,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _selectDuration(minutes),
                            backgroundColor:
                                _durationController.text == minutes.toString()
                                    ? TugColors.primaryPurple
                                    : Theme.of(context).brightness == Brightness.light
                                        ? TugColors.lightSurfaceVariant
                                        : TugColors.darkSurfaceVariant,
                          );
                        }).toList(),
                      ),
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
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showDurationPresets = false;
                            });
                          },
                          icon: const Icon(Icons.more_horiz, size: 16),
                          label: const Text('More Options'),
                          style: TugButtons.tertiaryButtonStyle(
                            isDark: Theme.of(context).brightness == Brightness.dark
                          ).copyWith(
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
                            ),
                            minimumSize: WidgetStateProperty.all(const Size(40, 36)),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (!_showDurationPresets) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: const InputDecoration(
                              labelText: 'Duration (minutes)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                          child: GestureDetector(
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
                              decoration: InputDecoration(
                                labelText: 'Date',
                                border: const OutlineInputBorder(),
                                fillColor: Theme.of(context).brightness == Brightness.light
                                    ? TugColors.lightSurfaceVariant
                                    : TugColors.darkSurfaceVariant,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      DateFormat('MMM d, yyyy').format(_selectedDate),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).brightness == Brightness.light
                                            ? TugColors.lightTextPrimary
                                            : TugColors.darkTextPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Theme.of(context).brightness == Brightness.light
                                        ? TugColors.primaryPurple
                                        : TugColors.primaryPurpleLight,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showDurationPresets = true;
                          });
                        },
                        icon: const Icon(Icons.chevron_left, size: 18),
                        label: const Text('Back to Simple View'),
                        style: TugButtons.tertiaryButtonStyle(
                          isDark: Theme.of(context).brightness == Brightness.dark
                        ).copyWith(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                          ),
                        ),
                      ),
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
                      style: TugButtons.primaryButtonStyle(
                        isDark: Theme.of(context).brightness == Brightness.dark
                      ),
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