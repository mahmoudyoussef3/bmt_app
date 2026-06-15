import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../cubit/tickets_state.dart';
import 'tickets_shared_widgets.dart';

class SummaryStats extends StatelessWidget {
  final TicketsLoaded state;
  const SummaryStats({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'New Tickets',
            value: state.newCount,
            color: Colors.blue,
            icon: Icons.mark_email_unread_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: StatCard(
            title: 'Under Review',
            value: state.underReviewCount,
            color: Colors.orange,
            icon: Icons.pending_actions_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: StatCard(
            title: 'Resolved',
            value: state.resolvedCount,
            color: Colors.green,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: StatCard(
            title: 'Delayed (>24h)',
            value: state.delayedCount,
            color: Colors.red,
            icon: Icons.running_with_errors_outlined,
            isAlert: state.delayedCount > 0,
          ),
        ),
      ],
    );
  }
}
