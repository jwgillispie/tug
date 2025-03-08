// lib/widgets/tug_of_war/tug_of_war_widget.dart
import 'package:flutter/material.dart';
import 'package:tug/utils/theme/colors.dart';

class TugOfWarWidget extends StatefulWidget {
  final String valueName;
  final int statedImportance; // 1-5 scale
  final int actualBehavior; // Minutes spent
  final int communityAverage; // Community average minutes
  final VoidCallback? onTap;

  const TugOfWarWidget({
    Key? key,
    required this.valueName,
    required this.statedImportance,
    required this.actualBehavior,
    required this.communityAverage,
    this.onTap,
  }) : super(key: key);

  @override
  State<TugOfWarWidget> createState() => _TugOfWarWidgetState();
}

class _TugOfWarWidgetState extends State<TugOfWarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  double _position = 0.0; // -1.0 to 1.0 where 0 is center

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _positionAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _calculatePosition();
  }

  @override
  void didUpdateWidget(TugOfWarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statedImportance != widget.statedImportance ||
        oldWidget.actualBehavior != widget.actualBehavior ||
        oldWidget.communityAverage != widget.communityAverage) {
      _calculatePosition();
    }
  }

  void _calculatePosition() {
    // Convert stated importance to percentage (1-5 → 20-100%)
    final statedImportancePercent = (widget.statedImportance / 5.0) * 100.0;
    
    // Calculate actual behavior as percentage of community average
    final actualBehaviorPercent = (widget.actualBehavior / widget.communityAverage) * 100.0;
    
    // Calculate the difference and normalize to -1.0 to 1.0 range
    final difference = actualBehaviorPercent - statedImportancePercent;
    final normalizedDifference = difference / 100.0;
    
    // Clamp to ensure it stays in range
    final clampedDifference = normalizedDifference.clamp(-1.0, 1.0);

    // Animate to new position
    _positionAnimation = Tween<double>(
      begin: _position,
      end: clampedDifference,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _position = clampedDifference;
    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getMessageColor() {
    if (_position < -0.4) {
      return TugColors.primaryPurple;
    } else if (_position > 0.4) {
      return TugColors.secondaryTeal;
    } else {
      return Colors.green;
    }
  }

  String _getMessage() {
    if (_position < -0.4) {
      return "Your actions aren't matching your stated importance.";
    } else if (_position > 0.4) {
      return "You're investing more time than your stated importance suggests.";
    } else {
      return "Good alignment between your stated values and actions!";
    }
  }

  // Calculate color intensity based on position
  double _getColorIntensity(String side) {
    if (side == 'stated' && _position <= 0) {
      return 0.5 + ((_position.abs()) / 2.0);
    } else if (side == 'actual' && _position >= 0) {
      return 0.5 + ((_position.abs()) / 2.0);
    }
    return 0.5 - ((_position.abs()) / 4.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Value Name and Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.valueName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Importance: ${widget.statedImportance}/5',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.actualBehavior} mins/day',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Tug of War Visualization
              SizedBox(
                height: 60,
                child: AnimatedBuilder(
                  animation: _positionAnimation,
                  builder: (context, child) {
                    final position = _positionAnimation.value;
                    
                    return Stack(
                      children: [
                        // Center line
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 2,
                            height: 50,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        
                        // Rope
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade700,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        
                        // Left handle (Stated Values)
                        Positioned(
                          left: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: TugColors.primaryPurple.withOpacity(_getColorIntensity('stated')),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        
                        // Right handle (Actual Behavior)
                        Positioned(
                          right: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: TugColors.secondaryTeal.withOpacity(_getColorIntensity('actual')),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        
                        // Center knot
                        Positioned(
                          left: MediaQuery.of(context).size.width / 2 - 16 + (position * MediaQuery.of(context).size.width / 4),
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: position < 0 ? TugColors.primaryPurple : TugColors.secondaryTeal,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stated Values',
                    style: TextStyle(
                      fontSize: 12,
                      color: TugColors.primaryPurple,
                    ),
                  ),
                  const Text(
                    'Actual Behavior',
                    style: TextStyle(
                      fontSize: 12,
                      color: TugColors.secondaryTeal,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Message based on position
              Text(
                _getMessage(),
                style: TextStyle(
                  fontSize: 14,
                  color: _getMessageColor(),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Community comparison
              const SizedBox(height: 8),
              Text(
                'Community average: ${widget.communityAverage} mins/day',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}