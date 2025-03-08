// lib/screens/activity/activity_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bevent.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/utils/theme/colors.dart';

// Simple activity model for demonstration purposes
class Activity {
  final String id;
  final String name;
  final String valueId;
  final int duration; // in minutes
  final DateTime date;
  final String? notes;

  Activity({
    required this.id,
    required this.name,
    required this.valueId,
    required this.duration,
    required this.date,
    this.notes,
  });
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // Mock activities for demonstration
  final List<Activity> _activities = [
    Activity(
      id: '1',
      name: 'Morning Jog',
      valueId: 'health',
      duration: 45,
      date: DateTime.now().subtract(const Duration(hours: 5)),
      notes: 'Felt great today!',
    ),
    Activity(
      id: '2',
      name: 'Family Dinner',
      valueId: 'family',
      duration: 90,
      date: DateTime.now().subtract(const Duration(hours: 24)),
      notes: 'Had a great conversation',
    ),
    Activity(
      id: '3',
      name: 'Coding Project',
      valueId: 'career',
      duration: 120,
      date: DateTime.now().subtract(const Duration(hours: 30)),
    ),
    Activity(
      id: '4',
      name: 'Reading Book',
      valueId: 'learning',
      duration: 30,
      date: DateTime.now().subtract(const Duration(hours: 48)),
      notes: 'Half-way through',
    ),
  ];

  // Value name lookup map
  Map<String, String> _valueNames = {};
  Map<String, String> _valueColors = {};

  @override
  void initState() {
    super.initState();
    // Load values for reference
    context.read<ValuesBloc>().add(LoadValues());
  }

  void _showAddActivitySheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final durationController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedValueId;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return BlocBuilder<ValuesBloc, ValuesState>(
          builder: (context, state) {
            List<ValueModel> values = [];
            if (state is ValuesLoaded) {
              values = state.values.where((v) => v.active).toList();
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log Activity',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Activity Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an activity name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedValueId,
                        items: values.map((value) {
                          return DropdownMenuItem(
                            value: value.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(value.color.substring(1), radix: 16) + 
                                      0xFF000000,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(value.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? valueId) {
                          selectedValueId = valueId;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a value';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: durationController,
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
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  selectedDate = picked;
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
                                      '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                                    ),
                                    const Icon(Icons.calendar_today, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: TugButtons.primaryButtonStyle,
                          onPressed: () {
                            if (formKey.currentState?.validate() ?? false) {
                              // Add activity (in a real app, this would call a bloc/repository)
                              setState(() {
                                _activities.insert(
                                  0,
                                  Activity(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    name: nameController.text,
                                    valueId: selectedValueId!,
                                    duration: int.parse(durationController.text),
                                    date: selectedDate,
                                    notes: notesController.text.isEmpty
                                        ? null
                                        : notesController.text,
                                  ),
                                );
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Save Activity'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showActivityDetails(BuildContext context, Activity activity) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(activity.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Value: ${_valueNames[activity.valueId] ?? activity.valueId}'),
              const SizedBox(height: 8),
              Text('Duration: ${activity.duration} minutes'),
              const SizedBox(height: 8),
              Text('Date: ${activity.date.month}/${activity.date.day}/${activity.date.year}'),
              if (activity.notes != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(activity.notes!),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // Delete activity (in a real app, this would call a bloc/repository)
                setState(() {
                  _activities.removeWhere((a) => a.id == activity.id);
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: TugColors.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Tracking'),
      ),
      body: BlocListener<ValuesBloc, ValuesState>(
        listener: (context, state) {
          if (state is ValuesLoaded) {
            // Update value name lookup map
            _valueNames = {};
            _valueColors = {};
            for (final value in state.values) {
              if (value.id != null) {
                _valueNames[value.id!] = value.name;
                _valueColors[value.id!] = value.color;
              }
            }
          }
        },
        child: _activities.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No activities logged yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start tracking time spent on your values',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: TugButtons.primaryButtonStyle,
                      onPressed: () {
                        _showAddActivitySheet(context);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Log Activity'),
                    ),
                  ],
                ),
              )
            : BlocBuilder<ValuesBloc, ValuesState>(
                builder: (context, state) {
                  if (state is ValuesLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _activities.length + 1, // +1 for the summary
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Summary card
                        final totalMinutes = _activities.fold(
                          0,
                          (sum, activity) => sum + activity.duration,
                        );
                        final hours = totalMinutes ~/ 60;
                        final minutes = totalMinutes % 60;
                        final timeDisplay = hours > 0
                            ? '$hours hr ${minutes > 0 ? '$minutes min' : ''}'
                            : '$minutes min';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Activity Summary',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildSummaryItem(
                                      'Total Time',
                                      timeDisplay,
                                      Icons.access_time,
                                    ),
                                    _buildSummaryItem(
                                      'Activities',
                                      _activities.length.toString(),
                                      Icons.event_note,
                                    ),
                                    _buildSummaryItem(
                                      'Values',
                                      _activities
                                          .map((a) => a.valueId)
                                          .toSet()
                                          .length
                                          .toString(),
                                      Icons.star,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final activity = _activities[index - 1];
                      final valueName = _valueNames[activity.valueId] ??
                          activity.valueId;
                      final valueColor = _valueColors[activity.valueId] ??
                          '#7C3AED'; // Default to purple

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            _showActivityDetails(context, activity);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(valueColor.substring(1), radix: 16) +
                                          0xFF000000,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${activity.duration}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(
                                          int.parse(valueColor.substring(1), radix: 16) +
                                              0xFF000000,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activity.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        valueName,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _getRelativeTime(activity.date),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${activity.duration} min',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddActivitySheet(context);
        },
        backgroundColor: TugColors.primaryPurple,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: TugColors.primaryPurple,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}