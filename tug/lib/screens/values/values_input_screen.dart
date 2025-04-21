// lib/screens/values/values_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/widgets/values/color_picker.dart';
import 'package:tug/widgets/values/edit_value_dialog.dart';
import 'package:tug/widgets/values/first_value_celebration.dart'; // Import the new widget
import '../../models/value_model.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/buttons.dart';
import '../../widgets/common/tug_text_field.dart';

class ValuesInputScreen extends StatefulWidget {
  const ValuesInputScreen({super.key});

  @override
  State<ValuesInputScreen> createState() => _ValuesInputScreenState();
}

class _ValuesInputScreenState extends State<ValuesInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _currentImportance = 3;
  String _selectedColor = '#7C3AED'; // Default to purple
  bool _isLoading = false;
  bool _showCelebration = false; // Track if we should show the celebration animation
  String _newValueName = ''; // Track the name of the first value for the celebration
  bool _isFirstLoad = true; // Track if this is the first load of the app

  @override
  void initState() {
    super.initState();
    // Load values when screen is initialized
    context.read<ValuesBloc>().add(LoadValues());
    // Check if this is the user's first time adding a value
    _checkFirstValueStatus();
  }

  // Check if the user has already added a value before
  Future<void> _checkFirstValueStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasAddedFirstValue = prefs.getBool('has_added_first_value') ?? false;
    setState(() {
      // We'll only show the celebration if they haven't added a value before
      _showCelebration = !hasAddedFirstValue;
    });
  }

  // Mark that the user has added their first value
  Future<void> _markFirstValueAdded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_added_first_value', true);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addValue() {
    if (_formKey.currentState?.validate() ?? false) {
      final newValue = ValueModel(
        name: _valueController.text.trim(),
        importance: _currentImportance.round(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
      );

      // Store the name of the newly added value if it's their first
      final String valueNameForCelebration = _valueController.text.trim();
      
      // Add the value via BLoC
      context.read<ValuesBloc>().add(AddValue(newValue));
      
      // Reset form
      _valueController.clear();
      _descriptionController.clear();
      setState(() {
        _currentImportance = 3;
        _selectedColor = '#7C3AED'; // Reset to default purple
      });
      
      // We'll check if we should show the celebration when the state updates
      // in the BlocListener, not right away
    }
  }

  void _handleContinue() {
    // Navigate to home screen or next onboarding step
    context.go('/home');
  }

  // New method to hide the celebration overlay
  void _dismissCelebration() {
    setState(() {
      _showCelebration = false;
    });
  }

  // New method to show the edit dialog using our new widget
  void _showEditDialog(BuildContext context, ValueModel value) {
    showDialog(
      context: context,
      builder: (context) => EditValueDialog(
        value: value,
        onSave: (updatedValue) {
          // Update the value using the bloc
          context.read<ValuesBloc>().add(UpdateValue(updatedValue));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ValuesBloc, ValuesState>(
      listener: (context, state) {
        setState(() => _isLoading = state is ValuesLoading);
        
        if (state is ValuesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: TugColors.error,
            ),
          );
        }

        // Check if values were successfully loaded
        if (state is ValuesLoaded) {
          // Only show celebration when transitioning from 0 to 1 value
          // We need to track if this is a new value being added vs. app startup
          
          // If this is their first value and they CAN see the celebration
          if (state.values.length == 1 && _showCelebration) {
            // But ONLY show it if this isn't the first load of the app
            // (i.e., only show when they actually add the value, not when loading existing values)
            if (!_isFirstLoad) {
              setState(() {
                _newValueName = state.values.first.name;
                // Show the celebration overlay
                _showCelebration = true;
              });
              
              // Mark that they've added their first value to not show again
              _markFirstValueAdded();
            }
          }
          
          // After first load, mark that subsequent state changes aren't initial loads
          if (_isFirstLoad) {
            _isFirstLoad = false;
          }
        }
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Your Values'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What matters most to you?',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add up to 5 values that guide your life',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: TugColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TugTextField(
                          label: 'Value',
                          hint: 'Enter a value (e.g., Health, Family)',
                          controller: _valueController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a value';
                            }
                            if (value.length < 2) {
                              return 'Value must be at least 2 characters';
                            }
                            if (value.length > 30) {
                              return 'Value must be at most 30 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'How important is this value? (1-5)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Slider(
                          value: _currentImportance,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _currentImportance.round().toString(),
                          activeColor: TugColors.primaryPurple,
                          onChanged: (value) {
                            setState(() {
                              _currentImportance = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TugTextField(
                          label: 'Description (Optional)',
                          hint: 'Describe why this value matters to you',
                          controller: _descriptionController,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose a color',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        ColorPicker(
                          selectedColor: _selectedColor,
                          onColorSelected: (color) {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<ValuesBloc, ValuesState>(
                          builder: (context, state) {
                            // Disable add button if we already have 5 values
                            final maxValuesReached = state is ValuesLoaded && 
                                state.values.where((v) => v.active).length >= 5;
                            
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: TugButtons.secondaryButtonStyle,
                                onPressed: (_isLoading || maxValuesReached) 
                                    ? null 
                                    : _addValue,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: TugColors.primaryPurple,
                                          ),
                                        )
                                      : Text(maxValuesReached 
                                          ? 'Maximum 5 values reached' 
                                          : 'Add Value'),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<ValuesBloc, ValuesState>(
                    builder: (context, state) {
                      if (state is ValuesLoaded) {
                        final activeValues = state.values.where((v) => v.active).toList();
                        
                        if (activeValues.isEmpty) {
                          return const Center(
                            child: Text('Add at least one value to continue'),
                          );
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Values',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            ...activeValues.map((value) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ValueCard(
                                value: value,
                                onDelete: () {
                                  context.read<ValuesBloc>().add(
                                    DeleteValue(value.id!),
                                  );
                                },
                                onEdit: () {
                                  _showEditDialog(context, value);
                                },
                              ),
                            )),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: TugButtons.primaryButtonStyle,
                                onPressed: _isLoading 
                                    ? null 
                                    : (activeValues.isNotEmpty 
                                        ? _handleContinue 
                                        : null),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Continue'),
                              ),
                            ),
                          ],
                        );
                      }
                      
                      if (state is ValuesLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Show the celebration overlay if this is the first value added
          if (_showCelebration)
            BlocBuilder<ValuesBloc, ValuesState>(
              builder: (context, state) {
                String valueName = 'Your First Value';
                if (state is ValuesLoaded && state.values.isNotEmpty) {
                  valueName = state.values.first.name;
                }
                return FirstValueCelebration(
                  valueName: valueName,
                  onDismiss: _dismissCelebration,
                );
              },
            ),
        ],
      ),
    );
  }
}

class ValueCard extends StatelessWidget {
  final ValueModel value;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ValueCard({
    super.key,
    required this.value,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final Color valueColor = Color(int.parse(value.color.substring(1), radix: 16) + 0xFF000000);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TugColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: valueColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Importance: ${value.importance}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TugColors.lightTextSecondary,
                  ),
                ),
                if (value.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    value.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TugColors.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            color: TugColors.primaryPurple,
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            color: TugColors.error,
          ),
        ],
      ),
    );
  }
}