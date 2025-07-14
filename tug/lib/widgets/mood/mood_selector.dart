// lib/widgets/mood/mood_selector.dart
import 'package:flutter/material.dart';
import 'package:tug/models/mood_model.dart';
import 'package:tug/services/mood_service.dart';
import 'package:tug/utils/theme/colors.dart';

class MoodSelector extends StatefulWidget {
  final MoodType? selectedMood;
  final Function(MoodType?) onMoodSelected;
  final bool isDarkMode;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
    this.isDarkMode = false,
  });

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  final MoodService _moodService = MoodService();
  List<MoodOption> _moodOptions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMoodOptions();
  }

  Future<void> _loadMoodOptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final options = await _moodService.getMoodOptions();
      setState(() {
        _moodOptions = options;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load mood options: $e';
        _isLoading = false;
      });
    }
  }

  Color _getMoodColor(int positivityScore) {
    if (positivityScore >= 8) {
      return Colors.green;
    } else if (positivityScore >= 6) {
      return Colors.lightGreen;
    } else if (positivityScore >= 4) {
      return Colors.orange;
    } else if (positivityScore >= 2) {
      return Colors.redAccent;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'how are you feeling?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TugColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'loading mood options...',
                  style: TextStyle(
                    color: widget.isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          )
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mood tracking temporarily unavailable',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'The mood tracking feature is still being deployed. You can continue logging your activity without selecting a mood for now.',
                  style: TextStyle(
                    color: widget.isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Skip mood selection and continue →',
                      style: TextStyle(
                        color: widget.isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    TextButton(
                      onPressed: _loadMoodOptions,
                      child: Text(
                        'retry',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? TugColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDarkMode 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                // Current selection display
                if (widget.selectedMood != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.mood,
                        color: _getMoodColor(_moodOptions
                            .firstWhere((m) => m.moodType == widget.selectedMood)
                            .positivityScore),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _moodOptions
                              .firstWhere((m) => m.moodType == widget.selectedMood)
                              .displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: widget.isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.onMoodSelected(null),
                        child: const Text('clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Mood grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _moodOptions.length,
                  itemBuilder: (context, index) {
                    final mood = _moodOptions[index];
                    final isSelected = widget.selectedMood == mood.moodType;
                    final moodColor = _getMoodColor(mood.positivityScore);
                    
                    return GestureDetector(
                      onTap: () {
                        widget.onMoodSelected(mood.moodType);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? moodColor.withValues(alpha: 0.2)
                              : (widget.isDarkMode 
                                  ? TugColors.darkSurfaceVariant 
                                  : TugColors.lightSurfaceVariant),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? moodColor
                                : (widget.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1)),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              mood.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                mood.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected
                                      ? moodColor
                                      : (widget.isDarkMode 
                                          ? TugColors.darkTextSecondary 
                                          : TugColors.lightTextSecondary),
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // Optional text
                if (widget.selectedMood == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'tap to select your current mood (optional)',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _moodOptions
                          .firstWhere((m) => m.moodType == widget.selectedMood)
                          .description,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: widget.isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}