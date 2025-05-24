// lib/screens/profile/import_activities_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/services/activity_service.dart';
import 'package:tug/services/strava_service.dart';
import 'package:tug/services/values_service.dart';
import 'package:tug/utils/theme/colors.dart';

class ImportActivitiesScreen extends StatefulWidget {
  const ImportActivitiesScreen({super.key});

  @override
  State<ImportActivitiesScreen> createState() => _ImportActivitiesScreenState();
}

class _ImportActivitiesScreenState extends State<ImportActivitiesScreen> {
  final StravaService _stravaService = StravaService();
  final ActivityService _activityService = ActivityService();
  final ValuesService _valuesService = ValuesService();

  bool _isStravaConnected = false;
  bool _isLoading = true;
  bool _isImporting = false;
  List<ActivityModel> _stravaActivities = [];
  List<ValueModel> _userValues = [];

  // Map to store selected values for each activity
  final Map<String, String> _selectedValueIds = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    // Check if connected to Strava
    final isConnected = await _stravaService.isConnected();

    if (isConnected) {
      // Load Strava activities and user values in parallel
      await Future.wait([
        _loadStravaActivities(),
        _loadUserValues(),
      ]);
    }

    setState(() {
      _isStravaConnected = isConnected;
      _isLoading = false;
    });
  }

  Future<void> _loadStravaActivities() async {
    try {
      final activities = await _stravaService.getActivities(limit: 20);
      setState(() {
        _stravaActivities = activities;
      });
    } catch (e) {
      debugPrint('Error loading Strava activities: $e');
    }
  }

  Future<void> _loadUserValues() async {
    try {
      final values = await _valuesService.getValues();
      setState(() {
        _userValues = values;
      });
    } catch (e) {
      debugPrint('Error loading user values: $e');
    }
  }

  Future<void> _connectToStrava() async {
    final result = await _stravaService.connect();

    if (result.success) {
      // Load activities after successful connection
      await Future.wait([
        _loadStravaActivities(),
        _loadUserValues(),
      ]);

      setState(() {
        _isStravaConnected = true;
      });
    }
  }

  Future<void> _importSelectedActivities() async {
    if (_selectedValueIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please assign values to activities first')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final activitiesToImport = _stravaActivities
          .where((activity) => _selectedValueIds.containsKey(activity.id))
          .map((activity) {
        // Create a new activity model with the selected value ID
        return ActivityModel(
          name: activity.name,
          valueId: _selectedValueIds[activity.id]!,
          duration: activity.duration,
          date: activity.date,
          notes: activity.notes,
          importSource: 'strava',
        );
      }).toList();

      // Import each activity
      for (final activity in activitiesToImport) {
        await _activityService.createActivity(activity);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${activitiesToImport.length} activities'),
            backgroundColor: TugColors.success,
          ),
        );

        // Return to previous screen
        context.pop();
      }
    } catch (e) {
      debugPrint('Error importing activities: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing activities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Activities'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isStravaConnected
              ? _buildConnectToStravaView()
              : _buildImportActivitiesView(),
      bottomNavigationBar: _isStravaConnected && _stravaActivities.isNotEmpty && _selectedValueIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isImporting ? null : _importSelectedActivities,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TugColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isImporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Import ${_selectedValueIds.length} Activities',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            )
          : null,
    );
  }

  Widget _buildConnectToStravaView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://cdn.iconscout.com/icon/free/png-256/free-strava-3629751-3031711.png',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFC5200), // Strava orange
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_run,
                  color: Colors.white,
                  size: 40,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Connect with Strava',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Import your runs, rides, and other activities from Strava to track them in Tug.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _connectToStrava,
            icon: const Icon(Icons.login),
            label: const Text('Connect to Strava'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC5200), // Strava orange
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportActivitiesView() {
    if (_stravaActivities.isEmpty) {
      return const Center(
        child: Text(
          'No Strava activities found. Try again later or create new activities in Strava.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Select activities to import',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Assign a value to each activity you want to import',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        ..._stravaActivities.map(_buildActivityItem),
        // Extra space at bottom for the import button
        const SizedBox(height: 70),
      ],
    );
  }

  Widget _buildActivityItem(ActivityModel activity) {
    final bool hasValue = _selectedValueIds.containsKey(activity.id);
    final selectedValueId = _selectedValueIds[activity.id];
    final ValueModel? selectedValue = selectedValueId != null
        ? _userValues.firstWhere((v) => v.id == selectedValueId,
            orElse: () => _userValues.first)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Activity icon based on type
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC5200).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getActivityIcon(activity.name),
                    color: const Color(0xFFFC5200),
                  ),
                ),
                const SizedBox(width: 12),

                // Activity title and details
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
                        '${_formatDate(activity.date)} • ${activity.duration} min',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Notes section
            if (activity.notes != null && activity.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activity.notes!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],

            // Value dropdown
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.category,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Select a value:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _userValues.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No values available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : DropdownButton<String>(
                            value: selectedValueId,
                            hint: const Text('Select a value'),
                            isExpanded: true,
                            underline: const SizedBox(), // Remove underline
                            onChanged: (String? newValue) {
                              setState(() {
                                if (newValue != null) {
                                  _selectedValueIds[activity.id!] = newValue;
                                } else {
                                  _selectedValueIds.remove(activity.id);
                                }
                              });
                            },
                            items: [
                              // First item is empty for deselection
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('None (Skip this activity)'),
                              ),
                              ..._userValues.map((value) {
                                return DropdownMenuItem<String>(
                                  value: value.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _getValueColor(value.color),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(value.name),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(String activityName) {
    final lowerName = activityName.toLowerCase();

    if (lowerName.contains('run') || lowerName.contains('marathon')) {
      return Icons.directions_run;
    } else if (lowerName.contains('ride') || lowerName.contains('cycling')) {
      return Icons.directions_bike;
    } else if (lowerName.contains('swim')) {
      return Icons.pool;
    } else if (lowerName.contains('walk') || lowerName.contains('hike')) {
      return Icons.hiking;
    } else if (lowerName.contains('yoga') || lowerName.contains('stretch')) {
      return Icons.self_improvement;
    } else {
      return Icons.fitness_center;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getValueColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return TugColors.primaryPurple;
    }

    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return TugColors.primaryPurple;
    }
  }
}
