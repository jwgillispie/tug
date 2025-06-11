// lib/blocs/values/values_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/repositories/values_repository.dart';
import 'package:flutter/foundation.dart';

class ValuesBloc extends Bloc<ValuesEvent, ValuesState> {
  final ValuesRepository valuesRepository;
  
  // Track if we've loaded values at least once
  bool _initialLoadComplete = false;

  ValuesBloc({required this.valuesRepository}) : super(ValuesInitial()) {
    on<LoadValues>(_onLoadValues);
    on<AddValue>(_onAddValue);
    on<UpdateValue>(_onUpdateValue);
    on<DeleteValue>(_onDeleteValue);
    on<LoadStreakStats>(_onLoadStreakStats);
    on<ClearValuesData>(_onClearValuesData);
  }

  Future<void> _onLoadValues(
    LoadValues event,
    Emitter<ValuesState> emit,
  ) async {
    // If this is not the first load and we're not forcing a refresh,
    // don't show loading state to avoid UI flicker
    if (!_initialLoadComplete && !event.forceRefresh) {
      emit(ValuesLoading());
    }
    
    try {
      final values = await valuesRepository.getValues(forceRefresh: event.forceRefresh);
      emit(ValuesLoaded(values));
      
      // Mark that we've done the initial load
      _initialLoadComplete = true;
      
    } catch (e) {
      emit(ValuesError(e.toString()));
    }
  }

  Future<void> _onAddValue(
    AddValue event,
    Emitter<ValuesState> emit,
  ) async {
    // Capture current state to restore if needed
    final currentState = state;
    
    emit(ValuesLoading());
    try {
      await valuesRepository.addValue(event.value);
      
      // Load the values to get the updated list
      final values = await valuesRepository.getValues(forceRefresh: true);
      emit(ValuesLoaded(values));
      
    } catch (e) {
      emit(ValuesError(e.toString()));
      
      // If there was an error, restore the previous state
      if (currentState is ValuesLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateValue(
    UpdateValue event,
    Emitter<ValuesState> emit,
  ) async {
    // Keep track of previous state
    final currentState = state;
    
    // Optimistically update the UI first for better UX
    if (currentState is ValuesLoaded) {
      final updatedValues = List<dynamic>.from(currentState.values);
      final index = updatedValues.indexWhere((value) => value.id == event.value.id);
      
      if (index != -1) {
        updatedValues[index] = event.value;
        emit(ValuesLoaded(List.from(updatedValues)));
      }
    } else {
      emit(ValuesLoading());
    }
    
    try {
      await valuesRepository.updateValue(event.value);
      
      // Load the values again to ensure consistency
      final values = await valuesRepository.getValues(forceRefresh: true);
      emit(ValuesLoaded(values));
      
    } catch (e) {
      emit(ValuesError(e.toString()));
      
      // Restore previous state if there was an error
      if (currentState is ValuesLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteValue(
    DeleteValue event,
    Emitter<ValuesState> emit,
  ) async {
    // Keep track of previous state
    final currentState = state;
    
    // Optimistically update the UI first for better UX
    if (currentState is ValuesLoaded) {
      final updatedValues = currentState.values.where((value) => value.id != event.valueId).toList();
      emit(ValuesLoaded(updatedValues));
    } else {
      emit(ValuesLoading());
    }
    
    try {
      await valuesRepository.deleteValue(event.valueId);
      
      // Load the values again to ensure consistency
      final values = await valuesRepository.getValues(forceRefresh: true);
      emit(ValuesLoaded(values));
      
    } catch (e) {
      emit(ValuesError(e.toString()));
      
      // Restore previous state if there was an error
      if (currentState is ValuesLoaded) {
        emit(currentState);
      }
    }
  }
  
  Future<void> _onLoadStreakStats(
    LoadStreakStats event,
    Emitter<ValuesState> emit,
  ) async {
    try {
      // Keep track of previous state to restore after loading streak stats
      final currentState = state;

      emit(ValuesLoading());

      final streakStats = await valuesRepository.getStreakStats(
        valueId: event.valueId,
        forceRefresh: event.forceRefresh ?? false
      );

      emit(StreakStatsLoaded(streakStats));

      // Restore previous state if it was ValuesLoaded
      if (currentState is ValuesLoaded) {
        emit(currentState);
      }

    } catch (e) {
      emit(ValuesError(e.toString()));
    }
  }

  void _onClearValuesData(
    ClearValuesData event,
    Emitter<ValuesState> emit,
  ) {
    // Clear all state data and reset to initial state
    _initialLoadComplete = false;
    
    emit(ValuesInitial());
  }
}