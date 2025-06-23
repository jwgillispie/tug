// lib/screens/vices/vices_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/vices/bloc/vices_bloc.dart';
import '../../blocs/vices/bloc/vices_event.dart';
import '../../blocs/vices/bloc/vices_state.dart';
import '../../widgets/vices/vice_color_picker.dart';
import '../../widgets/vices/edit_vice_dialog.dart';
import '../../models/vice_model.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/buttons.dart';
import '../../widgets/common/tug_text_field.dart';

class VicesInputScreen extends StatefulWidget {
  final bool fromHome;
  
  const VicesInputScreen({super.key, this.fromHome = false});

  @override
  State<VicesInputScreen> createState() => _VicesInputScreenState();
}

class _VicesInputScreenState extends State<VicesInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _viceController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _currentSeverity = 3;
  String _selectedColor = '#DC2626'; // Default to red
  bool _isLoading = false;
  bool _showWarning = true;

  @override
  void initState() {
    super.initState();
    context.read<VicesBloc>().add(LoadVices());
  }

  @override
  void dispose() {
    _viceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addVice() {
    if (_formKey.currentState?.validate() ?? false) {
      final newVice = ViceModel(
        name: _viceController.text.trim(),
        severity: _currentSeverity.round(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
      );
      
      context.read<VicesBloc>().add(AddVice(newVice));
      
      _viceController.clear();
      _descriptionController.clear();
      setState(() {
        _currentSeverity = 3;
        _selectedColor = '#DC2626';
      });
    }
  }

  void _handleContinue() {
    if (widget.fromHome) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _showEditDialog(BuildContext context, ViceModel vice) {
    showDialog(
      context: context,
      builder: (context) => EditViceDialog(
        vice: vice,
        onSave: (updatedVice) {
          context.read<VicesBloc>().add(UpdateVice(updatedVice));
        },
      ),
    );
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
              backgroundColor: TugColors.viceRed,
            ),
          );
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
                    ? [TugColors.viceRed, TugColors.viceOrange, TugColors.viceRedDark]
                    : [TugColors.lightBackground, TugColors.viceRed.withAlpha(20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            'manage vices',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.viceRed,
            ),
          ),
          leading: widget.fromHome 
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: TugColors.viceRed),
                  onPressed: () => context.pop(),
                )
              : null,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode 
                  ? [
                      TugColors.viceModeDarkBackground,
                      Color.lerp(TugColors.viceModeDarkBackground, TugColors.viceRed, 0.08) ?? TugColors.viceModeDarkBackground,
                    ] 
                  : [
                      TugColors.lightBackground,
                      Color.lerp(TugColors.lightBackground, TugColors.viceRed, 0.04) ?? TugColors.lightBackground,
                    ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning notice
                if (_showWarning)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: TugColors.viceOrange.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: TugColors.viceOrange.withAlpha(100),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: TugColors.viceOrange,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'approach with care',
                                style: TextStyle(
                                  color: TugColors.viceOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 20, color: TugColors.viceOrange),
                              onPressed: () => setState(() => _showWarning = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'this mode is for tracking behaviors you want to overcome. if you\'re struggling with serious addiction, consider professional support.',
                          style: TextStyle(
                            color: TugColors.viceOrange,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                Text(
                  widget.fromHome
                      ? 'identify what you want to overcome'
                      : 'what habits hold you back?',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.viceRed,
                  ) ?? TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.viceRed,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'define behaviors you want to break free from',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 32),
                
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TugTextField(
                        label: 'vice or habit',
                        hint: 'ex. smoking, procrastination, social media',
                        controller: _viceController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'please name the habit';
                          }
                          if (value.length < 2) {
                            return 'habit name too short';
                          }
                          if (value.length > 30) {
                            return 'please make it shorter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'severity level (1 = mild, 5 = critical)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                        ),
                      ),
                      Slider(
                        value: _currentSeverity,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '${_currentSeverity.round()} - ${ViceModel(name: '', severity: _currentSeverity.round(), color: '').severityDescription}',
                        activeColor: TugColors.getSeverityColor(_currentSeverity.round()),
                        onChanged: (value) {
                          setState(() {
                            _currentSeverity = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TugTextField(
                        label: 'why do you want to change this? (optional)',
                        hint: 'motivation helps during tough moments',
                        controller: _descriptionController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'pick a color',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ViceColorPicker(
                        selectedColor: _selectedColor,
                        onColorSelected: (color) {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<VicesBloc, VicesState>(
                        builder: (context, state) {
                          final maxVicesReached = state is VicesLoaded && 
                              state.vices.where((v) => v.active).length >= 5;
                          
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TugColors.viceRed,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: (_isLoading || maxVicesReached) 
                                  ? null 
                                  : _addVice,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(maxVicesReached 
                                      ? 'max 5 vices tracked' 
                                      : 'add vice'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                BlocBuilder<VicesBloc, VicesState>(
                  builder: (context, state) {
                    if (state is VicesLoaded) {
                      final activeVices = state.vices.where((v) => v.active).toList();
                      
                      if (activeVices.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.psychology_alt,
                                size: 64,
                                color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'no vices tracked yet',
                                style: TextStyle(
                                  color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'your vices',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.viceRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...activeVices.map((vice) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ViceCard(
                              vice: vice,
                              onDelete: () {
                                context.read<VicesBloc>().add(
                                  DeleteVice(vice.id!),
                                );
                              },
                              onEdit: () {
                                _showEditDialog(context, vice);
                              },
                            ),
                          )),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? TugColors.viceRed : TugColors.viceRedDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isLoading 
                                  ? null 
                                  : (activeVices.isNotEmpty 
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
                                  : Text(widget.fromHome ? 'done' : 'start tracking'),
                            ),
                          ),
                        ],
                      );
                    }
                    
                    if (state is VicesLoading) {
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
    );
  }
}

class ViceCard extends StatelessWidget {
  final ViceModel vice;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ViceCard({
    super.key,
    required this.vice,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final Color viceColor = Color(int.parse(vice.color.substring(1), radix: 16) + 0xFF000000);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Slidable(
        key: ValueKey(vice.id ?? vice.name),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          dragDismissible: false,
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: TugColors.viceOrange,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (_) => _showDeleteConfirmation(context),
              backgroundColor: TugColors.viceRedDark,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      viceColor.withAlpha(20),
                      viceColor.withAlpha(5),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      viceColor.withAlpha(10),
                    ],
                  ),
            border: Border.all(
              color: viceColor.withAlpha(100),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: viceColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vice.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'severity: ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: TugColors.getSeverityColor(vice.severity),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${vice.severity} - ${vice.severityDescription}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (vice.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            vice.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (vice.currentStreak > 0 || vice.longestStreak > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDarkMode ? TugColors.viceModeDarkSurface : TugColors.lightSurface).withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStreakIndicator(
                        context: context,
                        icon: Icons.psychology,
                        color: TugColors.getStreakColor(true, vice.currentStreak),
                        label: 'clean streak',
                        value: '${vice.currentStreak} day${vice.currentStreak != 1 ? 's' : ''}',
                      ),
                      _buildStreakIndicator(
                        context: context,
                        icon: Icons.emoji_events,
                        color: TugColors.success,
                        label: 'best streak',
                        value: '${vice.longestStreak} day${vice.longestStreak != 1 ? 's' : ''}',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? TugColors.viceModeDarkSurface : Colors.white,
        title: Text(
          'Remove Vice',
          style: TextStyle(
            color: isDarkMode ? TugColors.viceModeTextPrimary : TugColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'remove "${vice.name}" from tracking? this cannot be undone.',
          style: TextStyle(
            color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: TugColors.viceRed,
            ),
            child: const Text('remove'),
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
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(30),
          ),
          child: Icon(
            icon, 
            color: color, 
            size: 16,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDarkMode ? TugColors.viceModeTextSecondary : TugColors.lightTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}