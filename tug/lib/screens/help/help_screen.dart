// lib/screens/help/help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

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
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find answers to common questions or reach out for support',
              style: TextStyle(
                color: isDarkMode 
                    ? TugColors.darkTextSecondary 
                    : TugColors.lightTextSecondary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // FAQ Section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildFaqItem(
              context,
              'How do I add a new value?',
              'Go to the Profile tab, tap "Edit Values", then use the form at the top to add a new value. You can have up to 5 active values.'
            ),
            
            _buildFaqItem(
              context,
              'How does the tug-of-war visualization work?',
              'The tug-of-war shows the tension between your stated importance (left side) and your actual behavior (right side). The knot in the middle will move based on how your time spent compares to community averages.'
            ),
            
            _buildFaqItem(
              context,
              'Can I edit an activity after logging it?',
              'Yes! On the Activities tab, tap on any activity to view details. From there, you can edit or delete the activity.'
            ),
            
            _buildFaqItem(
              context,
              'How is my data stored?',
              'Your data is stored securely in our database. We use Firebase for authentication and MongoDB for storing your values and activities. Your data is not shared with third parties.'
            ),
            
            _buildFaqItem(
              context,
              'What does the community average represent?',
              'The community average is simply the rating of importance (1 - 5) assigned to a value multiplied It provides a benchmark to help you understand how your behavior compares.'
            ),
            
            const SizedBox(height: 32),
            
            // Contact Support Section
            const Text(
              'Still Need Help?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? TugColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our team is here to help with any questions or issues you may have.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: TugButtons.primaryButtonStyle,
                      onPressed: () {
                        _launchUrl('mailto:jordangillispie@outlook.com?subject=Tug%20App%20Support%20Request');
                      },
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Email Support'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? TugColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                height: 1.5,
                color: isDarkMode
                    ? TugColors.darkTextPrimary
                    : TugColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}