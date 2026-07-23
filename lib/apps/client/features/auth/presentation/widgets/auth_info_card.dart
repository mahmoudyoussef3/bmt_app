import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A tinted reassurance line inside an auth form: an accent icon beside a short
/// message. Deliberately lighter than a [ClientCard] — it is context for the
/// card next to it, not a card of its own.
class AuthInfoCard extends StatelessWidget {
  const AuthInfoCard({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClientSpacing.sm),
      decoration: BoxDecoration(
        color: ClientColors.primary.withAlpha(16),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: ClientColors.primary.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ClientColors.primaryFor(context)),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ),
        ],
      ),
    );
  }
}
