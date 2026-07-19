import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// The start-aligned "Forgot password?" link on the sign-in form.
class ForgotPasswordLink extends StatelessWidget {
  const ForgotPasswordLink({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.help_outline_rounded, size: 18),
        label: Text(context.l10n.auth_forgotPassword),
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
