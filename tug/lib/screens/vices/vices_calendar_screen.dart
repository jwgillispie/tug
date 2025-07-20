// lib/screens/vices/vices_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../blocs/vices/bloc/vices_bloc.dart';
import '../../blocs/vices/bloc/vices_event.dart';
import '../../blocs/vices/bloc/vices_state.dart';
import '../../models/vice_model.dart';
import '../../models/indulgence_model.dart';
import '../../utils/theme/colors.dart';
import '../../utils/quantum_effects.dart';
import '../../services/vice_service.dart';
import '../../services/app_mode_service.dart';

class VicesCalendarScreen extends StatefulWidget {
  const VicesCalendarScreen({super.key});

  @override
  State<VicesCalendarScreen> createState() => _VicesCalendarScreenState();
}

class _VicesCalendarScreenState extends State<VicesCalendarScreen> with AutomaticKeepAliveClientMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  ViceModel? _selectedVice;
  Map<DateTime, List<IndulgenceModel>> _indulgences = {};
  final ViceService _viceService = ViceService();
  final AppModeService _appModeService = AppModeService();
  AppMode _currentMode = AppMode.vicesMode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _initializeAppMode();
    context.read<VicesBloc>().add(const LoadVices(forceRefresh: false));
    _loadIndulgences();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _initializeAppMode() async {
    try {
      await _appModeService.initialize();
      _appModeService.modeStream.listen((mode) {
        if (mounted) {
          setState(() {
            _currentMode = mode;
          });
        }
      });
      setState(() {
        _currentMode = _appModeService.currentMode;
      });
    } catch (e) {
      _currentMode = AppMode.vicesMode;
    }
  }

  Future<void> _loadIndulgences() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final indulgences = await _viceService.getAllIndulgences();
      
      // Group indulgences by date
      final Map<DateTime, List<IndulgenceModel>> groupedIndulgences = {};
      for (final indulgence in indulgences) {
        final date = DateTime(
          indulgence.date.year,
          indulgence.date.month,
          indulgence.date.day,
        );
        
        if (!groupedIndulgences.containsKey(date)) {
          groupedIndulgences[date] = [];
        }
        groupedIndulgences[date]!.add(indulgence);
      }

      setState(() {
        _indulgences = groupedIndulgences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load indulgences: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  List<IndulgenceModel> _getIndulgencesForDay(DateTime day) {
    return _indulgences[DateTime(day.year, day.month, day.day)] ?? [];
  }

  bool _isCleanDay(DateTime day) {
    final indulgences = _getIndulgencesForDay(day);
    return indulgences.isEmpty && day.isBefore(DateTime.now().add(const Duration(days: 1)));
  }

  Widget _buildCalendarMarkers(DateTime day) {
    final indulgences = _getIndulgencesForDay(day);
    final isClean = _isCleanDay(day);
    
    if (indulgences.isEmpty && !isClean) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 4,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (indulgences.isNotEmpty)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: TugColors.indulgenceGreen,
                shape: BoxShape.circle,
              ),
            ),
          if (indulgences.isNotEmpty && isClean)
            const SizedBox(width: 2),
          if (isClean)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: TugColors.success,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  void _showDayDetails(DateTime day) {
    final indulgences = _getIndulgencesForDay(day);
    final isClean = _isCleanDay(day);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          DateFormat('MMMM d, yyyy').format(day),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (indulgences.isNotEmpty) ...[
              Text(
                'Indulgences (${indulgences.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: TugColors.indulgenceGreen,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...indulgences.map((indulgence) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TugColors.indulgenceGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TugColors.indulgenceGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: TugColors.indulgenceGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Vice: ${indulgence.viceId}', // We'd need to resolve the vice name
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (indulgence.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        indulgence.notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    Text(
                      DateFormat('HH:mm').format(indulgence.date),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              )),
            ],
            if (isClean) ...[
              if (indulgences.isNotEmpty) const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TugColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TugColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: TugColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Clean day',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: TugColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (indulgences.isEmpty && !isClean) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No data recorded',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (day.isAfter(DateTime.now().subtract(const Duration(days: 7))))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/indulgences/new');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TugColors.indulgenceGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Record Indulgence'),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakAnalysis() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<VicesBloc, VicesState>(
      builder: (context, state) {
        if (state is VicesLoaded) {
          final vices = state.vices.where((v) => v.active).toList();
          
          if (vices.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: TugColors.viceGreen.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Streaks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: TugColors.viceGreen,
                  ),
                ),
                const SizedBox(height: 16),
                ...vices.map((vice) {
                  final color = Color(int.parse(vice.color.substring(1), radix: 16) + 0xFF000000);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
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
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${vice.currentStreak} days',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: TugColors.getStreakColor(true, vice.currentStreak),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLegend() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TugColors.viceGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
            color: TugColors.success,
            label: 'Clean Day',
            icon: Icons.check_circle_outline,
          ),
          _buildLegendItem(
            color: TugColors.indulgenceGreen,
            label: 'Indulgence',
            icon: Icons.spa_rounded,
          ),
          _buildLegendItem(
            color: Colors.grey,
            label: 'No Data',
            icon: Icons.help_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode 
                  ? [TugColors.viceModeDarkBackground, TugColors.viceGreen, TugColors.viceEmerald]
                  : [TugColors.lightBackground, TugColors.viceGreen.withValues(alpha: 0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: QuantumEffects.holographicShimmer(
          child: QuantumEffects.gradientText(
            'vice calendar',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            colors: isDarkMode ? [TugColors.viceGreen, TugColors.viceEmerald, TugColors.viceGreenDark] : [TugColors.viceGreen, TugColors.viceEmerald],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: TugColors.viceGreen,
            ),
            onPressed: () {
              context.read<VicesBloc>().add(const LoadVices(forceRefresh: true));
              _loadIndulgences();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: TugColors.viceGreen),
                  const SizedBox(height: 16),
                  Text(
                    'Loading calendar...',
                    style: TextStyle(
                      color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Calendar
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TableCalendar<IndulgenceModel>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      eventLoader: _getIndulgencesForDay,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        markersMaxCount: 2,
                        markerDecoration: BoxDecoration(
                          color: TugColors.indulgenceGreen,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: TugColors.viceGreen.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: TugColors.viceGreen,
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: TextStyle(
                          color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                        ),
                        weekendTextStyle: TextStyle(
                          color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: TugColors.viceGreen,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: TugColors.viceGreen,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: TugColors.viceGreen,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          return _buildCalendarMarkers(day);
                        },
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _showDayDetails(selectedDay);
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),
                  ),
                  
                  // Legend
                  _buildLegend(),
                  
                  // Streak Analysis
                  _buildStreakAnalysis(),
                  
                  const SizedBox(height: 88), // Bottom padding for navigation
                ],
              ),
            ),
    );
  }
}