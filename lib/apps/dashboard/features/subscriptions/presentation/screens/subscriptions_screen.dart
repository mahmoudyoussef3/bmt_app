import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
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
import '../widgets/subscription_details_sheet.dart';
import '../widgets/subscription_formatting.dart';
import '../widgets/subscriptions_analytics.dart';
import '../widgets/subscriptions_toolbar.dart';
import '../widgets/trip_focus_panel.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_cap_notice.dart';

/// Dashboard → الاشتراكات.
///
/// Two modes over one dataset:
///   * no trip selected — the office's whole subscriber base, worked through
///     queue tabs (money to collect, renewals about to lapse).
///   * a trip selected — that departure's board: who is riding on it, on which
///     package, why they are entitled to, and what the office still needs to do
///     about them.
///
/// Both modes render across the **whole page width**, like every other module.
/// The subscriber file used to hold a permanent detail pane beside the list:
/// empty most of the day, and the rest of the time it left the board a single
/// narrow column of cards. It now opens as a sheet over the board instead
/// ([openSubscriptionDetails]).
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
          final tone = context.status(AppStatusTone.error);
          messenger.showSnackBar(
            SnackBar(
              content: Text(error, style: TextStyle(color: tone.onFill)),
              backgroundColor: tone.fill,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        final padding = isCompact ? AppSpacing.medium : AppSpacing.large;

        return ListView(
          padding: EdgeInsets.all(padding),
          children: _content(
            context,
            boardWidth: constraints.maxWidth - padding * 2,
          ),
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, {required double boardWidth}) {
    final cubit = context.read<SubscriptionsCubit>();

    return [
      DashboardModuleHeader(
        icon: DashboardIcons.subscriptionsActive,
        title: 'الاشتراكات',
        subtitle:
            'كل مشتركي المكتب — اختر رحلة لمعرفة من يركبها باشتراك وبأي باقة.',
        actions: [
          if (state.capReached)
            const DashboardCapNotice(
              rowCap: DashboardQueryCaps.subscriptions,
              noun: 'اشتراك',
              hint: 'ضيّق الفلاتر للوصول لاشتراكات أقدم.',
            ),
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
        sectionId: DashboardSectionIds.subscriptionsHeader,
        summary: _OfficeKpis(state: state),
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
      _SubscriberBoard(state: state, width: boardWidth),
      if (state.tripBoard == null && state.subscriptions.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.large),
        SubscriptionsAnalytics(subscriptions: state.subscriptions),
      ],
    ];
  }
}

/// The subscriber list as a card grid that uses the whole page.
///
/// One column per ~500px: a subscriber card carries a name, a package, a route,
/// a validity window and a money block, and stretching that across a 2000px
/// screen leaves the reader's eye travelling between two facts that belong
/// together.
class _SubscriberBoard extends StatelessWidget {
  const _SubscriberBoard({required this.state, required this.width});

  final SubscriptionsLoaded state;
  final double width;

  static int columnsFor(double width) {
    if (width >= 1560) return 3;
    if (width >= 940) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (state.filteredSubscriptions.isEmpty) return _EmptyBoard(state: state);

    final cards = _cards(context);
    final columns = columnsFor(width);
    final rows = <List<Widget>>[
      for (var index = 0; index < cards.length; index += columns)
        cards.skip(index).take(columns).toList(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.medium),
          // One IntrinsicHeight row per set of neighbours squares them off; a
          // Wrap let each card size to its own content and the grid read as
          // ragged. The cost is bounded — a row is at most three cards.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (position, card) in row.indexed) ...[
                  if (position > 0) const SizedBox(width: AppSpacing.medium),
                  Expanded(child: card),
                ],
                // Keeps a lone card on the final row at one column's width
                // instead of letting it stretch across the whole grid.
                for (var slot = row.length; slot < columns; slot++) ...[
                  const SizedBox(width: AppSpacing.medium),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _cards(BuildContext context) {
    if (state.tripBoard != null) {
      return [
        for (final subscriber in state.visibleTripSubscribers)
          SubscriptionCard(
            subscription: subscriber.subscription,
            tripSubscriber: subscriber,
            tripId: state.filters.tripId,
            isProcessing: state.isProcessing,
            selected: state.selectedId == subscriber.subscription.id,
            onTap: () =>
                openSubscriptionDetails(context, subscriber.subscription.id),
          ),
      ];
    }

    return [
      for (final subscription in state.visibleSubscriptions)
        SubscriptionCard(
          subscription: subscription,
          selected: state.selectedId == subscription.id,
          isProcessing: state.isProcessing,
          onTap: () => openSubscriptionDetails(context, subscription.id),
        ),
    ];
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({required this.state});

  final SubscriptionsLoaded state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
    );
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
