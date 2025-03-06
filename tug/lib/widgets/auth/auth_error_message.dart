// lib/widgets/auth/auth_error_message.dart
import 'package:flutter/material.dart';
import '../../utils/theme/colors.dart';

class AuthErrorMessage extends StatelessWidget {
  final String message;
  
  const AuthErrorMessage({super.key, required this.message});
  
  @override
  Widget build(BuildContext context) {
    return Container(
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
              message,
              style: TextStyle(
                color: TugColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}