// lib/widgets/tug_of_war/tug_of_war_widget.dart
import 'package:flutter/material.dart';
import 'package:tug/utils/theme/colors.dart';

class TugOfWarWidget extends StatefulWidget {
  final String valueName;
  final int statedImportance; // 1-5 scale
  final int actualBehavior; // Minutes spent
  final int communityAverage; // Community average minutes
  final String valueColor; // Added parameter for the value's color
  final VoidCallback? onTap;

  const TugOfWarWidget({
    Key? key,
    required this.valueName,
    required this.statedImportance,
    required this.actualBehavior,
    required this.communityAverage,
    this.valueColor = '#7C3AED', // Default to purple if not provided
    this.onTap,
  }) : super(key: key);

  @override
  State<TugOfWarWidget> createState() => _TugOfWarWidgetState();
}

class _TugOfWarWidgetState extends State<TugOfWarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  double _position = 0.0; // -1.0 to 1.0 where 0 is center
  late Color _valueColor;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _positionAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Convert the hex color string to a Color object
    _valueColor = _parseColor(widget.valueColor);
    
    _calculatePosition();
  }

  @override
  void didUpdateWidget(TugOfWarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statedImportance != widget.statedImportance ||
        oldWidget.actualBehavior != widget.actualBehavior ||
        oldWidget.communityAverage != widget.communityAverage ||
        oldWidget.valueColor != widget.valueColor) {
      
      // Update the color if it changed
      if (oldWidget.valueColor != widget.valueColor) {
        _valueColor = _parseColor(widget.valueColor);
      }
      
      _calculatePosition();
    }
  }
  
  // Helper method to parse hex color string to Color
  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      // Return a default color if parsing fails
      return TugColors.primaryPurple;
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
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _position = clampedDifference;
    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  // Calculate opacity for the handles
  // Only the winning side gets full opacity
  double _getHandleOpacity(String side) {
    // For balanced position, both sides get decent opacity
    if (_position.abs() < 0.1) {
      return 0.7;
    }
    
    if (side == 'stated' && _position < 0) {
      // Stated side is winning (negative position)
      return 1.0;
    } else if (side == 'actual' && _position > 0) {
      // Actual side is winning (positive position)
      return 1.0;
    } else {
      // This side is losing, reduce opacity
      return 0.3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? TugColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _valueColor.withOpacity(isDarkMode ? 0.2 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: _valueColor.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Value Name and Stats with enhanced typography
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.valueName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: _valueColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _valueColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _valueColor.withOpacity(0.2),
                                  width: 1
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: _valueColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Importance: ${widget.statedImportance}/5',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _valueColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _valueColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _valueColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${widget.actualBehavior} mins/day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _valueColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Tug of War Visualization with enhanced design
              SizedBox(
                height: 65,
                child: AnimatedBuilder(
                  animation: _positionAnimation,
                  builder: (context, child) {
                    final position = _positionAnimation.value;
                    
                    return Stack(
                      children: [
                        // Center line with value color
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 2,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _valueColor.withOpacity(0.3),
                                  _valueColor.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Rope with gradient matching the value color
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _valueColor.withOpacity(0.6),
                                  _valueColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        
                        // Left handle (Stated Values) with shadow
                        Positioned(
                          left: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _valueColor.withOpacity(_getHandleOpacity('stated')),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _valueColor.withOpacity(_position < 0 ? 0.4 : 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.white.withOpacity(_position < 0 ? 1.0 : 0.7),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        
                        // Right handle (Actual Behavior) with shadow
                        Positioned(
                          right: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _valueColor.withOpacity(_getHandleOpacity('actual')),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _valueColor.withOpacity(_position > 0 ? 0.4 : 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.white.withOpacity(_position > 0 ? 1.0 : 0.7),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        
                        // Center knot with shadow and animated position
                        Positioned(
                          left: MediaQuery.of(context).size.width / 2 - 16 + (position * MediaQuery.of(context).size.width / 4),
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: _valueColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _valueColor.withOpacity(isDarkMode ? 0.6 : 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
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
              
              const SizedBox(height: 12),
              
              // Labels with enhanced design
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _valueColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Stated Values',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _valueColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Actual Behavior',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _valueColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _valueColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Message based on position with enhanced design
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: _valueColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _valueColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _position < -0.4 
                          ? Icons.warning_amber_rounded 
                          : (_position > 0.4 ? Icons.info_outline : Icons.check_circle),
                      color: _valueColor,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getMessage(),
                        style: TextStyle(
                          fontSize: 13,
                          color: _valueColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Community comparison with enhanced design
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 14,
                    color: _valueColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Community average: ${widget.communityAverage} mins/day',
                    style: TextStyle(
                      fontSize: 12,
                      color: _valueColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}