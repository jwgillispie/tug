// lib/blocs/vices/bloc/vices_state.dart
import 'package:equatable/equatable.dart';
import '../../../models/vice_model.dart';
import '../../../models/indulgence_model.dart';

abstract class VicesState extends Equatable {
  const VicesState();

  @override
  List<Object?> get props => [];
}

class VicesInitial extends VicesState {
  const VicesInitial();
}

class VicesLoading extends VicesState {
  const VicesLoading();
}

class VicesLoaded extends VicesState {
  final List<ViceModel> vices;
  final List<IndulgenceModel> indulgences;

  const VicesLoaded({
    required this.vices,
    this.indulgences = const [],
  });

  @override
  List<Object> get props => [vices, indulgences];

  VicesLoaded copyWith({
    List<ViceModel>? vices,
    List<IndulgenceModel>? indulgences,
  }) {
    return VicesLoaded(
      vices: vices ?? this.vices,
      indulgences: indulgences ?? this.indulgences,
    );
  }
}

class VicesError extends VicesState {
  final String message;

  const VicesError(this.message);

  @override
  List<Object> get props => [message];
}

class ViceAdded extends VicesState {
  final ViceModel vice;

  const ViceAdded(this.vice);

  @override
  List<Object> get props => [vice];
}

class ViceUpdated extends VicesState {
  final ViceModel vice;

  const ViceUpdated(this.vice);

  @override
  List<Object> get props => [vice];
}

class ViceDeleted extends VicesState {
  final String viceId;

  const ViceDeleted(this.viceId);

  @override
  List<Object> get props => [viceId];
}

class IndulgenceRecorded extends VicesState {
  final IndulgenceModel indulgence;

  const IndulgenceRecorded(this.indulgence);

  @override
  List<Object> get props => [indulgence];
}

class ViceStreakUpdated extends VicesState {
  final String viceId;
  final int newStreak;

  const ViceStreakUpdated(this.viceId, this.newStreak);

  @override
  List<Object> get props => [viceId, newStreak];
}