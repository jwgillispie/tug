// lib/blocs/activities/activities_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/activity_model.dart';
import '../../models/value_model.dart';
import '../../models/mood_model.dart';
import '../../repositories/activity_repository.dart';
import '../../services/mood_service.dart';

// Events
abstract class ActivitiesEvent extends Equatable {
  const ActivitiesEvent();

  @override
  List<Object?> get props => [];
}

class LoadActivities extends ActivitiesEvent {
  final String? valueId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool forceRefresh;

  const LoadActivities({
    this.valueId,
    this.startDate,
    this.endDate,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [valueId, startDate, endDate, forceRefresh];
}

class AddActivity extends ActivitiesEvent {
  final ActivityModel activity;

  const AddActivity(this.activity);

  @override
  List<Object?> get props => [activity];
}

class AddActivityWithSocial extends ActivitiesEvent {
  final ActivityModel activity;
  final ValueModel? valueModel;
  final bool shareToSocial;
  final MoodType? mood;

  const AddActivityWithSocial({
    required this.activity,
    this.valueModel,
    this.shareToSocial = true,
    this.mood,
  });

  @override
  List<Object?> get props => [activity, valueModel, shareToSocial, mood];
}

class UpdateActivity extends ActivitiesEvent {
  final ActivityModel activity;

  const UpdateActivity(this.activity);

  @override
  List<Object?> get props => [activity];
}

class DeleteActivity extends ActivitiesEvent {
  final String activityId;

  const DeleteActivity(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class ClearActivitiesData extends ActivitiesEvent {
  const ClearActivitiesData();
}

// States
abstract class ActivitiesState extends Equatable {
  const ActivitiesState();

  @override
  List<Object?> get props => [];
}

class ActivitiesInitial extends ActivitiesState {}

class ActivitiesLoading extends ActivitiesState {}

class ActivitiesLoaded extends ActivitiesState {
  final List<ActivityModel> activities;

  const ActivitiesLoaded(this.activities);

  @override
  List<Object?> get props => [activities];
}

class ActivityOperationSuccess extends ActivitiesLoaded {
  final String message;

  const ActivityOperationSuccess({
    required this.message,
    required List<ActivityModel> activities,
  }) : super(activities);

  @override
  List<Object?> get props => [message, activities];
}

class ActivitiesError extends ActivitiesState {
  final String message;

  const ActivitiesError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ActivitiesBloc extends Bloc<ActivitiesEvent, ActivitiesState> {
  final ActivityRepository activityRepository;
  final MoodService moodService;
  
  // Track if we've loaded activities at least once
  bool _initialLoadComplete = false;
  
  // Keep track of the last loaded filter parameters
  String? _lastValueId;
  DateTime? _lastStartDate;
  DateTime? _lastEndDate;

  ActivitiesBloc({
    required this.activityRepository,
    required this.moodService,
  }) : super(ActivitiesInitial()) {
    on<LoadActivities>(_onLoadActivities);
    on<AddActivity>(_onAddActivity);
    on<AddActivityWithSocial>(_onAddActivityWithSocial);
    on<UpdateActivity>(_onUpdateActivity);
    on<DeleteActivity>(_onDeleteActivity);
    on<ClearActivitiesData>(_onClearActivitiesData);
  }

  Future<void> _onLoadActivities(
    LoadActivities event,
    Emitter<ActivitiesState> emit,
  ) async {
    // Check if this is the same query as before (to avoid unnecessary loading states)
    final isSameQuery = event.valueId == _lastValueId &&
        event.startDate == _lastStartDate &&
        event.endDate == _lastEndDate;
    
    // Save the current parameters for future reference
    _lastValueId = event.valueId;
    _lastStartDate = event.startDate;
    _lastEndDate = event.endDate;
    
    // If this is not the first load, it's the same query as before, 
    // and we're not forcing a refresh, don't show loading state
    if (!_initialLoadComplete || !isSameQuery || event.forceRefresh) {
      emit(ActivitiesLoading());
    }
    
    try {
      final activities = await activityRepository.getActivities(
        valueId: event.valueId,
        startDate: event.startDate,
        endDate: event.endDate,
        forceRefresh: event.forceRefresh,
      );
      emit(ActivitiesLoaded(activities));
      
      // Mark that we've done the initial load
      _initialLoadComplete = true;
      
    } catch (e) {
      emit(ActivitiesError(e.toString()));
    }
  }

  Future<void> _onAddActivity(
    AddActivity event,
    Emitter<ActivitiesState> emit,
  ) async {
    // Keep track of the current state to restore it if needed
    final currentState = state;
    
    emit(ActivitiesLoading());
    try {
      await activityRepository.addActivity(event.activity);
      
      // Get updated list of activities
      final activities = await activityRepository.getActivities(
        valueId: _lastValueId,
        startDate: _lastStartDate,
        endDate: _lastEndDate,
        forceRefresh: true, // Force refresh to get the latest data
      );
      
      emit(ActivityOperationSuccess(
        message: 'Activity added successfully',
        activities: activities,
      ));
      
    } catch (e) {
      emit(ActivitiesError(e.toString()));
      
      // If there was an error, restore the previous state
      if (currentState is ActivitiesLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onAddActivityWithSocial(
    AddActivityWithSocial event,
    Emitter<ActivitiesState> emit,
  ) async {
    // Keep track of the current state to restore it if needed
    final currentState = state;
    
    emit(ActivitiesLoading());
    try {
      // Create the activity and capture the returned activity with its ID
      final createdActivity = await activityRepository.addActivity(
        event.activity,
        shareToSocial: event.shareToSocial,
        valueModel: event.valueModel,
      );
      
      // Create mood entry if mood was provided and activity was successfully created
      if (event.mood != null && createdActivity.id != null) {
        try {
          // Creating mood entry for mood: ${event.mood!.name}, activity: ${createdActivity.id}
          final moodEntry = MoodEntry(
            moodType: event.mood!,
            positivityScore: _getMoodPositivityScore(event.mood!),
            recordedAt: event.activity.date,
            activityId: createdActivity.id,
          );
          await moodService.createMoodEntry(moodEntry);
          // Mood entry created successfully
        } catch (moodError) {
          // Don't fail the entire operation if mood creation fails
          // The activity was already created successfully
          // Mood entry creation failed: $moodError
        }
      } else {
        // No mood entry created - mood: ${event.mood}, activityId: ${createdActivity.id}
      }
      
      // Get updated list of activities
      final activities = await activityRepository.getActivities(
        valueId: _lastValueId,
        startDate: _lastStartDate,
        endDate: _lastEndDate,
        forceRefresh: true, // Force refresh to get the latest data
      );
      
      emit(ActivityOperationSuccess(
        message: 'Activity added successfully',
        activities: activities,
      ));
      
    } catch (e) {
      emit(ActivitiesError(e.toString()));
      
      // If there was an error, restore the previous state
      if (currentState is ActivitiesLoaded) {
        emit(currentState);
      }
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

  Future<void> _onUpdateActivity(
    UpdateActivity event,
    Emitter<ActivitiesState> emit,
  ) async {
    // Keep track of the current state to restore it if needed
    final currentState = state;
    
    // Optimistically update the UI first
    if (currentState is ActivitiesLoaded) {
      final updatedActivities = List<ActivityModel>.from(currentState.activities);
      final index = updatedActivities.indexWhere((activity) => activity.id == event.activity.id);
      
      if (index != -1) {
        updatedActivities[index] = event.activity;
        emit(ActivitiesLoaded(updatedActivities));
      } else {
        emit(ActivitiesLoading());
      }
    } else {
      emit(ActivitiesLoading());
    }
    
    try {
      await activityRepository.updateActivity(event.activity);
      
      // Get updated list of activities
      final activities = await activityRepository.getActivities(
        valueId: _lastValueId,
        startDate: _lastStartDate,
        endDate: _lastEndDate,
        forceRefresh: true, // Force refresh to get the latest data
      );
      
      emit(ActivityOperationSuccess(
        message: 'Activity updated successfully',
        activities: activities,
      ));
      
    } catch (e) {
      emit(ActivitiesError(e.toString()));
      
      // If there was an error, restore the previous state
      if (currentState is ActivitiesLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteActivity(
    DeleteActivity event,
    Emitter<ActivitiesState> emit,
  ) async {
    // Keep track of the current state to restore it if needed
    final currentState = state;
    
    // Optimistically update the UI first
    if (currentState is ActivitiesLoaded) {
      final updatedActivities = currentState.activities
          .where((activity) => activity.id != event.activityId)
          .toList();
      emit(ActivitiesLoaded(updatedActivities));
    } else {
      emit(ActivitiesLoading());
    }
    
    try {
      await activityRepository.deleteActivity(event.activityId);
      
      // Get updated list of activities
      final activities = await activityRepository.getActivities(
        valueId: _lastValueId,
        startDate: _lastStartDate,
        endDate: _lastEndDate,
        forceRefresh: true, // Force refresh to get the latest data
      );
      
      emit(ActivityOperationSuccess(
        message: 'Activity deleted successfully',
        activities: activities,
      ));
      
    } catch (e) {
      emit(ActivitiesError(e.toString()));
      
      // If there was an error, restore the previous state
      if (currentState is ActivitiesLoaded) {
        emit(currentState);
      }
    }
  }

  void _onClearActivitiesData(
    ClearActivitiesData event,
    Emitter<ActivitiesState> emit,
  ) {
    // Clear all state data and reset to initial state
    _initialLoadComplete = false;
    _lastValueId = null;
    _lastStartDate = null;
    _lastEndDate = null;
    
    emit(ActivitiesInitial());
  }
}