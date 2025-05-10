// lib/blocs/theme/theme_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class ThemeEvent {}

class ThemeChanged extends ThemeEvent {
  final bool isDarkMode;
  
  ThemeChanged(this.isDarkMode);
}

class ThemeLoaded extends ThemeEvent {}

// States
abstract class ThemeState {
  final bool isDarkMode;
  
  ThemeState(this.isDarkMode);
}

class ThemeInitial extends ThemeState {
  ThemeInitial() : super(false);
}

class ThemeLoadSuccess extends ThemeState {
  ThemeLoadSuccess(super.isDarkMode);
}

// BLoC
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _prefsKey = 'dark_mode';
  
  ThemeBloc() : super(ThemeInitial()) {
    on<ThemeChanged>(_onThemeChanged);
    on<ThemeLoaded>(_onThemeLoaded);
  }
  
  Future<void> _onThemeChanged(
    ThemeChanged event, 
    Emitter<ThemeState> emit,
  ) async {
    // Save preference to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, event.isDarkMode);
    
    emit(ThemeLoadSuccess(event.isDarkMode));
  }
  
  Future<void> _onThemeLoaded(
    ThemeLoaded event, 
    Emitter<ThemeState> emit,
  ) async {
    // Load preference from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(_prefsKey) ?? false;
    
    emit(ThemeLoadSuccess(isDarkMode));
  }
}