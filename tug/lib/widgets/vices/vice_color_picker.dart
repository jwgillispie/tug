// lib/widgets/vices/vice_color_picker.dart
import 'package:flutter/material.dart';
import '../../utils/theme/colors.dart';

class ViceColorPicker extends StatelessWidget {
  final String selectedColor;
  final Function(String) onColorSelected;

  const ViceColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      '#DC2626', // Red - primary vice color
      '#EA580C', // Orange
      '#D97706', // Amber
      '#CA8A04', // Yellow
      '#65A30D', // Lime
      '#16A34A', // Green
      '#059669', // Emerald
      '#0D9488', // Teal
      '#0891B2', // Sky
      '#2563EB', // Blue
      '#7C3AED', // Violet
      '#9333EA', // Purple
      '#C026D3', // Fuchsia
      '#E11D48', // Rose
      '#374151', // Gray
      '#1F2937', // Dark gray
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((colorHex) {
        final color = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
        final isSelected = selectedColor == colorHex;
        
        return GestureDetector(
          onTap: () => onColorSelected(colorHex),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      width: 3,
                    )
                  : Border.all(
                      color: color.withAlpha(100),
                      width: 1,
                    ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withAlpha(100),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: _getContrastColor(color),
                    size: 20,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we should use black or white text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}