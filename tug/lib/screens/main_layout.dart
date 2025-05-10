// lib/screens/main_layout.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/utils/theme/colors.dart';

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
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomAppBar(
        notchMargin: 6.0,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                index: 0,
                path: '/home',
              ),
              _buildNavItem(
                context: context,
                icon: Icons.insert_chart_outlined,
                selectedIcon: Icons.insert_chart,
                label: 'Progress',
                index: 1,
                path: '/progress',
              ),
              // Empty space for FAB
              const SizedBox(width: 40),
              _buildNavItem(
                context: context,
                icon: Icons.history_outlined,
                selectedIcon: Icons.history,
                label: 'Activities',
                index: 2,
                path: '/activities',
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile',
                index: 3,
                path: '/profile',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TugColors.primaryPurple,
        child: const Icon(Icons.add),
        onPressed: () {
          // Show bottom sheet to add new activity
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              // Show option menu for adding new items
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      title: Text(
                        'Add New',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.timelapse, color: TugColors.primaryPurple),
                      title: const Text('Log Activity'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/activities/new');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.star_outline, color: TugColors.primaryPurple),
                      title: const Text('Add Value'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/values-input');
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required String path,
  }) {
    final isSelected = currentIndex == index;
    
    return InkWell(
      onTap: () {
        if (!isSelected) {
          context.go(path);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? TugColors.primaryPurple : Colors.grey,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? TugColors.primaryPurple : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}