// lib/screens/values/values_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final List<ValueItem> _values = [];
  double _currentImportance = 3;
  bool _isLoading = false;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _addValue() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_values.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 5 values allowed'),
            backgroundColor: TugColors.error,
          ),
        );
        return;
      }

      setState(() {
        _values.add(
          ValueItem(
            name: _valueController.text,
            importance: _currentImportance.round(),
          ),
        );
        _valueController.clear();
        _currentImportance = 3;
      });
    }
  }

  void _removeValue(int index) {
    setState(() {
      _values.removeAt(index);
    });
  }

  void _handleSubmit() {
    if (_values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one value'),
          backgroundColor: TugColors.error,
        ),
      );
      return;
    }

    // TODO: Implement value submission to backend
    setState(() => _isLoading = true);
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isLoading = false);
      // Navigate to home screen after successful submission
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onChanged: (value) {
                      setState(() {
                        _currentImportance = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: TugButtons.secondaryButtonStyle,
                      onPressed: _values.length >= 5 ? null : _addValue,
                      child: const Text('Add Value'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_values.isNotEmpty) ...[
              Text(
                'Your Values',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ..._values.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ValueCard(
                    value: value,
                    onDelete: () => _removeValue(index),
                  ),
                );
              }),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: TugButtons.primaryButtonStyle,
                  onPressed: _isLoading ? null : _handleSubmit,
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
          ],
        ),
      ),
    );
  }
}

class ValueItem {
  final String name;
  final int importance;

  ValueItem({
    required this.name,
    required this.importance,
  });
}

class ValueCard extends StatelessWidget {
  final ValueItem value;
  final VoidCallback onDelete;

  const ValueCard({
    super.key,
    required this.value,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
              ],
            ),
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