import 'package:flutter/material.dart';

/// A small, muted, centered helper note shown at the foot of an auth form.
class AuthSecurityNote extends StatelessWidget {
  const AuthSecurityNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        height: 1.55,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
