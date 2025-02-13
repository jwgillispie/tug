// lib/utils/theme/buttons.dart
import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class TugButtons {
  // Primary Button
  static final primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: TugColors.primaryPurple,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: TugTextStyles.button,
    elevation: 0,
  );

  // Secondary Button
  static final secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: TugColors.primaryPurple,
    side: const BorderSide(color: TugColors.primaryPurple),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: TugTextStyles.button,
  );

  // Text Button
  static final textButtonStyle = TextButton.styleFrom(
    foregroundColor: TugColors.primaryPurple,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    textStyle: TugTextStyles.button,
  );

  // Icon Button
  static final iconButtonStyle = IconButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: TugColors.primaryPurple,
    padding: const EdgeInsets.all(8),
  );

  // Disabled Button States
  static ButtonStyle disabledButtonStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).disabledColor,
    foregroundColor: TugColors.lightTextSecondary,
    elevation: 0,
  );
}

// Example usage:
class ExampleButtons extends StatelessWidget {
  const ExampleButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          style: TugButtons.primaryButtonStyle,
          onPressed: () {},
          child: const Text('Primary Button'),
        ),
        OutlinedButton(
          style: TugButtons.secondaryButtonStyle,
          onPressed: () {},
          child: const Text('Secondary Button'),
        ),
        TextButton(
          style: TugButtons.textButtonStyle,
          onPressed: () {},
          child: const Text('Text Button'),
        ),
        IconButton(
          style: TugButtons.iconButtonStyle,
          onPressed: () {},
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}