// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/values/bloc/values_state.dart';
import 'package:tug/blocs/theme/theme_bloc.dart';
import 'package:tug/widgets/home/swipeable_quotes.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/buttons.dart';
import '../../utils/theme/decorations.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Collection of inspirational quotes about values
  final List<Map<String, String>> _quotes = [
    {
      'quote': 'When your values are clear to you, making decisions becomes easier.',
      'author': 'Roy E. Disney'
    },
    {
      'quote': 'If you don\'t stick to your values when they are being tested, they\'re not values, they\'re hobbies.',
      'author': 'Jon Stewart'
    },
    {
      'quote': 'Your beliefs become your thoughts. Your thoughts become your words. Your words become your actions.',
      'author': 'Gandhi'
    },
    {
      'quote': 'It\'s not hard to make decisions when you know what your values are.',
      'author': 'Roy Disney'
    },
    {
      'quote': 'Living with integrity means behaving in ways that are in harmony with your personal values.',
      'author': 'Barbara De Angelis'
    },
    {
      'quote': 'Your personal core values define who you are.',
      'author': 'Tony Hsieh'
    },
    {
      'quote': 'A highly developed value system is like a compass. It serves as a guide to point you in the right direction.',
      'author': 'Idowu Koyenikan'
    },
    {
      'quote': 'When values, thoughts, feelings, and actions are in alignment, a person becomes focused and character is strengthened.',
      'author': 'John C. Maxwell'
    },
    {
      'quote': 'In moments like this, it doesn\'t matter what you were born to be. It matters what you choose to become.',
      'author': 'Kristin Harmel'
    },
  ];
  
  @override
  void initState() {
    super.initState();
    // Load values when screen is initialized
    context.read<ValuesBloc>().add(LoadValues());
    
    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Start animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Navigate to values edit with return flag
  void _navigateToValuesEdit() {
    // Pass a parameter to indicate we should show a back button
    context.push('/values-input?fromHome=true');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ValuesBloc>().add(LoadValues());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutConfirmation();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
                ? [
                    TugColors.darkBackground,
                    Color.lerp(TugColors.darkBackground, TugColors.primaryPurple, 0.05) ?? TugColors.darkBackground,
                  ] 
                : [
                    TugColors.lightBackground,
                    Color.lerp(TugColors.lightBackground, TugColors.primaryPurple, 0.03) ?? TugColors.lightBackground,
                  ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: BlocBuilder<ValuesBloc, ValuesState>(
            builder: (context, state) {
              if (state is ValuesLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              if (state is ValuesError) {
                return Center(
                  child: Text('Error: ${state.message}'),
                );
              }
              
              if (state is ValuesLoaded) {
                final values = state.values.where((v) => v.active).toList();
                
                if (values.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_border_rounded,
                          size: 64,
                          color: TugColors.primaryPurple.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No values defined yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add some values to start tracking your progress',
                          style: TextStyle(
                            color: isDarkMode 
                                ? TugColors.darkTextSecondary 
                                : TugColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: TugButtons.primaryButtonStyle,
                          onPressed: _navigateToValuesEdit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Add Values'),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Swipeable Quotes
                    SwipeableQuotes(quotes: _quotes),
                    
                    // Values List
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Values',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _navigateToValuesEdit,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TugColors.primaryPurple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Edit Values'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...values.map((value) {
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
                            'Importance: ${value.importance}',
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
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: _navigateToValuesEdit,
                        ),
                      );
                    }).toList(),
                    
                    const SizedBox(height: 24),
                    
                    // Feature Cards Section
                    const Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Activity Tracking Card
                    GestureDetector(
                      onTap: () {
                        context.go('/activities');
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.3 : 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.history,
                                  color: TugColors.primaryPurple,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Activity Tracking',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Log time spent on your values',
                                      style: TextStyle(
                                        color: isDarkMode 
                                            ? TugColors.darkTextSecondary 
                                            : TugColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.1 : 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.chevron_right,
                                    color: TugColors.primaryPurple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Progress Tracking Card
                    GestureDetector(
                      onTap: () {
                        context.go('/progress');
                      },
                      child: Container(
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: TugColors.secondaryTeal.withOpacity(isDarkMode ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: TugColors.secondaryTeal.withOpacity(isDarkMode ? 0.3 : 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.insights,
                                  color: TugColors.secondaryTeal,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Progress Tracking',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'View your value alignment progress',
                                      style: TextStyle(
                                        color: isDarkMode 
                                            ? TugColors.darkTextSecondary 
                                            : TugColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: TugColors.secondaryTeal.withOpacity(isDarkMode ? 0.1 : 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.chevron_right,
                                    color: TugColors.secondaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              
              return const Center(
                child: Text('No values loaded'),
              );
            },
          ),
        ),
      ),
    );
  }
  
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: TugColors.error),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}