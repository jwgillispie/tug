// lib/widgets/home/item_list_section.dart
import 'package:flutter/material.dart';
import '../../utils/theme/colors.dart';
import '../../models/value_model.dart';
import '../../models/vice_model.dart';
import '../../services/app_mode_service.dart';

class ItemListSection<T> extends StatelessWidget {
  final String title;
  final String editButtonText;
  final List<T> items;
  final VoidCallback onEditPressed;
  final VoidCallback? onItemTap;
  final AppMode appMode;
  final bool isEmpty;
  final Widget emptyStateWidget;

  const ItemListSection({
    super.key,
    required this.title,
    required this.editButtonText,
    required this.items,
    required this.onEditPressed,
    this.onItemTap,
    required this.appMode,
    required this.isEmpty,
    required this.emptyStateWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = appMode == AppMode.vicesMode;

    if (isEmpty) {
      return emptyStateWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton(
              onPressed: onEditPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: isViceMode ? TugColors.viceRed : TugColors.primaryPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Text(editButtonText),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildItemCard(context, item, isDarkMode, isViceMode)),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, T item, bool isDarkMode, bool isViceMode) {
    if (item is ValueModel) {
      return _buildValueCard(context, item, isDarkMode);
    } else if (item is ViceModel) {
      return _buildViceCard(context, item, isDarkMode);
    }
    return const SizedBox.shrink();
  }

  Widget _buildValueCard(BuildContext context, ValueModel value, bool isDarkMode) {
    final Color valueColor = Color(
      int.parse(value.color.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? TugColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2) 
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.05) 
              : Colors.black.withOpacity(0.03),
          width: 0.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: valueColor.withOpacity(isDarkMode ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: valueColor.withOpacity(isDarkMode ? 0.3 : 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: valueColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        title: Text(
          value.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'importance: ${value.importance}',
          style: TextStyle(
            color: isDarkMode 
                ? TugColors.darkTextSecondary 
                : TugColors.lightTextSecondary,
            fontSize: 13,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star Icons based on importance
            ...List.generate(
              value.importance,
              (index) => Icon(
                Icons.star,
                size: 16,
                color: valueColor,
              ),
            ),
            ...List.generate(
              5 - value.importance,
              (index) => Icon(
                Icons.star_border,
                size: 16,
                color: valueColor.withOpacity(0.3),
              ),
            ),
          ],
        ),
        onTap: onItemTap,
      ),
    );
  }

  Widget _buildViceCard(BuildContext context, ViceModel vice, bool isDarkMode) {
    final Color viceColor = Color(
      int.parse(vice.color.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? TugColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.2) 
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.05) 
              : Colors.black.withOpacity(0.03),
          width: 0.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: viceColor.withOpacity(isDarkMode ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: viceColor.withOpacity(isDarkMode ? 0.3 : 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.block,
              color: viceColor,
              size: 20,
            ),
          ),
        ),
        title: Text(
          vice.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'clean streak: ${vice.currentStreak} days',
          style: TextStyle(
            color: isDarkMode 
                ? TugColors.darkTextSecondary 
                : TugColors.lightTextSecondary,
            fontSize: 13,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${vice.currentStreak}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: viceColor,
                  ),
                ),
                Text(
                  'days',
                  style: TextStyle(
                    fontSize: 10,
                    color: viceColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.trending_up,
              color: viceColor.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
        onTap: onItemTap,
      ),
    );
  }
}