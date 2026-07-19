import 'package:flutter/material.dart';

/// The header block inside [PremiumAuthScaffold]: an optional logo above the
/// screen title and an optional supporting subtitle.
class AuthScaffoldHeader extends StatelessWidget {
  const AuthScaffoldHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.logo,
  });

  final String title;
  final String? subtitle;
  final Widget? logo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (logo != null) ...[logo!, const SizedBox(height: 24)],
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
