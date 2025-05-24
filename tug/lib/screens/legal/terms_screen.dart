// lib/screens/legal/terms_screen.dart
import 'package:flutter/material.dart';
import '../../utils/theme/colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('terms of service'),
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
              'terms of service',
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
              'Welcome to Tug ("we," "our," or "us"). By downloading, accessing, or using our mobile application (the "App"), you agree to be bound by these Terms of Service ("Terms").',
            ),

            // Acceptance of Terms
            _buildSection(
              context,
              'acceptance of terms',
              'By registering for and/or using the App in any manner, you agree to these Terms and all other operating rules, policies, and procedures that may be published by us. If you do not agree to these Terms, you may not access or use the App.',
            ),

            // Changes to Terms
            _buildSection(
              context,
              'changes to terms',
              'We reserve the right to modify these Terms at any time. We will notify you of any changes by posting the new Terms on the App with a new effective date. Your continued use of the App after any such changes constitutes your acceptance of the new Terms.',
            ),

            // Account Registration
            _buildSection(
              context,
              'account registration',
              'To use certain features of the App, you must register for an account. You agree to provide accurate, current, and complete information during the registration process and to update such information to keep it accurate, current, and complete. You are responsible for safeguarding your password and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account.',
            ),

            // User Content
            _buildSection(
              context,
              'user content',
              'The App allows you to create and store content, including but not limited to personal values, activities, and related information ("User Content"). You retain all rights in your User Content. By providing User Content to the App, you grant us a worldwide, non-exclusive, royalty-free license to use, copy, modify, and display your User Content in connection with the operation of the App.',
            ),

            // Acceptable Use
            _buildSection(
              context,
              'acceptable use',
              'You agree not to use the App to:\n'
                  '• Violate any applicable law or regulation;\n'
                  '• Infringe the rights of any third party;\n'
                  '• Transmit any material that is harmful, threatening, abusive, harassing, tortious, defamatory, vulgar, obscene, or invasive of another\'s privacy;\n'
                  '• Transmit any viruses, malware, or other harmful code;\n'
                  '• Interfere with or disrupt the App or servers or networks connected to the App;\n'
                  '• Attempt to gain unauthorized access to any part of the App.',
            ),

            // Termination
            _buildSection(
              context,
              'termination',
              'We may terminate or suspend your access to the App immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach these Terms. Upon termination, your right to use the App will immediately cease.',
            ),

            // Disclaimer of Warranties
            _buildSection(
              context,
              'disclaimer of warranties',
              'THE APP IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. TO THE FULLEST EXTENT PERMISSIBLE UNDER APPLICABLE LAW, WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.',
            ),

            // Limitation of Liability
            _buildSection(
              context,
              'limitation of liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL WE BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING WITHOUT LIMITATION, LOSS OF PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES, RESULTING FROM YOUR ACCESS TO OR USE OF OR INABILITY TO ACCESS OR USE THE APP.',
            ),

            // Governing Law
            _buildSection(
              context,
              'governing law',
              'These Terms shall be governed by and construed in accordance with the laws of the United States, without regard to its conflict of law provisions.',
            ),

            // Contact Information
            _buildSection(
              context,
              'contact information',
              'If you have any questions about these Terms, please contact us at jordangillispie@outlook.com.',
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
