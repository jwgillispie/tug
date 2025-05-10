// Enhanced tug_text_field.dart with improved spacing and design consistency
import 'package:flutter/material.dart';
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
  });

  @override
  State<TugTextField> createState() => _TugTextFieldState();
}

class _TugTextFieldState extends State<TugTextField> {
  bool _obscureText = true;
  bool _isFocused = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = _isFocused
        ? (isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurple)
        : (isDark ? TugColors.darkTextSecondary : TugColors.lightTextSecondary);

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated label with color change on focus
          TugAnimations.fadeSlideIn(
            beginOffset: const Offset(0.0, 5.0),
            duration: const Duration(milliseconds: 300),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TugTextStyles.bodyMedium.copyWith(
                color: labelColor,
                fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
              child: Text(widget.label),
            ),
          ),
          const SizedBox(height: 8),

          // Animated container for the text field
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutQuad,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                if (_isFocused)
                  BoxShadow(
                    color: (isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurple).withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
              ],
            ),
            child: TextFormField(
              controller: widget.controller,
              validator: widget.validator,
              obscureText: _obscureText,
              keyboardType: widget.keyboardType,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onTap: widget.onTap,
              onChanged: widget.onChanged,
              readOnly: widget.readOnly,
              maxLines: widget.isPassword ? 1 : widget.maxLines,
              minLines: widget.minLines,
              enableInteractiveSelection: widget.enableInteractiveSelection,
              textCapitalization: widget.textCapitalization,
              cursorColor: isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurple,
              cursorWidth: 2.0,
              cursorRadius: const Radius.circular(4),
              style: TugTextStyles.bodyMedium.copyWith(
                color: isDark ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
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
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility : Icons.visibility_off,
                          color: isDark ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : widget.suffixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? TugColors.darkBorder : TugColors.lightBorder,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurple,
                    width: 2.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: TugColors.error,
                    width: 1.0,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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
            ),
          ),
        ],
      ),
    );
  }
}