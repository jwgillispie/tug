// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/auth/auth_bloc.dart';
import 'package:tug/utils/theme/colors.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Progress tracking
  bool _initialized = false;
  String _statusMessage = 'Loading...';
  double _progress = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    // Start animation immediately
    _animationController.forward();
    
    // Initialize remaining steps
    _initializeApp();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Simple delay to allow animation to run
      await Future.delayed(const Duration(seconds: 2));
      
      _updateProgress('Checking authentication...', 0.6);
      
      // Wait for animation to complete (at least 2.5 seconds total)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mark as initialized
      setState(() {
        _initialized = true;
        _progress = 1.0;
        _statusMessage = 'Ready!';
      });
      
      // Check authentication state
      if (mounted) {
        context.read<AuthBloc>().add(CheckAuthStatusEvent());
      }
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      debugPrint('Initialization error: $e');
    }
  }
  
  void _updateProgress(String message, double progress) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _progress = progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (!_initialized) return;
        
        if (state is Authenticated) {
          // User is authenticated, navigate to social
          context.go('/social');
        } else if (state is Unauthenticated) {
          // User not authenticated, go to login
          context.go('/login');
        }
        // Stay on splash screen if state is still loading
      },
      child: Scaffold(
        backgroundColor: TugColors.primaryPurple,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or branding
                const Icon(
                  Icons.balance,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                Text(
                  'tug',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Custom progress indicator
                Container(
                  width: 200,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}