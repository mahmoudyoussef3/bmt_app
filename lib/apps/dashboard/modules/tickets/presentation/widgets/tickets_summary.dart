import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/colors.dart';
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
            title: 'تذاكر جديدة',
            value: state.newCount,
            color: AppStatusColors.onInfoContainer,
            icon: Icons.mark_email_unread_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: StatCard(
            title: 'قيد المراجعة',
            value: state.underReviewCount,
            color: AppStatusColors.onWarningContainer,
            icon: Icons.pending_actions_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: StatCard(
            title: 'تم الحل',
            value: state.resolvedCount,
            color: AppStatusColors.onSuccessContainer,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: StatCard(
            title: 'متأخرة (>24 ساعة)',
            value: state.delayedCount,
            color: AppStatusColors.onErrorContainer,
            icon: Icons.running_with_errors_outlined,
            isAlert: state.delayedCount > 0,
          ),
        ),
      ],
    );
  }
}
