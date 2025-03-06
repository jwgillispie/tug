// lib/widgets/auth/email_verification_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../utils/theme/colors.dart';

class EmailVerificationBanner extends StatelessWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated && !state.emailVerified) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: TugColors.warning.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded, 
                  color: TugColors.warning
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please verify your email',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: TugColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Check your inbox for a verification link',
                        style: TextStyle(
                          color: TugColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(VerifyEmailEvent());
                  },
                  child: const Text('Resend'),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}