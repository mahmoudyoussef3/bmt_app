import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// Top bar for the daily booking wizard: back, title, step count and refresh.
class DailyBookingHeader extends StatelessWidget {
  const DailyBookingHeader({
    super.key,
    required this.step,
    required this.onBack,
    required this.onRefresh,
  });

  final int step;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(14),
        border: Border(bottom: BorderSide(color: Colors.black.withAlpha(15))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const DirectionalIcon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.booking_bookYourRide,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                context.l10n.booking_stepOf4(step),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            tooltip: context.l10n.tracking_refresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
