import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// The large confirmation card on the forgot-password success view: a mail icon
/// above the address the reset link was sent to.
class ForgotPasswordSuccessMailCard extends StatelessWidget {
  const ForgotPasswordSuccessMailCard({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.165)),
      ),
      child: Column(
        children: [
          Container(
            height: 86,
            width: 86,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.086),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 42,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.auth_recoveryLinkSent,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.auth_openEmailToReset,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.55,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
