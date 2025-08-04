// lib/widgets/home/components/home_settings_section.dart
import 'package:flutter/material.dart';
import '../../../services/app_mode_service.dart';
import '../../../utils/theme/colors.dart';

class HomeSettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final AppMode currentMode;
  
  const HomeSettingsSection({
    super.key,
    required this.title,
    required this.items,
    required this.currentMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = currentMode == AppMode.vicesMode;
    
    return Semantics(
      label: '$title settings section',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 24,
              right: 16,
              top: 32,
              bottom: 12,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isViceMode
                          ? [
                              TugColors.viceGreen.withValues(alpha: 0.2), 
                              TugColors.viceGreenLight.withValues(alpha: 0.1)
                            ]
                          : [
                              TugColors.primaryPurple.withValues(alpha: 0.2), 
                              TugColors.primaryPurpleLight.withValues(alpha: 0.1)
                            ],
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
              ],
            ),
          ),
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
                children: items,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeFeatureSettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final AppMode currentMode;
  
  const HomeFeatureSettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    required this.currentMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = currentMode == AppMode.vicesMode;
    
    return Semantics(
      label: '$title, $description',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              border: isLast ? null : Border(
                bottom: BorderSide(
                  color: isDarkMode
                      ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
                      : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: TugColors.getPrimaryColor(isViceMode),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: TugColors.getTextColor(isDarkMode, isViceMode),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}