import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../../domain/entities/client_notification.dart';

class NotificationsCategoryBar extends StatelessWidget {
  const NotificationsCategoryBar({
    super.key,
    required this.active,
    required this.onSelect,
  });

  final NotificationCategory? active;
  final ValueChanged<NotificationCategory?> onSelect;

  static List<(NotificationCategory?, String)> _categories(AppLocalizations l10n) => [
    (null, l10n.notifications_categoryAll),
    (NotificationCategory.booking, l10n.notifications_categoryBooking),
    (NotificationCategory.payment, l10n.notifications_categoryPayment),
    (NotificationCategory.trip, l10n.notifications_categoryTrip),
    (NotificationCategory.announcement, l10n.notifications_categoryNews),
    (NotificationCategory.promotion, l10n.notifications_categoryOffers),
    (NotificationCategory.emergency, l10n.notifications_categoryAlerts),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = _categories(context.l10n);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: categories.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (cat, label) = categories[i];
          final selected = active == cat;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? cs.primary : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}
