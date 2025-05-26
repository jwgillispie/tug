// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/buttons.dart';
import '../../widgets/common/tug_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _errorMessage = null);
      context.read<AuthBloc>().add(
            LoginEvent(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
        } else {
          setState(() => _isLoading = false);

          if (state is Authenticated) {
            // Show a success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hello beautiful'),
                backgroundColor: TugColors.success,
              ),
            );

            // Navigate directly to home page
            context.go('/home');
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'welcome back',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'sign in to continue',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: TugColors.lightTextSecondary,
                        ),
                  ),

                  // Error message display
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
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
                              style: TextStyle(
                                color: TugColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  TugTextField(
                    label: 'email',
                    hint: 'enter your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TugTextField(
                    label: 'password',
                    hint: 'enter your password',
                    controller: _passwordController,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'please enter your password';
                      }
                      if (value.length < 6) {
                        return 'password gotta be longer than that';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TugButtons.tertiaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                      onPressed: () {
                        context.go('/forgot-password');
                      },
                      child: const Text('forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: TugButtons.primaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                      onPressed: _isLoading ? null : _handleLogin,
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
                            : const Text('sign in'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'don\'t have an account?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        style: TugButtons.tertiaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                        onPressed: () => context.go('/signup'),
                        child: const Text('sign up'),
                      ),
                    ],
                  ),

                  // For development purposes - diagnostics link
                  // if (const bool.fromEnvironment('dart.vm.product') == false)
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 24),
                  //     child: Center(
                  //       child: TextButton.icon(
                  //         onPressed: () => context.go('/diagnostics'),
                  //         icon: const Icon(Icons.settings),
                  //         label: const Text('Diagnostics'),
                  //         style: TugButtons.tertiaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                  //       ),
                  //     ),
                  //   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
