// Enhanced tug_of_war_widget.dart with improved spacing and interactive animations
import 'package:flutter/material.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/theme/text_styles.dart';
import 'package:tug/utils/animations.dart';

class TugOfWarWidget extends StatefulWidget {
  final String valueName;
  final int statedImportance; // 1-5 scale
  final int actualBehavior; // Minutes spent
  final int communityAverage; // Community average minutes
  final String valueColor; // Added parameter for the value's color
  final VoidCallback? onTap;

  const TugOfWarWidget({
    super.key,
    required this.valueName,
    required this.statedImportance,
    required this.actualBehavior,
    required this.communityAverage,
    this.valueColor = '#8A4FFF', // Updated default to our new primary color
    this.onTap,
  });

  @override
  State<TugOfWarWidget> createState() => _TugOfWarWidgetState();
}

class _TugOfWarWidgetState extends State<TugOfWarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  double _position = 0.0; // -1.0 to 1.0 where 0 is center
  late Color _valueColor;
  bool _isHovered = false;

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
      return "your actions aren't matching your stated importance.";
    } else if (_position > 0.4) {
      return "you're investing more time than your stated importance suggests.";
    } else {
      return "good alignment between your stated values and actions!";
    }
  }

  // Use constant icons to avoid dynamic IconData
  static const IconData _warningIcon = Icons.warning_amber_rounded;
  static const IconData _infoIcon = Icons.info_outline;
  static const IconData _checkIcon = Icons.check_circle;
  
  // Get message icon based on position
  IconData _getMessageIcon() {
    if (_position < -0.4) {
      return _warningIcon;
    } else if (_position > 0.4) {
      return _infoIcon;
    } else {
      return _checkIcon;
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

    return TugAnimations.springInteractive(
      onTap: widget.onTap ?? () {},
      pressedScale: 0.98,
      useSprings: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuad,
          decoration: BoxDecoration(
            color: isDarkMode ? TugColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _valueColor.withOpacity(isDarkMode ? 0.25 : 0.12),
                blurRadius: _isHovered ? 12 : 8,
                spreadRadius: _isHovered ? 1 : 0,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
            border: Border.all(
              color: _valueColor.withOpacity(_isHovered ? 0.15 : 0.08),
              width: _isHovered ? 1.0 : 0.5,
            ),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22.0, 20.0, 22.0, 88.0),
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
                          // Value name with elegant typography
                          Text(
                            widget.valueName,
                            style: TugTextStyles.titleSmall.copyWith(
                              color: _valueColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Importance badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _valueColor.withOpacity(isDarkMode ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _valueColor.withOpacity(0.2),
                                width: 1
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: _valueColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Importance: ${widget.statedImportance}/5',
                                  style: TugTextStyles.label.copyWith(
                                    color: _valueColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Time spent badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _valueColor.withOpacity(isDarkMode ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _valueColor.withOpacity(isDarkMode ? 0.25 : 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: _valueColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.actualBehavior} mins/day',
                            style: TugTextStyles.label.copyWith(
                              color: _valueColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // Tug of War Visualization with enhanced design
                SizedBox(
                  height: 70,
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
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _valueColor.withOpacity(0.2),
                                    _valueColor.withOpacity(0.4),
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _valueColor.withOpacity(_getHandleOpacity('stated')),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _valueColor.withOpacity(_position < 0 ? 0.5 : 0.15),
                                      blurRadius: 10,
                                      spreadRadius: _position < 0 ? 1 : 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white.withOpacity(_position < 0 ? 1.0 : 0.7),
                                  size: 20,
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _valueColor.withOpacity(_getHandleOpacity('actual')),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _valueColor.withOpacity(_position > 0 ? 0.5 : 0.15),
                                      blurRadius: 10,
                                      spreadRadius: _position > 0 ? 1 : 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white.withOpacity(_position > 0 ? 1.0 : 0.7),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                          // Center knot with shadow and animated position
                          AnimatedBuilder(
                            animation: _positionAnimation,
                            builder: (context, child) {
                              return Positioned(
                                left: MediaQuery.of(context).size.width / 2 - 15 + (position * MediaQuery.of(context).size.width / 4),
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: TugAnimations.pulsate(
                                    duration: const Duration(milliseconds: 3000),
                                    minScale: 0.95,
                                    maxScale: 1.05,
                                    child: Container(
                                      width: 28,
                                      height: 28,
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
                              );
                            }
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // Labels with enhanced design
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
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
                            'stated values',
                            style: TugTextStyles.label.copyWith(
                              color: _valueColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Actual Behavior',
                            style: TugTextStyles.label.copyWith(
                              color: _valueColor,
                              fontWeight: FontWeight.w500,
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
                ),

                const SizedBox(height: 18),

                // Message based on position with enhanced design
                TugAnimations.fadeSlideIn(
                  duration: const Duration(milliseconds: 400),
                  beginOffset: const Offset(0, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _valueColor.withOpacity(isDarkMode ? 0.12 : 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _valueColor.withOpacity(isDarkMode ? 0.25 : 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          child: Icon(
                            _getMessageIcon(),
                            color: _valueColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _getMessage(),
                            style: TugTextStyles.bodySmall.copyWith(
                              color: _valueColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Community comparison with enhanced design
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _valueColor.withOpacity(isDarkMode ? 0.08 : 0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: _valueColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'community average: ${widget.communityAverage} mins/day',
                          style: TugTextStyles.caption.copyWith(
                            color: _valueColor.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }
}