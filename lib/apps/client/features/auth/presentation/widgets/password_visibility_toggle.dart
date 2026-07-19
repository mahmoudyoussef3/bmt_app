import 'package:flutter/material.dart';

/// The show/hide-password suffix button used by [PremiumAuthTextField].
class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    super.key,
    required this.obscured,
    required this.isFocused,
    required this.onToggle,
  });

  final bool obscured;
  final bool isFocused;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      splashRadius: 22,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: isFocused
            ? scheme.primary
            : scheme.onSurfaceVariant.withValues(alpha: 0.65),
      ),
      onPressed: onToggle,
    );
  }
}
