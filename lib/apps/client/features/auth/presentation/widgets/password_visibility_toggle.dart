import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// The show/hide-password suffix button used by [AuthTextField].
class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    super.key,
    required this.obscured,
    required this.onToggle,
  });

  final bool obscured;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: ClientColors.textTertiaryFor(context),
      ),
      onPressed: onToggle,
    );
  }
}
