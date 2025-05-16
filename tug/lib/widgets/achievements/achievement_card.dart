// lib/widgets/achievements/achievement_card.dart
import 'package:flutter/material.dart';
import 'package:tug/models/achievement_model.dart';

class AchievementCard extends StatelessWidget {
  final AchievementModel achievement;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: achievement.color.withAlpha(isDarkMode ? 77 : 26), // 0.3 or 0.1 opacity
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: achievement.isUnlocked
                ? achievement.color.withAlpha(128) // 0.5 opacity
                : Colors.grey.withAlpha(26), // 0.1 opacity
            width: achievement.isUnlocked ? 1.5 : 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Progress indicator as background
              if (!achievement.isUnlocked)
                Positioned.fill(
                  child: LinearProgressIndicator(
                    value: achievement.progress,
                    backgroundColor: Colors.transparent,
                    color: achievement.color.withAlpha(26), // 0.1 opacity
                  ),
                ),
              
              // Main content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Achievement icon with animation if unlocked
                    _buildAchievementIcon(achievement, isDarkMode),
                    
                    const SizedBox(width: 16),
                    
                    // Achievement details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Achievement title
                              Flexible(
                                child: Text(
                                  achievement.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: achievement.isUnlocked
                                        ? achievement.color
                                        : isDarkMode
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              // Unlock date for unlocked achievements
                              if (achievement.isUnlocked && achievement.unlockedAt != null)
                                Text(
                                  _formatDate(achievement.unlockedAt!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Achievement description
                          Text(
                            achievement.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade800,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Progress indicator for locked achievements
                          if (!achievement.isUnlocked)
                            _buildProgressIndicator(achievement, isDarkMode),
                        ],
                      ),
                    ),
                    
                    // Locked/unlocked indicator
                    if (achievement.isUnlocked)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      )
                    else
                      Icon(
                        Icons.lock,
                        color: isDarkMode
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                  ],
                ),
              ),
              
              // Highlight for unlocked achievements
              if (achievement.isUnlocked)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: achievement.color,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAchievementIcon(AchievementModel achievement, bool isDarkMode) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? achievement.color.withAlpha(isDarkMode ? 51 : 26) // 0.2 or 0.1 opacity
            : Colors.grey.withAlpha(isDarkMode ? 51 : 26), // 0.2 or 0.1 opacity
        shape: BoxShape.circle,
        border: Border.all(
          color: achievement.isUnlocked
              ? achievement.color.withAlpha(128) // 0.5 opacity
              : Colors.grey.withAlpha(77), // 0.3 opacity
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          achievement.icon,
          size: 28,
          color: achievement.isUnlocked
              ? achievement.color
              : Colors.grey,
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator(AchievementModel achievement, bool isDarkMode) {
    final progressPercent = (achievement.progress * 100).toInt();
    
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: achievement.progress,
              backgroundColor: isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              color: achievement.color.withAlpha(179), // 0.7 opacity
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$progressPercent%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDarkMode
                ? Colors.grey.shade400
                : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }
}