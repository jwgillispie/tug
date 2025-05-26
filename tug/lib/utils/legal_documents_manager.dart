// lib/utils/legal_documents_manager.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// A utility class to manage and provide access to legal documents throughout the app
class LegalDocumentsManager {
  // Singleton pattern
  static final LegalDocumentsManager _instance =
      LegalDocumentsManager._internal();
  factory LegalDocumentsManager() => _instance;
  LegalDocumentsManager._internal();

  // App version
  static const String appVersion = '2.0.0';

  // Document version dates
  static const String termsVersion = '2025-04-01';
  static const String privacyVersion = '2025-04-01';

  // Contact email addresses
  static const String supportEmail = 'jordangillispie@outlook.com';
  static const String privacyEmail = 'jordangillispie@outlookcom';

  // Web URLs for the documents (if you have a website)
  static const String termsUrl = 'https://www.tugapp.example.com/terms';
  static const String privacyUrl = 'https://www.tugapp.example.com/privacy';

  /// Navigate to the Terms of Service screen
  void showTerms(BuildContext context) {
    context.push('/terms');
  }

  /// Navigate to the Privacy Policy screen
  void showPrivacy(BuildContext context) {
    context.push('/privacy');
  }

  /// Open email client to contact support
  Future<void> contactSupport() async {
    final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: supportEmail,
        queryParameters: {'subject': 'Tug App Support Request (v$appVersion)'});

    await _launchUrl(emailLaunchUri.toString());
  }

  /// Open email client for privacy inquiries
  Future<void> contactPrivacy() async {
    final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: privacyEmail,
        queryParameters: {'subject': 'Tug App Privacy Inquiry (v$appVersion)'});

    await _launchUrl(emailLaunchUri.toString());
  }

  /// Open web browser to view online terms
  Future<void> viewOnlineTerms() async {
    await _launchUrl(termsUrl);
  }

  /// Open web browser to view online privacy policy
  Future<void> viewOnlinePrivacy() async {
    await _launchUrl(privacyUrl);
  }

  /// Helper method to launch URLs
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  /// Show terms acceptance dialog and return whether user accepted
  Future<bool> showTermsAcceptanceDialog(BuildContext context) async {
    bool accepted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms & Privacy'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Before you continue, please review and accept our Terms of Service and Privacy Policy.',
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => showTerms(context),
                      child: const Text('Terms of Service'),
                    ),
                    TextButton(
                      onPressed: () => showPrivacy(context),
                      child: const Text('Privacy Policy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Decline'),
            ),
            ElevatedButton(
              onPressed: () {
                accepted = true;
                Navigator.of(context).pop();
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );

    return accepted;
  }
}
