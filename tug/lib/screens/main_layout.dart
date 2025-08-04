// lib/screens/main_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme/colors.dart';
import '../utils/theme/decorations.dart';
import '../utils/quantum_effects.dart';
import '../utils/mobile_ux_utils.dart';
import '../widgets/common/mobile_bottom_sheet.dart';
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
        'icon': Icons.people_outline,
        'selectedIcon': Icons.people,
        'label': 'social',
        'index': 0,
        'path': '/social',
      },
      {
        'icon': isViceMode ? Icons.spa_outlined : Icons.insights_outlined,
        'selectedIcon': isViceMode ? Icons.spa : Icons.insights_rounded,
        'label': isViceMode ? 'track' : 'progress',
        'index': 1,
        'path': isViceMode ? '/indulgence-tracking' : '/progress',
      },
      {
        'icon': Icons.home_outlined,
        'selectedIcon': Icons.home,
        'label': 'home',
        'index': 2,
        'path': '/home',
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                TugColors.getBackgroundColor(isDarkMode, isViceMode),
                TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.02),
                TugColors.getBackgroundColor(isDarkMode, isViceMode),
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: Stack(
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
        ),
        floatingActionButton: Semantics(
          label: isViceMode ? 'Add new indulgence or manage vices' : 'Add new activity or value',
          button: true,
          child: QuantumEffects.floating(
            offset: 4, // Reduced from 8 for better performance
            child: QuantumEffects.quantumBorder(
              glowColor: TugColors.getPrimaryColor(isViceMode),
              intensity: 0.4, // Reduced from 0.8 for better performance
              child: Container(
                height: 56,
                width: 56,
                decoration: TugDecorations.premiumButtonDecoration(
                  isDark: isDarkMode,
                  isViceMode: isViceMode,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    onTap: () => _showAddActionSheet(context, isViceMode),
                    borderRadius: BorderRadius.circular(28),
                    child: QuantumEffects.cosmicBreath(
                      intensity: 0.02, // Reduced for better performance
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
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
    return Container(
      width: double.infinity, // Ensure full width
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TugColors.getSurfaceColor(isDarkMode, isViceMode).withValues(alpha: 0.9),
            TugColors.getSurfaceColor(isDarkMode, isViceMode).withValues(alpha: 0.8),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : TugColors.primaryPurple).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      height: 44 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding, top: 4),
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
    );
  }

  // Mobile-optimized add action sheet
  void _showAddActionSheet(BuildContext context, bool isViceMode) {
    final items = isViceMode ? [
      MobileBottomSheetItem(
        icon: Icons.spa_rounded,
        title: 'record indulgence',
        description: 'track when you indulged in a vice',
        gradient: TugColors.getIndulgenceGradient(),
        onTap: () => context.go('/indulgences/new'),
      ),
      MobileBottomSheetItem(
        icon: Icons.psychology_rounded,
        title: 'manage vices',
        description: 'add or edit your tracked vices',
        gradient: TugColors.getViceGradient(),
        onTap: () => context.go('/vices-input'),
      ),
      MobileBottomSheetItem(
        icon: isViceMode ? Icons.favorite : Icons.psychology,
        title: 'switch to ${isViceMode ? 'values' : 'vices'} mode',
        description: isViceMode 
            ? 'track positive habits and values'
            : 'track behaviors to overcome',
        onTap: () => _appModeService.toggleMode(),
      ),
    ] : [
      MobileBottomSheetItem(
        icon: Icons.timelapse_rounded,
        title: 'log activity',
        description: 'record activity session',
        gradient: TugColors.getPrimaryGradient(),
        onTap: () {
          context.replace('/activities/new');
        },
      ),
      MobileBottomSheetItem(
        icon: Icons.star_rounded,
        title: 'add value',
        description: 'define what matters to you',
        gradient: TugColors.getPrimaryGradient(),
        onTap: () => context.go('/values-input'),
      ),
      MobileBottomSheetItem(
        icon: isViceMode ? Icons.favorite : Icons.psychology,
        title: 'switch to ${isViceMode ? 'values' : 'vices'} mode',
        description: isViceMode 
            ? 'track positive habits and values'
            : 'track behaviors to overcome',
        onTap: () => _appModeService.toggleMode(),
      ),
    ];

    MobileBottomSheet.show(
      context: context,
      title: _appModeService.primaryActionText,
      subtitle: isViceMode 
          ? 'track your vices or record an indulgence'
          : 'what would you like to add today?',
      items: items,
      isViceMode: isViceMode,
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

    // Generate proper semantic labels for accessibility
    final semanticLabel = _getSemanticLabel(label, isViceMode, isSelected);

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      child: MobileUXUtils.mobileButton(
        onPressed: () {
          if (!isSelected) {
            context.go(path);
          }
        },
        backgroundColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: QuantumEffects.floating(
          offset: isSelected ? 2 : 1, // Reduced for better performance
          child: Container(
            constraints: const BoxConstraints(
              minWidth: MobileUXUtils.minTouchTarget,
              minHeight: MobileUXUtils.minTouchTarget,
            ),
            decoration: isSelected
                ? TugDecorations.iconContainerDecoration(
                    isDark: isDarkMode,
                    isViceMode: isViceMode,
                  )
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced icon with quantum effects for selected state
                isSelected
                    ? QuantumEffects.cosmicBreath(
                        intensity: 0.02, // Reduced for better performance
                        child: Icon(
                          selectedIcon,
                          color: activeColor,
                          size: 20,
                          shadows: TugColors.getNeonGlow(
                            activeColor,
                            intensity: 0.3,
                          ).map((s) => Shadow(
                            color: s.color,
                            blurRadius: s.blurRadius / 2,
                            offset: Offset(s.offset.dx, s.offset.dy),
                          )).toList(),
                        ),
                      )
                    : Icon(
                        icon,
                        color: inactiveColor,
                        size: 18,
                      ),
                const SizedBox(width: 3),
                // Enhanced text with flexible layout
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isSelected ? 11 : 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? activeColor : inactiveColor,
                      letterSpacing: isSelected ? 0.2 : 0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Generate descriptive semantic labels for screen readers
  String _getSemanticLabel(String label, bool isViceMode, bool isSelected) {
    final selectedText = isSelected ? ', currently selected' : '';
    
    switch (label) {
      case 'social':
        return 'Social feed, view posts and connect with friends$selectedText';
      case 'track':
        return isViceMode 
            ? 'Track indulgences, monitor vice behaviors$selectedText'
            : 'Progress tracking, view your activity statistics$selectedText';
      case 'progress':
        return 'Progress tracking, view your activity statistics$selectedText';
      case 'home':
        return 'Home dashboard, overview of your activities and values$selectedText';
      case 'profile':
        return 'Profile settings, manage your account and preferences$selectedText';
      default:
        return '$label tab$selectedText';
    }
  }
}
