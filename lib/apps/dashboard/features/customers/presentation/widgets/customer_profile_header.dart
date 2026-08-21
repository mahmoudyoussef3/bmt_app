import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/avatar.dart';

import '../../domain/entities/customer_insight.dart';
import '../../domain/entities/customer_profile.dart';
import 'customers_format.dart';

/// Who this customer is, and what the office should know before reading further.
///
/// Identity on the start side, the ملخص العميل chips beneath it. The chips are
/// deterministic sentences derived from the metrics on the same page — never a
/// score, never a prediction — so anything they claim can be checked against
/// the tab it came from.
class CustomerProfileHeader extends StatelessWidget {
  const CustomerProfileHeader({
    super.key,
    required this.profile,
    required this.now,
    required this.onOpenTab,
  });

  final CustomerProfile profile;
  final DateTime now;

  /// The quick actions jump to a tab of this same workspace rather than
  /// navigating away — every one of them is a section of this page, and sending
  /// the operator to الحجوزات to re-find the person they already have open is
  /// the round trip this module exists to delete.
  final void Function(int tabIndex) onOpenTab;

  @override
  Widget build(BuildContext context) {
    final client = profile.client;
    final insights = CustomerInsights.of(profile, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final identity = _Identity(client: client);
            final actions = _QuickActions(onOpenTab: onOpenTab);

            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  identity,
                  const SizedBox(height: AppSpacing.medium),
                  actions,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: identity),
                const SizedBox(width: AppSpacing.medium),
                // Flexible so the actions Wrap gets a bounded width and wraps
                // onto a second line. Unbounded, three buttons at 1.6× text
                // scale are wider than the row above the stacking breakpoint.
                Flexible(child: actions),
              ],
            );
          },
        ),
        if (insights.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          _InsightChips(insights: insights),
        ],
      ],
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.client});

  final CustomerIdentity client;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(initials: client.initials, radius: 28),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.fullName,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Wrap(
                spacing: AppSpacing.medium,
                runSpacing: AppSpacing.xSmall,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Meta(icon: Icons.phone_outlined, value: client.phone),
                  if (client.email != null)
                    _Meta(
                      icon: Icons.alternate_email_rounded,
                      value: client.email!,
                    ),
                  _Meta(
                    icon: Icons.badge_outlined,
                    value: 'رقم العميل: ${client.shortId}',
                  ),
                  _Meta(
                    icon: DashboardIcons.time,
                    value: 'مسجّل منذ ${CustomersFormat.date(client.joinedAt)}',
                  ),
                  _StatusBadge(status: client.status),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = DashboardColors.mutedInk(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: muted),
        const SizedBox(width: AppSpacing.xSmall),
        // Flexible, not a bare Text: the Wrap hands each item a bounded width,
        // and a long email at 1.6× text scale overflows it otherwise.
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: muted, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = status == 'active'
        ? scheme.primary
        : DashboardColors.mutedInk(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        CustomersFormat.clientStatus(status),
        style: TextStyle(
          color: tone,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Three shortcuts into this workspace's own tabs.
///
/// Nothing here changes business state. Approving a payment, adjusting a wallet
/// and deciding a refund all have audited homes in الحجوزات and محفظة العملاء
/// with their own guards; a second button into the same RPCs would be a second
/// set of preconditions to keep in step, and this module is a read surface.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenTab});

  final void Function(int tabIndex) onOpenTab;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.xSmall,
      children: [
        OutlinedButton.icon(
          onPressed: () => onOpenTab(1),
          icon: const Icon(DashboardIcons.bookings, size: 18),
          label: const Text('عرض الرحلات'),
        ),
        OutlinedButton.icon(
          onPressed: () => onOpenTab(2),
          icon: const Icon(DashboardIcons.subscriptions, size: 18),
          label: const Text('عرض الاشتراكات'),
        ),
        OutlinedButton.icon(
          onPressed: () => onOpenTab(3),
          icon: const Icon(DashboardIcons.payments, size: 18),
          label: const Text('عرض المدفوعات'),
        ),
      ],
    );
  }
}

class _InsightChips extends StatelessWidget {
  const _InsightChips({required this.insights});

  final List<CustomerInsight> insights;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.xSmall,
      children: [
        for (final insight in insights)
          _Chip(
            label: insight.label,
            tone: CustomersFormat.insightTone(insight.tone, context),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tone,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
