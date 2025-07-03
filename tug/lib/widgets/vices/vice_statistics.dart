// lib/widgets/vices/vice_statistics.dart
import 'package:flutter/material.dart';
import '../../models/vice_model.dart';
import '../../utils/theme/colors.dart';

class ViceStatistics extends StatelessWidget {
  final List<ViceModel> vices;

  const ViceStatistics({
    super.key,
    required this.vices,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate statistics
    final totalVices = vices.length;
    final activeStreaks = vices.where((v) => v.currentStreak > 0).length;
    final totalCleanDays = vices.fold<int>(0, (sum, vice) => sum + vice.currentStreak);
    final averageStreak = totalVices > 0 ? (totalCleanDays / totalVices).round() : 0;
    final longestStreak = vices.isEmpty ? 0 : vices.map((v) => v.longestStreak).reduce((a, b) => a > b ? a : b);
    
    // Calculate milestones achieved (7, 30, 100, 365 days)
    final milestones = [7, 30, 100, 365];
    final totalMilestones = vices.fold<int>(0, (sum, vice) {
      return sum + milestones.where((milestone) => vice.longestStreak >= milestone).length;
    });
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TugColors.viceGreen.withValues(alpha: isDarkMode ? 0.9 : 0.8),
            TugColors.viceGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TugColors.viceGreen.withValues(alpha: isDarkMode ? 0.4 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'vice check',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Statistics Grid
          if (totalVices > 0) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.trending_up,
                    label: 'active streaks',
                    value: '$activeStreaks/$totalVices',
                    subtitle: activeStreaks == totalVices ? 'all clean!' : 'keep going!',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_today,
                    label: 'total clean days',
                    value: '$totalCleanDays',
                    subtitle: totalCleanDays == 1 ? 'day' : 'days',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.timeline,
                    label: 'average streak',
                    value: '$averageStreak',
                    subtitle: averageStreak == 1 ? 'day' : 'days',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.emoji_events,
                    label: 'best streak',
                    value: '$longestStreak',
                    subtitle: longestStreak == 1 ? 'day' : 'days',
                  ),
                ),
              ],
            ),
            if (totalMilestones > 0) ...[
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.stars,
                label: 'milestones achieved',
                value: '$totalMilestones',
                subtitle: 'recovery milestones unlocked',
                isWide: true,
              ),
            ],
            const SizedBox(height: 16),
            _buildProgressSection(vices),
          ] else ...[
            // Empty state
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'no vices tracked yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'add some vices to see your recovery progress',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    bool isWide = false,
  }) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(List<ViceModel> vices) {
    if (vices.isEmpty) return const SizedBox.shrink();
    
    // Find the vice with the longest current streak for motivation
    final bestCurrentVice = vices.reduce((a, b) => 
        a.currentStreak > b.currentStreak ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'clean streak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (bestCurrentVice.currentStreak > 0) ...[
            Text(
              '🌟 ${bestCurrentVice.name}: ${bestCurrentVice.currentStreak} days clean',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getMotivationalMessage(bestCurrentVice.currentStreak),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ] else ...[
            Text(
              'every journey starts with a single day. you\'ve got this! 💪',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getMotivationalMessage(int streak) {
    if (streak >= 365) return 'incredible! a full year of freedom! 🎉';
    if (streak >= 100) return 'amazing! you\'ve hit triple digits! 🚀';
    if (streak >= 30) return 'fantastic! a full month of progress! 🌟';
    if (streak >= 7) return 'great job! a week of strength! 💪';
    if (streak >= 3) return 'building momentum! keep going! ⚡';
    return 'every day counts! stay strong! 🌱';
  }
}