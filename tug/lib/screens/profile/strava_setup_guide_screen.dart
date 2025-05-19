// lib/screens/profile/strava_setup_guide_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class StravaSetupGuideScreen extends StatelessWidget {
  const StravaSetupGuideScreen({Key? key}) : super(key: key);
  
  String _getCallbackDomain() {
    final redirectUri = dotenv.env['STRAVA_REDIRECT_URI'] ?? 'http://localhost';
    return redirectUri.contains('://') 
      ? redirectUri.split('://').last.split('/').first 
      : redirectUri;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strava API Setup Guide'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '1. Register a Strava API Application',
              content: [
                _buildStepText(
                  'Go to the Strava API settings page (link below)',
                ),
                _buildStepText(
                  'Fill in your application details:',
                ),
                _buildSubStepText('Application Name: Tug'),
                _buildSubStepText('Category: Fitness'),
                _buildSubStepText('Website: Your website or example.com'),
                _buildSubStepText('Authorization Callback Domain: localhost'),
                _buildSubStepText('Note: "localhost" is explicitly allowed by Strava for development'),
                _buildLinkButton(
                  context: context, 
                  isDark: isDarkMode,
                  url: 'https://www.strava.com/settings/api',
                  label: 'Open Strava API Settings',
                ),
              ],
            ),
            _buildDivider(),
            _buildSection(
              title: '2. Get Your API Credentials',
              content: [
                _buildStepText(
                  'After creating your application, Strava will provide:',
                ),
                _buildSubStepText('Client ID: A numerical identifier'),
                _buildSubStepText('Client Secret: A unique string'),
                _buildStepText(
                  'Copy these values and add them to your .env file:',
                ),
                _buildCodeBlock(
                  isDark: isDarkMode,
                  code: 'STRAVA_CLIENT_ID=your_client_id_here\n'
                      'STRAVA_CLIENT_SECRET=your_client_secret_here\n'
                      'STRAVA_REDIRECT_URI=http://localhost',
                ),
              ],
            ),
            _buildDivider(),
            _buildSection(
              title: '3. Configure Your App',
              content: [
                _buildStepText(
                  'Make sure your app is properly configured:',
                ),
                _buildSubStepText(
                  'Android: URL scheme set in AndroidManifest.xml',
                ),
                _buildSubStepText('iOS: URL scheme set in Info.plist'),
                _buildSubStepText(
                  'Reload the app after updating the .env file',
                ),
              ],
            ),
            _buildDivider(),
            _buildSection(
              title: '4. Test the Integration',
              content: [
                _buildStepText('Go to the Profile screen'),
                _buildStepText(
                  'Tap "Connect to Strava" in the Connected Accounts section',
                ),
                _buildStepText(
                  'You should be redirected to the Strava authorization page',
                ),
                _buildStepText(
                  'After authorizing, you\'ll be redirected back to the app',
                ),
              ],
            ),
            _buildDivider(),
            _buildSection(
              title: 'Troubleshooting',
              content: [
                _buildStepText(
                  'Redirect not working: Ensure callback domain is set to "localhost" in Strava settings',
                ),
                _buildStepText(
                  'Authentication errors: Double-check your credentials',
                ),
                _buildStepText(
                  'Rate limits: Strava allows 100 requests every 15 minutes and 1000 per day',
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...content,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStepText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.arrow_right,
            size: 20,
            color: TugColors.primaryPurple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStepText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(
              fontSize: 16,
              color: TugColors.primaryPurple,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock({required bool isDark, required String code}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: code.split('\n').map((line) {
              return Text(
                line,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
              );
            }).toList(),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.copy, size: 20),
              color: TugColors.primaryPurple,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(GlobalKey<ScaffoldState>()
                        .currentContext as BuildContext)
                    .showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton({
    required BuildContext context,
    required bool isDark,
    required String url,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.open_in_new),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: TugColors.primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onPressed: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not launch URL'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        color: Colors.grey.withOpacity(0.3),
        thickness: 1,
      ),
    );
  }
}