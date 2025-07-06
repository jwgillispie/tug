// lib/screens/about/about_screen.dart
import 'package:flutter/material.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('about viceless'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Version
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: TugColors.primaryPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.balance,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Viceless',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'version 3.0.0',
                    style: TextStyle(
                      color: isDarkMode 
                          ? TugColors.darkTextSecondary 
                          : TugColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Description
            _buildSection(
              context,
              'what is viceless?',
              'Viceless helps you track your personal values and overcome destructive habits. '
              'Switch between Values Mode to build positive streaks, and Vices Mode to track your journey toward breaking free from negative behaviors. '
              'Create awareness of the gap between your stated values and actual behavior.'
            ),
            
            // How it works
            _buildSection(
              context,
              'how it works',
              '• Values Mode: Define your personal values and track aligned activities\n'
              '• Vices Mode: Identify destructive habits and track clean streaks\n'
              '• Build positive streaks and break negative patterns\n'
              '• Visualize your progress with charts and rankings\n'
              '• Switch modes to focus on growth or recovery\n'
              '• Create awareness between your values and actions'
            ),
            
            // Developer Info
            _buildSection(
              context,
              'developer',
              'Created by Jordan Gillispie'
            ),
            
            // Contact
            _buildSection(
              context,
              'contact',
              'Questions or feedback? Reach out at: jordangillispie@outlook.com\n\n'
              'If you\'re struggling with addiction or mental health, please reach out to:\n'
              '• National Suicide Prevention Lifeline: 988\n'
              '• SAMHSA National Helpline: 1-800-662-4357'
            ),
            
            // Recent Features
            _buildSection(
              context,
              'new in v3.0.0',
              '• dual mode system - Switch between Values and Vices tracking\n'
              '• vice tracking - Monitor destructive habits and build clean streaks\n'
              '• serious mode theme - Appropriate visual tone for vice recovery\n'
              '• enhanced support - Crisis resources and coping strategies\n'
              '• improved analytics - Better insights for both modes\n'
              '• quantum ui effects - Beautiful animations throughout the app'
            ),
            
            // App version details
            _buildSection(
              context,
              'technical details',
              'Built with Flutter\n'
              'Firebase Authentication\n'
              'MongoDB Backend\n'
              'Version 3.0.0 (July 2025)'
            ),
            
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  _launchUrl('mailto:jordangillispie@outlook.com?subject=Viceless%20App%20Feedback');
                },
                icon: const Icon(Icons.email_outlined),
                label: const Text('send feedback'),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Copyright notice
            Center(
              child: Text(
                '© ${DateTime.now().year} Viceless App. All rights reserved.',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(BuildContext context, String title, String content) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              height: 1.5,
              color: isDarkMode
                  ? TugColors.darkTextPrimary
                  : TugColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}