// lib/screens/activity/activity_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tug/blocs/activities/activities_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/widgets/activity/activity_form.dart';
import 'package:tug/widgets/activity/edit_activity_dialog.dart';

class ActivityScreen extends StatefulWidget {
  final bool showAddForm;

  const ActivityScreen({
    super.key,
    this.showAddForm = false,
  });

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  String? _filterValueId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    // Load activities and values when screen is initialized, but don't force a refresh
    context.read<ActivitiesBloc>().add(const LoadActivities(forceRefresh: false));
    context.read<ValuesBloc>().add(const LoadValues(forceRefresh: false));

    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _animationController.forward();

    // Show add activity form if flagged
    if (widget.showAddForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddActivitySheet();
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Implement wantKeepAlive for AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;
  
  // Add a refresh method
  void _refreshActivities() {
    context.read<ActivitiesBloc>().add(LoadActivities(
      valueId: _filterValueId,
      startDate: _startDate,
      endDate: _endDate,
      forceRefresh: true, // Force refresh from server
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing activities...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showAddActivitySheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? TugColors.darkSurface : Colors.white,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = Color(int.parse(valueColor.substring(1), radix: 16) + 0xFF000000);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? TugColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            activity.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDarkMode ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? Colors.white24 : Colors.black12,
                          width: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Value: $valueName',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                isDarkMode: isDarkMode,
                icon: Icons.timer_outlined,
                iconColor: color,
                label: 'Duration:',
                value: '${activity.duration} minutes',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                isDarkMode: isDarkMode,
                icon: Icons.calendar_today_outlined,
                iconColor: color,
                label: 'Date:',
                value: DateFormat('MMM d, yyyy').format(activity.date),
              ),
              if (activity.notes != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Notes:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? TugColors.darkSurfaceVariant.withOpacity(0.5)
                        : TugColors.lightSurfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? Colors.white12 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    activity.notes!,
                    style: TextStyle(
                      color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                    ),
                  ),
                ),
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
    // Show the edit activity dialog
    showDialog(
      context: context,
      builder: (context) => EditActivityDialog(
        activity: activity,
        onSave: (updatedActivity) {
          // Update the activity using the bloc
          context.read<ActivitiesBloc>().add(UpdateActivity(updatedActivity));
        },
      ),
    );
  }

  void _showDeleteConfirmation(ActivityModel activity) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? TugColors.darkSurface : Colors.white,
          title: const Text('Delete Activity'),
          content: Text('You deadass want to delete "${activity.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Nah'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (activity.id != null) {
                  context
                      .read<ActivitiesBloc>()
                      .add(DeleteActivity(activity.id!));
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: TugColors.error,
              ),
              child: const Text('Yes bro'),
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
    // Must call super.build for AutomaticKeepAliveClientMixin
    super.build(context);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshActivities,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Activity Summary Card
            _buildActivitySummary(),
    
            // Filters
            if (_showFilters) _buildFilters(),
    
            // Activities List
            Expanded(
              child: BlocBuilder<ActivitiesBloc, ActivitiesState>(
                builder: (context, state) {
                  if (state is ActivitiesLoading && _isFirstLoad) {
                    // Only show loading indicator on first load
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
                            onPressed: _refreshActivities,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
    
                  // We're no longer on first load
                  _isFirstLoad = false;
    
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
                          Icon(
                            Icons.history,
                            size: 64,
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Not shit here',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Get tugging on them activities',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: TugButtons.primaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                                onPressed: _showAddActivitySheet,
                                icon: const Icon(Icons.add),
                                label: const Text('Log Activity'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/import-activities');
                                },
                                icon: const Icon(Icons.cloud_download),
                                label: const Text('Import from Strava'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: TugColors.primaryPurple),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
    
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    child: Column(
                      children: activities.map((activity) {
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
      
                        return _buildActivityCard(activity, valueName, valueColor);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity, String valueName, String valueColor) {
    final color = Color(int.parse(valueColor.substring(1), radix: 16) + 0xFF000000);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? TugColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2) 
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.05) 
              : Colors.black.withOpacity(0.03),
          width: 0.5,
        ),
      ),
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDarkMode ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withOpacity(isDarkMode ? 0.3 : 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${activity.duration}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'min',
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          valueName,
                          style: TextStyle(
                            color: color.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _getRelativeTime(activity.date),
                          style: TextStyle(
                            color: isDarkMode 
                                ? Colors.grey.shade400 
                                : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySummary() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? TugColors.darkSurface : TugColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2) 
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.05) 
              : Colors.black.withOpacity(0.03),
          width: 0.5,
        ),
      ),
      child: BlocBuilder<ActivitiesBloc, ActivitiesState>(
        builder: (context, state) {
          if (state is ActivitiesLoaded) {
            final activities = state.activities;

            if (activities.isEmpty) {
              return Center(
                child: Text(
                  'It\'s empty and lonley over here',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              );
            }

            // Calculate total time
            final totalTime = activities.fold<int>(
                0, (sum, activity) => sum + activity.duration);

            // Calculate activities per value
            final valuesMap = <String, int>{};
            for (final activity in activities) {
              valuesMap.update(
                activity.valueId,
                (count) => count + 1,
                ifAbsent: () => 1,
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  title: 'Activities',
                  value: activities.length.toString(),
                  icon: Icons.history,
                ),
                _buildSummaryItem(
                  title: 'Values',
                  value: valuesMap.length.toString(),
                  icon: Icons.star,
                ),
                _buildSummaryItem(
                  title: 'Total Time',
                  value: '${totalTime}m',
                  icon: Icons.access_time,
                ),
                
                // Import button
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/import-activities');
                  },
                  tooltip: 'Import Activities',
                  icon: const Icon(
                    Icons.cloud_download_outlined,
                    color: TugColors.primaryPurple,
                  ),
                ),
              ],
            );
          }

          return Center(
            child: Text(
              'Hold onnnn...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Helper function to build detail rows with consistent styling
  Widget _buildDetailRow({
    required bool isDarkMode,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode
                    ? TugColors.darkTextSecondary
                    : TugColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDarkMode
                    ? TugColors.darkTextPrimary
                    : TugColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDarkMode ? TugColors.darkBackground : Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Activities',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _filterValueId = null;
                    _startDate = null;
                    _endDate = null;
                    _showFilters = false;
                  });

                  context.read<ActivitiesBloc>().add(const LoadActivities());
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Value Filter
          BlocBuilder<ValuesBloc, ValuesState>(
            builder: (context, state) {
              final values = state is ValuesLoaded
                  ? state.values.where((v) => v.active).toList()
                  : <ValueModel>[];

              return DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  labelText: 'Filter by Value',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  filled: true,
                  fillColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
                ),
                value: _filterValueId,
                dropdownColor: isDarkMode ? TugColors.darkSurface : Colors.white,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'All Values',
                      style: TextStyle(
                        color: isDarkMode 
                            ? TugColors.darkTextPrimary 
                            : TugColors.lightTextPrimary,
                      ),
                    ),
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
                          Text(
                            value.name,
                            style: TextStyle(
                              color: isDarkMode 
                                  ? TugColors.darkTextPrimary 
                                  : TugColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
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
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: isDarkMode
                                ? const ColorScheme.dark(
                                    primary: TugColors.primaryPurple,
                                    onPrimary: Colors.white,
                                    surface: TugColors.darkSurface,
                                    onSurface: TugColors.darkTextPrimary,
                                  )
                                : const ColorScheme.light(
                                    primary: TugColors.primaryPurple,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: TugColors.lightTextPrimary,
                                  ),
                          ),
                          child: child!,
                        );
                      },
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
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      filled: true,
                      fillColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
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
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: isDarkMode
                                ? const ColorScheme.dark(
                                    primary: TugColors.primaryPurple,
                                    onPrimary: Colors.white,
                                    surface: TugColors.darkSurface,
                                    onSurface: TugColors.darkTextPrimary,
                                  )
                                : const ColorScheme.light(
                                    primary: TugColors.primaryPurple,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: TugColors.lightTextPrimary,
                                  ),
                          ),
                          child: child!,
                        );
                      },
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
                    decoration: InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      filled: true,
                      fillColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
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
        ],
      ),
    );
  }
}