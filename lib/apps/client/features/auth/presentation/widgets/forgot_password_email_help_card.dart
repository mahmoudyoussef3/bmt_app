import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// A muted "can't find the email?" hint shown beneath the resend controls.
class ForgotPasswordEmailHelpCard extends StatelessWidget {
  const ForgotPasswordEmailHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.275),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.176)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: scheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.auth_emailHelp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.55,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
