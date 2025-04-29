// lib/screens/profile/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/utils/theme/buttons.dart';
import 'package:tug/widgets/common/tug_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleChangePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      
      if (user != null && email != null) {
        // Create a credential with email and current password
        final credential = EmailAuthProvider.credential(
          email: email,
          password: _currentPasswordController.text,
        );
        
        // Reauthenticate the user
        await user.reauthenticateWithCredential(credential);
        
        // Change the password
        await user.updatePassword(_newPasswordController.text);
        
        setState(() {
          _successMessage = 'Password changed successfully';
          _isLoading = false;
          
          // Clear form fields
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred while changing password';
      
      switch (e.code) {
        case 'wrong-password':
          message = 'Your current password is incorrect';
          break;
        case 'requires-recent-login':
          message = 'For security reasons, please log out and log back in before changing your password';
          break;
        case 'weak-password':
          message = 'The new password is too weak. Please choose a stronger password';
          break;
        default:
          message = 'Error: ${e.message}';
      }
      
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Your Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For security, please enter your current password before setting a new one',
                style: TextStyle(
                  color: TugColors.lightTextSecondary,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error message display
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TugColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: TugColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: TugColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Success message display
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TugColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: TugColors.success,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: TugColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Current Password Field
              TugTextField(
                label: 'Current Password',
                hint: 'Enter your current password',
                controller: _currentPasswordController,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // New Password Field
              TugTextField(
                label: 'New Password',
                hint: 'Enter your new password',
                controller: _newPasswordController,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Confirm New Password Field
              TugTextField(
                label: 'Confirm New Password',
                hint: 'Confirm your new password',
                controller: _confirmPasswordController,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: TugButtons.primaryButtonStyle,
                  onPressed: _isLoading ? null : _handleChangePassword,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Update Password'),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Password requirements note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Password Requirements:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• Minimum 6 characters'),
                    Text('• Use a mix of letters, numbers, and symbols for stronger security'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}