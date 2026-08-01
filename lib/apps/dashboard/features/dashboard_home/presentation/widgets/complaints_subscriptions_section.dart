import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// Two curated "needs follow-up" queues, same visual family as the trips
/// panel: open complaints (most urgent first) and subscriptions either
/// awaiting payment or running out soonest.
class ComplaintsSubscriptionsSection extends StatelessWidget {
  const ComplaintsSubscriptionsSection({
    super.key,
    required this.summary,
    required this.onOpenModule,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final complaintsPanel = _complaintsPanel();
    final subscriptionsPanel = _subscriptionsPanel();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 780) {
          return Column(
            children: [
              complaintsPanel,
              const SizedBox(height: AppSpacing.medium),
              subscriptionsPanel,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: complaintsPanel),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: subscriptionsPanel),
          ],
        );
      },
    );
  }

  Widget _complaintsPanel() {
    final complaints = summary.openComplaints();
    return DashboardPanel(
      icon: Icons.support_agent_rounded,
      title: 'الشكاوى المفتوحة',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.tickets),
        child: const Text('عرض الكل'),
      ),
      child: complaints.isEmpty
          ? const EmptyState(emoji: '🎉', title: 'لا شكاوى مفتوحة حالياً')
          : Column(
              children: [
                for (final ticket in complaints) _ComplaintRow(ticket: ticket),
              ],
            ),
    );
  }

  Widget _subscriptionsPanel() {
    final subscriptions = summary.subscriptionsNeedingFollowUp();
    return DashboardPanel(
      icon: Icons.workspace_premium_rounded,
      title: 'الاشتراكات تحتاج متابعة',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.subscriptions),
        child: const Text('عرض الكل'),
      ),
      child: subscriptions.isEmpty
          ? const EmptyState(emoji: '👍', title: 'لا اشتراكات بحاجة لمتابعة')
          : Column(
              children: [
                for (final subscription in subscriptions)
                  _SubscriptionRow(subscription: subscription),
              ],
            ),
    );
  }
}

class _ComplaintRow extends StatelessWidget {
  const _ComplaintRow({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final urgent =
        ticket.priority == TicketPriority.urgent ||
        ticket.priority == TicketPriority.high;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title.isEmpty ? ticket.category : ticket.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  ticket.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          StatusChip(
            label: ticket.status.label,
            color: urgent ? const Color(0x1AD64545) : null,
            textColor: urgent ? const Color(0xFFD64545) : null,
          ),
        ],
      ),
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  const _SubscriptionRow({required this.subscription});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final pendingPayment =
        subscription.status == SubscriptionStatus.pendingPayment;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subscription.routeLabel.isEmpty
                      ? subscription.packageName
                      : subscription.routeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          StatusChip(
            label: pendingPayment
                ? subscription.status.label
                : '${subscription.remainingDays} يوم متبقي',
            color: pendingPayment ? const Color(0x1AF5A623) : null,
            textColor: pendingPayment ? const Color(0xFFF5A623) : null,
          ),
        ],
      ),
    );
  }
}
