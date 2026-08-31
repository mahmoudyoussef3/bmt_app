import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/entitlements/entitlement_context.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/business_attention.dart';
import '../../domain/entities/business_overview.dart';
import '../cubit/business_overview_cubit.dart';
import '../cubit/business_overview_state.dart';
import '../models/overview_window.dart';
import '../widgets/business_attention_section.dart';
import '../widgets/business_health_section.dart';
import '../widgets/business_overview_header.dart';
import '../widgets/customer_snapshot_section.dart';
import '../widgets/financial_snapshot_section.dart';
import '../widgets/operational_snapshot_section.dart';
import '../widgets/period_kpi_band.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/revenue_trend_section.dart';
import '../widgets/route_performance_section.dart';
import '../widgets/smart_insights_section.dart';

/// The executive tab: how the business is doing, and what needs the owner.
///
/// ## Built to الرئيسية's plan, on purpose
///
/// These are the console's two most-opened screens and the same person reads
/// them one after the other all day, so they are laid out to the same plan and
/// drawn from the same parts: a bare title block, a four-tile KPI band, the
/// attention queue full width beneath it, then **two-column bands, a wider
/// panel beside a narrower companion**, each folding to one column at 900px.
/// Bands are paired tall-with-tall so neither column runs a screen further than
/// its neighbour.
///
/// Everything inside those panels is Home's vocabulary too — rows and divided
/// strips on the panel's own surface, ratios as tracks, one tinted glyph per
/// record. The previous revision nested twenty-three bordered boxes inside
/// already-bordered panels and opened on a full-bleed gradient hero that Home
/// had retired, which is why the two screens read as two different products.
///
/// ## The page, in the order an owner asks
///
/// 1. *Who, which period, and is anything wrong?* — the title block, its period
///    switcher, and the verdict chips.
/// 2. *How did the period go?* — four KPIs, money first, each with its own
///    shape and movement.
/// 3. *What needs me?* — the attention queues, full width, never scrolled past.
/// 4. *Where does the money stand, and which way is it going?*
/// 5. *Which corridors earn their buses, and is anything off target?*
/// 6. *What is running today, and who is buying?*
/// 7. *What do the numbers mean, and what can I start from here?*
///
/// ## One period, stated once
///
/// Every time-scoped figure reads from [OverviewWindow]. Live state — trips
/// running now, rosters, queue depths — deliberately does not, and the panels
/// holding it say «اليوم» so the difference is visible. Before this control
/// existed the page mixed one-day, seven-day and thirty-day windows with
/// nothing on screen saying which was which.
///
/// ## What this screen is not
///
/// Not an admin surface. Nothing here writes: every row, tile and button leads
/// to the module that owns the decision. That is the line between this and the
/// operator's console on `/`, and it is what keeps the page readable in the
/// thirty seconds it is designed for.
class BusinessOverviewScreen extends StatefulWidget {
  const BusinessOverviewScreen({
    super.key,
    required this.office,
    required this.canOpenRoute,
    this.entitlements,
    this.onOpenModule,
    this.onCreateTrip,
    this.initialWindow = OverviewWindow.month,
  });

  final OfficeContext office;

  /// The shell's `role ∧ entitlement` gate. Quick actions and drill-ins the
  /// operator cannot use are dropped rather than shown disabled.
  final bool Function(String route) canOpenRoute;

  /// The resolved licence, read live rather than from the loaded snapshot:
  /// entitlements change when a contract changes, not when this page refreshes.
  final EntitlementContext? entitlements;

  final ValueChanged<String>? onOpenModule;

  /// Opens the trip planner. Owned by the shell, which owns navigation.
  final VoidCallback? onCreateTrip;

  /// Which period the page opens on. A month is the default because it is the
  /// shortest window in which most offices' figures stop being noise.
  final OverviewWindow initialWindow;

  @override
  State<BusinessOverviewScreen> createState() => _BusinessOverviewScreenState();
}

class _BusinessOverviewScreenState extends State<BusinessOverviewScreen> {
  late OverviewWindow _window = widget.initialWindow;

  /// Switching windows re-derives from rows already in memory — no refetch, no
  /// spinner. That is only true because the cubit is a composition root over
  /// use cases the modules already loaded; it is also why offering 90 days
  /// costs nothing and why the page can afford to state its period at all.
  void _selectWindow(OverviewWindow window) {
    if (window == _window) return;
    setState(() => _window = window);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessOverviewCubit, BusinessOverviewState>(
      builder: (context, state) {
        return switch (state) {
          BusinessOverviewLoading() => const DashboardLoading(),
          BusinessOverviewError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<BusinessOverviewCubit>().load(),
          ),
          BusinessOverviewLoaded(:final overview, :final isRefreshing) =>
            _LoadedView(
              office: widget.office,
              overview: overview,
              window: _window,
              onWindowChanged: _selectWindow,
              isRefreshing: isRefreshing,
              entitlements: widget.entitlements,
              canOpenRoute: widget.canOpenRoute,
              onOpenModule: widget.onOpenModule ?? (_) {},
              onCreateTrip: widget.onCreateTrip,
            ),
        };
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.office,
    required this.overview,
    required this.window,
    required this.onWindowChanged,
    required this.isRefreshing,
    required this.canOpenRoute,
    required this.onOpenModule,
    this.entitlements,
    this.onCreateTrip,
  });

  final OfficeContext office;
  final BusinessOverview overview;
  final OverviewWindow window;
  final ValueChanged<OverviewWindow> onWindowChanged;
  final bool isRefreshing;
  final bool Function(String route) canOpenRoute;
  final ValueChanged<String> onOpenModule;
  final EntitlementContext? entitlements;
  final VoidCallback? onCreateTrip;

  /// Below this the bands stack. Home's number, for Home's reason: each column
  /// needs ~380px before a row carrying a name, a track and a denominator stops
  /// being readable.
  static const double _splitBreakpoint = 900;

  /// The gap between bands, and between the two panels of one band. One value,
  /// so a band never reads as more closely related to the band under it than to
  /// its own other half. Home's, again.
  static const double _bandGap = 24;

  @override
  Widget build(BuildContext context) {
    final attention =
        [...overview.attentionItems, ...licenseLimitAttention(entitlements)]
          ..sort((a, b) {
            final bySeverity = b.kind.severity.index.compareTo(
              a.kind.severity.index,
            );
            return bySeverity != 0 ? bySeverity : b.count.compareTo(a.count);
          });

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        BusinessOverviewHeader(
          office: office,
          overview: overview,
          window: window,
          onWindowChanged: onWindowChanged,
          isRefreshing: isRefreshing,
          onRefresh: () => context.read<BusinessOverviewCubit>().refresh(),
          onCreateTrip: onCreateTrip,
        ),
        if (overview.unavailable.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.large),
          // The shared notice every other module uses for a partial load,
          // rather than this page's own wording for the same fact.
          DashboardPartialDataNotice(
            sources: [for (final source in overview.unavailable) source.label],
          ),
        ],
        if (OverviewCoverageNotice.isNeeded(overview, window)) ...[
          const SizedBox(height: AppSpacing.small),
          OverviewCoverageNotice(overview: overview, window: window),
        ],
        const SizedBox(height: _bandGap),
        PeriodKpiBand(
          overview: overview,
          window: window,
          onOpenModule: onOpenModule,
        ),
        const SizedBox(height: _bandGap),
        BusinessAttentionSection(items: attention, onOpenModule: onOpenModule),
        const SizedBox(height: _bandGap),
        _Band(
          main: FinancialSnapshotSection(
            overview: overview,
            window: window,
            onOpenModule: onOpenModule,
          ),
          side: RevenueTrendSection(
            overview: overview,
            window: window,
            onOpenModule: onOpenModule,
          ),
        ),
        const SizedBox(height: _bandGap),
        _Band(
          main: RoutePerformanceSection(
            overview: overview,
            window: window,
            onOpenModule: onOpenModule,
          ),
          side: BusinessHealthSection(
            overview: overview,
            onOpenModule: onOpenModule,
          ),
        ),
        const SizedBox(height: _bandGap),
        _Band(
          main: OperationalSnapshotSection(
            overview: overview,
            onOpenModule: onOpenModule,
          ),
          side: CustomerSnapshotSection(
            overview: overview,
            window: window,
            onOpenModule: onOpenModule,
          ),
        ),
        const SizedBox(height: _bandGap),
        _Band(
          main: SmartInsightsSection(
            insights: overview.insights,
            onOpenModule: onOpenModule,
          ),
          side: QuickActionsSection(
            onOpenModule: onOpenModule,
            canOpen: canOpenRoute,
          ),
        ),
      ],
    );
  }
}

/// One row of the page: a wider primary panel with a narrower companion,
/// stacking to full width when the window can no longer hold both.
class _Band extends StatelessWidget {
  const _Band({required this.main, required this.side});

  final Widget main;
  final Widget side;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scaled: a breakpoint compared against a raw pixel width is a fixed
        // lane one level up, and at 1.6× each column needs the full width the
        // stacked layout gives it.
        final split = MediaQuery.textScalerOf(
          context,
        ).scale(_LoadedView._splitBreakpoint);

        if (constraints.maxWidth < split) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              main,
              const SizedBox(height: _LoadedView._bandGap),
              side,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: main),
            const SizedBox(width: _LoadedView._bandGap),
            Expanded(flex: 2, child: side),
          ],
        );
      },
    );
  }
}
