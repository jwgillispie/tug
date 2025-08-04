// lib/widgets/social/battle_leaderboard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';

/// BATTLE LEADERBOARD
/// Revolutionary social feature that turns balance tracking into a competitive game
/// Users can see how they rank against friends in the eternal battle of values vs vices
class BattleLeaderboard extends StatefulWidget {
  final UserModel? currentUser;
  final List<BattleWarrior> warriors;
  final String leaderboardType; // weekly, monthly, allTime
  
  const BattleLeaderboard({
    super.key,
    this.currentUser,
    required this.warriors,
    this.leaderboardType = 'weekly',
  });

  @override
  State<BattleLeaderboard> createState() => _BattleLeaderboardState();
}

class _BattleLeaderboardState extends State<BattleLeaderboard>
    with TickerProviderStateMixin {
  
  late AnimationController _leaderboardController;
  late AnimationController _crownController;
  late AnimationController _sparkleController;
  
  late Animation<double> _slideAnimation;
  late Animation<double> _crownRotation;
  late Animation<double> _sparkleOpacity;
  
  String _selectedPeriod = 'weekly';
  // bool _showOnlyFriends = false; // Future feature

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.leaderboardType;
    _setupAnimations();
    _startLeaderboardAnimations();
  }

  void _setupAnimations() {
    _leaderboardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _crownController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideAnimation = CurvedAnimation(
      parent: _leaderboardController,
      curve: Curves.easeOutBack,
    );
    
    _crownRotation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _crownController,
      curve: Curves.easeInOut,
    ));
    
    _sparkleOpacity = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));
  }

  void _startLeaderboardAnimations() {
    _leaderboardController.forward();
  }

  @override
  void dispose() {
    _leaderboardController.dispose();
    _crownController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: 'Battle Leaderboard: ${widget.warriors.length} warriors competing in $_selectedPeriod rankings',
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildLeaderboardHeader(isDarkMode),
            const SizedBox(height: 16),
            _buildPeriodSelector(isDarkMode),
            const SizedBox(height: 16),
            _buildPodium(isDarkMode),
            const SizedBox(height: 20),
            _buildLeaderboardList(isDarkMode),
            const SizedBox(height: 16),
            _buildJoinBattleButton(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withValues(alpha: 0.2),
            Colors.orange.withValues(alpha: 0.1),
            Colors.red.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _sparkleOpacity,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.amber.withValues(alpha: 0.4),
                    Colors.amber.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 32,
              ),
            ),
            builder: (context, child) => Transform.scale(
              scale: 1.0 + (_sparkleOpacity.value * 0.1),
              child: child,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'battle leaderboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'warriors ranked by balance mastery',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '${widget.warriors.length} warriors',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDarkMode) {
    final periods = [
      {'key': 'weekly', 'label': 'This Week', 'icon': Icons.calendar_view_week},
      {'key': 'monthly', 'label': 'This Month', 'icon': Icons.calendar_month},
      {'key': 'allTime', 'label': 'Hall of Fame', 'icon': Icons.military_tech},
    ];
    
    return Row(
      children: periods.map((period) {
        final isSelected = _selectedPeriod == period['key'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = period['key'] as String;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ) : null,
                color: isSelected ? null : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    period['icon'] as IconData,
                    color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black54),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    period['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPodium(bool isDarkMode) {
    if (widget.warriors.length < 3) {
      return _buildInsufficientData(isDarkMode);
    }
    
    final topThree = widget.warriors.take(3).toList();
    
    return AnimatedBuilder(
      animation: _slideAnimation,
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            // Background podium
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Second place (left)
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.grey.withValues(alpha: 0.3),
                            Colors.grey.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '2',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // First place (center, tallest)
                  Expanded(
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.amber.withValues(alpha: 0.4),
                            Colors.amber.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '1',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Third place (right)
                  Expanded(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.brown.withValues(alpha: 0.3),
                            Colors.brown.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '3',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Warriors on podium
            Positioned(
              bottom: 120,
              left: 20,
              child: _buildPodiumWarrior(topThree[1], 2, isDarkMode), // Second
            ),
            Positioned(
              bottom: 160,
              left: MediaQuery.of(context).size.width / 3 - 30,
              child: _buildPodiumWarrior(topThree[0], 1, isDarkMode), // First
            ),
            if (topThree.length > 2)
              Positioned(
                bottom: 80,
                right: 20,
                child: _buildPodiumWarrior(topThree[2], 3, isDarkMode), // Third
              ),
          ],
        ),
      ),
      builder: (context, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: child,
      ),
    );
  }

  Widget _buildPodiumWarrior(BattleWarrior warrior, int position, bool isDarkMode) {
    Color positionColor;
    switch (position) {
      case 1:
        positionColor = Colors.amber;
        break;
      case 2:
        positionColor = Colors.grey;
        break;
      case 3:
        positionColor = Colors.brown;
        break;
      default:
        positionColor = Colors.grey;
    }
    
    return Column(
      children: [
        if (position == 1) 
          AnimatedBuilder(
            animation: _crownRotation,
            child: Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 32,
            ),
            builder: (context, child) => Transform.rotate(
              angle: _crownRotation.value,
              child: child,
            ),
          ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                positionColor.withValues(alpha: 0.4),
                positionColor.withValues(alpha: 0.2),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: positionColor,
              width: 3,
            ),
          ),
          child: ClipOval(
            child: warrior.avatarUrl != null
                ? Image.network(
                    warrior.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      color: positionColor,
                      size: 30,
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: positionColor,
                    size: 30,
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: positionColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            warrior.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: positionColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${warrior.battleScore}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: positionColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList(bool isDarkMode) {
    final remainingWarriors = widget.warriors.skip(3).toList();
    
    if (remainingWarriors.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        Text(
          'Battle Rankings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...remainingWarriors.asMap().entries.map((entry) {
          final index = entry.key;
          final warrior = entry.value;
          final position = index + 4; // Starting from 4th place
          
          return _buildLeaderboardItem(warrior, position, isDarkMode);
        }),
      ],
    );
  }

  Widget _buildLeaderboardItem(BattleWarrior warrior, int position, bool isDarkMode) {
    final isCurrentUser = widget.currentUser?.id == warrior.userId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isCurrentUser ? LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.05),
          ],
        ) : null,
        color: isCurrentUser ? null : (isDarkMode ? Colors.grey.shade800 : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? Colors.blue : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
          width: isCurrentUser ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCurrentUser ? Colors.blue : Colors.black).withValues(alpha: isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getPositionColor(position).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getPositionColor(position),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getPositionColor(position),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: warrior.avatarUrl != null
                  ? Image.network(
                      warrior.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.person,
                        color: _getPositionColor(position),
                        size: 20,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: _getPositionColor(position),
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      warrior.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${warrior.battleStreak} day streak • Level ${warrior.level}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${warrior.battleScore}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getPositionColor(position),
                ),
              ),
              Text(
                'battle score',
                style: TextStyle(
                  fontSize: 10,
                  color: _getPositionColor(position).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinBattleButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (context.mounted) {
            context.go('/social');
          }
        },
        icon: const Icon(Icons.flash_on, size: 24),
        label: const Text('JOIN THE BATTLE'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          shadowColor: Colors.amber.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildInsufficientData(bool isDarkMode) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Building the Leaderboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'More warriors are needed to crown a champion! Invite friends to join the battle.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(int position) {
    if (position <= 5) return Colors.amber;
    if (position <= 10) return Colors.orange;
    if (position <= 20) return Colors.blue;
    return Colors.grey;
  }
}

/// Model for a battle warrior (user in the leaderboard)
class BattleWarrior {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int battleScore;
  final int battleStreak;
  final int level;
  final double winRate;
  final String battleClass; // "Champion", "Warrior", "Novice"
  
  const BattleWarrior({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.battleScore,
    required this.battleStreak,
    required this.level,
    required this.winRate,
    required this.battleClass,
  });
}