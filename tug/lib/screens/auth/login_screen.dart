// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/buttons.dart';
import '../../utils/theme/decorations.dart';
import '../../utils/quantum_effects.dart';
import '../../utils/loading_messages.dart';
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
  String _loadingMessage = '';

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
            _loadingMessage = LoadingMessages.getAuth();
          });
        } else {
          setState(() => _isLoading = false);

          if (state is Authenticated) {
            // Show a success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('hello beautiful'),
                backgroundColor: TugColors.success,
              ),
            );

            // Navigate directly to social page
            context.go('/social');
          } else if (state is AuthError) {
            // Handle authentication errors
            setState(() {
              _errorMessage = state.message;
            });
          }
        }
      },
      child: Scaffold(
        body: QuantumEffects.quantumParticleField(
          isDark: Theme.of(context).brightness == Brightness.dark,
          particleCount: 15,
          child: Container(
            decoration: TugDecorations.appBackground(
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  
                  // Enhanced welcome header with quantum effects
                  QuantumEffects.cosmicBreath(
                    intensity: 0.08,
                    child: QuantumEffects.gradientText(
                      'welcome back',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ) ?? const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      colors: [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark],
                    ),
                  ),
                  const SizedBox(height: 12),
                  QuantumEffects.floating(
                    offset: 3,
                    child: Text(
                      'sign in to continue',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? TugColors.darkTextSecondary
                            : TugColors.lightTextSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // Enhanced error message display
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    QuantumEffects.quantumBorder(
                      glowColor: TugColors.error,
                      intensity: 0.6,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              TugColors.error.withValues(alpha: 0.1),
                              TugColors.error.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: TugColors.error.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            QuantumEffects.cosmicBreath(
                              intensity: 0.1,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      TugColors.error.withValues(alpha: 0.3),
                                      TugColors.error.withValues(alpha: 0.1),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.error_outline,
                                  color: TugColors.error,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: TugColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                  const SizedBox(height: 32),
                  
                  // Enhanced login button with premium styling
                  QuantumEffects.floating(
                    offset: 2,
                    child: Container(
                      width: double.infinity,
                      decoration: TugDecorations.premiumButtonDecoration(
                        isDark: Theme.of(context).brightness == Brightness.dark,
                        isViceMode: false,
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  QuantumEffects.holographicShimmer(
                                    child: const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      _loadingMessage,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'sign in',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
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
    ),
      ),
    );
  }
}
