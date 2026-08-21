import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';

import '../../domain/entities/customer_subscription.dart';
import '../cubit/customer_profile_cubit.dart';
import '../cubit/customer_profile_state.dart';
import 'customer_tab_scaffold.dart';
import 'customers_format.dart';

/// الاشتراكات — every package this customer has held with this office.
///
/// Current ones first, then history. Each card carries its own usage bar, but
/// **only when the usage can actually be computed**: a package with
/// `trips_count = 0` — three of which exist in the live data — has no
/// denominator, and a 0% bar would tell the owner the customer has used nothing
/// when the truth is that nothing is measurable.
class CustomerSubscriptionsTab extends StatelessWidget {
  const CustomerSubscriptionsTab({
    super.key,
    required this.state,
    required this.now,
  });

  final CustomerProfileLoadedState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerProfileCubit>();
    final subscriptions = state.subscriptions;

    return CustomerTabScaffold(
      status: state.subscriptionsStatus,
      onRetry: () => cubit.loadSubscriptions(force: true),
      loadingRows: 3,
      child: subscriptions.isEmpty
          ? const AppCard(
              child: DashboardEmptyState(
                icon: DashboardIcons.subscriptions,
                title: 'لا توجد اشتراكات',
                message: 'لم يشترِ هذا العميل أي باقة من المكتب حتى الآن.',
              ),
            )
          : Column(
              children: [
                for (final subscription in subscriptions) ...[
                  _SubscriptionCard(subscription: subscription, now: now),
                  const SizedBox(height: AppSpacing.small),
                ],
              ],
            ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription, required this.now});

  final CustomerSubscription subscription;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final tone = CustomersFormat.subscriptionTone(
      subscription.status,
      subscription.isCurrent,
      context,
    );
    final remaining = subscription.daysRemaining(now);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.packageName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (subscription.routeName != null)
                      Text(
                        subscription.routeName!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: DashboardColors.mutedInk(context),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tone.withAlpha(28),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  // A row still marked `active` past its end date is labelled
                  // as expired here, because that is what it is.
                  subscription.status == 'active' && !subscription.isCurrent
                      ? 'منتهي'
                      : CustomersFormat.subscriptionStatus(subscription.status),
                  style: TextStyle(
                    color: tone,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.large,
            runSpacing: AppSpacing.small,
            children: [
              _Fact(
                label: 'البداية',
                value: subscription.startDate == null
                    ? '—'
                    : CustomersFormat.date(subscription.startDate!),
              ),
              _Fact(
                label: 'النهاية',
                value: subscription.endDate == null
                    ? 'غير محدد'
                    : CustomersFormat.date(subscription.endDate!),
              ),
              _Fact(
                label: 'عدد الرحلات',
                value: subscription.tripsCount == 0
                    ? '—'
                    : CustomersFormat.count(subscription.tripsCount),
              ),
              _Fact(
                label: 'المستخدمة',
                value: CustomersFormat.count(subscription.tripsUsed),
              ),
              _Fact(
                label: 'المتبقية',
                value: subscription.tripsCount == 0
                    ? '—'
                    : CustomersFormat.count(subscription.tripsRemaining),
              ),
              _Fact(
                label: 'القيمة',
                value: CustomersFormat.money(subscription.totalPrice),
              ),
              if (subscription.remainingAmount > 0)
                _Fact(
                  label: 'متبقٍ للسداد',
                  value: CustomersFormat.money(subscription.remainingAmount),
                ),
              if (subscription.renewalsCount > 0)
                _Fact(
                  label: 'التجديدات',
                  value: CustomersFormat.count(subscription.renewalsCount),
                ),
              if (subscription.isCurrent && remaining != null && remaining >= 0)
                _Fact(label: 'ينتهي خلال', value: '$remaining يوم'),
            ],
          ),
          if (subscription.usageFraction != null) ...[
            const SizedBox(height: AppSpacing.medium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الاستخدام',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
                Text(
                  '${subscription.usagePercent!.toStringAsFixed(subscription.usagePercent! % 1 == 0 ? 0 : 1)}٪',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xSmall),
            AppProgressBar(progress: subscription.usageFraction!),
          ] else ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              'لا يمكن حساب نسبة الاستخدام: هذه الباقة لا تحدد عدد رحلات.',
              style: TextStyle(
                fontSize: 12,
                color: DashboardColors.faintInk(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: DashboardColors.mutedInk(context),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
