// lib/screens/main_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme/colors.dart';
import '../utils/theme/decorations.dart';
import '../utils/quantum_effects.dart';
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
        'label': 'home',
        'index': 0,
        'path': '/social',
      },
      {
        'icon': Icons.insights_outlined,
        'selectedIcon': Icons.insights_rounded,
        'label': 'progress',
        'index': 1,
        'path': '/progress',
      },
      {
        'icon': Icons.waving_hand_outlined,
        'selectedIcon': Icons.waving_hand,
        'label': 'hello',
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
        floatingActionButton: QuantumEffects.floating(
          offset: 8,
          child: QuantumEffects.quantumBorder(
            glowColor: TugColors.getPrimaryColor(isViceMode),
            intensity: 0.8,
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
                    intensity: 0.05,
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
                  icon: Icons.spa_rounded,
                  gradient: TugColors.getIndulgenceGradient(),
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
          color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
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
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
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
      child: QuantumEffects.floating(
        offset: isSelected ? 3 : 1,
        child: Container(
          height: 40,
          constraints: const BoxConstraints(minWidth: 0),
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
                      intensity: 0.05,
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
    );
  }
}
