import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_pager.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_results_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';

import '../../domain/entities/subscription_trip.dart';
import '../../domain/entities/user_subscription.dart';
import '../../plans/presentation/cubit/subscription_plans_cubit.dart';
import '../../plans/presentation/screens/subscription_plans_screen.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import '../models/subscription_queue_tab.dart';
import '../widgets/create_subscription_sheet.dart';
import '../widgets/subscription_card.dart';
import '../widgets/subscription_details_sheet.dart';
import '../widgets/subscription_formatting.dart';
import '../widgets/subscriptions_analytics.dart';
import '../widgets/subscriptions_table.dart';
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
        child: Scaffold(
          appBar: AppBar(title: const Text('إدارة باقات الاشتراك')),
          body: const SubscriptionPlansScreen(),
        ),
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
        // Open, like every other المبيعات header: the counts are what the
        // module is opened to read, not a once-a-shift figure worth folding.
        initiallyExpanded: true,
        collapsedSummary: DashboardSectionSummary(
          items: [
            'نشطة ${arabicNumber(state.activeCount)}',
            'بانتظار الدفع ${arabicNumber(state.pendingPaymentCount)}',
            'ينتهي قريبًا ${arabicNumber(state.expiringSoonCount)}',
            'متبقٍ ${subscriptionMoney(state.outstandingRevenue)}',
          ],
        ),
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
      _SubscriberBoard(state: state, width: boardWidth),
      if (state.tripBoard == null && state.subscriptions.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.large),
        Text(
          'نظرة عامة على المكتب بالكامل، بصرف النظر عن الفلاتر الحالية',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        SubscriptionsAnalytics(subscriptions: state.subscriptions),
      ],
    ];
  }
}

/// The subscriber list: the shared results header, then the table on desktop
/// widths and a card grid below them — both paged by the same index, so
/// narrowing the window never moves the operator to a different set of rows.
///
/// One column per ~500px in card mode: a subscriber card carries a name, a
/// package, a route, a validity window and a money block, and stretching that
/// across a 2000px screen leaves the reader's eye travelling between two facts
/// that belong together.
class _SubscriberBoard extends StatefulWidget {
  const _SubscriberBoard({required this.state, required this.width});

  final SubscriptionsLoaded state;
  final double width;

  @override
  State<_SubscriberBoard> createState() => _SubscriberBoardState();
}

class _SubscriberBoardState extends State<_SubscriberBoard> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant _SubscriberBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new filter/tab can shrink the result set out from under the current
    // page — land back on the first page rather than an empty one.
    final maxPage = (_total / subscriptionsPageSize).ceil() - 1;
    if (_page > maxPage) _page = maxPage.clamp(0, 1 << 30);
  }

  /// The trip board lists subscribers, the office view lists subscriptions;
  /// both page against their own length.
  int get _total => widget.state.tripBoard != null
      ? widget.state.visibleTripSubscribers.length
      : widget.state.visibleSubscriptions.length;

  int get _pageCount => (_total / subscriptionsPageSize).ceil().clamp(1, 99999);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final trip = state.selectedTrip;

    if (state.filteredSubscriptions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, trip: trip, showing: 0),
          const SizedBox(height: AppSpacing.small),
          _EmptyBoard(state: state),
        ],
      );
    }

    // The whole-office list becomes a sortable table on wide screens, matching
    // every other EWT module. A trip in focus keeps the card grid: its
    // check-in action and link chip need more room per row than a table cell
    // gives them.
    final isTable =
        state.tripBoard == null && widget.width >= kDashboardTableBreakpoint;

    if (isTable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, trip: trip, showing: _pageItems().length),
          const SizedBox(height: AppSpacing.small),
          SubscriptionsTable(
            state: state,
            pageIndex: _page,
            onPageChanged: (page) => setState(() => _page = page),
          ),
        ],
      );
    }

    final cards = _cards(context);
    final columns = dashboardCardColumnsFor(widget.width);
    final rows = <List<Widget>>[
      for (var index = 0; index < cards.length; index += columns)
        cards.skip(index).take(columns).toList(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, trip: trip, showing: cards.length),
        const SizedBox(height: AppSpacing.small),
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
        const SizedBox(height: AppSpacing.small),
        // The same bar the table closes with, so both layouts page identically.
        AppCard(
          padding: EdgeInsets.zero,
          child: DashboardPagerBar(
            totalLabel: 'الإجمالي ${arabicNumber(_total)} اشتراك',
            currentPage: _page,
            pages: _pageCount,
            onPageChanged: (page) => setState(() => _page = page),
          ),
        ),
      ],
    );
  }

  Widget _header(
    BuildContext context, {
    required SubscriptionTrip? trip,
    required int showing,
  }) {
    final first = showing == 0 ? 0 : _page * subscriptionsPageSize + 1;
    final last = first == 0 ? 0 : first + showing - 1;

    return DashboardResultsHeader(
      icon: trip == null ? DashboardIcons.subscriptions : DashboardIcons.trips,
      title: trip == null
          ? 'قائمة المشتركين'
          : 'مشتركو رحلة ${arabicDigits(trip.code)}',
      subtitle: showing == 0
          ? 'لا نتائج'
          : 'عرض ${arabicNumber(first)}–${arabicNumber(last)} '
                'من ${arabicNumber(_total)}',
    );
  }

  /// One page's worth of the office-wide list.
  List<UserSubscription> _pageItems() {
    final items = widget.state.visibleSubscriptions;
    final start = (_page * subscriptionsPageSize).clamp(0, items.length);
    final end = (start + subscriptionsPageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  List<Widget> _cards(BuildContext context) {
    final state = widget.state;

    if (state.tripBoard != null) {
      final subscribers = state.visibleTripSubscribers;
      final start = (_page * subscriptionsPageSize).clamp(
        0,
        subscribers.length,
      );
      final end = (start + subscriptionsPageSize).clamp(0, subscribers.length);
      return [
        for (final subscriber in subscribers.sublist(start, end))
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
      for (final subscription in _pageItems())
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
    return DashboardEmptyState(
      icon: state.filters.hasTrip
          ? DashboardIcons.trips
          : DashboardIcons.subscriptions,
      title: state.filters.hasTrip
          ? 'لا يوجد مشتركون على هذه الرحلة'
          : 'لا توجد اشتراكات مطابقة',
      message: state.filters.hasTrip
          ? 'لم يشترِ أحد باقة على هذه الرحلة، ولا يوجد اشتراك سارٍ على خط سيرها في هذا التاريخ.'
          : 'جرّب تغيير التبويب أو مسح الفلاتر.',
    );
  }
}

/// Office-wide numbers — always the whole book, never the filtered slice, so
/// they stay comparable as the operator moves between tabs and trips.
///
/// Four tiles in one row, tinted with each tone's `accent`, tapping through to
/// the queue that produced them: the same shape and the same contract as
/// الحجوزات' and العملاء' strips. The fifth tile — the active book's contracted
/// value — folded into the money tile's detail line, where "محصّل … متبقٍ …"
/// says more in one row than two tiles said in two.
class _OfficeKpis extends StatelessWidget {
  const _OfficeKpis({required this.state});

  final SubscriptionsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionsCubit>();

    return DashboardKpiGrid(
      maxColumns: 4,
      itemExtent: 132,
      children: [
        DashboardKpiCard(
          label: 'اشتراكات نشطة',
          value: arabicNumber(state.activeCount),
          detail: 'من ${arabicNumber(state.subscriptions.length)} إجمالي',
          icon: Icons.workspace_premium_outlined,
          color: context.status(AppStatusTone.success).accent,
          emphasized: true,
          onTap: () => cubit.switchTab(SubscriptionQueueTab.active),
          tapHint: 'عرض الاشتراكات النشطة',
        ),
        DashboardKpiCard(
          label: 'بانتظار الدفع',
          value: arabicNumber(state.pendingPaymentCount),
          detail: 'اشتراكات تنتظر تحصيلاً',
          icon: Icons.hourglass_top_outlined,
          color: context.status(AppStatusTone.warning).accent,
          emphasized: true,
          onTap: () => cubit.switchTab(SubscriptionQueueTab.pendingPayment),
          tapHint: 'عرض من لم يسدد بعد',
        ),
        DashboardKpiCard(
          label: 'ينتهي خلال أسبوع',
          value: arabicNumber(state.expiringSoonCount),
          detail: 'يحتاج تجديدًا',
          icon: Icons.event_repeat_outlined,
          color: context.status(AppStatusTone.error).accent,
          emphasized: true,
          onTap: () => cubit.switchTab(SubscriptionQueueTab.expiringSoon),
          tapHint: 'عرض ما يقارب الانتهاء',
        ),
        // No tab behind this one: it is money, not a queue of rows, so it does
        // not pretend to be a shortcut into the list.
        DashboardKpiCard(
          label: 'قيمة الاشتراكات النشطة',
          value: subscriptionMoney(state.activeSubscriptionsValue),
          detail:
              'محصّل ${subscriptionMoney(state.collectedRevenue)} · '
              'متبقٍ ${subscriptionMoney(state.outstandingRevenue)}',
          icon: Icons.monetization_on_outlined,
          color: context.status(AppStatusTone.info).accent,
          emphasized: true,
        ),
      ],
    );
  }
}
