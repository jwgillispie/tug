// lib/blocs/activities/activities_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/activity_model.dart';
import '../../repositories/activity_repository.dart';

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

  const LoadActivities({
    this.valueId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [valueId, startDate, endDate];
}

class AddActivity extends ActivitiesEvent {
  final ActivityModel activity;

  const AddActivity(this.activity);

  @override
  List<Object?> get props => [activity];
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

  ActivitiesBloc({required this.activityRepository}) : super(ActivitiesInitial()) {
    on<LoadActivities>(_onLoadActivities);
    on<AddActivity>(_onAddActivity);
    on<UpdateActivity>(_onUpdateActivity);
    on<DeleteActivity>(_onDeleteActivity);
  }

  Future<void> _onLoadActivities(
    LoadActivities event,
    Emitter<ActivitiesState> emit,
  ) async {
    emit(ActivitiesLoading());
    try {
      final activities = await activityRepository.getActivities(
        valueId: event.valueId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(ActivitiesLoaded(activities));
    } catch (e) {
      emit(ActivitiesError(e.toString()));
    }
  }

  Future<void> _onAddActivity(
    AddActivity event,
    Emitter<ActivitiesState> emit,
  ) async {
    emit(ActivitiesLoading());
    try {
      await activityRepository.addActivity(event.activity);
      final activities = await activityRepository.getActivities();
      emit(ActivityOperationSuccess(
        message: 'Activity added successfully',
        activities: activities,
      ));
    } catch (e) {
      emit(ActivitiesError(e.toString()));
    }
  }

  Future<void> _onUpdateActivity(
    UpdateActivity event,
    Emitter<ActivitiesState> emit,
  ) async {
    emit(ActivitiesLoading());
    try {
      await activityRepository.updateActivity(event.activity);
      final activities = await activityRepository.getActivities();
      emit(ActivityOperationSuccess(
        message: 'Activity updated successfully',
        activities: activities,
      ));
    } catch (e) {
      emit(ActivitiesError(e.toString()));
    }
  }

  Future<void> _onDeleteActivity(
    DeleteActivity event,
    Emitter<ActivitiesState> emit,
  ) async {
    emit(ActivitiesLoading());
    try {
      await activityRepository.deleteActivity(event.activityId);
      final activities = await activityRepository.getActivities();
      emit(ActivityOperationSuccess(
        message: 'Activity deleted successfully',
        activities: activities,
      ));
    } catch (e) {
      emit(ActivitiesError(e.toString()));
    }
  }
}