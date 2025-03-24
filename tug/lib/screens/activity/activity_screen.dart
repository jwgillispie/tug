// lib/screens/activity/activity_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tug/blocs/activities/activities_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/widgets/activity/activity_form.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String? _filterValueId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Load activities and values when screen is initialized
    context.read<ActivitiesBloc>().add(const LoadActivities());
  }

  void _showAddActivitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Log Activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BlocListener<ActivitiesBloc, ActivitiesState>(
                listener: (context, state) {
                  if (state is ActivityOperationSuccess) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: TugColors.success,
                      ),
                    );
                  } else if (state is ActivitiesError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: TugColors.error,
                      ),
                    );
                  }
                },
                child: ActivityFormWidget(
                  isLoading: context.watch<ActivitiesBloc>().state
                      is ActivitiesLoading,
                  onSave: (name, valueId, duration, date, notes) {
                    final activity = ActivityModel(
                      name: name,
                      valueId: valueId,
                      duration: duration,
                      date: date,
                      notes: notes,
                    );

                    context.read<ActivitiesBloc>().add(AddActivity(activity));
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showActivityDetails(
      ActivityModel activity, String valueName, String valueColor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(activity.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(
                          int.parse(valueColor.substring(1), radix: 16) +
                              0xFF000000),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Value: $valueName'),
                ],
              ),
              const SizedBox(height: 8),
              Text('Duration: ${activity.duration} minutes'),
              const SizedBox(height: 8),
              Text('Date: ${DateFormat('MMM d, yyyy').format(activity.date)}'),
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
                Navigator.pop(context);
                // Implement edit functionality
                _showEditActivitySheet(activity);
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmation(activity);
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

  void _showEditActivitySheet(ActivityModel activity) {
    // Implementation will be similar to _showAddActivitySheet but with pre-filled values
    // This can be expanded later
  }

  void _showDeleteConfirmation(ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: Text('Are you sure you want to delete "${activity.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context
                    .read<ActivitiesBloc>()
                    .add(DeleteActivity(activity.id!));
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
        actions: [
          IconButton(
            icon:
                Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          if (_showFilters) _buildFilters(),

          // Activities List
          Expanded(
            child: BlocBuilder<ActivitiesBloc, ActivitiesState>(
              builder: (context, state) {
                if (state is ActivitiesLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is ActivitiesError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: TugColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<ActivitiesBloc>()
                                .add(const LoadActivities());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final List<ActivityModel> activities;
                if (state is ActivitiesLoaded) {
                  activities = state.activities;
                } else {
                  activities = [];
                }

                if (activities.isEmpty) {
                  return Center(
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
                          onPressed: _showAddActivitySheet,
                          icon: const Icon(Icons.add),
                          label: const Text('Log Activity'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];

                    // Find value name and color using BLoC
                    String valueName = 'Unknown Value';
                    String valueColor = '#7C3AED'; // Default purple

                    // Get value name from BLoC state
                    final valuesState = context.watch<ValuesBloc>().state;
                    if (valuesState is ValuesLoaded) {
                      final value = valuesState.values.firstWhere(
                        (v) => v.id == activity.valueId,
                        orElse: () => const ValueModel(
                          name: 'Unknown Value',
                          importance: 1,
                          color: '#7C3AED',
                        ),
                      );
                      valueName = value.name;
                      valueColor = value.color;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          _showActivityDetails(activity, valueName, valueColor);
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
                                    int.parse(valueColor.substring(1),
                                            radix: 16) +
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
                                        int.parse(valueColor.substring(1),
                                                radix: 16) +
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActivitySheet,
        backgroundColor: TugColors.primaryPurple,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Activities',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          // Value Filter
          BlocBuilder<ValuesBloc, ValuesState>(
            builder: (context, state) {
              final values = state is ValuesLoaded
                  ? state.values.where((v) => v.active).toList()
                  : <ValueModel>[];

              return DropdownButtonFormField<String?>(
                decoration: const InputDecoration(
                  labelText: 'Filter by Value',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                value: _filterValueId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Values'),
                  ),
                  ...values.map((value) {
                    final valueColor = Color(
                      int.parse(value.color.substring(1), radix: 16) +
                          0xFF000000,
                    );

                    return DropdownMenuItem(
                      value: value.id,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
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
                ],
                onChanged: (String? valueId) {
                  setState(() {
                    _filterValueId = valueId;
                  });

                  context.read<ActivitiesBloc>().add(
                        LoadActivities(
                          valueId: valueId,
                          startDate: _startDate,
                          endDate: _endDate,
                        ),
                      );
                },
              );
            },
          ),

          const SizedBox(height: 16),

          // Date Range Filter
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                      });

                      context.read<ActivitiesBloc>().add(
                            LoadActivities(
                              valueId: _filterValueId,
                              startDate: _startDate,
                              endDate: _endDate,
                            ),
                          );
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _startDate != null
                              ? DateFormat('MMM d, yyyy').format(_startDate!)
                              : 'Any Date',
                        ),
                        const Icon(Icons.calendar_today, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ??
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked;
                      });

                      context.read<ActivitiesBloc>().add(
                            LoadActivities(
                              valueId: _filterValueId,
                              startDate: _startDate,
                              endDate: _endDate,
                            ),
                          );
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _endDate != null
                              ? DateFormat('MMM d, yyyy').format(_endDate!)
                              : 'Today',
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

          // Reset Filters Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterValueId = null;
                  _startDate = null;
                  _endDate = null;
                });

                context.read<ActivitiesBloc>().add(const LoadActivities());
              },
              child: const Text('Reset Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
