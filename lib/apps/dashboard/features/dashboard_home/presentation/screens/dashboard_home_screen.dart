import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_page_body.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import '../../domain/entities/dashboard_home_summary.dart';
import '../cubit/dashboard_home_cubit.dart';
import '../cubit/dashboard_home_state.dart';
import '../widgets/action_required_section.dart';
import '../widgets/customer_pulse_section.dart';
import '../widgets/fleet_team_section.dart';
import '../widgets/home_header_banner.dart';
import '../widgets/home_kpi_grid.dart';
import '../widgets/recent_bookings_section.dart';
import '../widgets/revenue_trend_section.dart';
import '../widgets/route_performance_section.dart';
import '../widgets/today_trips_section.dart';

/// The dashboard's landing screen — every role sees this first.
///
/// Owns no data source of its own: [DashboardHomeCubit] composes the same use
/// cases every other module already calls, so every number here matches its
/// full module screen for this office.
///
/// ## The page, in the order an operator asks
///
/// 1. *How are we doing, and what is happening this minute?* — the greeting,
///    the pulse strip (next departure, buses rolling, seats still on sale) and
///    four KPIs, each carrying the shape of its own last week.
/// 2. *Is anything broken?* — the attention panel, full width, directly under
///    the KPIs, as a grid rather than a stacked list so every standing queue is
///    visible without scrolling. It is the one thing that must never be
///    scrolled past.
/// 3. *What is running?* — today's departure board beside the money.
/// 4. *What is selling, and is the business healthy?* — the newest bookings and
///    the customer ratings.
/// 5. *Where should the next bus go?* — route occupancy over the month, beside
///    the standing fleet and roster.
///
/// ## Why the page grew
///
/// The first version of this screen cut everything that did not answer one of
/// three questions, and cut correctly — a donut of today's trips by status, a
/// running total of every booking ever taken, a duplicate of the office-profile
/// marketplace card. But the trim went one step past the mark: the summary was
/// still *computing* route occupancy, the newest bookings and the review
/// averages on every single load, and drawing none of them. Three real answers
/// were being derived and thrown away, and the console's landing page ended a
/// third of the way down a desktop window with two-thirds of it blank.
///
/// So the rule here is not "show less", it is **show what was already true**.
/// Every panel added back is rendered from a figure [DashboardHomeSummary]
/// already had; nothing new is fetched, and no panel exists that a sibling
/// module could not confirm.
///
/// ## Layout
///
/// Three two-column bands, wide panel beside narrow companion, each folding to
/// a single column when the window can no longer hold both. The bands are
/// paired so the columns stay roughly level: the tall departure board sits
/// against the tall money panel, and the two short panels sit against each
/// other, which is what stops one column running a screen further than its
/// neighbour.
///
/// The frame itself — page inset, band gap, fold breakpoint — comes from
/// [DashboardPageBody], not from constants of Home's own, because مركز العمليات
/// المباشر is laid out to this same plan and the two screens may not disagree
/// about the size of their margins.
class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({
    super.key,
    required this.office,
    this.onOpenModule,
    this.onCreateTrip,
  });

  final OfficeContext office;
  final ValueChanged<String>? onOpenModule;

  /// Opens the trip planner. Provided by the shell, which owns navigation —
  /// the home screen only says *when*.
  final VoidCallback? onCreateTrip;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardHomeCubit, DashboardHomeState>(
      builder: (context, state) {
        return switch (state) {
          DashboardHomeLoading() => const DashboardLoading(),
          DashboardHomeError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<DashboardHomeCubit>().load(),
          ),
          DashboardHomeLoaded(:final summary) => _LoadedView(
            office: office,
            summary: summary,
            onOpenModule: onOpenModule ?? (_) {},
            onCreateTrip: onCreateTrip,
          ),
        };
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.office,
    required this.summary,
    required this.onOpenModule,
    this.onCreateTrip,
  });

  final OfficeContext office;
  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;
  final VoidCallback? onCreateTrip;

  @override
  Widget build(BuildContext context) {
    return DashboardPageBody(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            HomeHeaderBanner(
              office: office,
              summary: summary,
              updatedAt: DateTime.now(),
              onRefresh: () => context.read<DashboardHomeCubit>().load(),
              onCreateTrip: onCreateTrip,
            ),
            if (summary.unavailable.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.large),
              DashboardPartialDataNotice(sources: summary.unavailable),
            ],
          ],
        ),
        HomeKpiGrid(summary: summary, onOpenModule: onOpenModule),
        ActionRequiredSection(summary: summary, onOpenModule: onOpenModule),
        DashboardBand(
          main: TodayTripsSection(
            summary: summary,
            onOpenModule: onOpenModule,
            onCreateTrip: onCreateTrip,
          ),
          side: RevenueTrendSection(summary: summary),
        ),
        DashboardBand(
          main: RecentBookingsSection(
            summary: summary,
            onOpenModule: onOpenModule,
          ),
          side: CustomerPulseSection(
            summary: summary,
            onOpenModule: onOpenModule,
          ),
        ),
        DashboardBand(
          main: RoutePerformanceSection(
            summary: summary,
            onOpenModule: onOpenModule,
          ),
          side: FleetTeamSection(summary: summary, onOpenModule: onOpenModule),
        ),
      ],
    );
  }
}
