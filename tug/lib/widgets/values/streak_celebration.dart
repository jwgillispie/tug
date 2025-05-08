// lib/widgets/values/streak_celebration.dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../utils/theme/colors.dart';

class StreakCelebration extends StatefulWidget {
  final String valueName;
  final int streakCount;
  final VoidCallback onDismiss;

  const StreakCelebration({
    super.key,
    required this.valueName,
    required this.streakCount,
    required this.onDismiss,
  });

  @override
  State<StreakCelebration> createState() => _StreakCelebrationState();
}

class _StreakCelebrationState extends State<StreakCelebration> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getStreakMessage() {
    if (widget.streakCount >= 100) {
      return "UNBELIEVABLE!";
    } else if (widget.streakCount >= 30) {
      return "PHENOMENAL!";
    } else if (widget.streakCount >= 7) {
      return "AMAZING!";
    } else {
      return "AWESOME!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent background
        GestureDetector(
          onTap: widget.onDismiss,
          child: Container(
            color: Colors.black.withOpacity(0.7),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        
        // Celebration content
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.05,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.05,
                  shouldLoop: false,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                    TugColors.primaryPurple,
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Icon(
                  Icons.local_fire_department,
                  size: 64,
                  color: Colors.orange,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  _getStreakMessage(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: TugColors.primaryPurple,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  "${widget.streakCount} DAY STREAK",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  "You've been consistent with '${widget.valueName}' for ${widget.streakCount} days in a row!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: widget.onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TugColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Keep it up!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}