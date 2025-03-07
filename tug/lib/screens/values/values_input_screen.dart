// lib/screens/values/values_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bevent.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/widgets/values/color_picker.dart';
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
    // Navigate to home screen or next onboarding step
    context.go('/home');
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
      },
      child: Scaffold(
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
    );
  }

  Future<void> _showEditDialog(BuildContext context, ValueModel value) async {
    final nameController = TextEditingController(text: value.name);
    final descriptionController = TextEditingController(text: value.description);
    double importance = value.importance.toDouble();
    String color = value.color;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Value'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TugTextField(
                label: 'Value',
                controller: nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Importance: ${importance.round()}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              StatefulBuilder(
                builder: (context, setState) => Slider(
                  value: importance,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: importance.round().toString(),
                  activeColor: TugColors.primaryPurple,
                  onChanged: (value) {
                    setState(() {
                      importance = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              TugTextField(
                label: 'Description (Optional)',
                controller: descriptionController,
              ),
              const SizedBox(height: 16),
              Text(
                'Color',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) => ColorPicker(
                  selectedColor: color,
                  onColorSelected: (newColor) {
                    setState(() {
                      color = newColor;
                    });
                  },
                ),
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
              if (nameController.text.trim().isNotEmpty) {
                final updatedValue = value.copyWith(
                  name: nameController.text.trim(),
                  importance: importance.round(),
                  description: descriptionController.text.trim(),
                  color: color,
                );
                
                context.read<ValuesBloc>().add(UpdateValue(updatedValue));
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
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