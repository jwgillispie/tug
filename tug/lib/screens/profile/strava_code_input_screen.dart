// lib/screens/profile/strava_code_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/services/strava_service.dart';
import 'package:tug/utils/theme/colors.dart';

class StravaCodeInputScreen extends StatefulWidget {
  const StravaCodeInputScreen({Key? key}) : super(key: key);

  @override
  State<StravaCodeInputScreen> createState() => _StravaCodeInputScreenState();
}

class _StravaCodeInputScreenState extends State<StravaCodeInputScreen> {
  final TextEditingController _codeController = TextEditingController();
  final StravaService _stravaService = StravaService();
  bool _isProcessing = false;
  String _status = '';
  bool _isSuccess = false;
  
  // Method to show detailed help for finding the authorization code
  void _showHelpDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Find Your Authorization Code'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 1: Go to the Strava Authorization Page',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'If you haven\'t already, tap the "Connect with Strava" button to open the authorization page.',
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Step 2: Authorize the App',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Click "Authorize" on the Strava website to grant access to your account.',
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Step 3: Find the Code in the URL',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'After authorizing, you\'ll be redirected to a page that might show an error. Look at the URL in your browser\'s address bar.',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black26 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The URL will look like:',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'http://localhost/?state=&code=d152fd1ac1bddbe6e819d5c31386d8293fdb65b9&scope=read,activity:read',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Step 4: Copy the Code',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Copy the part of the URL that follows "code=" and ends before the next "&" character. This is your authorization code.',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TugColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TugColors.primaryPurple.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Example code:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'd152fd1ac1bddbe6e819d5c31386d8293fdb65b9',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: TugColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Step 5: Paste the Code',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste the code into the input field and tap "Connect to Strava".',
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Troubleshooting Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• If the page says "Cannot open page" or similar, that\'s normal. Look at the URL.\n'
                '• Make sure you copy only the code portion, not the entire URL.\n'
                '• Try tapping the "paste" button next to the input field - it will extract the code automatically.\n'
                '• If you can\'t see the full URL, try sharing the page or copying the link.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleCodeInput() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _status = 'Please enter a valid authorization code';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = 'Processing authorization code...';
    });

    try {
      // Call a new method we'll add to StravaService
      final result = await _stravaService.handleManualCode(code);
      
      setState(() {
        _isProcessing = false;
        _isSuccess = result.success;
        _status = result.success 
            ? 'Successfully connected to Strava!' 
            : 'Error: ${result.errorMessage ?? "Failed to connect"}';
      });

      if (result.success) {
        // Wait a bit before returning to the previous screen
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.pop(true); // Return success
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Strava Authorization Code'),
        actions: [
          // Add help button
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How to find the code',
            onPressed: () => _showHelpDialog(context, isDarkMode),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            const Text(
              'After authorizing in the Strava website, you\'ll be redirected to a URL. The authorization appears in the URL as a "code" parameter:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black26 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example URL:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'http://localhost/?state=&code=d152fd1ac1bddbe6e819d5c31386d8293fdb65b9&scope=read,activity:read',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The code you need to copy is highlighted here:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'http://localhost/?state=&code=',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    'd152fd1ac1bddbe6e819d5c31386d8293fdb65b9',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: TugColors.primaryPurple,
                      fontWeight: FontWeight.bold,
                      backgroundColor: isDarkMode ? Colors.black26 : Colors.grey.shade200,
                    ),
                  ),
                  Text(
                    '&scope=read,activity:read',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Copy the value after "code=" and before "&scope" and paste it below:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Code input field
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Authorization Code',
                hintText: 'e.g. 7a3eacdb63bfcd437298992262baa24b',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data != null && data.text != null) {
                      // Clean up the pasted text to extract just the code
                      String text = data.text!.trim();
                      debugPrint('Pasted text: $text');
                      
                      if (text.contains('code=')) {
                        // Extract just the code param value
                        final regex = RegExp(r'code=([^&]+)');
                        final match = regex.firstMatch(text);
                        if (match != null && match.groupCount >= 1) {
                          text = match.group(1) ?? text;
                          debugPrint('Extracted code: $text');
                        }
                      } else if (text.contains('localhost') || text.contains('tug://')) {
                        // Handle full URLs
                        try {
                          final uri = Uri.parse(text);
                          final code = uri.queryParameters['code'];
                          if (code != null) {
                            text = code;
                            debugPrint('Extracted code from URI: $text');
                          }
                        } catch (e) {
                          debugPrint('Failed to parse URI: $e');
                          // Keep original text if parsing fails
                        }
                      }
                      
                      // Remove any whitespace
                      text = text.trim();
                      _codeController.text = text;
                    }
                  },
                ),
              ),
              maxLines: 1,
              onSubmitted: (_) => _handleCodeInput(),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleCodeInput,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TugColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Connect to Strava',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Status message
            if (_status.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}