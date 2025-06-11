// lib/widgets/email_signup_widget.dart
import 'package:flutter/material.dart';
import 'package:tug/services/email_service.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/utils/theme/colors.dart';

class EmailSignupWidget extends StatefulWidget {
  const EmailSignupWidget({super.key});

  @override
  State<EmailSignupWidget> createState() => _EmailSignupWidgetState();
}

class _EmailSignupWidgetState extends State<EmailSignupWidget> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailService = EmailService();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _subscriptionSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final success = await _emailService.saveEmail(email);

      if (success) {
        setState(() {
          _subscriptionSuccess = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to save email. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stay Updated',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to our newsletter for updates and early access.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            if (!_subscriptionSuccess) ...[
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'enter your email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: TugButtons.primaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('subscribe'),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: TugColors.error,
                  ),
                ),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Thanks for subscribing! We\'ll keep you updated.',
                        style: const TextStyle(
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}