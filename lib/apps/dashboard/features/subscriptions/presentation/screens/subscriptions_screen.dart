import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/master_detail_layout.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../../plans/presentation/cubit/subscription_plans_cubit.dart';
import '../../plans/presentation/screens/subscription_plans_screen.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import '../widgets/create_subscription_sheet.dart';
import '../widgets/subscription_card.dart';
import '../widgets/subscription_details_panel.dart';
import '../widgets/subscription_formatting.dart';
import '../widgets/subscriptions_analytics.dart';
import '../widgets/subscriptions_toolbar.dart';
import '../widgets/trip_focus_panel.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

/// Dashboard → الاشتراكات.
///
/// Two modes over one dataset:
///   * no trip selected — the office's whole subscriber base, worked through
///     queue tabs (money to collect, renewals about to lapse).
///   * a trip selected — that departure's board: who is riding on it, on which
///     package, why they are entitled to, and what the office still needs to do
///     about them.
class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionsCubit, SubscriptionsState>(
      listenWhen: (previous, current) =>
          current is SubscriptionsLoaded &&
          (current.actionError != null || current.actionMessage != null),
      listener: (context, state) {
        if (state is! SubscriptionsLoaded) return;
        final messenger = ScaffoldMessenger.of(context);
        final error = state.actionError;
        final message = state.actionMessage;
        if (error != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: context.status(AppStatusTone.error).ink,
            ),
          );
        } else if (message != null) {
          messenger.showSnackBar(SnackBar(content: Text(message)));
        }
        context.read<SubscriptionsCubit>().clearActionFeedback();
      },
      builder: (context, state) => switch (state) {
        SubscriptionsInitial() ||
        SubscriptionsLoading() => const DashboardLoading(),
        SubscriptionsError(:final message) => DashboardErrorState(
          message: message,
          onRetry: () => context.read<SubscriptionsCubit>().load(),
        ),
        SubscriptionsLoaded() => _SubscriptionsWorkspace(state: state),
      },
    );
  }
}

void openPlansManagement(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => dashboardDi<SubscriptionPlansCubit>()..load(),
        child: const Scaffold(body: SubscriptionPlansScreen()),
      ),
    ),
  );
}

class _SubscriptionsWorkspace extends StatelessWidget {
  const _SubscriptionsWorkspace({required this.state});

  final SubscriptionsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionsCubit>();
    final selected = state.selected;

    final master = ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.subscriptionsActive,
          title: 'الاشتراكات',
          subtitle:
              'كل مشتركي المكتب — اختر رحلة لمعرفة من يركبها باشتراك وبأي باقة.',
          actions: [
            if (state.isProcessing)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.small),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            OutlinedButton.icon(
              onPressed: cubit.load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث'),
            ),
            OutlinedButton.icon(
              onPressed: () => openPlansManagement(context),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('إدارة الباقات'),
            ),
            FilledButton.icon(
              onPressed: () => openCreateSubscription(context, state),
              icon: const Icon(Icons.add_rounded),
              label: const Text('اشتراك جديد'),
            ),
          ],
          child: _OfficeKpis(state: state),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (state.tripBoard != null) ...[
          TripFocusPanel(
            board: state.tripBoard!,
            isProcessing: state.isProcessing,
          ),
          const SizedBox(height: AppSpacing.medium),
        ],
        SubscriptionsToolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        _ResultsHeader(state: state),
        const SizedBox(height: AppSpacing.small),
        ..._buildRows(context),
        if (state.tripBoard == null && state.subscriptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.large),
          SubscriptionsAnalytics(subscriptions: state.subscriptions),
        ],
      ],
    );

    return MasterDetailLayout(
      master: master,
      detail: selected == null
          ? null
          : SubscriptionDetailsPanel(
              subscription: selected,
              state: state,
              onClose: () => cubit.select(null),
            ),
      placeholderTitle: 'اختر مشتركًا لعرض تفاصيله',
      placeholderSubtitle:
          'تظهر هنا بيانات الاشتراك وسجل الرحلات المستهلكة وكل عمليات المكتب.',
    );
  }

  List<Widget> _buildRows(BuildContext context) {
    final cubit = context.read<SubscriptionsCubit>();

    if (state.filteredSubscriptions.isEmpty) {
      return [
        AppCard(
          padding: EdgeInsets.zero,
          child: EmptyState(
            emoji: state.filters.hasTrip ? '🚌' : '📭',
            title: state.filters.hasTrip
                ? 'لا يوجد مشتركون على هذه الرحلة'
                : 'لا توجد اشتراكات مطابقة',
            subtitle: state.filters.hasTrip
                ? 'لم يشترِ أحد باقة على هذه الرحلة، ولا يوجد اشتراك سارٍ على خط سيرها في هذا التاريخ.'
                : 'جرّب تغيير التبويب أو مسح الفلاتر.',
          ),
        ),
      ];
    }

    // On a trip board every row carries its link chip and check-in action; off
    // it, the same card without the trip-specific parts.
    if (state.tripBoard != null) {
      return [
        for (final subscriber in state.visibleTripSubscribers)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.medium),
            child: SubscriptionCard(
              subscription: subscriber.subscription,
              tripSubscriber: subscriber,
              tripId: state.filters.tripId,
              isProcessing: state.isProcessing,
              selected: state.selectedId == subscriber.subscription.id,
              onTap: () => cubit.loadDetails(subscriber.subscription.id),
            ),
          ),
      ];
    }

    return [
      for (final subscription in state.visibleSubscriptions)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.medium),
          child: SubscriptionCard(
            subscription: subscription,
            selected: state.selectedId == subscription.id,
            isProcessing: state.isProcessing,
            onTap: () => cubit.loadDetails(subscription.id),
          ),
        ),
    ];
  }
}

/// Office-wide numbers — always the whole book, never the filtered slice, so
/// they stay comparable as the operator moves between tabs and trips.
class _OfficeKpis extends StatelessWidget {
  const _OfficeKpis({required this.state});

  final SubscriptionsLoaded state;

  @override
  Widget build(BuildContext context) {
    return DashboardKpiGrid(
      children: [
        DashboardKpiCard(
          label: 'اشتراكات نشطة',
          value: arabicNumber(state.activeCount),
          detail: 'من ${arabicNumber(state.subscriptions.length)} إجمالي',
          icon: Icons.workspace_premium_outlined,
          color: context.status(AppStatusTone.success).ink,
        ),
        DashboardKpiCard(
          label: 'بانتظار الدفع',
          value: arabicNumber(state.pendingPaymentCount),
          icon: Icons.hourglass_top_outlined,
          color: context.status(AppStatusTone.warning).ink,
        ),
        DashboardKpiCard(
          label: 'ينتهي خلال أسبوع',
          value: arabicNumber(state.expiringSoonCount),
          detail: 'يحتاج تجديدًا',
          icon: Icons.event_repeat_outlined,
          color: context.status(AppStatusTone.warning).ink,
        ),
        DashboardKpiCard(
          label: 'محصّل',
          value: subscriptionMoney(state.collectedRevenue),
          detail: 'متبقٍ ${subscriptionMoney(state.outstandingRevenue)}',
          icon: Icons.savings_outlined,
        ),
      ],
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.state});

  final SubscriptionsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trip = state.selectedTrip;

    return Row(
      children: [
        Expanded(
          child: Text(
            trip == null
                ? 'قائمة المشتركين'
                : 'مشتركو رحلة ${arabicDigits(trip.code)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          '${arabicNumber(state.resultCount)} اشتراك',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
