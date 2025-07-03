// lib/screens/values/values_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/utils/quantum_effects.dart';
import 'package:tug/widgets/values/color_picker.dart';
import 'package:tug/widgets/values/edit_value_dialog.dart';
import 'package:tug/widgets/values/first_value_celebration.dart';
import '../../models/value_model.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/buttons.dart';
import '../../utils/theme/decorations.dart';
import '../../services/app_mode_service.dart';
import '../../widgets/common/tug_text_field.dart';

class ValuesInputScreen extends StatefulWidget {
  // Add parameter to detect if coming from home screen
  final bool fromHome;
  
  const ValuesInputScreen({super.key, this.fromHome = false});

  @override
  State<ValuesInputScreen> createState() => _ValuesInputScreenState();
}

class _ValuesInputScreenState extends State<ValuesInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _currentImportance = 3;
  String _selectedColor = '#7C3AED'; // Default to purple
  bool _isLoading = false;
  bool _showCelebration = false;
  String _newValueName = '';
  
  // Keep track of previous state to detect transitions
  int _previousValueCount = 0;
  bool _isFirstLoad = true;
  bool _showSwipeHint = true;

  @override
  void initState() {
    super.initState();
    // Load values when screen is initialized
    context.read<ValuesBloc>().add(LoadValues());
  }

  @override
  void dispose() {
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addValue() {
    if (_formKey.currentState?.validate() ?? false) {
      final newValue = ValueModel(
        name: _valueController.text.trim(),
        importance: _currentImportance.round(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
      );

      // Store the name of the newly added value for celebration
      _newValueName = _valueController.text.trim();
      
      // Add the value via BLoC
      context.read<ValuesBloc>().add(AddValue(newValue));
      
      // Reset form
      _valueController.clear();
      _descriptionController.clear();
      setState(() {
        _currentImportance = 3;
        _selectedColor = '#7C3AED'; // Reset to default purple
      });
    }
  }

  void _handleContinue() {
    // Navigate to home screen or back, depending on where we came from
    if (widget.fromHome) {
      context.pop(); // Go back to home if we came from there
    } else {
      context.go('/home'); // Otherwise go to home
    }
  }

  // Method to hide the celebration overlay
  void _dismissCelebration() {
    setState(() {
      _showCelebration = false;
    });
  }

  // Method to show the edit dialog
  void _showEditDialog(BuildContext context, ValueModel value) {
    showDialog(
      context: context,
      builder: (context) => EditValueDialog(
        value: value,
        onSave: (updatedValue) {
          // Update the value using the bloc
          context.read<ValuesBloc>().add(UpdateValue(updatedValue));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ValuesBloc, ValuesState>(
      listener: (context, state) {
        setState(() => _isLoading = state is ValuesLoading);
        
        if (state is ValuesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: TugColors.error,
            ),
          );
        }

        // Check if values were successfully loaded
        if (state is ValuesLoaded) {
          final currentValues = state.values.where((v) => v.active).toList();
          final currentCount = currentValues.length;
          
          // Detect transition from 0 to 1 values, but not on first load
          if (currentCount == 1 && _previousValueCount == 0 && !_isFirstLoad) {
            setState(() {
              _showCelebration = true;
              _newValueName = currentValues.first.name;
            });
          }
          
          // Store the current count for next comparison
          _previousValueCount = currentCount;
          
          // After first load, mark that we're no longer in initial load
          if (_isFirstLoad) {
            _isFirstLoad = false;
          }
        }
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: Theme.of(context).brightness == Brightness.dark 
                        ? [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark]
                        : [TugColors.lightBackground, TugColors.warning.withAlpha(20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: QuantumEffects.holographicShimmer(
                child: QuantumEffects.gradientText(
                  'enter values',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  colors: Theme.of(context).brightness == Brightness.dark 
                      ? [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark] 
                      : [TugColors.warning, TugColors.primaryPurple],
                ),
              ),
              // Add back button if we came from home screen
              leading: widget.fromHome 
                  ? QuantumEffects.floating(
                      offset: 3,
                      child: QuantumEffects.quantumBorder(
                        glowColor: TugColors.warning,
                        intensity: 0.6,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                TugColors.warning.withAlpha(40),
                                TugColors.warning.withAlpha(10),
                              ],
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back, color: TugColors.warning),
                            onPressed: () => context.pop(),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            body: QuantumEffects.quantumParticleField(
              isDark: Theme.of(context).brightness == Brightness.dark,
              particleCount: 20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: Theme.of(context).brightness == Brightness.dark 
                        ? [
                            TugColors.darkBackground,
                            Color.lerp(TugColors.darkBackground, TugColors.warning, 0.08) ?? TugColors.darkBackground,
                          ] 
                        : [
                            TugColors.lightBackground,
                            Color.lerp(TugColors.lightBackground, TugColors.warning, 0.04) ?? TugColors.lightBackground,
                          ],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QuantumEffects.cosmicBreath(
                        intensity: 0.05,
                        child: QuantumEffects.gradientText(
                          widget.fromHome
                              ? 'edit your values'
                              : 'what do you care about more than anything?',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ) ?? TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          colors: [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark],
                        ),
                      ),
                      const SizedBox(height: 12),
                      QuantumEffects.floating(
                        offset: 5,
                        child: Text(
                          'put up to 5 valuable values',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? TugColors.darkTextSecondary 
                                : TugColors.lightTextSecondary,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TugTextField(
                          label: 'value',
                          hint: 'ex health, family, creativity, learning ',
                          controller: _valueController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'please enter a value';
                            }
                            if (value.length < 2) {
                              return 'value gotta be longer than that';
                            }
                            if (value.length > 30) {
                              return 'okay that\'s awesome but can you make it a little shorter?';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'how important is this value? (meh - everything)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Slider(
                          value: _currentImportance,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _currentImportance.round().toString(),
                          activeColor: TugColors.primaryPurple,
                          onChanged: (value) {
                            setState(() {
                              _currentImportance = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TugTextField(
                          label: 'description (only if you want)',
                          hint: 'why?',
                          controller: _descriptionController,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'pick a color',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        ColorPicker(
                          selectedColor: _selectedColor,
                          onColorSelected: (color) {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<ValuesBloc, ValuesState>(
                          builder: (context, state) {
                            // Disable add button if we already have 5 values
                            final maxValuesReached = state is ValuesLoaded && 
                                state.values.where((v) => v.active).length >= 5;
                            
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: TugButtons.secondaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                                onPressed: (_isLoading || maxValuesReached) 
                                    ? null 
                                    : _addValue,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: TugColors.primaryPurple,
                                          ),
                                        )
                                      : Text(maxValuesReached 
                                          ? 'okay! 5 values! AWESOME' 
                                          : 'add'),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<ValuesBloc, ValuesState>(
                    builder: (context, state) {
                      if (state is ValuesLoaded) {
                        final activeValues = state.values.where((v) => v.active).toList();
                        
                        if (activeValues.isEmpty) {
                          return const Center(
                            child: Text('gotta have at least one value :)'),
                          );
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'your values',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            // Add guidance text for new users
                            if (activeValues.length == 1 && !widget.fromHome)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: TugColors.primaryPurple.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: TugColors.primaryPurple.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: TugColors.primaryPurple,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Great! Add 2-4 more values, then hit GO to start tracking activities.',
                                        style: TextStyle(
                                          color: TugColors.primaryPurple,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Swipe hint
                            if (activeValues.isNotEmpty && _showSwipeHint)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: TugColors.primaryPurple.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: TugColors.primaryPurple.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.swipe_left,
                                          color: TugColors.primaryPurple,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'swipe left on values to edit or delete',
                                          style: TextStyle(
                                            color: TugColors.primaryPurple,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        Icons.close,
                                        color: TugColors.primaryPurple,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _showSwipeHint = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ...activeValues.map((value) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ValueCard(
                                value: value,
                                onDelete: () {
                                  if (_showSwipeHint) {
                                    setState(() {
                                      _showSwipeHint = false;
                                    });
                                  }
                                  context.read<ValuesBloc>().add(
                                    DeleteValue(value.id!),
                                  );
                                },
                                onEdit: () {
                                  if (_showSwipeHint) {
                                    setState(() {
                                      _showSwipeHint = false;
                                    });
                                  }
                                  _showEditDialog(context, value);
                                },
                              ),
                            )),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: TugButtons.primaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                                onPressed: _isLoading 
                                    ? null 
                                    : (activeValues.isNotEmpty 
                                        ? _handleContinue 
                                        : null),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(widget.fromHome ? 'done' : 'go!'),
                              ),
                            ),
                          ],
                        );
                      }
                      
                      if (state is ValuesLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
            ),
          ), 
          
          // Show the celebration overlay if we just added the first value
          if (_showCelebration)
            FirstValueCelebration(
              valueName: _newValueName,
              onDismiss: _dismissCelebration,
            ),
        ],
      ),
    );
  }
}

class ValueCard extends StatelessWidget {
  final ValueModel value;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ValueCard({
    super.key,
    required this.value,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final Color valueColor = Color(int.parse(value.color.substring(1), radix: 16) + 0xFF000000);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return QuantumEffects.cosmicBreath(
      intensity: 0.03,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Slidable(
          key: ValueKey(value.id ?? value.name),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            dragDismissible: false,
            children: [
              SlidableAction(
                onPressed: (_) => onEdit(),
                backgroundColor: TugColors.primaryPurple,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
                padding: const EdgeInsets.all(0),
              ),
              SlidableAction(
                onPressed: (_) => _showDeleteConfirmation(context),
                backgroundColor: TugColors.error,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
                padding: const EdgeInsets.all(0),
              ),
            ],
          ),
          child: QuantumEffects.glassContainer(
            isDark: isDarkMode,
            blur: 15,
            opacity: 0.1,
            borderRadius: BorderRadius.circular(16),
            child: QuantumEffects.quantumBorder(
              glowColor: valueColor,
              intensity: 0.4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            valueColor.withAlpha(15),
                            valueColor.withAlpha(5),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            valueColor.withAlpha(10),
                          ],
                        ),
                  boxShadow: TugColors.getNeonGlow(
                    valueColor,
                    intensity: 0.3,
                  ),
                ),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  QuantumEffects.cosmicBreath(
                    intensity: 0.08,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            valueColor,
                            valueColor.withAlpha(180),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: TugColors.getNeonGlow(
                          valueColor,
                          intensity: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QuantumEffects.gradientText(
                          value.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ) ?? TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          colors: [valueColor, valueColor.withAlpha(200)],
                        ),
                        const SizedBox(height: 6),
                        QuantumEffects.floating(
                          offset: 2,
                          child: Row(
                            children: [
                              Text(
                                'importance: ',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              ...List.generate(
                                value.importance,
                                (index) => QuantumEffects.cosmicBreath(
                                  intensity: 0.05,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.star,
                                      size: 16,
                                      color: valueColor,
                                      shadows: TugColors.getNeonGlow(
                                        valueColor,
                                        intensity: 0.3,
                                      ).map((s) => Shadow(
                                        color: s.color,
                                        blurRadius: s.blurRadius,
                                        offset: Offset(s.offset.dx, s.offset.dy),
                                      )).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              ...List.generate(
                                5 - value.importance,
                                (index) => Container(
                                  margin: const EdgeInsets.only(right: 2),
                                  child: Icon(
                                    Icons.star_border,
                                    size: 16,
                                    color: valueColor.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (value.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          QuantumEffects.floating(
                            offset: 1,
                            child: Text(
                              value.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (value.currentStreak > 0 || value.longestStreak > 0) ...[
                const SizedBox(height: 16),
                QuantumEffects.glassContainer(
                  isDark: isDarkMode,
                  blur: 8,
                  opacity: 0.05,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        QuantumEffects.floating(
                          offset: 2,
                          child: _buildStreakIndicator(
                            context: context,
                            icon: Icons.local_fire_department,
                            color: Color(0xFFF57C00), // Orange
                            label: 'current streak',
                            value: '${value.currentStreak} day${value.currentStreak != 1 ? 's' : ''}',
                          ),
                        ),
                        QuantumEffects.floating(
                          offset: 3,
                          child: _buildStreakIndicator(
                            context: context,
                            icon: Icons.emoji_events,
                            color: Color(0xFFFFD700), // Gold
                            label: 'top streak',
                            value: '${value.longestStreak} day${value.longestStreak != 1 ? 's' : ''}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ]),
              ),
          ),
        ),
      ),
    ));
  }
  
  void _showDeleteConfirmation(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? TugColors.darkSurface : Colors.white,
        title: Text(
          'Delete Value',
          style: TextStyle(
            color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'delete "${value.name}"? this cannot be undone.',
          style: TextStyle(
            color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: TugColors.error,
            ),
            child: const Text('delete'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStreakIndicator({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        QuantumEffects.cosmicBreath(
          intensity: 0.06,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withAlpha(50),
                  color.withAlpha(20),
                ],
              ),
            ),
            child: Icon(
              icon, 
              color: color, 
              size: 16,
              shadows: TugColors.getNeonGlow(
                color,
                intensity: 0.4,
              ).map((s) => Shadow(
                color: s.color,
                blurRadius: s.blurRadius / 2,
                offset: Offset(s.offset.dx, s.offset.dy),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            QuantumEffects.gradientText(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ) ?? TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              colors: [color, color.withAlpha(180)],
            ),
          ],
        ),
      ],
    );
  }
}