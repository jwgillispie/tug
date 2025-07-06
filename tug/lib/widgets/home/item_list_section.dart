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
        // Enhanced section header with premium styling
        Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 16,
            top: 32,
            bottom: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isViceMode
                        ? [TugColors.viceGreen.withValues(alpha: 0.2), TugColors.viceGreenLight.withValues(alpha: 0.1)]
                        : [TugColors.primaryPurple.withValues(alpha: 0.2), TugColors.primaryPurpleLight.withValues(alpha: 0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: TugColors.getPrimaryColor(isViceMode),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isViceMode
                        ? [TugColors.viceGreen.withValues(alpha: 0.2), TugColors.viceGreenLight.withValues(alpha: 0.1)]
                        : [TugColors.primaryPurple.withValues(alpha: 0.2), TugColors.primaryPurpleLight.withValues(alpha: 0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: onEditPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Text(
                    editButtonText.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: TugColors.getPrimaryColor(isViceMode),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Enhanced container with premium styling
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(
              color: isDarkMode
                  ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
                  : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: items.map((item) => _buildItemCard(context, item, isDarkMode, isViceMode)).toList(),
            ),
          ),
        ),
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

    return InkWell(
      onTap: onItemTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          child: Row(
            children: [
              // Enhanced icon with gradient background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [valueColor.withValues(alpha: 0.15), valueColor.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: valueColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'importance: ${value.importance}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Enhanced star rating display
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
                      : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
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
                        color: valueColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViceCard(BuildContext context, ViceModel vice, bool isDarkMode) {
    final Color viceColor = Color(
      int.parse(vice.color.substring(1), radix: 16) + 0xFF000000,
    );

    return InkWell(
      onTap: onItemTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          child: Row(
            children: [
              // Enhanced icon with gradient background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [viceColor.withValues(alpha: 0.15), viceColor.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.block,
                  color: viceColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vice.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'clean streak: ${vice.currentStreak} days',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Enhanced streak display
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
                      : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${vice.currentStreak}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: viceColor,
                          ),
                        ),
                        Text(
                          'days',
                          style: TextStyle(
                            fontSize: 10,
                            color: viceColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.trending_up,
                      color: viceColor.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}