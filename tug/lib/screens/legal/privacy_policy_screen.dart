// lib/screens/legal/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import '../../utils/theme/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('privacy policy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'privacy policy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'last updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-01',
              style: TextStyle(
                color: isDarkMode
                    ? TugColors.darkTextSecondary
                    : TugColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              context,
              'introduction',
              'At Tug, we take your privacy seriously. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (the "App"). Please read this Privacy Policy carefully. By using the App, you consent to the practices described in this Privacy Policy.',
            ),

            // Information We Collect
            _buildSection(
              context,
              'information we collect',
              'We may collect several types of information from and about users of our App, including:\n\n'
                  '• Personal Identifiers: Email address and authentication information when you register for an account.\n'
                  '• User Content: Information you provide in the App, such as your personal values, activities, and related notes.\n'
                  '• Usage Data: Information about how you use the App, including time spent in the App, features used, and other diagnostic data.\n'
                  '• Device Information: Information about your mobile device, including device type, operating system, and unique device identifiers.',
            ),

            // How We Use Your Information
            _buildSection(
              context,
              'how we use your information',
              'We use the information we collect to:\n\n'
                  '• Provide, maintain, and improve the App;\n'
                  '• Process and complete transactions;\n'
                  '• Send you technical notices, updates, security alerts, and support messages;\n'
                  '• Respond to your comments, questions, and requests;\n'
                  '• Monitor and analyze trends, usage, and activities in connection with the App;\n'
                  '• Detect, investigate, and prevent fraudulent transactions and other illegal activities;\n'
                  '• Personalize your experience by providing content and features that match your profile and interests.',
            ),

            // Sharing of Information
            _buildSection(
              context,
              'sharing of information',
              'We may share information we collect as follows:\n\n'
                  '• With service providers who perform services on our behalf;\n'
                  '• To comply with legal obligations;\n'
                  '• To protect and defend our rights and property;\n'
                  '• With your consent or at your direction.\n\n'
                  'We do not sell your personal information to third parties.',
            ),

            // Data Security
            _buildSection(
              context,
              'data security',
              'We implement appropriate technical and organizational measures to protect the security of your personal information. However, please be aware that no method of transmission over the Internet or method of electronic storage is 100% secure.',
            ),

            // Data Retention
            _buildSection(
              context,
              'data retention',
              'We will retain your personal information only for as long as reasonably necessary to fulfill the purposes for which it was collected, including for the purposes of satisfying any legal, regulatory, tax, accounting, or reporting requirements.',
            ),

            // Children's Privacy
            _buildSection(
              context,
              'children\'s privacy',
              'The App is not intended for children under the age of 13, and we do not knowingly collect personal information from children under 13. If we learn we have collected or received personal information from a child under 13, we will delete that information.',
            ),

            // Your Rights
            _buildSection(
              context,
              'your rights',
              'Depending on your location, you may have certain rights regarding your personal information, including:\n\n'
                  '• Access: You can request access to your personal information.\n'
                  '• Correction: You can request that we correct inaccurate or incomplete information.\n'
                  '• Deletion: You can request that we delete your personal information.\n'
                  '• Restriction: You can request that we restrict the processing of your information.\n'
                  '• Data Portability: You can request a copy of your information in a structured, commonly used, and machine-readable format.\n\n'
                  'To exercise these rights, please contact us at jordangillispie@outlook.com.',
            ),

            // Changes to this Privacy Policy
            _buildSection(
              context,
              'changes to this privacy policy',
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
            ),

            // Contact Information
            _buildSection(
              context,
              'contact information',
              'If you have any questions about this Privacy Policy, please contact us at jordangillispie@outlook.com.',
            ),

            // Last section padding
            const SizedBox(height: 32),
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
