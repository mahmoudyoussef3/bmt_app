import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Closing section of the details card: the problem as the client described it.
class TicketDetailsDescription extends StatelessWidget {
  const TicketDetailsDescription({super.key, required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.support_description,
            style: ClientTypography.headingSmall(
              context,
            ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: ClientTypography.bodyMedium(context).copyWith(
              color: scheme.onSurfaceVariant.withAlpha(220),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
