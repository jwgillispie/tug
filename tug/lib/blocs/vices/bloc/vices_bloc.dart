// lib/blocs/vices/bloc/vices_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../services/vice_service.dart';
import 'vices_event.dart';
import 'vices_state.dart';

class VicesBloc extends Bloc<VicesEvent, VicesState> {
  final ViceService _viceService;
  final Logger _logger = Logger();

  VicesBloc({required ViceService viceService}) 
      : _viceService = viceService,
        super(const VicesInitial()) {
    
    on<LoadVices>(_onLoadVices);
    on<AddVice>(_onAddVice);
    on<UpdateVice>(_onUpdateVice);
    on<DeleteVice>(_onDeleteVice);
    on<RecordIndulgence>(_onRecordIndulgence);
    on<LoadIndulgences>(_onLoadIndulgences);
    on<UpdateViceStreak>(_onUpdateViceStreak);
    on<MarkCleanDay>(_onMarkCleanDay);
  }

  Future<void> _onLoadVices(LoadVices event, Emitter<VicesState> emit) async {
    try {
      // Don't show loading if we have cached data and it's not a force refresh
      final shouldShowLoading = event.forceRefresh || state is! VicesLoaded;
      
      if (shouldShowLoading) {
        emit(const VicesLoading());
      }
      
      final vices = await _viceService.getVices(
        forceRefresh: event.forceRefresh,
        useCache: !event.forceRefresh,
      );
      
      emit(VicesLoaded(vices: vices));
    } catch (e) {
      _logger.e('Error loading vices: $e');
      emit(VicesError('Failed to load vices: ${e.toString()}'));
    }
  }

  Future<void> _onAddVice(AddVice event, Emitter<VicesState> emit) async {
    try {
      emit(const VicesLoading());
      
      await _viceService.createVice(event.vice);
      
      // Get updated list of vices
      final vices = await _viceService.getVices();
      
      emit(VicesLoaded(vices: vices));
    } catch (e) {
      _logger.e('Error adding vice: $e');
      emit(VicesError('Failed to add vice: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateVice(UpdateVice event, Emitter<VicesState> emit) async {
    try {
      emit(const VicesLoading());
      
      await _viceService.updateVice(event.vice);
      
      // Get updated list of vices
      final vices = await _viceService.getVices();
      
      emit(VicesLoaded(vices: vices));
    } catch (e) {
      _logger.e('Error updating vice: $e');
      emit(VicesError('Failed to update vice: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteVice(DeleteVice event, Emitter<VicesState> emit) async {
    try {
      emit(const VicesLoading());
      
      await _viceService.deleteVice(event.viceId);
      
      // Get updated list of vices
      final vices = await _viceService.getVices();
      
      emit(VicesLoaded(vices: vices));
    } catch (e) {
      _logger.e('Error deleting vice: $e');
      emit(VicesError('Failed to delete vice: ${e.toString()}'));
    }
  }

  Future<void> _onRecordIndulgence(RecordIndulgence event, Emitter<VicesState> emit) async {
    try {
      emit(const VicesLoading());
      
      final recordedIndulgence = await _viceService.recordIndulgence(event.indulgence);
      
      // Emit the specific success state first
      emit(IndulgenceRecorded(recordedIndulgence));
      
      // Get updated list of vices (with updated streaks)
      final vices = await _viceService.getVices();
      
      emit(VicesLoaded(vices: vices));
    } catch (e) {
      _logger.e('Error recording indulgence: $e');
      emit(VicesError('Failed to record indulgence: ${e.toString()}'));
    }
  }

  Future<void> _onLoadIndulgences(LoadIndulgences event, Emitter<VicesState> emit) async {
    try {
      final indulgences = await _viceService.getIndulgences(event.viceId);
      
      if (state is VicesLoaded) {
        final currentState = state as VicesLoaded;
        emit(currentState.copyWith(indulgences: indulgences));
      } else {
        // If vices aren't loaded yet, load them too
        final vices = await _viceService.getVices();
        emit(VicesLoaded(vices: vices, indulgences: indulgences));
      }
    } catch (e) {
      _logger.e('Error loading indulgences: $e');
      emit(VicesError('Failed to load indulgences: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateViceStreak(UpdateViceStreak event, Emitter<VicesState> emit) async {
    try {
      await _viceService.updateViceStreak(event.viceId, event.newStreak);
      
      // Get updated list of vices
      final vices = await _viceService.getVices();
      
      if (state is VicesLoaded) {
        final currentState = state as VicesLoaded;
        emit(currentState.copyWith(vices: vices));
      } else {
        emit(VicesLoaded(vices: vices));
      }
    } catch (e) {
      _logger.e('Error updating vice streak: $e');
      emit(VicesError('Failed to update streak: ${e.toString()}'));
    }
  }

  Future<void> _onMarkCleanDay(MarkCleanDay event, Emitter<VicesState> emit) async {
    try {
      await _viceService.markCleanDay(event.viceId, event.date);
      
      // Get updated list of vices
      final vices = await _viceService.getVices();
      
      if (state is VicesLoaded) {
        final currentState = state as VicesLoaded;
        emit(currentState.copyWith(vices: vices));
      } else {
        emit(VicesLoaded(vices: vices));
      }
    } catch (e) {
      _logger.e('Error marking clean day: $e');
      emit(VicesError('Failed to mark clean day: ${e.toString()}'));
    }
  }
}