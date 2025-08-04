import 'package:flutter/material.dart';
import '../../models/value_model.dart';
import '../../utils/theme/colors.dart';
import '../../utils/quantum_effects.dart';

/// 🤖 AI ACTIVITY SUGGESTIONS
/// Suggests personalized activities based on user's values
/// Clean, simple design focused on value-driven recommendations
class AIActivitySuggestions extends StatelessWidget {
  final List<ValueModel> values;
  final Function(String)? onActivityTap;

  const AIActivitySuggestions({
    super.key,
    required this.values,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final suggestions = _generateActivitySuggestions();
    
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: QuantumEffects.glassContainer(
        isDark: isDarkMode,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDarkMode),
              const SizedBox(height: 12),
              _buildSuggestionsList(suggestions, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: TugColors.primaryPurple.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lightbulb_outline,
            color: TugColors.primaryPurple,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'suggested activities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                ),
              ),
              Text(
                'personalized for your values',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsList(List<ActivitySuggestion> suggestions, bool isDarkMode) {
    return Column(
      children: suggestions.take(3).map((suggestion) => 
        _buildSuggestionItem(suggestion, isDarkMode)
      ).toList(),
    );
  }

  Widget _buildSuggestionItem(ActivitySuggestion suggestion, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onActivityTap?.call(suggestion.activity),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Text(
                suggestion.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.activity,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'strengthens ${suggestion.valueType}',
                      style: TextStyle(
                        fontSize: 12,
                        color: TugColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ActivitySuggestion> _generateActivitySuggestions() {
    final Map<String, List<ActivitySuggestion>> valueSuggestions = {
      'health': [
        ActivitySuggestion('take a 15-minute walk', '🚶‍♂️', 'health'),
        ActivitySuggestion('drink a glass of water', '💧', 'health'),
        ActivitySuggestion('do 10 push-ups', '💪', 'health'),
        ActivitySuggestion('meditate for 5 minutes', '🧘‍♂️', 'health'),
        ActivitySuggestion('stretch for 10 minutes', '🤸‍♀️', 'health'),
      ],
      'learning': [
        ActivitySuggestion('read for 20 minutes', '📚', 'learning'),
        ActivitySuggestion('watch an educational video', '🎥', 'learning'),
        ActivitySuggestion('practice a new skill', '🎯', 'learning'),
        ActivitySuggestion('listen to a podcast', '🎧', 'learning'),
        ActivitySuggestion('write in a journal', '✍️', 'learning'),
      ],
      'family': [
        ActivitySuggestion('call a family member', '📞', 'family'),
        ActivitySuggestion('share a meal together', '🍽️', 'family'),
        ActivitySuggestion('help with household tasks', '🏠', 'family'),
        ActivitySuggestion('plan a family activity', '👨‍👩‍👧‍👦', 'family'),
        ActivitySuggestion('write a thank you note', '💌', 'family'),
      ],
      'creativity': [
        ActivitySuggestion('draw or sketch for 15 minutes', '🎨', 'creativity'),
        ActivitySuggestion('write something creative', '✏️', 'creativity'),
        ActivitySuggestion('play a musical instrument', '🎵', 'creativity'),
        ActivitySuggestion('try a new recipe', '👨‍🍳', 'creativity'),
        ActivitySuggestion('organize your space', '✨', 'creativity'),
      ],
      'growth': [
        ActivitySuggestion('set a small goal', '🎯', 'growth'),
        ActivitySuggestion('reflect on progress', '🤔', 'growth'),
        ActivitySuggestion('try something new', '🌟', 'growth'),
        ActivitySuggestion('practice gratitude', '🙏', 'growth'),
        ActivitySuggestion('help someone else', '🤝', 'growth'),
      ],
    };

    final List<ActivitySuggestion> suggestions = [];
    
    // Get suggestions based on user's values
    for (final value in values.take(3)) {
      final valueKey = _getValueKey(value.name.toLowerCase());
      final valueSuggestionsList = valueSuggestions[valueKey] ?? valueSuggestions['growth']!;
      
      // Pick a random suggestion for this value
      if (valueSuggestionsList.isNotEmpty) {
        final randomIndex = DateTime.now().millisecond % valueSuggestionsList.length;
        suggestions.add(valueSuggestionsList[randomIndex]);
      }
    }

    return suggestions;
  }

  String _getValueKey(String valueName) {
    if (valueName.contains('health') || valueName.contains('fitness') || valueName.contains('wellness')) {
      return 'health';
    } else if (valueName.contains('learn') || valueName.contains('education') || valueName.contains('knowledge')) {
      return 'learning';
    } else if (valueName.contains('family') || valueName.contains('relationship') || valueName.contains('love')) {
      return 'family';
    } else if (valueName.contains('creative') || valueName.contains('art') || valueName.contains('music')) {
      return 'creativity';
    } else {
      return 'growth';
    }
  }
}

class ActivitySuggestion {
  final String activity;
  final String emoji;
  final String valueType;

  ActivitySuggestion(this.activity, this.emoji, this.valueType);
}