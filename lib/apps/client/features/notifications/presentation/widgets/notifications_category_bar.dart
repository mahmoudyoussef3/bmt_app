import 'package:flutter/material.dart';

import '../../domain/entities/client_notification.dart';

class NotificationsCategoryBar extends StatelessWidget {
  const NotificationsCategoryBar({
    super.key,
    required this.active,
    required this.onSelect,
  });

  final NotificationCategory? active;
  final ValueChanged<NotificationCategory?> onSelect;

  static const _categories = [
    (null, 'All'),
    (NotificationCategory.booking, 'Booking'),
    (NotificationCategory.payment, 'Payment'),
    (NotificationCategory.trip, 'Trip'),
    (NotificationCategory.announcement, 'News'),
    (NotificationCategory.promotion, 'Offers'),
    (NotificationCategory.emergency, 'Alerts'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _categories.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (cat, label) = _categories[i];
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
