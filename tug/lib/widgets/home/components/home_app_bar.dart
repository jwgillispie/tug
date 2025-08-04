// lib/widgets/home/components/home_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../services/app_mode_service.dart';
import '../../../utils/quantum_effects.dart';
import '../../../utils/theme/colors.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AppMode currentMode;
  
  const HomeAppBar({
    super.key,
    required this.currentMode,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = currentMode == AppMode.vicesMode;
    
    // Get personalized greeting from AuthBloc
    final greeting = _buildGreeting(context);
    
    return Semantics(
      header: true,
      label: 'Home screen header with greeting: $greeting',
      child: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isViceMode
                  ? (isDarkMode 
                      ? [TugColors.darkBackground, TugColors.viceGreenDark, TugColors.viceGreen]
                      : [TugColors.lightBackground, TugColors.viceGreen.withValues(alpha: 0.08)])
                  : (isDarkMode 
                      ? [TugColors.darkBackground, TugColors.primaryPurpleDark, TugColors.primaryPurple]
                      : [TugColors.lightBackground, TugColors.primaryPurple.withAlpha(20)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: QuantumEffects.gradientText(
          greeting,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          colors: isViceMode
              ? [TugColors.viceGreen, TugColors.viceGreenDark]
              : [TugColors.primaryPurple, TugColors.primaryPurpleDark],
        ),
      ),
    );
  }

  String _buildGreeting(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String greeting = 'hello';
    
    if (authState is Authenticated) {
      final displayName = authState.user.displayName;
      final email = authState.user.email;
      
      if (displayName != null && displayName.isNotEmpty) {
        greeting = 'hello, ${displayName.split(' ')[0]}';
      } else if (email != null && email.isNotEmpty) {
        // Use the part before @ in the email if no display name
        greeting = 'hello, ${email.split('@')[0]}';
      }
    }
    
    return greeting;
  }
}