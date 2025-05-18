// lib/screens/main_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/animations.dart';
import 'dart:ui';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    // Define the navigation data for animation sequencing
    final navItems = [
      {
        'icon': Icons.home_outlined,
        'selectedIcon': Icons.home_rounded,
        'label': 'Home',
        'index': 0,
        'path': '/home',
      },
      {
        'icon': Icons.insights_outlined,
        'selectedIcon': Icons.insights_rounded,
        'label': 'Progress',
        'index': 1,
        'path': '/progress',
      },
      {
        'icon': Icons.history_outlined,
        'selectedIcon': Icons.history_rounded,
        'label': 'Activities',
        'index': 2,
        'path': '/activities',
      },
      {
        'icon': Icons.person_outline_rounded,
        'selectedIcon': Icons.person_rounded,
        'label': 'Profile',
        'index': 3,
        'path': '/profile',
      },
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor:
            isDarkMode ? TugColors.darkBackground : Colors.white,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true, // Important for the transparent bottom nav effect
        resizeToAvoidBottomInset: true, // Allow resizing when keyboard appears
        body: Stack(
          children: [
            // Main content
            child,

            // Bottom navigation overlay - allows for glass effect
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildImmersiveBottomNav(
                  context, navItems, isDarkMode, bottomPadding),
            ),
          ],
        ),
        floatingActionButton: Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TugColors.primaryPurple,
            boxShadow: [
              BoxShadow(
                color: TugColors.primaryPurple.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAddActionSheet(context),
              borderRadius: BorderRadius.circular(27),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // Simplified bottom navigation for better responsiveness
  Widget _buildImmersiveBottomNav(
      BuildContext context,
      List<Map<String, dynamic>> navItems,
      bool isDarkMode,
      double bottomPadding) {
    return Material(
      elevation: 4,
      color: isDarkMode ? TugColors.darkSurface : Colors.white,
      child: Container(
        height:
            40 + bottomPadding, // Further reduced height to prevent overflow
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          children: [
            // Create equal width nav items with flexible spacing
            for (int i = 0; i < 2; i++)
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: navItems[i]['icon'],
                  selectedIcon: navItems[i]['selectedIcon'],
                  label: navItems[i]['label'],
                  index: navItems[i]['index'],
                  path: navItems[i]['path'],
                  isDarkMode: isDarkMode,
                ),
              ),

            // Center space for FAB that adapts with screen size
            Expanded(
              child: Container(), // Responsive space that grows/shrinks
            ),

            // Last two nav items
            for (int i = 2; i < 4; i++)
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: navItems[i]['icon'],
                  selectedIcon: navItems[i]['selectedIcon'],
                  label: navItems[i]['label'],
                  index: navItems[i]['index'],
                  path: navItems[i]['path'],
                  isDarkMode: isDarkMode,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Simplified add action sheet
  void _showAddActionSheet(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? TugColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What would you like to add today?',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Simpler option cards
              _buildActionCard(
                context: context,
                title: 'Log Activity',
                description: 'Record a new activity session',
                icon: Icons.timelapse_rounded,
                gradient: TugColors.getPrimaryGradient(),
                path: '/activities/new',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context: context,
                title: 'Add Value',
                description: 'Define what matters to you',
                icon: Icons.star_rounded,
                gradient: TugColors.getSecondaryGradient(),
                path: '/values-input',
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        );
      },
    );
  }

  // Simplified action card for the bottom sheet
  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required LinearGradient gradient,
    required String path,
    required bool isDarkMode,
  }) {
    // Use the first color of the gradient for a solid accent
    final Color accentColor = gradient.colors.first;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      color: isDarkMode ? TugColors.darkSurfaceVariant : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          context.go(path);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon with solid color
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.4)
                    : Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required String path,
    required bool isDarkMode,
  }) {
    final isSelected = currentIndex == index;
    final Color activeColor = TugColors.primaryPurple;
    final Color inactiveColor = isDarkMode
        ? Colors.white.withOpacity(0.6)
        : Colors.black.withOpacity(0.5);

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.lightImpact();
          context.go(path);
        }
      },
      child: SizedBox(
        height: 40, // Match container height
        width: double.infinity,
        child: Row(
          // Changed to Row instead of Column to avoid overflow
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple icon with no special effects
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 20, // Reduced size
            ),
            const SizedBox(width: 4),
            // Simple text beside icon
            Text(
              label,
              style: TextStyle(
                fontSize: 11, // Smaller font
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
