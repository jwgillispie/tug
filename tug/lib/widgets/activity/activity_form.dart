// lib/widgets/activity/activity_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/models/mood_model.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/time_utils.dart';
import 'package:tug/widgets/values/streak_celebration.dart';
import 'package:tug/widgets/mood/mood_selector.dart';

class ActivityFormWidget extends StatefulWidget {
  final Function(String name, List<String> valueIds, int duration, DateTime date,
      String? notes, bool isPublic, bool notesPublic, MoodType? mood) onSave;
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

  List<String> _selectedValueIds = []; // Changed to support multiple values
  DateTime _selectedDate = DateTime.now();
  bool _showDurationPresets = true;
  bool _showStreakCelebration = false;
  String _streakValueName = '';
  int _streakCount = 0;
  bool _isSaving = false;
  bool _isPublic = true; // Default to public for social sharing
  bool _notesPublic = false; // Default notes to private for privacy
  MoodType? _selectedMood; // User's current mood

  @override
  void initState() {
    super.initState();
    // Listen to notes changes to show/hide notes privacy toggle
    _notesController.addListener(() {
      setState(() {
        // Force rebuild to show/hide notes privacy toggle
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // Prevent multiple saves
    if (_isSaving) return;
    
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedValueIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('please select at least one value'),
            backgroundColor: TugColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      final name = _nameController.text.trim();
      final duration = int.tryParse(_durationController.text) ?? 0;
      final notes =
          _notesController.text.isEmpty ? null : _notesController.text;

      // Load streak stats for the primary selected value to see if we need to show a celebration
      context.read<ValuesBloc>().add(LoadStreakStats(valueId: _selectedValueIds.first));
      
      // After creating the activity, wait for it to be processed, then check streak milestones
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        
        final valuesState = context.read<ValuesBloc>().state;
        if (valuesState is ValuesLoaded) {
          final selectedValue = valuesState.values.firstWhere(
            (v) => v.id == _selectedValueIds.first, // Use primary value for streak celebration
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
            if (mounted) {
              setState(() {
                _streakValueName = selectedValue.name;
                _streakCount = selectedValue.currentStreak;
                _showStreakCelebration = true;
              });
            }
          }
        }
      });

      widget.onSave(name, _selectedValueIds, duration, _selectedDate, notes, _isPublic, _notesPublic, _selectedMood);
    }
  }
  
  void _dismissStreakCelebration() {
    setState(() {
      _showStreakCelebration = false;
    });
  }

  @override
  void didUpdateWidget(ActivityFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reset saving state when the external loading state changes from true to false
    if (oldWidget.isLoading && !widget.isLoading && _isSaving) {
      setState(() {
        _isSaving = false;
      });
    }
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
            if (values.isNotEmpty && _selectedValueIds.isEmpty) {
              // Direct assignment is safe here as we're just initializing the value
              _selectedValueIds = [values.first.id!];

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
                      labelText: 'activity name',
                      hintText: 'what did you do?',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'please enter an activity name';
                      }
                      if (value.length < 2) {
                        return 'activity name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Multi-Value Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Related Values',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select which values this activity supports (tap to toggle)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Selected values display
                      if (_selectedValueIds.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedValueIds.map((valueId) {
                              final value = values.firstWhere((v) => v.id == valueId);
                              final valueColor = Color(
                                int.parse(value.color.substring(1), radix: 16) + 0xFF000000,
                              );
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: valueColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: valueColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: valueColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      value.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: valueColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedValueIds.remove(valueId);
                                        });
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: valueColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Available values list
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: values.length,
                          itemBuilder: (context, index) {
                            final value = values[index];
                            final isSelected = _selectedValueIds.contains(value.id);
                            final valueColor = Color(
                              int.parse(value.color.substring(1), radix: 16) + 0xFF000000,
                            );
                            
                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: valueColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? valueColor : Colors.grey.shade400,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              title: Text(
                                value.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? valueColor : null,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedValueIds.remove(value.id);
                                  } else {
                                    _selectedValueIds.add(value.id!);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      // Validation error display
                      if (_selectedValueIds.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Please select at least one value',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Duration Input
                  if (_showDurationPresets) ...[
                    const Text(
                      'duration (minutes):',
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
                              TimeUtils.formatMinutes(minutes),
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
                              labelText: 'custom duration',
                              hintText: 'minutes',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'please enter duration';
                              }
                              final minutes = int.tryParse(value);
                              if (minutes == null || minutes <= 0) {
                                return 'enter a valid number of minutes';
                              }
                              if (minutes > 1440) {
                                return 'maximum 24 hours (1440 minutes)';
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
                          label: const Text('more options'),
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
                              labelText: 'duration (minutes)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'please enter duration';
                              }
                              final minutes = int.tryParse(value);
                              if (minutes == null || minutes <= 0) {
                                return 'enter a valid number of minutes';
                              }
                              if (minutes > 1440) {
                                return 'maximum 24 hours (1440 minutes)';
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
                                labelText: 'date',
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
                        label: const Text('back to simple view'),
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
                      labelText: 'notes (optional)',
                      hintText: 'add any additional details',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 16),

                  // Mood Selection
                  MoodSelector(
                    selectedMood: _selectedMood,
                    onMoodSelected: (mood) {
                      setState(() {
                        _selectedMood = mood;
                      });
                    },
                    isDarkMode: Theme.of(context).brightness == Brightness.dark,
                  ),

                  const SizedBox(height: 16),

                  // Privacy Controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'privacy settings',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Share Activity Toggle
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'share activity',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'post this activity to your social feed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPublic,
                              onChanged: (value) {
                                setState(() {
                                  _isPublic = value;
                                  // If activity is private, notes should be private too
                                  if (!value) {
                                    _notesPublic = false;
                                  }
                                });
                              },
                              activeColor: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                        
                        // Include Notes Toggle (only show if activity is public and notes exist)
                        if (_isPublic && _notesController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'include notes',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'share your notes with friends',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _notesPublic,
                                onChanged: (value) {
                                  setState(() {
                                    _notesPublic = value;
                                  });
                                },
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Saving status message
                  if (_isSaving || widget.isLoading) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TugColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: TugColors.primaryPurple.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: TugColors.primaryPurple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'saving your activity... please wait',
                              style: TextStyle(
                                color: TugColors.primaryPurple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: TugButtons.primaryButtonStyle(
                        isDark: Theme.of(context).brightness == Brightness.dark
                      ),
                      onPressed: (_isSaving || widget.isLoading) ? null : _handleSave,
                      child: (_isSaving || widget.isLoading)
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('save activity'),
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