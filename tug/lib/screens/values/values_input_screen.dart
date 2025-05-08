// lib/screens/values/values_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/widgets/values/color_picker.dart';
import 'package:tug/widgets/values/edit_value_dialog.dart';
import 'package:tug/widgets/values/first_value_celebration.dart';
import '../../models/value_model.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/buttons.dart';
import '../../widgets/common/tug_text_field.dart';

class ValuesInputScreen extends StatefulWidget {
  // Add parameter to detect if coming from home screen
  final bool fromHome;
  
  const ValuesInputScreen({super.key, this.fromHome = false});

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
  bool _showCelebration = false;
  String _newValueName = '';
  
  // Keep track of previous state to detect transitions
  int _previousValueCount = 0;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    // Load values when screen is initialized
    context.read<ValuesBloc>().add(LoadValues());
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

      // Store the name of the newly added value for celebration
      _newValueName = _valueController.text.trim();
      
      // Add the value via BLoC
      context.read<ValuesBloc>().add(AddValue(newValue));
      
      // Reset form
      _valueController.clear();
      _descriptionController.clear();
      setState(() {
        _currentImportance = 3;
        _selectedColor = '#7C3AED'; // Reset to default purple
      });
    }
  }

  void _handleContinue() {
    // Navigate to home screen or back, depending on where we came from
    if (widget.fromHome) {
      context.pop(); // Go back to home if we came from there
    } else {
      context.go('/home'); // Otherwise go to home
    }
  }

  // Method to hide the celebration overlay
  void _dismissCelebration() {
    setState(() {
      _showCelebration = false;
    });
  }

  // Method to show the edit dialog
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
          final currentValues = state.values.where((v) => v.active).toList();
          final currentCount = currentValues.length;
          
          // Detect transition from 0 to 1 values, but not on first load
          if (currentCount == 1 && _previousValueCount == 0 && !_isFirstLoad) {
            setState(() {
              _showCelebration = true;
              _newValueName = currentValues.first.name;
            });
          }
          
          // Store the current count for next comparison
          _previousValueCount = currentCount;
          
          // After first load, mark that we're no longer in initial load
          if (_isFirstLoad) {
            _isFirstLoad = false;
          }
        }
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Values'),
              // Add back button if we came from home screen
              leading: widget.fromHome 
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    )
                  : null,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fromHome
                        ? 'Edit your values'
                        : 'What do you care about more than anything else?',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can pick up to 5 things',
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
                          hint: 'Think Health, Family, Creativity, Learning ',
                          controller: _valueController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a value';
                            }
                            if (value.length < 2) {
                              return 'Value gotta be longer than that';
                            }
                            if (value.length > 30) {
                              return 'Okay that\'s awesome but can you make it a little shorter?';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'How important is this value? (meh - everything)',
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
                          hint: 'Why?',
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
                                          ? 'Okay! 5 values! AWESOME' 
                                          : 'Add'),
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
                            child: Text('Gotta have at least one value :)'),
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
                                    : Text(widget.fromHome ? 'Done' : 'GO!'),
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
          
          // Show the celebration overlay if we just added the first value
          if (_showCelebration)
            FirstValueCelebration(
              valueName: _newValueName,
              onDismiss: _dismissCelebration,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (value.currentStreak > 0 || value.longestStreak > 0) ...[
            const SizedBox(height: 12),
            Divider(color: TugColors.lightBorder),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStreakIndicator(
                  context: context,
                  icon: Icons.local_fire_department,
                  color: Color(0xFFF57C00), // Orange
                  label: 'Current Streak',
                  value: '${value.currentStreak} day${value.currentStreak != 1 ? 's' : ''}',
                ),
                _buildStreakIndicator(
                  context: context,
                  icon: Icons.emoji_events,
                  color: Color(0xFFFFD700), // Gold
                  label: 'Best Streak',
                  value: '${value.longestStreak} day${value.longestStreak != 1 ? 's' : ''}',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStreakIndicator({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TugColors.lightTextSecondary,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}