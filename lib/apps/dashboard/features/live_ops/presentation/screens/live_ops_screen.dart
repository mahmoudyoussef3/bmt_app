import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../../core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../../../core/widgets/dashboard_state_views.dart';
import '../../domain/entities/fleet_feed.dart';
import '../../domain/entities/live_ops_snapshot.dart';
import '../bloc/fleet_tracking_bloc.dart';
import '../bloc/fleet_tracking_state.dart';
import '../cubit/live_ops_cubit.dart';
import '../cubit/live_ops_state.dart';
import '../widgets/feed_link_banner.dart';
import '../widgets/fleet_tracking_scope.dart';
import '../widgets/incident_queue_section.dart';
import '../widgets/live_ops_all_clear.dart';
import '../widgets/live_ops_map.dart';
import '../widgets/live_ops_summary_bar.dart';
import '../widgets/live_trip_card.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

/// The Live Operations Center — the dashboard's answer to "what is happening on
/// the road right now?". It renders the office's active trips with an honest
/// read of each trip's tracking health, and the open incident queue.
///
/// Two state holders feed it, and the split is what makes it cheap:
/// [LiveOpsCubit] carries the roster and the incident queue (realtime-triggered,
/// with a slow poll behind it), while [FleetTrackingBloc] carries live positions
/// over one subscription. Positions land every few seconds; almost nothing on
/// this screen is about a position.
///
/// | Region | Rebuilds on a position? |
/// |---|---|
/// | map markers | yes — and only the marker layer, via [FleetVehicleLayer] |
/// | a trip card's health badge + "آخر تحديث" line | yes, that card only |
/// | «تتبع متعثّر» KPI tile | only when the count changes |
/// | incident queue, critical banner, other KPI tiles | **no** |
/// | map camera, tile layer, panel chrome | **no** |
class LiveOpsScreen extends StatelessWidget {
  /// Whether this operator may move incidents through their lifecycle. Support
  /// agents get the module read-only — see [DashboardPermission.liveOpsIncidentAction].
  final bool canResolveIncidents;

  const LiveOpsScreen({super.key, this.canResolveIncidents = true});

  @override
  Widget build(BuildContext context) {
    // The bridge that hands the roster to the feed. It renders its child
    // untouched, so it costs no layout — see [FleetTrackingScope].
    return FleetTrackingScope(
      child: BlocConsumer<LiveOpsCubit, LiveOpsState>(
        listenWhen: (prev, curr) =>
            curr is LiveOpsLoaded && curr.actionError != null,
        listener: (context, state) {
          if (state is LiveOpsLoaded && state.actionError != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionError!)));
          }
        },
        // The roster changes rarely. Without this, an acknowledged incident or a
        // slow poll returning identical data rebuilt the entire board.
        buildWhen: (prev, curr) => !_sameRender(prev, curr),
        builder: (context, state) {
          return switch (state) {
            LiveOpsLoading() => const DashboardLoading(),
            LiveOpsError(:final message) => DashboardErrorState(
              message: message,
              onRetry: () => context.read<LiveOpsCubit>().load(),
            ),
            LiveOpsLoaded() => _LiveOpsBody(
              state: state,
              canResolveIncidents: canResolveIncidents,
            ),
          };
        },
      ),
    );
  }

  /// Would these two states draw the same board?
  ///
  /// [LiveOpsLoaded] is rebuilt wholesale by every refresh, so reference equality
  /// says nothing. What actually changes the page is the roster, the incident
  /// queue and the selection — deliberately *not* `generatedAt`, which moves on
  /// every poll and would defeat the whole check.
  static bool _sameRender(LiveOpsState prev, LiveOpsState curr) {
    if (prev is! LiveOpsLoaded || curr is! LiveOpsLoaded) return false;
    if (prev.selectedTripId != curr.selectedTripId) return false;

    final a = prev.snapshot;
    final b = curr.snapshot;
    if (a.activeTrips.length != b.activeTrips.length) return false;
    if (a.incidents.length != b.incidents.length) return false;

    for (var i = 0; i < a.activeTrips.length; i++) {
      final x = a.activeTrips[i];
      final y = b.activeTrips[i];
      if (x.id != y.id ||
          x.statusLabel != y.statusLabel ||
          x.bookedSeats != y.bookedSeats ||
          x.driverName != y.driverName ||
          x.vehicleLabel != y.vehicleLabel) {
        return false;
      }
    }
    for (var i = 0; i < a.incidents.length; i++) {
      final x = a.incidents[i];
      final y = b.incidents[i];
      if (x.id != y.id || x.status != y.status) return false;
    }
    return true;
  }
}

class _LiveOpsBody extends StatelessWidget {
  final LiveOpsLoaded state;
  final bool canResolveIncidents;

  const _LiveOpsBody({required this.state, required this.canResolveIncidents});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final snapshot = state.snapshot;
    final cubit = context.read<LiveOpsCubit>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.liveOpsActive,
          title: 'مركز العمليات المباشر',
          subtitle:
              'الرحلات الجارية الآن، صحة تتبّع كل مركبة، والبلاغات المفتوحة من الكباتن.',
          actions: [
            FilledButton.tonalIcon(
              onPressed: cubit.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث'),
            ),
          ],
          sectionId: DashboardSectionIds.liveOpsHeader,
          // Only the at-risk tile depends on the feed, and only on a count — so
          // the KPI row repaints when that number changes, not when a bus moves.
          summary: BlocSelector<FleetTrackingBloc, FleetTrackingState, int>(
            selector: (feed) => feed.atRiskCount(
              snapshot.activeTrips.map((t) => t.id),
              feed.evaluatedAt ?? now,
            ),
            builder: (context, atRisk) =>
                LiveOpsSummaryBar(snapshot: snapshot, atRisk: atRisk, now: now),
          ),
        ),
        if (snapshot.hasCriticalIncident) ...[
          const SizedBox(height: AppSpacing.medium),
          const _CriticalBanner(),
        ],

        if (snapshot.activeTrips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          BlocBuilder<FleetTrackingBloc, FleetTrackingState>(
            builder: (context, feed) => DashboardPanel(
              sectionId: DashboardSectionIds.liveOpsMap,
              icon: Icons.map_rounded,
              title: 'خريطة الأسطول المباشرة',
              // Counted off the feed, not off the roster's seed fixes — after
              // the first socket delivery those two numbers diverge.
              subtitle: '${feed.vehicles.length} مركبة ترسل موقعها',
              child: Column(
                children: [
                  const FeedLinkBanner(),
                  LiveOpsMap(
                    trips: snapshot.activeTrips,
                    vehicles: feed.vehicles,
                    now: feed.evaluatedAt ?? now,
                    selectedTripId: state.selectedTripId,
                    onSelect: cubit.selectTrip,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.medium),
        // Nothing running and nothing reported is one fact, not two empty
        // panels: the all-clear card states both in a quarter of the height.
        if (snapshot.isQuiet)
          LiveOpsAllClear(generatedAt: snapshot.generatedAt, now: now)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final trips = _TripsPanel(
                trips: snapshot.activeTrips,
                now: now,
                selectedTripId: state.selectedTripId,
                onSelect: cubit.selectTrip,
              );
              final incidents = _IncidentsPanel(
                snapshot: snapshot,
                now: now,
                canAct: canResolveIncidents,
              );

              if (constraints.maxWidth >= 1080) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: trips),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(flex: 2, child: incidents),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  trips,
                  const SizedBox(height: AppSpacing.medium),
                  incidents,
                ],
              );
            },
          ),
      ],
    );
  }
}

class _TripsPanel extends StatelessWidget {
  final List<LiveTrip> trips;
  final DateTime now;
  final String? selectedTripId;
  final ValueChanged<String?> onSelect;

  const _TripsPanel({
    required this.trips,
    required this.now,
    required this.selectedTripId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = [...trips]
      ..sort((a, b) {
        final byOverdue = (b.isOverdueAt(now) ? 1 : 0).compareTo(
          a.isOverdueAt(now) ? 1 : 0,
        );
        if (byOverdue != 0) return byOverdue;
        return a.departureTime.compareTo(b.departureTime);
      });

    return DashboardPanel(
      sectionId: DashboardSectionIds.liveOpsTrips,
      icon: Icons.route_rounded,
      title: 'الرحلات على الطريق',
      subtitle: trips.isEmpty ? null : '${trips.length} رحلة نشطة',
      child: trips.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.trips,
              title: 'لا توجد رحلات على الطريق حالياً',
              message:
                  'ستظهر الرحلات هنا فور أن يبدأ الكباتن تنفيذها، مع تتبّع مباشر لكل مركبة.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final twoCols = constraints.maxWidth >= 680;
                final width = twoCols
                    ? (constraints.maxWidth - AppSpacing.medium) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: AppSpacing.medium,
                  runSpacing: AppSpacing.medium,
                  children: [
                    for (final trip in ordered)
                      SizedBox(
                        width: width,
                        child: _TrackedTripCard(
                          trip: trip,
                          fallbackNow: now,
                          selected: trip.id == selectedTripId,
                          onTap: () => onSelect(trip.id),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

/// One trip card, subscribed to just its own vehicle.
///
/// The selector returns a record, so the card rebuilds when *this* trip's
/// position or the board clock changes — and a position landing for a different
/// bus rebuilds nothing here. On a board with a dozen trips that is the
/// difference between one card repainting and twelve.
class _TrackedTripCard extends StatelessWidget {
  final LiveTrip trip;

  /// Used until the feed has a clock of its own, i.e. before the first position.
  final DateTime fallbackNow;

  final bool selected;
  final VoidCallback onTap;

  const _TrackedTripCard({
    required this.trip,
    required this.fallbackNow,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      FleetTrackingBloc,
      FleetTrackingState,
      ({TrackedVehicle? vehicle, DateTime now})
    >(
      selector: (feed) => (
        vehicle: feed.vehicle(trip.id),
        now: feed.evaluatedAt ?? fallbackNow,
      ),
      builder: (context, view) => LiveTripCard(
        trip: trip,
        vehicle: view.vehicle,
        now: view.now,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}

class _IncidentsPanel extends StatelessWidget {
  final LiveOpsSnapshot snapshot;
  final DateTime now;
  final bool canAct;

  const _IncidentsPanel({
    required this.snapshot,
    required this.now,
    required this.canAct,
  });

  @override
  Widget build(BuildContext context) {
    final open = snapshot.openIncidents;
    final unacknowledged = snapshot.unacknowledgedCount;
    return DashboardPanel(
      sectionId: DashboardSectionIds.liveOpsIncidents,
      icon: Icons.report_rounded,
      title: 'البلاغات المفتوحة',
      subtitle: open.isEmpty
          ? null
          : (unacknowledged > 0
                ? '$unacknowledged بحاجة استلام من ${open.length}'
                : '${open.length} قيد المعالجة'),
      child: IncidentQueueSection(
        incidents: open,
        now: now,
        canAct: canAct,
        onAction: (incident, next, {note}) => context
            .read<LiveOpsCubit>()
            .updateIncident(incident, next, note: note),
      ),
    );
  }
}

class _CriticalBanner extends StatelessWidget {
  const _CriticalBanner();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: context.status(AppStatusTone.error).tint,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(
          color: context.status(AppStatusTone.error).ink.withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sos_rounded,
            color: context.status(AppStatusTone.error).ink,
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بلاغ طوارئ نشط',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.status(AppStatusTone.error).ink,
                  ),
                ),
                Text(
                  'أحد الكباتن أرسل بلاغ نجدة — يتطلب تدخلاً فورياً من فريق العمليات.',
                  style: text.bodySmall?.copyWith(
                    color: context.status(AppStatusTone.error).ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
