// lib/widgets/profile/social_statistics.dart
import 'package:flutter/material.dart';
import '../../services/social_service.dart';
import '../../services/app_mode_service.dart';
import '../../utils/theme/colors.dart';

class SocialStatistics extends StatefulWidget {
  const SocialStatistics({super.key});

  @override
  State<SocialStatistics> createState() => _SocialStatisticsState();
}

class _SocialStatisticsState extends State<SocialStatistics> {
  final SocialService _socialService = SocialService();
  final AppModeService _appModeService = AppModeService();
  
  bool _isLoading = true;
  Map<String, dynamic> _socialStats = {};
  AppMode _currentMode = AppMode.valuesMode;

  @override
  void initState() {
    super.initState();
    _initializeMode();
    _loadSocialStatistics();
  }

  void _initializeMode() async {
    await _appModeService.initialize();
    if (mounted) {
      setState(() {
        _currentMode = _appModeService.currentMode;
      });
    }
  }

  Future<void> _loadSocialStatistics() async {
    setState(() => _isLoading = true);

    try {
      // Use the new backend endpoint for optimized statistics
      final stats = await _socialService.getSocialStatistics();
      
      if (mounted) {
        setState(() {
          _socialStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _socialStats = {
            'total_posts': 0,
            'total_comments': 0,
            'friends_count': 0,
            'pending_requests': 0,
            'avg_comments_per_post': 0.0,
            'most_popular_post_id': null,
            'post_type_breakdown': {
              'activity_update': 0,
              'vice_progress': 0,
              'achievement': 0,
              'general': 0,
            },
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isViceMode
              ? [
                  TugColors.viceEmerald.withValues(alpha: isDarkMode ? 0.9 : 0.8),
                  TugColors.viceEmerald,
                ]
              : [
                  TugColors.primaryPurple.withValues(alpha: isDarkMode ? 0.9 : 0.8),
                  TugColors.primaryPurple,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isViceMode ? TugColors.viceEmerald : TugColors.primaryPurple)
                .withValues(alpha: isDarkMode ? 0.4 : 0.3),
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
                  Icons.people,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'social activity',
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

          // Statistics content
          if (_isLoading) ...[
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'loading social stats...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildSocialStatisticsGrid(),
            const SizedBox(height: 16),
            _buildEngagementMetrics(),
            if (_socialStats['post_type_breakdown'] != null && 
                (_socialStats['post_type_breakdown'] as Map).values.any((v) => v > 0)) ...[
              const SizedBox(height: 16),
              _buildPostTypeBreakdown(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSocialStatisticsGrid() {
    final totalPosts = _socialStats['total_posts'] ?? 0;
    final friendsCount = _socialStats['friends_count'] ?? 0;
    final totalComments = _socialStats['total_comments'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.post_add,
                label: 'total posts',
                value: '$totalPosts',
                subtitle: totalPosts == 1 ? 'post' : 'posts',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.group,
                label: 'friends',
                value: '$friendsCount',
                subtitle: friendsCount == 1 ? 'friend' : 'friends',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.record_voice_over,
                label: 'comments',
                value: '$totalComments',
                subtitle: 'received',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEngagementMetrics() {
    final avgComments = _socialStats['avg_comments_per_post'] ?? 0;
    final pendingRequests = _socialStats['pending_requests'] ?? 0;

    return Container(
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
              const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'engagement metrics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                label: 'avg comments/post',
                value: '$avgComments',
              ),
              if (pendingRequests > 0)
                _buildMetricItem(
                  label: 'pending requests',
                  value: '$pendingRequests',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostTypeBreakdown() {
    final breakdown = _socialStats['post_type_breakdown'] as Map<String, dynamic>? ?? {};
    
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
              const Icon(
                Icons.pie_chart,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'post types',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...breakdown.entries.map((entry) => _buildPostTypeItem(entry.key, entry.value as int)),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
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

  Widget _buildMetricItem({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPostTypeItem(String type, int count) {
    final displayType = type == 'activity_update' 
        ? 'activity updates'
        : type == 'vice_progress'
            ? 'recovery posts'
            : type == 'achievement'
                ? 'achievements'
                : type;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayType,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$count ${count == 1 ? 'post' : 'posts'}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}