
// lib/blocs/values/values_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bevent.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/repositories/values_repository.dart';


class ValuesBloc extends Bloc<ValuesEvent, ValuesState> {
  final ValuesRepository valuesRepository;

  ValuesBloc({required this.valuesRepository}) : super(ValuesInitial()) {
    on<LoadValues>(_onLoadValues);
    on<AddValue>(_onAddValue);
    on<UpdateValue>(_onUpdateValue);
    on<DeleteValue>(_onDeleteValue);
  }

  Future<void> _onLoadValues(
    LoadValues event,
    Emitter<ValuesState> emit,
  ) async {
    emit(ValuesLoading());
    try {
      final values = await valuesRepository.getValues();
      emit(ValuesLoaded(values));
    } catch (e) {
      emit(ValuesError(e.toString()));
    }
  }

  Future<void> _onAddValue(
    AddValue event,
    Emitter<ValuesState> emit,
  ) async {
    emit(ValuesLoading());
    try {
      await valuesRepository.addValue(event.value);
      final values = await valuesRepository.getValues();
      emit(ValuesLoaded(values));
    } catch (e) {
      emit(ValuesError(e.toString()));
    }
  }

  Future<void> _onUpdateValue(
    UpdateValue event,
    Emitter<ValuesState> emit,
  ) async {
    emit(ValuesLoading());
    try {
      await valuesRepository.updateValue(event.value);
      final values = await valuesRepository.getValues();
      emit(ValuesLoaded(values));
    } catch (e) {
      emit(ValuesError(e.toString()));
    }
  }

  Future<void> _onDeleteValue(
    DeleteValue event,
    Emitter<ValuesState> emit,
  ) async {
    emit(ValuesLoading());
    try {
      await valuesRepository.deleteValue(event.valueId);
      final values = await valuesRepository.getValues();
      emit(ValuesLoaded(values));
    } catch (e) {
      emit(ValuesError(e.toString()));
    }
  }
}