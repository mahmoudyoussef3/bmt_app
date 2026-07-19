import 'package:flutter/material.dart';

import 'auth_error_banner.dart';
import 'auth_info_card.dart';

/// The shared top of an auth form: an inline error banner (collapsed when
/// [error] is null) above the reassurance [AuthInfoCard], with the spacing that
/// separates the header from the fields below.
class AuthFormHeader extends StatelessWidget {
  const AuthFormHeader({
    super.key,
    required this.error,
    required this.onDismissError,
    required this.infoIcon,
    required this.infoText,
  });

  final String? error;
  final VoidCallback onDismissError;
  final IconData infoIcon;
  final String infoText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthErrorBanner(message: error, onDismiss: onDismissError),
        AuthInfoCard(icon: infoIcon, text: infoText),
        const SizedBox(height: 18),
      ],
    );
  }
}
