// lib/blocs/values/values_event.dart
import 'package:equatable/equatable.dart';
import 'package:tug/models/value_model.dart';

abstract class ValuesEvent extends Equatable {
  const ValuesEvent();

  @override
  List<Object?> get props => [];
}

class LoadValues extends ValuesEvent {}

class AddValue extends ValuesEvent {
  final ValueModel value;

  const AddValue(this.value);

  @override
  List<Object?> get props => [value];
}

class UpdateValue extends ValuesEvent {
  final ValueModel value;

  const UpdateValue(this.value);

  @override
  List<Object?> get props => [value];
}

class DeleteValue extends ValuesEvent {
  final String valueId;

  const DeleteValue(this.valueId);

  @override
  List<Object?> get props => [valueId];
}