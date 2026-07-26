import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
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
/// its full module screen for this office. Laid out by business priority —
/// office identity + KPIs, then operational health + what needs attention,
/// then trips/bookings/payments, then fleet/captains/activity, then
/// marketplace status — per the requested information hierarchy.
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        // Level 1 — office identity + critical KPIs.
        HomeHeaderBanner(office: office),
        const SizedBox(height: AppSpacing.medium),
        HomeKpiGrid(summary: summary),
        const SizedBox(height: AppSpacing.medium),

        // Level 2 — operational health + what needs attention.
        OperationalOverviewSection(summary: summary),
        const SizedBox(height: AppSpacing.medium),
        ActionRequiredSection(onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.medium),

        // Level 3 — trips, bookings, payments.
        TripsSnapshotSection(summary: summary, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.medium),
        BookingsPaymentsSection(summary: summary, onOpenModule: onOpenModule),
        const SizedBox(height: AppSpacing.medium),

        // Level 4 — fleet, captains, activity.
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

        // Level 5 — secondary insights.
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
            children: [left, const SizedBox(height: AppSpacing.medium), right],
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
