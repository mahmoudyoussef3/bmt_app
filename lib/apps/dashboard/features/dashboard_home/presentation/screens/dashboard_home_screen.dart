import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/dashboard_home_summary.dart';
import '../cubit/dashboard_home_cubit.dart';
import '../cubit/dashboard_home_state.dart';
import '../widgets/action_required_section.dart';
import '../widgets/bookings_payments_section.dart';
import '../widgets/captains_snapshot_card.dart';
import '../widgets/complaints_subscriptions_section.dart';
import '../widgets/fleet_snapshot_card.dart';
import '../widgets/home_header_banner.dart';
import '../widgets/home_kpi_grid.dart';
import '../widgets/marketplace_status_card.dart';
import '../widgets/operational_overview_section.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/trips_snapshot_section.dart';

/// The dashboard's landing screen — every role sees this first.
///
/// Owns no data source of its own: [DashboardHomeCubit] composes the same
/// use cases every other module already calls, so every number here matches
/// its full module screen for this office.
///
/// Laid out as an operations command center: office identity + KPIs span the
/// full width, then the page splits into a main operations column (today's
/// status, trips, bookings/payments, fleet/captains, secondary queues)
/// beside a fixed "needs you now" rail (urgent action items + live activity)
/// on wide screens — the two most time-sensitive panels stay in view the
/// whole time the operator scans the rest. Narrow screens can't afford a
/// rail, so action items move to the top of a single column instead.
class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({
    super.key,
    required this.office,
    this.onOpenModule,
  });

  final OfficeContext office;
  final ValueChanged<String>? onOpenModule;

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
  });

  final OfficeContext office;
  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  static const double _railBreakpoint = AppLayout.breakpointTablet;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        HomeHeaderBanner(
          office: office,
          onRefresh: () => context.read<DashboardHomeCubit>().load(),
        ),
        const SizedBox(height: AppSpacing.medium),
        HomeKpiGrid(summary: summary),
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _railBreakpoint) {
              return _WideLayout(summary: summary, onOpenModule: onOpenModule);
            }
            return _NarrowLayout(summary: summary, onOpenModule: onOpenModule);
          },
        ),
      ],
    );
  }
}

/// Desktop: a main operations column beside a fixed-priority attention rail,
/// so urgent items and live activity never scroll out of reach.
class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.summary, required this.onOpenModule});

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _MainColumn(summary: summary, onOpenModule: onOpenModule),
        ),
        const SizedBox(width: AppSpacing.large),
        Expanded(flex: 2, child: _AttentionRail(onOpenModule: onOpenModule)),
      ],
    );
  }
}

/// Narrow: a single column, with action items promoted right under the KPIs
/// since there's no room for a persistent rail.
class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.summary, required this.onOpenModule});

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActionRequiredSection(onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.medium),
        OperationalOverviewSection(summary: summary),
        const SizedBox(height: AppSpacing.medium),
        TripsSnapshotSection(summary: summary, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.medium),
        BookingsPaymentsSection(summary: summary, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.medium),
        _TwoColumn(
          left: FleetSnapshotCard(summary: summary, onOpenModule: onOpenModule),
          right: CaptainsSnapshotCard(
            summary: summary,
            onOpenModule: onOpenModule,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        const RecentActivitySection(),
        const SizedBox(height: AppSpacing.medium),
        ComplaintsSubscriptionsSection(
          summary: summary,
          onOpenModule: onOpenModule,
        ),
        const SizedBox(height: AppSpacing.medium),
        MarketplaceStatusCard(summary: summary),
      ],
    );
  }
}

/// Today's pulse, then the operational detail panels in business priority:
/// trips, bookings/payments, fleet/captains, then secondary queues.
class _MainColumn extends StatelessWidget {
  const _MainColumn({required this.summary, required this.onOpenModule});

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OperationalOverviewSection(summary: summary),
        const SizedBox(height: AppSpacing.medium),
        TripsSnapshotSection(summary: summary, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.medium),
        BookingsPaymentsSection(summary: summary, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.medium),
        _TwoColumn(
          left: FleetSnapshotCard(summary: summary, onOpenModule: onOpenModule),
          right: CaptainsSnapshotCard(
            summary: summary,
            onOpenModule: onOpenModule,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        ComplaintsSubscriptionsSection(
          summary: summary,
          onOpenModule: onOpenModule,
        ),
        const SizedBox(height: AppSpacing.medium),
        MarketplaceStatusCard(summary: summary),
      ],
    );
  }
}

/// "What needs you right now": urgent action items above a live activity
/// feed — both already sourced from `OperationalAlertsCubit`, so pairing
/// them in one rail is reuse, not a new data path.
class _AttentionRail extends StatelessWidget {
  const _AttentionRail({required this.onOpenModule});

  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActionRequiredSection(onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.medium),
        const RecentActivitySection(),
      ],
    );
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 780) {
          return Column(
            children: [
              left,
              const SizedBox(height: AppSpacing.medium),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}
