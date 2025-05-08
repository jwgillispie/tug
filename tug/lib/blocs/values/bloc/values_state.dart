// lib/blocs/values/values_state.dart
import 'package:equatable/equatable.dart';
import 'package:tug/models/value_model.dart';

abstract class ValuesState extends Equatable {
  const ValuesState();

  @override
  List<Object?> get props => [];
}

class ValuesInitial extends ValuesState {}

class ValuesLoading extends ValuesState {}

class ValuesLoaded extends ValuesState {
  final List<ValueModel> values;

  const ValuesLoaded(this.values);

  @override
  List<Object?> get props => [values];
}

class ValuesError extends ValuesState {
  final String message;

  const ValuesError(this.message);

  @override
  List<Object?> get props => [message];
}

class StreakStatsLoaded extends ValuesState {
  final Map<String, dynamic> streakStats;
  
  const StreakStatsLoaded(this.streakStats);
  
  @override
  List<Object?> get props => [streakStats];
}