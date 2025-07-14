// lib/screens/activity/activity_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tug/blocs/activities/activities_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/quantum_effects.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/utils/time_utils.dart';
import 'package:tug/widgets/activity/activity_form.dart';
import 'package:tug/widgets/activity/edit_activity_dialog.dart';
import 'package:tug/services/app_mode_service.dart';
import 'package:tug/services/activity_service.dart';
import 'package:tug/blocs/vices/bloc/vices_bloc.dart';
import 'package:tug/blocs/vices/bloc/vices_event.dart';
import 'package:tug/blocs/vices/bloc/vices_state.dart';
import 'package:tug/models/mood_model.dart';
import 'package:tug/services/mood_service.dart';

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
  bool _showSwipeHint = true;
  final AppModeService _appModeService = AppModeService();
  final ActivityService _activityService = ActivityService();
  final MoodService _moodService = MoodService();
  AppMode _currentMode = AppMode.valuesMode;

  @override
  void initState() {
    super.initState();
    
    // Initialize mode service and load appropriate data
    _initializeAppMode();
    
    // Load activities (always load these)
    context.read<ActivitiesBloc>().add(const LoadActivities(forceRefresh: false));
    
    // Load mode-specific data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_currentMode == AppMode.valuesMode) {
          context.read<ValuesBloc>().add(const LoadValues(forceRefresh: false));
        } else {
          context.read<VicesBloc>().add(const LoadVices());
        }
      }
    });

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

    // Check if swipe hint has been shown before
    _checkSwipeHintStatus();

    // Show add activity form if flagged
    if (widget.showAddForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddActivitySheet();
      });
    }
  }
  
  void _checkSwipeHintStatus() async {
    // This could be expanded to use SharedPreferences to persist the setting
    // For now, we'll just use the in-memory state
    // If we wanted to persist:
    // final prefs = await SharedPreferences.getInstance();
    // setState(() {
    //   _showSwipeHint = prefs.getBool('show_swipe_hint') ?? true;
    // });
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
  Future<void> _refreshActivities() async {
    // Clear activity cache before refreshing
    try {
      await _activityService.clearCache();
    } catch (e) {
      // Cache clear failed - not critical, continue with refresh
    }
    
    context.read<ActivitiesBloc>().add(LoadActivities(
      valueId: _filterValueId,
      startDate: _startDate,
      endDate: _endDate,
      forceRefresh: true, // Force refresh from server
    ));
    
    // Add a small delay to ensure the refresh indicator shows
    await Future.delayed(const Duration(milliseconds: 500));
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'log activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate back to the activities route when manually closed
                      if (widget.showAddForm) {
                        GoRouter.of(context).go('/activities');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BlocListener<ActivitiesBloc, ActivitiesState>(
                listener: (context, state) {
                  if (state is ActivityOperationSuccess) {
                    Navigator.pop(context);
                    // Navigate back to the activities route to reset the form state
                    if (widget.showAddForm) {
                      GoRouter.of(context).go('/activities');
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: TugColors.success,
                      ),
                    );
                  } else if (state is ActivitiesError) {
                    // Don't close the modal on error, so user can see the error and try again
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
                  onSave: (name, valueId, duration, date, notes, isPublic, notesPublic, mood) {
                    final activity = ActivityModel(
                      name: name,
                      valueId: valueId,
                      duration: duration,
                      date: date,
                      notes: notes,
                      isPublic: isPublic,
                      notesPublic: notesPublic,
                    );

                    // Get the value model for social sharing
                    ValueModel? selectedValue;
                    final valuesState = context.read<ValuesBloc>().state;
                    if (valuesState is ValuesLoaded) {
                      try {
                        selectedValue = valuesState.values.firstWhere(
                          (v) => v.id == valueId,
                        );
                      } catch (e) {
                        // Value not found, will use null
                      }
                    }

                    context.read<ActivitiesBloc>().add(AddActivityWithSocial(
                      activity: activity,
                      valueModel: selectedValue,
                    ));
                    
                    // Create mood entry if mood was selected
                    if (mood != null) {
                      _createMoodEntry(mood, date);
                    }
                    
                    // Navigate back to home after saving
                    Navigator.of(context).pop();
                    context.go('/social');
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
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
                        'value: $valueName',
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
                label: 'duration:',
                value: TimeUtils.formatMinutes(activity.duration),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                isDarkMode: isDarkMode,
                icon: Icons.calendar_today_outlined,
                iconColor: color,
                label: 'date:',
                value: DateFormat('MMM d, yyyy').format(activity.date),
              ),
              if (activity.notes != null) ...[
                const SizedBox(height: 16),
                Text(
                  'notes:',
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
              child: const Text('close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditActivitySheet(activity);
              },
              child: const Text('edit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmation(activity);
              },
              style: TextButton.styleFrom(
                foregroundColor: TugColors.error,
              ),
              child: const Text('delete'),
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
          title: const Text('delete activity'),
          content: Text('you deadass want to delete "${activity.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('nah'),
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
              child: const Text('yes bro'),
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

  int _getMoodPositivityScore(MoodType mood) {
    switch (mood) {
      case MoodType.ecstatic:
        return 10;
      case MoodType.joyful:
        return 9;
      case MoodType.confident:
        return 8;
      case MoodType.content:
        return 7;
      case MoodType.focused:
        return 6;
      case MoodType.neutral:
        return 5;
      case MoodType.restless:
        return 4;
      case MoodType.tired:
        return 3;
      case MoodType.frustrated:
        return 2;
      case MoodType.anxious:
        return 2;
      case MoodType.sad:
        return 1;
      case MoodType.overwhelmed:
        return 1;
      case MoodType.angry:
        return 1;
      case MoodType.defeated:
        return 0;
      case MoodType.depressed:
        return 0;
    }
  }

  void _createMoodEntry(MoodType mood, DateTime date) async {
    try {
      final moodEntry = MoodEntry(
        moodType: mood,
        positivityScore: _getMoodPositivityScore(mood),
        recordedAt: date,
      );
      await _moodService.createMoodEntry(moodEntry);
    } catch (e) {
      // Don't fail activity creation if mood creation fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activity saved, but mood tracking failed: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _initializeAppMode() async {
    try {
      await _appModeService.initialize();
      _appModeService.modeStream.listen((mode) {
        if (mounted) {
          setState(() {
            _currentMode = mode;
          });
          // Reload appropriate data when mode changes
          if (_currentMode == AppMode.valuesMode) {
            context.read<ValuesBloc>().add(const LoadValues(forceRefresh: true));
          } else {
            context.read<VicesBloc>().add(const LoadVices());
          }
        }
      });
      setState(() {
        _currentMode = _appModeService.currentMode;
      });
    } catch (e) {
      // Mode service initialization failed - default to values mode
      _currentMode = AppMode.valuesMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Must call super.build for AutomaticKeepAliveClientMixin
    super.build(context);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _currentMode == AppMode.vicesMode
                ? (isDarkMode ? TugColors.viceGreen : TugColors.viceGreenDark)
                : (isDarkMode ? TugColors.primaryPurpleLight : TugColors.primaryPurple),
          ),
          onPressed: () {
            context.go('/social');
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _currentMode == AppMode.vicesMode
                  ? (isDarkMode 
                      ? [TugColors.darkBackground, TugColors.viceGreenDark, TugColors.viceGreen]
                      : [TugColors.lightBackground, TugColors.viceGreen.withValues(alpha: 0.08)])
                  : (isDarkMode 
                      ? [TugColors.darkBackground, TugColors.primaryPurpleDark, TugColors.primaryPurple]
                      : [TugColors.lightBackground, TugColors.primaryPurple.withAlpha(20)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: QuantumEffects.holographicShimmer(
          child: QuantumEffects.gradientText(
            _currentMode == AppMode.vicesMode ? 'lapses tracking' : 'activity tracking',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            colors: _currentMode == AppMode.vicesMode
                ? (isDarkMode ? [TugColors.viceGreen, TugColors.viceEmerald, TugColors.viceGreenDark] : [TugColors.viceGreen, TugColors.viceEmerald])
                : (isDarkMode ? [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark] : [TugColors.primaryPurple, TugColors.primaryPurpleLight]),
          ),
        ),
        actions: [
          QuantumEffects.floating(
            offset: 5,
            child: QuantumEffects.quantumBorder(
              glowColor: TugColors.primaryPurpleLight,
              intensity: 0.8,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      TugColors.primaryPurple.withAlpha(100),
                      TugColors.primaryPurpleDark.withAlpha(80),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TugColors.primaryPurple.withAlpha(100),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _currentMode == AppMode.vicesMode 
            ? _buildVicesContent()
            : Column(
                children: [
                  // Activity Summary Card
                  _buildActivitySummary(),
          
                  // Filters
                  if (_showFilters) _buildFilters(),
          
                  // Activities List
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshActivities,
                child: BlocBuilder<ActivitiesBloc, ActivitiesState>(
                builder: (context, state) {
                  if (state is ActivitiesLoading && _isFirstLoad) {
                    // Only show loading indicator on first load
                    return ListView(
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: CircularProgressIndicator(
                            color: _currentMode == AppMode.vicesMode 
                                ? TugColors.viceGreen 
                                : TugColors.primaryPurple,
                          ),
                        ),
                      ],
                    );
                  }
    
                  if (state is ActivitiesError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 200),
                        Center(
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
                              const Text(
                                'pull down to refresh',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                    return ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
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
                                'put stuff here',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'get tugging on them activities',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                style: TugButtons.primaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                                onPressed: _showAddActivitySheet,
                                icon: const Icon(Icons.add),
                                label: const Text('log activity'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
    
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    child: Column(
                      children: [
                        // Swipe hint
                        if (activities.isNotEmpty && _showSwipeHint)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDarkMode 
                                    ? TugColors.primaryPurple.withOpacity(0.15) 
                                    : TugColors.primaryPurple.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: TugColors.primaryPurple.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.swipe_left,
                                        color: TugColors.primaryPurple,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'swipe left on activities to edit or delete',
                                        style: TextStyle(
                                          color: TugColors.primaryPurple,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.close,
                                      color: TugColors.primaryPurple,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showSwipeHint = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Activities list
                        ...activities.map((activity) {
                          // Find value name and color using BLoC
                          String valueName = 'unknown value';
                          String valueColor = '#7C3AED'; // Default purple
        
                          // Get value name from BLoC state
                          final valuesState = context.watch<ValuesBloc>().state;
                          if (valuesState is ValuesLoaded) {
                            final value = valuesState.values.firstWhere(
                              (v) => v.id == activity.valueId,
                              orElse: () => const ValueModel(
                                name: 'unknown value',
                                importance: 1,
                                color: '#7C3AED',
                              ),
                            );
                            valueName = value.name;
                            valueColor = value.color;
                          }
        
                          return _buildActivityCard(activity, valueName, valueColor);
                        }),
                      ],
                    ),
                  );
                },
              ),
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
    
    return QuantumEffects.quantumBorder(
      glowColor: color,
      intensity: 0.3,
      child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode 
                  ? [
                      TugColors.darkSurface,
                      Color.lerp(TugColors.darkSurface, color, 0.03) ?? TugColors.darkSurface,
                    ]
                  : [
                      Colors.white,
                      Color.lerp(Colors.white, color, 0.02) ?? Colors.white,
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(25),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.25) 
                    : Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: color.withAlpha(60),
              width: 1,
            ),
          ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
        child: Slidable(
          key: ValueKey(activity.id ?? activity.name),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            dragDismissible: false,
            children: [
              SlidableAction(
                onPressed: (_) {
                  // Hide the swipe hint after user has used the functionality
                  if (_showSwipeHint) {
                    setState(() {
                      _showSwipeHint = false;
                    });
                  }
                  _showEditActivitySheet(activity);
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
                padding: const EdgeInsets.all(0),
              ),
              SlidableAction(
                onPressed: (_) {
                  // Hide the swipe hint after user has used the functionality
                  if (_showSwipeHint) {
                    setState(() {
                      _showSwipeHint = false;
                    });
                  }
                  _showDeleteConfirmation(activity);
                },
                backgroundColor: TugColors.error,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
                padding: const EdgeInsets.all(0),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              _showActivityDetails(activity, valueName, valueColor);
            },
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
                          TimeUtils.formatMinutes(activity.duration),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: color,
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
                child: QuantumEffects.gradientText(
                  'quantum void - awaiting first activity',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                  colors: [TugColors.primaryPurple, TugColors.primaryPurpleLight],
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
                  title: 'activities',
                  value: activities.length.toString(),
                  icon: Icons.history,
                ),
                _buildSummaryItem(
                  title: 'values',
                  value: valuesMap.length.toString(),
                  icon: Icons.star,
                ),
                _buildSummaryItem(
                  title: 'total time',
                  value: TimeUtils.formatMinutes(totalTime),
                  icon: Icons.access_time,
                ),
              ],
            );
          }

          return Center(
            child: Text(
              'patience is a virtue',
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
                'filter activities',
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
                label: const Text('reset'),
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
                  labelText: 'filter by value',
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
                      'all values',
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
                      labelText: 'start date',
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
                      labelText: 'end date',
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

  Widget _buildVicesContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<VicesBloc, VicesState>(
      builder: (context, state) {
        if (state is VicesLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: TugColors.viceGreen),
                const SizedBox(height: 16),
                Text(
                  'loading vices...',
                  style: TextStyle(
                    color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        
        if (state is VicesError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: TugColors.viceGreen,
                ),
                const SizedBox(height: 16),
                Text(
                  'error loading vices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(
                    color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        if (state is VicesLoaded) {
          final vices = state.vices;
          
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'indulgence tracking',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: TugColors.viceGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'when in vices mode, use this space to record lapses',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                
                if (vices.isEmpty) ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 80,
                            color: TugColors.viceGreen.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'no vices tracked yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'add vices to track indulgences',
                            style: TextStyle(
                              color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go('/vices-input'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TugColors.viceGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('manage vices'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'your vices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: vices.length,
                      itemBuilder: (context, index) {
                        final vice = vices[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(int.parse('0xFF${vice.color.substring(1)}')),
                                  Color(int.parse('0xFF${vice.color.substring(1)}')).withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                vice.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                'clean days: ${vice.currentStreak}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  // Navigate to indulgence recording for this vice
                                  context.go('/indulgences/new');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('record lapse'),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => context.go('/vices-input'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TugColors.viceGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('manage vices'),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        
        return const Center(
          child: Text('no data available'),
        );
      },
    );
  }
}