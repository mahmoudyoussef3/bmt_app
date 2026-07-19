import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../support_ticket_labels.dart';

/// The two metadata pieces under a ticket's title: what it is about, and when
/// it was filed.
class TicketCategoryChip extends StatelessWidget {
  const TicketCategoryChip({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_rounded,
            size: 14,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            supportCategoryLabel(context, category),
            style: ClientTypography.labelMedium(context).copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TicketCreatedAtLabel extends StatelessWidget {
  const TicketCreatedAtLabel({super.key, required this.createdAt});

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          DateFormat(
            'MMM dd, yyyy',
            Localizations.localeOf(context).toString(),
          ).format(createdAt),
          style: ClientTypography.labelMedium(context).copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
