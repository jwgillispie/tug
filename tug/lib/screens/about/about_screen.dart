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
        title: const Text('about tug'),
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
                    'Tug',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'version 1.2.0',
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
              'what is tug?',
              'Tug helps you visualize the pull between what you say matters and how you actually spend your time. '
              'By tracking time spent on activities aligned with your values, Tug creates awareness of the gap between stated values and actual behavior.'
            ),
            
            // How it works
            _buildSection(
              context,
              'how it works',
              '1. Define your personal values (up to 5)\n'
              '2. Track time spent on value-aligned activities\n'
              '3. Build streaks by engaging with your values daily\n'
              '4. Visualize your progress with activity charts and rankings\n'
              '5. Identify areas for better alignment in your life'
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
              'Questions or feedback? Reach out at: jordangillispie@outlook.com'
            ),
            
            // Recent Features
            _buildSection(
              context,
              'new features',
              '• activity chart - Track your progress with a visual representation of your activity minutes\n'
              '• streak tracking - Build and maintain daily streaks for each value\n'
              '• strava integration - Import your activities directly from Strava\n'
              '• activity rankings - See how you compare with others in the community'
            ),
            
            // App version details
            _buildSection(
              context,
              'technical details',
              'Built with Flutter\n'
              'Firebase Authentication\n'
              'MongoDB Backend\n'
              'Version 1.2.0 (May 2025)'
            ),
            
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  _launchUrl('mailto:jordangillispie@outlook.com?subject=Tug%20App%20Feedback');
                },
                icon: const Icon(Icons.email_outlined),
                label: const Text('send feedback'),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Copyright notice
            Center(
              child: Text(
                '© ${DateTime.now().year} Tug App. All rights reserved.',
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