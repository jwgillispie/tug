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
import '../../services/vice_service.dart';

class IndulgenceScreen extends StatefulWidget {
  const IndulgenceScreen({super.key});

  @override
  State<IndulgenceScreen> createState() => _IndulgenceScreenState();
}

class _IndulgenceScreenState extends State<IndulgenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();
  
  List<ViceModel> _selectedVices = []; // Changed to support multiple vices
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _emotionalState = 5;
  List<String> _selectedTriggers = [];
  bool _isLoading = false;
  bool _isPublic = false; // Default indulgences to private for sensitivity
  bool _notesPublic = false; // Default notes to private for privacy
  MoodType? _selectedMood; // User's current mood
  final MoodService _moodService = MoodService();
  final ViceService _viceService = ViceService();
  
  // Fallback vice list for when bloc fails
  List<ViceModel> _fallbackVices = [];
  bool _usesFallback = false;

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
    
    // Load vices with more aggressive retry logic
    _loadVicesWithRetry();
    
    // Listen to notes changes to show/hide notes privacy toggle
    _notesController.addListener(() {
      setState(() {
        // Force rebuild to show/hide notes privacy toggle
      });
    });
  }

  Future<void> _loadVicesWithRetry() async {
    // print('DEBUG: Loading vices with force refresh by default (using the working method)');
    
    // Use the working method immediately: bloc force refresh
    // This bypasses the potentially corrupted cache that causes the "missing IDs" issue
    context.read<VicesBloc>().add(const LoadVices(forceRefresh: true));
    
    // Give it time to load since this approach works reliably
    await Future.delayed(const Duration(seconds: 2));
    
    // Only use fallback if the proven method somehow fails
    if (mounted) {
      final state = context.read<VicesBloc>().state;
      if (state is VicesError || 
          (state is VicesLoaded && state.vices.isEmpty)) {
        // print('DEBUG: Force refresh failed, trying direct service as fallback');
        await _loadVicesDirectly();
      } else if (state is VicesLoaded) {
        // print('DEBUG: Successfully loaded ${state.vices.length} vices with force refresh');
      }
    }
  }

  Future<void> _loadVicesDirectly() async {
    try {
      // print('DEBUG: Attempting direct vice service call as fallback');
      final vices = await _viceService.getVices(forceRefresh: false, useCache: true);
      final activeVices = vices.where((v) => v.active && v.id != null).toList();
      
      // print('DEBUG: Direct service loaded ${activeVices.length} vices');
      
      if (activeVices.isNotEmpty) {
        setState(() {
          _fallbackVices = activeVices;
          _usesFallback = true;
        });
      }
    } catch (e) {
      // print('DEBUG: Direct service call failed: $e');
    }
  }

  Future<void> _performDataCleanup() async {
    try {
      // print('DEBUG: Starting comprehensive data cleanup...');
      
      // Clear all caches completely
      await _viceService.clearAllCache();
      // print('DEBUG: Cleared all vice service caches');
      
      // Clear local state
      if (mounted) {
        setState(() {
          _fallbackVices.clear();
          _usesFallback = false;
          _selectedVices.clear();
        });
      }
      // print('DEBUG: Cleared local state');
      
      // Force a fresh load using the working method (bloc refresh)
      context.read<VicesBloc>().add(const ClearVicesCache());
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        context.read<VicesBloc>().add(const LoadVices(forceRefresh: true));
        // print('DEBUG: Triggered fresh data load via bloc refresh (the working method)');
      }
      
      // Show user feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Deep cleanup completed. Fresh data loaded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // print('DEBUG: Data cleanup failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleanup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _recordIndulgence() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedVices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one vice'),
          backgroundColor: TugColors.indulgenceGreen,
        ),
      );
      return;
    }

    if (_selectedVices.any((v) => v.id == null || v.id!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected vice has no ID. Please refresh and try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final indulgenceDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final indulgence = IndulgenceModel(
        viceIds: _selectedVices.map((v) => v.id!).toList(),
        userId: 'current_user', // This should come from auth
        date: indulgenceDateTime,
        duration: _durationController.text.isNotEmpty 
            ? int.tryParse(_durationController.text) 
            : null,
        notes: _notesController.text.trim(),
        severityAtTime: _selectedVices.isNotEmpty ? _selectedVices.first.severity : 1, // Use primary vice severity
        triggers: _selectedTriggers,
        emotionalState: _emotionalState,
        isPublic: _isPublic,
        notesPublic: _notesPublic,
      );

      // print('DEBUG: Recording indulgence for vice ${_selectedVice!.name} (ID: ${_selectedVice!.id})');
      // print('DEBUG: Social sharing settings - isPublic: $_isPublic, notesPublic: $_notesPublic');
      // print('DEBUG: Notes content: "${_notesController.text.trim()}"');
      // print('DEBUG: Will create social post: ${_isPublic && _notesPublic && _notesController.text.trim().isNotEmpty}');
      // print('DEBUG: Indulgence details: ${indulgence.toString()}');
      
      context.read<VicesBloc>().add(RecordIndulgence(indulgence));
      
      // Create mood entry if mood was selected
      if (_selectedMood != null) {
        _createMoodEntry(_selectedMood!, indulgenceDateTime);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording indulgence: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        // print('DEBUG: BlocListener received state: ${state.runtimeType}');
        if (state is VicesLoaded) {
          // print('DEBUG: VicesLoaded with ${state.vices.length} vices');
        }
        if (state is VicesError) {
          // print('DEBUG: VicesError: ${state.message}');
        }
        
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
              if (state is VicesLoading && _selectedVices.isEmpty) {
                return Center(child: CircularProgressIndicator(color: TugColors.indulgenceGreen));
              }
              
              // Handle error state gracefully
              if (state is VicesError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading vices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Unable to load vices due to authentication issues. Please try again or check your connection.',
                          style: TextStyle(
                            color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.read<VicesBloc>().add(const LoadVices(forceRefresh: true));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TugColors.indulgenceGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('retry'),
                      ),
                    ],
                  ),
                );
              }
              
              // Use fallback vices if bloc fails but we have cached vices
              final allVices = _usesFallback && _fallbackVices.isNotEmpty
                  ? _fallbackVices
                  : (state is VicesLoaded ? state.vices : <ViceModel>[]);
              
              // Filter for active vices - be very lenient for now
              final vices = allVices.where((v) => v.active).toList();
              
              // Debug info
              // print('DEBUG: BlocBuilder - State: ${state.runtimeType}, All vices: ${allVices.length}, Active vices: ${vices.length}, Uses fallback: $_usesFallback');
              // if (allVices.isNotEmpty) {
              //   print('DEBUG: First vice - Name: ${allVices.first.name}, Active: ${allVices.first.active}, ID: ${allVices.first.id}');
              //   print('DEBUG: All vices details:');
              //   for (var i = 0; i < allVices.length; i++) {
              //     final vice = allVices[i];
              //     print('  Vice $i: ${vice.name}, Active: ${vice.active}, ID: ${vice.id}');
              //   }
              // } else {
              //   print('DEBUG: No vices found at all');
              // }
              
              // Check dropdown filtering
              final dropdownVices = vices.where((v) => v.id != null && v.id!.isNotEmpty).toList();
              // print('DEBUG: Dropdown will show ${dropdownVices.length} vices (filtered for valid IDs)');
              
              if (vices.isEmpty && (state is VicesLoaded || _usesFallback)) {
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
                child: Column(
                  children: [
                    // Show fallback indicator if using cached data
                    if (_usesFallback) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Using cached vices data due to connectivity issues',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Form(
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
                        child: Builder(
                          builder: (context) {
                            final validVices = vices.where((v) => v.id != null && v.id!.isNotEmpty).toList();
                            // print('DEBUG: DropdownButton validVices count: ${validVices.length}');
                            
                            if (validVices.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vices.isNotEmpty 
                                          ? 'Vices found but missing IDs. Please refresh or contact support.'
                                          : 'No vices available. Please add vices first.',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            // This is the method that works!
                                            context.read<VicesBloc>().add(const LoadVices(forceRefresh: true));
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: TugColors.indulgenceGreen,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                          child: const Text(
                                            'Fix & Reload Vices',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () async {
                                            await _performDataCleanup();
                                          },
                                          child: Text(
                                            'Deep Clean',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Vices',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to select multiple vices for this indulgence',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Selected vices display
                                if (_selectedVices.isNotEmpty) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                      color: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
                                    ),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _selectedVices.map((vice) {
                                        final viceColor = Color(
                                          int.parse(vice.color.substring(1), radix: 16) + 0xFF000000,
                                        );
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: viceColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: viceColor),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: viceColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                vice.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: viceColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: TugColors.getSeverityColor(vice.severity),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${vice.severity}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedVices.remove(vice);
                                                  });
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: viceColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                // Available vices list
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    color: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: validVices.length,
                                    itemBuilder: (context, index) {
                                      final vice = validVices[index];
                                      final isSelected = _selectedVices.any((v) => v.id == vice.id);
                                      final viceColor = Color(
                                        int.parse(vice.color.substring(1), radix: 16) + 0xFF000000,
                                      );
                                      
                                      return ListTile(
                                        dense: true,
                                        leading: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: viceColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? viceColor : Colors.grey.shade400,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        title: Text(
                                          vice.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            color: isSelected 
                                                ? viceColor 
                                                : (isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary),
                                          ),
                                        ),
                                        trailing: Container(
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
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedVices.removeWhere((v) => v.id == vice.id);
                                            } else {
                                              _selectedVices.add(vice);
                                            }
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                                // Validation error display
                                if (_selectedVices.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Please select at least one vice',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.red.shade300 : Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }
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
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}