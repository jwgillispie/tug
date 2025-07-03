// lib/screens/auth/signup_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../utils/theme/buttons.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/decorations.dart';
import '../../utils/quantum_effects.dart';
import '../../utils/loading_messages.dart';
import '../../widgets/common/tug_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _loadingMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('\$5 if you read this'),
          backgroundColor: TugColors.error,
        ),
      );
      return;
    }

    setState(() => _errorMessage = null);

    // Use BLoC for signup
    context.read<AuthBloc>().add(
          SignUpEvent(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('yayyyyyyyyyyyyyyy'),
                backgroundColor: TugColors.success,
              ),
            );
            context.go('/home');
          } else if (state is AuthError) {
            setState(() => _errorMessage = state.message);
          } else if (state is EmailVerificationSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('verification email sent. please check your inbox.'),
                backgroundColor: TugColors.success,
              ),
            );
          }
        }
      },
      child: Scaffold(
        body: QuantumEffects.quantumParticleField(
          isDark: Theme.of(context).brightness == Brightness.dark,
          particleCount: 20,
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
                  
                  // Enhanced header with quantum effects
                  QuantumEffects.cosmicBreath(
                    intensity: 0.08,
                    child: QuantumEffects.gradientText(
                      'create account',
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
                      'start tugging them values',
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
                    label: 'full name',
                    hint: 'enter your full name',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'please enter your name';
                      }
                      if (value.length < 2) {
                        return 'your name is 1 letter fr?';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TugTextField(
                    label: 'email',
                    hint: 'enter your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'try again, that email fake';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TugTextField(
                    label: 'password',
                    hint: 'create a password',
                    controller: _passwordController,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'please enter a password';
                      }
                      if (value.length < 6) {
                        return 'password must be longer than that';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TugTextField(
                    label: 'can you do that one more time please :)',
                    hint: 'confirm your password',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'one more time please!';
                      }
                      if (value != _passwordController.text) {
                        return 'passwords aren\'t twinning';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Enhanced terms agreement section
                  QuantumEffects.glassContainer(
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    blur: 10,
                    opacity: 0.1,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          QuantumEffects.quantumBorder(
                            glowColor: TugColors.primaryPurple,
                            intensity: _acceptedTerms ? 0.8 : 0.3,
                            child: Container(
                              height: 24,
                              width: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: _acceptedTerms
                                    ? LinearGradient(
                                        colors: [TugColors.primaryPurple, TugColors.primaryPurpleLight],
                                      )
                                    : null,
                                border: Border.all(
                                  color: TugColors.primaryPurple.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _acceptedTerms = !_acceptedTerms;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: _acceptedTerms
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'i agree to the ',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? TugColors.darkTextSecondary
                                      : TugColors.lightTextSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'terms of service',
                                    style: TextStyle(
                                      color: TugColors.primaryPurple,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        context.push('/terms');
                                      },
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'privacy policy',
                                    style: TextStyle(
                                      color: TugColors.primaryPurple,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        context.push('/privacy');
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Enhanced create account button with premium styling
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
                        onPressed: _isLoading ? null : _handleSignUp,
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
                                'create account',
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
                        'already have an account?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        style: TugButtons.tertiaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                        onPressed: () => context.go('/login'),
                        child: const Text('sign in'),
                      ),
                    ],
                  ),
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
