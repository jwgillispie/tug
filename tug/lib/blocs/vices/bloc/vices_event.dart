// lib/blocs/vices/bloc/vices_event.dart
import 'package:equatable/equatable.dart';
import '../../../models/vice_model.dart';
import '../../../models/indulgence_model.dart';

abstract class VicesEvent extends Equatable {
  const VicesEvent();

  @override
  List<Object?> get props => [];
}

class LoadVices extends VicesEvent {
  final bool forceRefresh;
  
  const LoadVices({this.forceRefresh = false});
  
  @override
  List<Object> get props => [forceRefresh];
}

class AddVice extends VicesEvent {
  final ViceModel vice;

  const AddVice(this.vice);

  @override
  List<Object> get props => [vice];
}

class UpdateVice extends VicesEvent {
  final ViceModel vice;

  const UpdateVice(this.vice);

  @override
  List<Object> get props => [vice];
}

class DeleteVice extends VicesEvent {
  final String viceId;

  const DeleteVice(this.viceId);

  @override
  List<Object> get props => [viceId];
}

class RecordIndulgence extends VicesEvent {
  final IndulgenceModel indulgence;

  const RecordIndulgence(this.indulgence);

  @override
  List<Object> get props => [indulgence];
}

class LoadIndulgences extends VicesEvent {
  final String viceId;

  const LoadIndulgences(this.viceId);

  @override
  List<Object> get props => [viceId];
}

class UpdateViceStreak extends VicesEvent {
  final String viceId;
  final int newStreak;

  const UpdateViceStreak(this.viceId, this.newStreak);

  @override
  List<Object> get props => [viceId, newStreak];
}

class MarkCleanDay extends VicesEvent {
  final String viceId;
  final DateTime date;

  const MarkCleanDay(this.viceId, this.date);

  @override
  List<Object> get props => [viceId, date];
}

class ClearVicesCache extends VicesEvent {
  const ClearVicesCache();
}