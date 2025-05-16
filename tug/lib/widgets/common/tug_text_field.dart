// Futuristic tug_text_field.dart with cyberpunk styling and advanced animations
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/text_styles.dart';
import '../../utils/animations.dart';

class TugTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final EdgeInsetsGeometry padding;
  final bool readOnly;
  final FocusNode? focusNode;
  final int? maxLines;
  final int? minLines;
  final bool enableInteractiveSelection;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  
  // Advanced styling options
  final bool useGlassMorphism;
  final Color? accentColor;
  final bool enableGlow;
  final bool enableFloatingLabel;
  final BorderRadius? borderRadius;
  final bool enableShimmer;
  final bool animateOnFocus;

  const TugTextField({
    super.key,
    required this.label,
    this.hint,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.onTap,
    this.onChanged,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.readOnly = false,
    this.focusNode,
    this.maxLines = 1,
    this.minLines,
    this.enableInteractiveSelection = true,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    
    // Advanced styling defaults
    this.useGlassMorphism = false,
    this.accentColor,
    this.enableGlow = false,
    this.enableFloatingLabel = true,
    this.borderRadius,
    this.enableShimmer = false,
    this.animateOnFocus = true,
  });

  @override
  State<TugTextField> createState() => _TugTextFieldState();
}

class _TugTextFieldState extends State<TugTextField> with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  bool _isFocused = false;
  bool _hasValue = false;
  late final FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateAnimation;
  
  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _hasValue = widget.controller?.text.isNotEmpty ?? false;
    
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _translateAnimation = Tween<double>(
      begin: 0.0,
      end: -12.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // If controller already has text, update hasValue
    widget.controller?.addListener(_handleTextChange);
    
    // Initial state of animations
    if (_hasValue || _isFocused) {
      _animationController.value = 1.0;
    }
  }
  
  void _handleTextChange() {
    final hasValue = widget.controller!.text.isNotEmpty;
    if (hasValue != _hasValue) {
      setState(() {
        _hasValue = hasValue;
      });
      
      if (widget.enableFloatingLabel) {
        if (hasValue && !_isFocused) {
          _animationController.forward();
        } else if (!hasValue && !_isFocused) {
          _animationController.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleTextChange);
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (widget.animateOnFocus) {
      if (_isFocused || _hasValue) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveAccentColor = widget.accentColor ?? 
        (isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurple);
    
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(14);
        
    final labelColor = _isFocused
        ? effectiveAccentColor
        : (isDark ? TugColors.darkTextSecondary : TugColors.lightTextSecondary);
    
    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated label with color change on focus
          if (widget.enableFloatingLabel)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _translateAnimation.value),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    alignment: Alignment.centerLeft,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TugTextStyles.bodyMedium.copyWith(
                        color: labelColor,
                        fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                      child: widget.enableShimmer && _isFocused
                          ? TugAnimations.gradientShimmerText(
                              text: widget.label,
                              gradientColors: [
                                effectiveAccentColor,
                                Color.lerp(effectiveAccentColor, isDark ? Colors.white : Colors.black, 0.3) ?? effectiveAccentColor,
                                effectiveAccentColor,
                              ],
                              style: TugTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.2,
                              ),
                            )
                          : Text(widget.label),
                    ),
                  ),
                );
              },
            ),
          
          if (widget.enableFloatingLabel)
            const SizedBox(height: 8),

          // Animated container for the text field
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutQuad,
            decoration: BoxDecoration(
              borderRadius: effectiveBorderRadius,
              boxShadow: [
                if (_isFocused && widget.enableGlow)
                  BoxShadow(
                    color: effectiveAccentColor.withOpacity(0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                if (_isFocused && !widget.enableGlow)
                  BoxShadow(
                    color: effectiveAccentColor.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: widget.useGlassMorphism
                ? _buildGlassMorphicTextField(isDark, effectiveAccentColor, effectiveBorderRadius)
                : _buildStandardTextField(isDark, effectiveAccentColor, effectiveBorderRadius),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStandardTextField(bool isDark, Color accentColor, BorderRadius borderRadius) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: widget.keyboardType,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onTap: widget.onTap,
      onChanged: (value) {
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      },
      readOnly: widget.readOnly,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      minLines: widget.minLines,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      cursorColor: accentColor,
      cursorWidth: 2.0,
      cursorRadius: const Radius.circular(4),
      style: TugTextStyles.bodyMedium.copyWith(
        color: isDark ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: !widget.enableFloatingLabel ? widget.label : widget.hint,
        hintStyle: TugTextStyles.bodyMedium.copyWith(
          color: (isDark
              ? TugColors.darkTextSecondary
              : TugColors.lightTextSecondary).withOpacity(0.6),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: isDark
            ? TugColors.darkSurfaceVariant.withOpacity(_isFocused ? 0.7 : 0.5)
            : TugColors.lightSurfaceVariant.withOpacity(_isFocused ? 0.5 : 0.3),
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: widget.prefixIcon,
              )
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: _isFocused 
                    ? accentColor
                    : isDark ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                  size: 20,
                ),
                splashRadius: 20,
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                  // Refocus to keep keyboard open
                  if (_isFocused) {
                    _focusNode.requestFocus();
                  }
                },
              )
            : widget.suffixIcon,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: isDark ? TugColors.darkBorder : TugColors.lightBorder,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: accentColor,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: TugColors.error,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: TugColors.error,
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: widget.maxLines == 1,
        errorStyle: TugTextStyles.caption.copyWith(
          color: TugColors.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildGlassMorphicTextField(bool isDark, Color accentColor, BorderRadius borderRadius) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: TugAnimations.glassMorphism(
        blurAmount: 5,
        borderRadius: borderRadius,
        tintColor: isDark ? Colors.black : Colors.white,
        tintOpacity: isDark ? 0.3 : 0.15,
        borderOpacity: isDark ? 0.15 : 0.2,
        isDark: isDark,
        border: Border.all(
          color: _isFocused ? accentColor.withOpacity(0.5) : (isDark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.white.withOpacity(0.3)),
          width: _isFocused ? 1.5 : 0.5,
        ),
        child: TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onTap: widget.onTap,
          onChanged: (value) {
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
          },
          readOnly: widget.readOnly,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          minLines: widget.minLines,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          cursorColor: accentColor,
          cursorWidth: 2.0,
          cursorRadius: const Radius.circular(4),
          style: TugTextStyles.bodyMedium.copyWith(
            color: isDark ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: !widget.enableFloatingLabel ? widget.label : widget.hint,
            hintStyle: TugTextStyles.bodyMedium.copyWith(
              color: (isDark
                  ? TugColors.darkTextSecondary
                  : TugColors.lightTextSecondary).withOpacity(0.6),
              fontWeight: FontWeight.w400,
            ),
            filled: false,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: widget.prefixIcon,
                  )
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: _isFocused 
                        ? accentColor
                        : isDark ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                      size: 20,
                    ),
                    splashRadius: 20,
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                      // Refocus to keep keyboard open
                      if (_isFocused) {
                        _focusNode.requestFocus();
                      }
                    },
                  )
                : widget.suffixIcon,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            isDense: widget.maxLines == 1,
            errorStyle: TugTextStyles.caption.copyWith(
              color: TugColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}