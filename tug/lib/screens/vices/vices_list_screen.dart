// lib/screens/vices/vices_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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

class VicesListScreen extends StatefulWidget {
  const VicesListScreen({super.key});

  @override
  State<VicesListScreen> createState() => _VicesListScreenState();
}

class _VicesListScreenState extends State<VicesListScreen> with AutomaticKeepAliveClientMixin {
  String? _filterSeverity;
  bool _showFilters = false;
  bool _isFirstLoad = true;
  bool _showSwipeHint = true;
  final ViceService _viceService = ViceService();
  final AppModeService _appModeService = AppModeService();
  AppMode _currentMode = AppMode.vicesMode;
  final Set<String> _expandedVices = <String>{}; // Track which vices are expanded
  final Map<String, List<IndulgenceModel>> _viceIndulgences = {}; // Cache indulgences by vice ID

  @override
  void initState() {
    super.initState();
    _initializeAppMode();
    context.read<VicesBloc>().add(const LoadVices(forceRefresh: false));
    _preloadIndulgenceCounts();
  }

  Future<void> _preloadIndulgenceCounts() async {
    // Wait a bit for vices to load first
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    try {
      final state = context.read<VicesBloc>().state;
      if (state is VicesLoaded) {
        final activeVices = state.vices.where((v) => v.active && v.id != null).toList();
        
        // Load indulgence counts for all vices in background
        for (final vice in activeVices) {
          if (!mounted) return;
          _loadIndulgencesForVice(vice.id!);
          // Small delay to avoid overwhelming the server
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    } catch (e) {
      // Silent failure - this is just for UX improvement
    }
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

  Future<void> _refreshVices() async {
    try {
      await _viceService.clearAllCache();
    } catch (e) {
      // Cache clear failed - not critical
    }
    
    // Clear cached indulgences
    _viceIndulgences.clear();
    _expandedVices.clear();
    
    context.read<VicesBloc>().add(const LoadVices(forceRefresh: true));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _loadIndulgencesForVice(String viceId) async {
    if (_viceIndulgences.containsKey(viceId)) {
      return; // Already loaded
    }
    
    try {
      final indulgences = await _viceService.getIndulgences(viceId);
      if (mounted) {
        setState(() {
          _viceIndulgences[viceId] = indulgences;
        });
      }
    } catch (e) {
      // Handle error - show empty list
      if (mounted) {
        setState(() {
          _viceIndulgences[viceId] = [];
        });
      }
    }
  }

  void _toggleViceExpansion(ViceModel vice) {
    if (vice.id == null) return;
    
    setState(() {
      if (_expandedVices.contains(vice.id)) {
        _expandedVices.remove(vice.id);
      } else {
        _expandedVices.add(vice.id!);
        // Load indulgences when expanding
        _loadIndulgencesForVice(vice.id!);
      }
    });
  }

  void _showViceDetails(ViceModel vice) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = Color(int.parse(vice.color.substring(1), radix: 16) + 0xFF000000);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
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
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                isDarkMode: isDarkMode,
                icon: Icons.priority_high,
                iconColor: TugColors.getSeverityColor(vice.severity),
                label: 'severity:',
                value: '${vice.severity}/5 - ${vice.severityDescription}',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                isDarkMode: isDarkMode,
                icon: Icons.psychology,
                iconColor: TugColors.getStreakColor(true, vice.currentStreak),
                label: 'clean streak:',
                value: '${vice.currentStreak} day${vice.currentStreak != 1 ? 's' : ''}',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                isDarkMode: isDarkMode,
                icon: Icons.emoji_events,
                iconColor: TugColors.success,
                label: 'best streak:',
                value: '${vice.longestStreak} day${vice.longestStreak != 1 ? 's' : ''}',
              ),
              if (vice.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'motivation:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? TugColors.viceModeDarkSurface.withOpacity(0.5)
                        : TugColors.lightSurface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    vice.description,
                    style: TextStyle(
                      color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/indulgences/new');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TugColors.indulgenceGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('record indulgence'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow({
    required bool isDarkMode,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode
                    ? TugColors.viceModeTextSecondary
                    : TugColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDarkMode
                    ? TugColors.viceModeTextPrimary
                    : TugColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;
    
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
            'your vices',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            colors: isDarkMode ? [TugColors.viceGreen, TugColors.viceEmerald, TugColors.viceGreenDark] : [TugColors.viceGreen, TugColors.viceEmerald],
          ),
        ),
        actions: [
          QuantumEffects.floating(
            offset: 5,
            child: QuantumEffects.quantumBorder(
              glowColor: TugColors.viceGreen,
              intensity: 0.8,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      TugColors.viceGreen.withValues(alpha: 0.4),
                      TugColors.viceGreenDark.withValues(alpha: 0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TugColors.viceGreen.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Vice Summary Card
          _buildViceSummary(),
          
          // Filters
          if (_showFilters) _buildFilters(),
          
          // Vices List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshVices,
              color: TugColors.viceGreen,
              child: BlocBuilder<VicesBloc, VicesState>(
                builder: (context, state) {
                  if (state is VicesLoading && _isFirstLoad) {
                    return ListView(
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: CircularProgressIndicator(
                            color: TugColors.viceGreen,
                          ),
                        ),
                      ],
                    );
                  }
                  
                  if (state is VicesError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: TugColors.error,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error: ${state.message}',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'pull down to refresh',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  
                  _isFirstLoad = false;
                  
                  final List<ViceModel> vices;
                  if (state is VicesLoaded) {
                    var allVices = state.vices.where((v) => v.active).toList();
                    
                    // Apply severity filter if set
                    if (_filterSeverity != null) {
                      final severity = int.parse(_filterSeverity!);
                      allVices = allVices.where((v) => v.severity == severity).toList();
                    }
                    
                    vices = allVices;
                  } else {
                    vices = [];
                  }
                  
                  if (vices.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                size: 64,
                                color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'no vices tracked',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'start tracking vices to see them here',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TugColors.viceGreen,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => context.go('/vices-input'),
                                icon: const Icon(Icons.add),
                                label: const Text('manage vices'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    child: Column(
                      children: [
                        // Swipe hint
                        if (vices.isNotEmpty && _showSwipeHint)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDarkMode 
                                    ? TugColors.viceGreen.withOpacity(0.15) 
                                    : TugColors.viceGreen.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: TugColors.viceGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.swipe_left,
                                        color: TugColors.viceGreen,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'tap for details, swipe for actions',
                                        style: TextStyle(
                                          color: TugColors.viceGreen,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.close,
                                      color: TugColors.viceGreen,
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
                          ),
                        // Vices list
                        ...vices.map((vice) => _buildExpandableViceCard(vice)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableViceCard(ViceModel vice) {
    final color = Color(int.parse(vice.color.substring(1), radix: 16) + 0xFF000000);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = vice.id != null && _expandedVices.contains(vice.id);
    final indulgences = vice.id != null ? (_viceIndulgences[vice.id] ?? <IndulgenceModel>[]) : <IndulgenceModel>[];
    
    return QuantumEffects.quantumBorder(
      glowColor: color,
      intensity: 0.3,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
                ? [
                    TugColors.viceModeDarkSurface,
                    Color.lerp(TugColors.viceModeDarkSurface, color, 0.03) ?? TugColors.viceModeDarkSurface,
                  ]
                : [
                    Colors.white,
                    Color.lerp(Colors.white, color, 0.02) ?? Colors.white,
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.25) 
                  : Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Main vice card
              Slidable(
                key: ValueKey(vice.id ?? vice.name),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  dragDismissible: false,
                  children: [
                    SlidableAction(
                      onPressed: (_) {
                        if (_showSwipeHint) {
                          setState(() {
                            _showSwipeHint = false;
                          });
                        }
                        context.go('/indulgences/new');
                      },
                      backgroundColor: TugColors.indulgenceGreen,
                      foregroundColor: Colors.white,
                      icon: Icons.spa_rounded,
                      label: 'Record',
                    ),
                    SlidableAction(
                      onPressed: (_) {
                        if (_showSwipeHint) {
                          setState(() {
                            _showSwipeHint = false;
                          });
                        }
                        context.go('/vices-input');
                      },
                      backgroundColor: TugColors.viceEmerald,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => _toggleViceExpansion(vice),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Vice color and streak indicator
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: color.withOpacity(isDarkMode ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(isDarkMode ? 0.3 : 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${vice.currentStreak}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: color,
                                ),
                              ),
                              Text(
                                'days',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Vice info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vice.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                                          ),
                                        ),
                                        if (!isExpanded) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            indulgences.isNotEmpty 
                                                ? 'Tap to view ${indulgences.length} indulgence${indulgences.length != 1 ? 's' : ''}'
                                                : 'Tap to see indulgence history',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: color.withOpacity(0.8),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Icon(
                                        isExpanded ? Icons.expand_less : Icons.expand_more,
                                        color: color,
                                        size: 24,
                                      ),
                                      if (!isExpanded && indulgences.isNotEmpty) ...[
                                        Text(
                                          '${indulgences.length}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: color.withOpacity(0.7),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: TugColors.getSeverityColor(vice.severity),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'severity ${vice.severity}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'best: ${vice.longestStreak} days',
                                    style: TextStyle(
                                      color: TugColors.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (isExpanded) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${indulgences.length} indulgence${indulgences.length != 1 ? 's' : ''} recorded',
                                  style: TextStyle(
                                    color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Expanded indulgences list
              if (isExpanded) _buildIndulgencesList(vice, indulgences, color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndulgencesList(ViceModel vice, List<IndulgenceModel> indulgences, Color viceColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (indulgences.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? TugColors.viceModeDarkSurface.withOpacity(0.5)
              : Colors.grey.shade50,
          border: Border(
            top: BorderSide(
              color: viceColor.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.celebration,
              color: TugColors.success,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No indulgences recorded - keep up the clean streak!',
                style: TextStyle(
                  color: TugColors.success,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode 
            ? TugColors.viceModeDarkSurface.withOpacity(0.5)
            : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: viceColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: viceColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Indulgences',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: viceColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${indulgences.length} total',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Indulgences list (show max 5 recent ones)
          ...indulgences.take(5).map((indulgence) => _buildIndulgenceItem(indulgence, viceColor)),
          // Show more button if there are more than 5
          if (indulgences.length > 5) _buildShowMoreButton(vice, indulgences.length - 5),
        ],
      ),
    );
  }

  Widget _buildIndulgenceItem(IndulgenceModel indulgence, Color viceColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dateFormatter = DateFormat('MMM d, y \'at\' h:mm a');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and time
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: viceColor.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormatter.format(indulgence.date),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                  ),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (indulgence.triggers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: indulgence.triggers.take(3).map((trigger) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: viceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: viceColor.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        trigger,
                        style: TextStyle(
                          fontSize: 10,
                          color: viceColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          // Duration if available
          if (indulgence.duration != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.orange.withOpacity(0.2) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                indulgence.formattedDuration,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShowMoreButton(ViceModel vice, int remainingCount) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: TextButton.icon(
          onPressed: () {
            // TODO: Navigate to full indulgences list for this vice
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$remainingCount more indulgences for ${vice.name}'),
                backgroundColor: TugColors.viceGreen,
              ),
            );
          },
          icon: Icon(
            Icons.expand_more,
            size: 16,
            color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
          ),
          label: Text(
            'Show $remainingCount more',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildViceSummary() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? TugColors.viceModeDarkSurface : TugColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2) 
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.05) 
              : Colors.black.withOpacity(0.03),
          width: 0.5,
        ),
      ),
      child: BlocBuilder<VicesBloc, VicesState>(
        builder: (context, state) {
          if (state is VicesLoaded) {
            final vices = state.vices.where((v) => v.active).toList();

            if (vices.isEmpty) {
              return Center(
                child: QuantumEffects.gradientText(
                  'no vices tracked yet',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                  colors: [TugColors.viceGreen, TugColors.viceEmerald],
                ),
              );
            }

            // Calculate statistics
            final totalStreak = vices.fold<int>(0, (sum, vice) => sum + vice.currentStreak);
            final avgStreak = vices.isNotEmpty ? (totalStreak / vices.length).round() : 0;
            final longestStreak = vices.fold<int>(0, (max, vice) => vice.longestStreak > max ? vice.longestStreak : max);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  title: 'tracked',
                  value: vices.length.toString(),
                  icon: Icons.psychology,
                ),
                _buildSummaryItem(
                  title: 'avg streak',
                  value: '$avgStreak days',
                  icon: Icons.trending_up,
                ),
                _buildSummaryItem(
                  title: 'best streak',
                  value: '$longestStreak days',
                  icon: Icons.emoji_events,
                ),
              ],
            );
          }

          return Center(
            child: Text(
              'loading...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Icon(
          icon,
          color: TugColors.viceGreen,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDarkMode ? TugColors.viceModeDarkBackground : Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'filter vices',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _filterSeverity = null;
                    _showFilters = false;
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('reset'),
                style: TextButton.styleFrom(
                  foregroundColor: TugColors.viceGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Severity Filter
          DropdownButtonFormField<String?>(
            decoration: InputDecoration(
              labelText: 'filter by severity',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              filled: true,
              fillColor: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
            ),
            value: _filterSeverity,
            dropdownColor: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'all severities',
                  style: TextStyle(
                    color: isDarkMode 
                        ? TugColors.viceModeTextPrimary 
                        : TugColors.lightTextPrimary,
                  ),
                ),
              ),
              ...List.generate(5, (index) {
                final severity = index + 1;
                return DropdownMenuItem(
                  value: severity.toString(),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: TugColors.getSeverityColor(severity),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'severity $severity',
                        style: TextStyle(
                          color: isDarkMode 
                              ? TugColors.viceModeTextPrimary 
                              : TugColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (String? severity) {
              setState(() {
                _filterSeverity = severity;
              });
            },
          ),
        ],
      ),
    );
  }
}