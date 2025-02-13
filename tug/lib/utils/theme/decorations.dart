
// lib/utils/theme/decorations.dart
import 'package:flutter/material.dart';
import 'colors.dart';

class TugDecorations {
  // Card shadows
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 3,
    offset: const Offset(0, 1),
  );

  static BoxShadow elevatedShadow = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 6,
    offset: const Offset(0, 4),
  );

  // Card decorations
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [cardShadow],
  );

  static BoxDecoration elevatedDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [elevatedShadow],
  );
}
