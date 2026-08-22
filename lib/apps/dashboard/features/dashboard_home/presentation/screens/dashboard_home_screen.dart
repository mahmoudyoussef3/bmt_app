import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import '../../domain/entities/dashboard_home_summary.dart';
import '../cubit/dashboard_home_cubit.dart';
import '../cubit/dashboard_home_state.dart';
import '../widgets/action_required_section.dart';
import '../widgets/fleet_team_section.dart';
import '../widgets/home_header_banner.dart';
import '../widgets/home_kpi_grid.dart';
import '../widgets/revenue_trend_section.dart';
import '../widgets/today_trips_section.dart';

/// The dashboard's landing screen — every role sees this first.
///
/// Owns no data source of its own: [DashboardHomeCubit] composes the same use
/// cases every other module already calls, so every number here matches its
/// full module screen for this office.
///
/// The page answers three questions in the order an operator asks them:
///
/// 1. *How are we doing today?* — the greeting line and four KPIs.
/// 2. *Is anything broken?* — the attention panel, full width, directly under
///    the KPIs, as a grid rather than a stacked list so every standing queue
///    is visible without scrolling. It is the one thing that must never be
///    scrolled past.
/// 3. *What is running, and what does the standing picture look like?* —
///    today's departure board beside a rail of revenue and fleet capacity.
///
/// Everything that answered none of those was cut rather than moved: a donut
/// of today's trips by status (the KPI row and the trip rows already say it),
/// running totals of every booking ever taken, the newest-bookings list and
/// the activity feed (each one click away in its own module), and a
/// duplicate of the office-profile marketplace card.
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

  /// Below this the two-column bands stack. Chosen so each column keeps ~380px
  /// — a trip row with time, route, captain and a seat bar stops being
  /// readable much under that.
  static const double _splitBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        HomeHeaderBanner(
          office: office,
          todayTripsCount: summary.todayTripsCount,
          updatedAt: DateTime.now(),
          onRefresh: () => context.read<DashboardHomeCubit>().load(),
          onCreateTrip: onCreateTrip,
        ),
        if (summary.unavailable.isNotEmpty) ...[
          const SizedBox(height: 16),
          DashboardPartialDataNotice(sources: summary.unavailable),
        ],
        const SizedBox(height: 24),
        HomeKpiGrid(summary: summary, onOpenModule: onOpenModule),
        const SizedBox(height: 24),
        ActionRequiredSection(summary: summary, onOpenModule: onOpenModule),
        const SizedBox(height: 24),
        _Band(
          main: TodayTripsSection(
            summary: summary,
            onOpenModule: onOpenModule,
            onCreateTrip: onCreateTrip,
          ),
          side: Column(
            children: [
              RevenueTrendSection(summary: summary),
              const SizedBox(height: 24),
              FleetTeamSection(summary: summary, onOpenModule: onOpenModule),
            ],
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
        if (constraints.maxWidth < _LoadedView._splitBreakpoint) {
          return Column(
            children: [
              main,
              const SizedBox(height: 24),
              side,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: main),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: side),
          ],
        );
      },
    );
  }
}
