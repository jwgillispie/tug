// lib/screens/vices/indulgence_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/vices/bloc/vices_bloc.dart';
import '../../blocs/vices/bloc/vices_event.dart';
import '../../blocs/vices/bloc/vices_state.dart';
import '../../models/vice_model.dart';
import '../../models/indulgence_model.dart';
import '../../models/mood_model.dart';
import '../../utils/theme/colors.dart';
import '../../widgets/common/tug_text_field.dart';
import '../../widgets/mood/mood_selector.dart';
import '../../services/mood_service.dart';

class IndulgenceScreen extends StatefulWidget {
  const IndulgenceScreen({super.key});

  @override
  State<IndulgenceScreen> createState() => _IndulgenceScreenState();
}

class _IndulgenceScreenState extends State<IndulgenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();
  
  ViceModel? _selectedVice;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _emotionalState = 5;
  List<String> _selectedTriggers = [];
  bool _isLoading = false;
  bool _isPublic = false; // Default indulgences to private for sensitivity
  bool _notesPublic = false; // Default notes to private for privacy
  MoodType? _selectedMood; // User's current mood
  final MoodService _moodService = MoodService();

  final List<String> _commonTriggers = [
    'stress',
    'boredom',
    'loneliness',
    'anger',
    'anxiety',
    'peer pressure',
    'celebration',
    'habit',
    'availability',
    'fatigue',
  ];

  @override
  void initState() {
    super.initState();
    context.read<VicesBloc>().add(const LoadVices());
    
    // Listen to notes changes to show/hide notes privacy toggle
    _notesController.addListener(() {
      setState(() {
        // Force rebuild to show/hide notes privacy toggle
      });
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _recordIndulgence() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedVice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a vice'),
            backgroundColor: TugColors.indulgenceGreen,
          ),
        );
        return;
      }

      final indulgenceDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final indulgence = IndulgenceModel(
        viceId: _selectedVice!.id!,
        userId: 'current_user', // This should come from auth
        date: indulgenceDateTime,
        duration: _durationController.text.isNotEmpty 
            ? int.tryParse(_durationController.text) 
            : null,
        notes: _notesController.text.trim(),
        severityAtTime: _selectedVice!.severity,
        triggers: _selectedTriggers,
        emotionalState: _emotionalState,
        isPublic: _isPublic,
        notesPublic: _notesPublic,
      );

      context.read<VicesBloc>().add(RecordIndulgence(indulgence));
      
      // Create mood entry if mood was selected
      if (_selectedMood != null) {
        _createMoodEntry(_selectedMood!, indulgenceDateTime);
      }
    }
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  int _getMoodPositivityScore(MoodType mood) {
    switch (mood) {
      case MoodType.ecstatic:
        return 10;
      case MoodType.joyful:
        return 9;
      case MoodType.confident:
        return 8;
      case MoodType.content:
        return 7;
      case MoodType.focused:
        return 6;
      case MoodType.neutral:
        return 5;
      case MoodType.restless:
        return 4;
      case MoodType.tired:
        return 3;
      case MoodType.frustrated:
        return 2;
      case MoodType.anxious:
        return 2;
      case MoodType.sad:
        return 1;
      case MoodType.overwhelmed:
        return 1;
      case MoodType.angry:
        return 1;
      case MoodType.defeated:
        return 0;
      case MoodType.depressed:
        return 0;
    }
  }

  void _createMoodEntry(MoodType mood, DateTime date) async {
    try {
      final moodEntry = MoodEntry(
        moodType: mood,
        positivityScore: _getMoodPositivityScore(mood),
        recordedAt: date,
      );
      await _moodService.createMoodEntry(moodEntry);
    } catch (e) {
      // Don't fail indulgence creation if mood creation fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Indulgence saved, but mood tracking failed: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return BlocListener<VicesBloc, VicesState>(
      listener: (context, state) {
        setState(() => _isLoading = state is VicesLoading);
        
        if (state is VicesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: TugColors.indulgenceGreen,
            ),
          );
        }
        
        if (state is IndulgenceRecorded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Indulgence recorded'),
              backgroundColor: TugColors.indulgenceGreenLight,
            ),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/social');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode 
                    ? [TugColors.indulgenceGreen, TugColors.indulgenceGreenLight, TugColors.indulgenceGreenDark]
                    : [TugColors.lightBackground, TugColors.indulgenceGreen.withAlpha(20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            'record indulgence',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.indulgenceGreen,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: TugColors.indulgenceGreen),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/social');
              }
            },
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode 
                  ? [
                      TugColors.viceModeDarkBackground,
                      Color.lerp(TugColors.viceModeDarkBackground, TugColors.indulgenceGreen, 0.08) ?? TugColors.viceModeDarkBackground,
                    ] 
                  : [
                      TugColors.lightBackground,
                      Color.lerp(TugColors.lightBackground, TugColors.indulgenceGreen, 0.04) ?? TugColors.lightBackground,
                    ],
            ),
          ),
          child: BlocBuilder<VicesBloc, VicesState>(
            builder: (context, state) {
              if (state is VicesLoading && _selectedVice == null) {
                return Center(child: CircularProgressIndicator(color: TugColors.indulgenceGreen));
              }
              
              final vices = state is VicesLoaded 
                  ? state.vices.where((v) => v.active).toList()
                  : <ViceModel>[];
              
              if (vices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.psychology_alt,
                        size: 64,
                        color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no vices to track',
                        style: TextStyle(
                          color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'add some vices first to record indulgences',
                        style: TextStyle(
                          color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/vices-input'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TugColors.indulgenceGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('manage vices'),
                      ),
                    ],
                  ),
                );
              }
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Warning
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: TugColors.indulgenceMint.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: TugColors.indulgenceMint.withAlpha(100),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.healing,
                              color: TugColors.indulgenceGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'recording helps build awareness. be honest and kind to yourself.',
                                style: TextStyle(
                                  color: TugColors.indulgenceGreen,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Vice Selection
                      Text(
                        'which vice?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.indulgenceGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: TugColors.indulgenceGreen.withAlpha(50),
                          ),
                        ),
                        child: DropdownButton<ViceModel>(
                          value: _selectedVice,
                          hint: Text(
                            'select a vice',
                            style: TextStyle(
                              color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                            ),
                          ),
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
                          items: vices.toSet().map((vice) {
                            final color = Color(int.parse(vice.color.substring(1), radix: 16) + 0xFF000000);
                            return DropdownMenuItem<ViceModel>(
                              value: vice,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      vice.name,
                                      style: TextStyle(
                                        color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: TugColors.getSeverityColor(vice.severity),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${vice.severity}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (vice) {
                            setState(() {
                              _selectedVice = vice;
                            });
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Date and Time
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'date',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.indulgenceGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectDate,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: TugColors.indulgenceGreen.withAlpha(50),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: TugColors.indulgenceGreen,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                          style: TextStyle(
                                            color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'time',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.indulgenceGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: TugColors.indulgenceGreen.withAlpha(50),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: TugColors.indulgenceGreen,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _selectedTime.format(context),
                                          style: TextStyle(
                                            color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Duration (optional)
                      TugTextField(
                        label: 'duration (minutes) - optional',
                        hint: 'how long did this last?',
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Emotional State
                      Text(
                        'emotional state before (1 = very low, 10 = very good)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.indulgenceGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: _emotionalState.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _emotionalState.toString(),
                        activeColor: TugColors.indulgenceGreenLight,
                        onChanged: (value) {
                          setState(() {
                            _emotionalState = value.round();
                          });
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Triggers
                      Text(
                        'what triggered this? (tap to select)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.indulgenceGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _commonTriggers.map((trigger) {
                          final isSelected = _selectedTriggers.contains(trigger);
                          return FilterChip(
                            label: Text(trigger),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTriggers.add(trigger);
                                } else {
                                  _selectedTriggers.remove(trigger);
                                }
                              });
                            },
                            selectedColor: TugColors.indulgenceMint.withAlpha(100),
                            checkmarkColor: TugColors.indulgenceGreen,
                            labelStyle: TextStyle(
                              color: isSelected 
                                  ? TugColors.indulgenceGreen
                                  : (isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Mood Selection
                      MoodSelector(
                        selectedMood: _selectedMood,
                        onMoodSelected: (mood) {
                          setState(() {
                            _selectedMood = mood;
                          });
                        },
                        isDarkMode: isDarkMode,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Notes
                      TugTextField(
                        label: 'notes (optional)',
                        hint: 'how are you feeling? what will you do differently next time?',
                        controller: _notesController,
                        maxLines: 4,
                      ),
                      
                      const SizedBox(height: 24),

                      // Privacy Controls
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: TugColors.indulgenceGreen.withAlpha(50),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 18,
                                  color: TugColors.indulgenceGreen,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'privacy settings',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: TugColors.indulgenceGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Share Indulgence Toggle
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'share indulgence',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        'post this indulgence to your social feed',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isPublic,
                                  onChanged: (value) {
                                    setState(() {
                                      _isPublic = value;
                                      // If indulgence is private, notes should be private too
                                      if (!value) {
                                        _notesPublic = false;
                                      }
                                    });
                                  },
                                  activeColor: TugColors.indulgenceGreen,
                                ),
                              ],
                            ),
                            
                            // Include Notes Toggle (only show if indulgence is public and notes exist)
                            if (_isPublic && _notesController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'include notes',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                                          ),
                                        ),
                                        Text(
                                          'share your notes with friends',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _notesPublic,
                                    onChanged: (value) {
                                      setState(() {
                                        _notesPublic = value;
                                      });
                                    },
                                    activeColor: TugColors.indulgenceGreen,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TugColors.indulgenceGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _recordIndulgence,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'record indulgence',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                
                        ),
                      ),
                      SizedBox(height: 100,)
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}