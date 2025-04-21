// Updated decorations.dart
import 'package:flutter/material.dart';
import 'colors.dart';

class TugDecorations {
  // Refined shadows
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 8,
    offset: const Offset(0, 2),
    spreadRadius: 0,
  );

  static BoxShadow elevatedShadow = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 16,
    offset: const Offset(0, 4),
    spreadRadius: 0,
  );

  // Card decorations with subtle border
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [cardShadow],
    border: Border.all(
      color: Theme.of(context).brightness == Brightness.light 
          ? Colors.black.withOpacity(0.03) 
          : Colors.white.withOpacity(0.03),
      width: 0.5,
    ),
  );

  static BoxDecoration elevatedDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [elevatedShadow],
    border: Border.all(
      color: Theme.of(context).brightness == Brightness.light 
          ? Colors.black.withOpacity(0.03) 
          : Colors.white.withOpacity(0.03),
      width: 0.5,
    ),
  );
  
  // Gradient background decoration
  static BoxDecoration gradientBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        TugColors.gradientStart.withOpacity(0.05),
        TugColors.gradientEnd.withOpacity(0.15),
      ],
    ),
  );
}