// lib/widgets/tug_of_war/enhanced_tug_of_war_widget.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tug/utils/theme/colors.dart';

class EnhancedTugOfWarWidget extends StatefulWidget {
  final String valueName;
  final int statedImportance; // 1-5 scale
  final int actualBehavior; // Minutes spent
  final int communityAverage; // Community average minutes
  final String valueColor; // Added parameter for the value's color
  final VoidCallback? onTap;

  const EnhancedTugOfWarWidget({
    super.key,
    required this.valueName,
    required this.statedImportance,
    required this.actualBehavior,
    required this.communityAverage,
    this.valueColor = '#7C3AED', // Default to purple if not provided
    this.onTap,
  });

  @override
  State<EnhancedTugOfWarWidget> createState() => _EnhancedTugOfWarWidgetState();
}

class _EnhancedTugOfWarWidgetState extends State<EnhancedTugOfWarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _ropeWaveAnimation;
  double _position = 0.0; // -1.0 to 1.0 where 0 is center
  late Color _valueColor;
  bool _userInteracting = false;
  late double _dragStartPosition;
  double _userDragOffset = 0.0;
  
  // No longer needed since we removed emoji animations
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _positionAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)
      ),
    );
    
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut)
      ),
    );
    
    _ropeWaveAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: Curves.linear
      ),
    );

    // Convert the hex color string to a Color object
    _valueColor = _parseColor(widget.valueColor);
    
    _calculatePosition();
    
    // Start subtle continuous animation
    _animationController.repeat(min: 0.7, max: 1.0, period: const Duration(seconds: 3));
  }

  @override
  void didUpdateWidget(EnhancedTugOfWarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statedImportance != widget.statedImportance ||
        oldWidget.actualBehavior != widget.actualBehavior ||
        oldWidget.communityAverage != widget.communityAverage ||
        oldWidget.valueColor != widget.valueColor) {
      
      // Update the color if it changed
      if (oldWidget.valueColor != widget.valueColor) {
        _valueColor = _parseColor(widget.valueColor);
      }
      
      // Only recalculate if not currently being dragged by user
      if (!_userInteracting) {
        _calculatePosition();
      }
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
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)
      ),
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

  // Calculate character state based on position
  String _getCharacterState(String side) {
    if (side == 'stated') {
      if (_position < -0.4) return 'winning';
      if (_position > 0.4) return 'losing';
      return 'neutral';
    } else { // actual side
      if (_position > 0.4) return 'winning';
      if (_position < -0.4) return 'losing';
      return 'neutral';
    }
  }
  
  // Calculate opacity for the characters
  double _getCharacterOpacity(String side) {
    // For balanced position, both sides get decent opacity
    if (_position.abs() < 0.1) {
      return 1.0;
    }
    
    if (side == 'stated' && _position < 0) {
      // Stated side is winning (negative position)
      return 1.0;
    } else if (side == 'actual' && _position > 0) {
      // Actual side is winning (positive position)
      return 1.0;
    } else {
      // This side is losing, reduce opacity
      return 0.7;
    }
  }
  
  // Get icon for character state instead of emoji
  IconData _getCharacterIcon(String side, String state) {
    if (side == 'stated') {
      switch (state) {
        case 'winning': return Icons.star_rounded;
        case 'losing': return Icons.star_outline;
        default: return Icons.star_half_rounded;
      }
    } else { // actual side
      switch (state) {
        case 'winning': return Icons.access_time_filled_rounded;
        case 'losing': return Icons.access_time_outlined;
        default: return Icons.access_time_rounded;
      }
    }
  }
  
  void _handleDragStart(DragStartDetails details) {
    _userInteracting = true;
    _dragStartPosition = _position;
    _userDragOffset = 0.0;
    
    // Pause automatic animation during user interaction
    _animationController.stop();
  }
  
  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_userInteracting) return;
    
    setState(() {
      // Convert the drag into a reasonable position change
      // The divisor controls sensitivity (higher = less sensitive)
      _userDragOffset += details.delta.dx / 200;
      
      // Calculate new position from starting position plus drag
      final newPosition = (_dragStartPosition + _userDragOffset).clamp(-1.0, 1.0);
      _position = newPosition;
      
      // Update the animation's end value (not animating during drag)
      _positionAnimation = AlwaysStoppedAnimation(_position);
    });
  }
  
  void _handleDragEnd(DragEndDetails details) {
    _userInteracting = false;
    
    // Enhanced animation with spring physics
    final velocity = details.velocity.pixelsPerSecond.dx;
    final normalizedVelocity = velocity / 1000.0; // Scale down velocity
    
    // Calculate new position incorporating velocity for natural feel
    final projectedPosition = (_position + (normalizedVelocity * 0.1)).clamp(-1.0, 1.0);
    
    // Use velocity to determine animation dynamics
    _positionAnimation = Tween<double>(
      begin: _position,
      end: projectedPosition,
    ).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: velocity.abs() > 500 
            ? const Interval(0.0, 0.7, curve: Curves.elasticOut) // More bounce for faster flicks
            : const Interval(0.0, 0.7, curve: Curves.easeOutBack)  // Gentler for slow drags
      ),
    );
    
    _position = projectedPosition;
    _animationController.forward(from: 0.0).then((_) {
      // Resume subtle animation after initial animation completes
      _animationController.repeat(min: 0.7, max: 1.0, period: const Duration(seconds: 3));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statedCharacterState = _getCharacterState('stated');
    final actualCharacterState = _getCharacterState('actual');
    
    return GestureDetector(
      onTap: widget.onTap,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
              ? [
                  TugColors.darkSurface,
                  Color.lerp(TugColors.darkSurface, _valueColor, 0.08) ?? TugColors.darkSurface,
                ]
              : [
                  Colors.white,
                  Color.lerp(Colors.white, _valueColor, 0.03) ?? Colors.white,
                ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _valueColor.withOpacity(isDarkMode ? 0.25 : 0.15),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: _valueColor.withOpacity(isDarkMode ? 0.1 : 0.05),
              blurRadius: 3,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
          border: Border.all(
            color: _valueColor.withOpacity(isDarkMode ? 0.2 : 0.1),
            width: 1.0,
          ),
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 88.0),
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
                                boxShadow: [
                                  BoxShadow(
                                    color: _valueColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                                border: Border.all(
                                  color: _valueColor.withOpacity(0.3),
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _valueColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                          _valueColor.withOpacity(isDarkMode ? 0.15 : 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _valueColor.withOpacity(isDarkMode ? 0.25 : 0.15),
                          blurRadius: 6,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
              
              // Enhanced Tug of War Visualization
              SizedBox(
                height: 100, // Adjusted height to prevent overflow
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final position = _positionAnimation.value;
                    final bounce = _bounceAnimation.value;
                    final wavePhase = _ropeWaveAnimation.value;
                    
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Ground line with gradient
                        // Enhanced ground line with glow effect
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 25,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _valueColor.withOpacity(0.5),
                                  Colors.grey.withOpacity(0.6),
                                  _valueColor.withOpacity(0.5),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _valueColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Center line
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 2,
                            height: 35,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _valueColor.withOpacity(0.0),
                                  _valueColor.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Custom rope with wave animation
                        CustomPaint(
                          size: Size(MediaQuery.of(context).size.width - 80, 30),
                          painter: RopePainter(
                            position: position,
                            bounce: bounce,
                            wavePhase: wavePhase,
                            ropeColor: _valueColor,
                          ),
                        ),
                        
                        // Left character (Stated Values)
                        Positioned(
                          left: 0,
                          bottom: 30,
                          child: Opacity(
                            opacity: _getCharacterOpacity('stated'),
                            child: Transform.translate(
                              offset: Offset(
                                -5.0 * position, // Move slightly with the tug
                                position < 0 ? -2.0 * bounce : 0, // Bounce when winning
                              ),
                              child: SizedBox(
                                width: 50,
                                height: 40, // Reduced height to prevent overflow
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Character icon with appropriate state and highlight effects
                                    ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (bounds) => LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _valueColor,
                                          Color.lerp(_valueColor, Colors.white, 0.3) ?? _valueColor,
                                        ],
                                      ).createShader(bounds),
                                      child: Icon(
                                        _getCharacterIcon('stated', statedCharacterState),
                                        size: 28,
                                      ),
                                    ),
                                    // Extra visual emphasis when winning
                                    if (statedCharacterState == 'winning')
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _valueColor.withAlpha(100),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Right character (Actual Behavior)
                        Positioned(
                          right: 0,
                          bottom: 30,
                          child: Opacity(
                            opacity: _getCharacterOpacity('actual'),
                            child: Transform.translate(
                              offset: Offset(
                                5.0 * position, // Move slightly with the tug
                                position > 0 ? -2.0 * bounce : 0, // Bounce when winning
                              ),
                              child: SizedBox(
                                width: 50,
                                height: 40, // Reduced height to prevent overflow
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Character icon with appropriate state and highlight effects
                                    ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (bounds) => LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _valueColor,
                                          Color.lerp(_valueColor, Colors.white, 0.3) ?? _valueColor,
                                        ],
                                      ).createShader(bounds),
                                      child: Icon(
                                        _getCharacterIcon('actual', actualCharacterState),
                                        size: 28,
                                      ),
                                    ),
                                    // Extra visual emphasis when winning
                                    if (actualCharacterState == 'winning')
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _valueColor.withAlpha(100),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Rope center knot with enhanced visuals
                        Positioned(
                          left: MediaQuery.of(context).size.width / 2 - 36 + (position * MediaQuery.of(context).size.width / 4),
                          bottom: 15,
                          child: Transform.translate(
                            offset: Offset(0, math.sin(wavePhase) * 2), // Subtle vertical movement
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Color.lerp(_valueColor, Colors.white, 0.3) ?? _valueColor,
                                    _valueColor,
                                  ],
                                  stops: const [0.0, 1.0],
                                  radius: 0.8,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _valueColor.withOpacity(isDarkMode ? 0.7 : 0.5),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2),
                                    blurRadius: 5,
                                    spreadRadius: -1,
                                    offset: const Offset(-1, -1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, _) {
                                    // Pulsing inner knot effect
                                    final pulseFactor = 0.9 + (0.2 * math.sin(wavePhase * 2));
                                    
                                    return Container(
                                      width: 15 * pulseFactor,
                                      height: 15 * pulseFactor,
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.9),
                                            _valueColor.withOpacity(0.7),
                                          ],
                                          stops: const [0.3, 1.0],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.7),
                                            blurRadius: 4,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.8),
                                          width: 2,
                                        ),
                                      ),
                                    );
                                  }
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Interactive hint when user starts dragging
                        if (_userInteracting)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _valueColor.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      'Drag to test balance!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.touch_app,
                                      size: 14,
                                      color: Colors.white,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
              
              // Interactive helper text
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Try tugging the rope!',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// Custom painter for the rope with wave animation
class RopePainter extends CustomPainter {
  final double position;
  final double bounce;
  final double wavePhase;
  final Color ropeColor;
  
  RopePainter({
    required this.position,
    required this.bounce,
    required this.wavePhase,
    required this.ropeColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ropeColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final center = Offset(size.width / 2, size.height / 2);
    final leftEnd = Offset(0, size.height / 2);
    final rightEnd = Offset(size.width, size.height / 2);
    
    // Calculate the center knot position based on the position value
    final knotOffset = position * (size.width / 4);
    final knotPosition = Offset(center.dx + knotOffset, center.dy);
    
    // Create a path for the rope with wave effect
    final path = Path();
    path.moveTo(leftEnd.dx, leftEnd.dy);
    
    // Create multiple control points for a more natural wave
    final segments = 10;
    final segmentWidth = (knotPosition.dx - leftEnd.dx) / segments;
    
    for (int i = 1; i <= segments; i++) {
      final x = leftEnd.dx + (i * segmentWidth);
      // Calculate vertical offset using sine wave
      final waveHeight = 3.0 * (1.0 - i / segments); // Taper wave as we approach the knot
      final y = leftEnd.dy + math.sin(wavePhase + (i * 0.7)) * waveHeight;
      path.lineTo(x, y);
    }
    
    // Continue with the right side of the rope
    for (int i = 1; i <= segments; i++) {
      final x = knotPosition.dx + (i * ((rightEnd.dx - knotPosition.dx) / segments));
      // Reversed for right side
      final waveHeight = 3.0 * (i / segments); // Taper wave as we leave the knot
      final y = rightEnd.dy + math.sin(wavePhase + math.pi + (i * 0.7)) * waveHeight;
      path.lineTo(x, y);
    }
    
    // Draw the wavy rope
    canvas.drawPath(path, paint);
    
    // Draw segments with alternating colors for a rope-like effect
    final ropePaint = Paint()
      ..color = ropeColor.withOpacity(0.7)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    
    // Draw short segments along the rope path
    final segmentLength = 8.0;
    final pathMetrics = path.computeMetrics().single;
    var distance = 0.0;
    
    while (distance < pathMetrics.length) {
      // Extract a segment of the path
      final extractPath = pathMetrics.extractPath(
        distance,
        math.min(distance + segmentLength, pathMetrics.length),
      );
      
      // Draw with varying opacity for texture
      ropePaint.color = ropeColor.withOpacity(
        distance.toInt() % 20 < 10 ? 0.8 : 0.5,
      );
      
      canvas.drawPath(extractPath, ropePaint);
      distance += segmentLength * 2; // Skip to create the effect
    }
  }
  
  @override
  bool shouldRepaint(RopePainter oldDelegate) {
    return oldDelegate.position != position ||
           oldDelegate.bounce != bounce ||
           oldDelegate.wavePhase != wavePhase ||
           oldDelegate.ropeColor != ropeColor;
  }
}