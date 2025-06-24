// lib/screens/main_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme/colors.dart';
import '../services/app_mode_service.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final AppModeService _appModeService = AppModeService();
  AppMode _currentMode = AppMode.valuesMode;

  @override
  void initState() {
    super.initState();
    _initializeMode();
  }

  void _initializeMode() async {
    await _appModeService.initialize();
    _appModeService.modeStream.listen((mode) {
      if (mounted) {
        setState(() {
          _currentMode = mode;
        });
      }
    });
    setState(() {
      _currentMode = _appModeService.currentMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final isViceMode = _currentMode == AppMode.vicesMode;

    // Define the navigation data based on current mode
    final navItems = [
      {
        'icon': Icons.home_outlined,
        'selectedIcon': Icons.home_rounded,
        'label': 'home',
        'index': 0,
        'path': '/home',
      },
      {
        'icon': Icons.insights_outlined,
        'selectedIcon': Icons.insights_rounded,
        'label': 'progress',
        'index': 1,
        'path': '/progress',
      },
      {
        'icon': isViceMode ? Icons.warning_outlined : Icons.history_outlined,
        'selectedIcon': isViceMode ? Icons.warning_rounded : Icons.history_rounded,
        'label': isViceMode ? 'lapses' : 'activities',
        'index': 2,
        'path': '/activities',
      },
      {
        'icon': Icons.person_outline_rounded,
        'selectedIcon': Icons.person_rounded,
        'label': 'profile',
        'index': 3,
        'path': '/profile',
      },
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor:
            TugColors.getBackgroundColor(isDarkMode, isViceMode),
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
            widget.child,

            // Bottom navigation overlay - allows for glass effect
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildImmersiveBottomNav(
                  context, navItems, isDarkMode, bottomPadding, isViceMode),
            ),
          ],
        ),
        floatingActionButton: Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TugColors.getPrimaryColor(isViceMode),
            boxShadow: [
              BoxShadow(
                color: TugColors.getPrimaryColor(isViceMode).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAddActionSheet(context, isViceMode),
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
      double bottomPadding,
      bool isViceMode) {
    return Material(
      elevation: 4,
      color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
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
                  isViceMode: isViceMode,
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
                  isViceMode: isViceMode,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Simplified add action sheet
  void _showAddActionSheet(BuildContext context, bool isViceMode) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: TugColors.getSurfaceColor(isDarkMode, isViceMode),
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
                _appModeService.primaryActionText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: TugColors.getTextColor(isDarkMode, isViceMode),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isViceMode 
                    ? 'track your vices or record an indulgence'
                    : 'what would you like to add today?',
                style: TextStyle(
                  fontSize: 14,
                  color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                ),
              ),
              const SizedBox(height: 24),

              // Mode-specific option cards
              if (isViceMode) ...[
                _buildActionCard(
                  context: context,
                  title: 'record indulgence',
                  description: 'track when you indulged in a vice',
                  icon: Icons.warning_rounded,
                  gradient: TugColors.getViceGradient(),
                  path: '/indulgences/new',
                  isDarkMode: isDarkMode,
                  isViceMode: isViceMode,
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  context: context,
                  title: 'manage vices',
                  description: 'add or edit your tracked vices',
                  icon: Icons.psychology_rounded,
                  gradient: TugColors.getViceGradient(),
                  path: '/vices-input',
                  isDarkMode: isDarkMode,
                  isViceMode: isViceMode,
                ),
                const SizedBox(height: 16),
                _buildModeToggleCard(context, isDarkMode, isViceMode),
              ] else ...[
                _buildActionCard(
                  context: context,
                  title: 'log activity',
                  description: 'record activity session',
                  icon: Icons.timelapse_rounded,
                  gradient: TugColors.getPrimaryGradient(),
                  path: '/activities/new',
                  isDarkMode: isDarkMode,
                  isViceMode: isViceMode,
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  context: context,
                  title: 'add value',
                  description: 'define what matters to you',
                  icon: Icons.star_rounded,
                  gradient: TugColors.getPrimaryGradient(),
                  path: '/values-input',
                  isDarkMode: isDarkMode,
                  isViceMode: isViceMode,
                ),
                const SizedBox(height: 16),
                _buildModeToggleCard(context, isDarkMode, isViceMode),
              ],
            ],
          ),
        );
      },
    );
  }

  // Mode toggle card
  Widget _buildModeToggleCard(BuildContext context, bool isDarkMode, bool isViceMode) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: TugColors.getPrimaryColor(isViceMode).withAlpha(50),
          width: 1,
        ),
      ),
      color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _appModeService.toggleMode();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: TugColors.getPrimaryColor(!isViceMode),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isViceMode ? Icons.favorite : Icons.psychology,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'switch to ${isViceMode ? 'values' : 'vices'} mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: TugColors.getTextColor(isDarkMode, isViceMode),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isViceMode 
                          ? 'track positive habits and values'
                          : 'track behaviors to overcome',
                      style: TextStyle(
                        fontSize: 14,
                        color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.swap_horiz,
                size: 20,
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              ),
            ],
          ),
        ),
      ),
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
    required bool isViceMode,
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
      color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          // Use replace instead of go for the activity form to ensure proper navigation
          if (path == '/activities/new') {
            context.replace(path);
          } else {
            context.go(path);
          }
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
                        color: TugColors.getTextColor(isDarkMode, isViceMode),
                      ),
                    ),
                    const SizedBox(height: 2),
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
    required bool isViceMode,
  }) {
    final isSelected = widget.currentIndex == index;
    final Color activeColor = TugColors.getPrimaryColor(isViceMode);
    final Color inactiveColor = TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true);

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
