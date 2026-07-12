import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/widgets/widgets.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_awaiting_trips_view.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_dev_mode_sheet.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/pages/passenger_list_page.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/pages/trip_execution_page.dart';

import '../../domain/entities/assigned_trip.dart';
import '../cubit/assigned_trips_cubit.dart';
import '../cubit/assigned_trips_state.dart';
import '../widgets/assigned_trip_card.dart';
import '../widgets/assigned_trips_app_bar.dart';
import '../widgets/assigned_trips_overview_panel.dart';
import '../widgets/assigned_trips_section_title.dart';
import '../widgets/assigned_trips_skeleton.dart';

class AssignedTripsPage extends StatefulWidget {
  const AssignedTripsPage({super.key});

  @override
  State<AssignedTripsPage> createState() => _AssignedTripsPageState();
}

class _AssignedTripsPageState extends State<AssignedTripsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AssignedTripsCubit>().load();
  }

  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await context.read<AssignedTripsCubit>().refresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: BlocBuilder<AssignedTripsCubit, AssignedTripsState>(
        builder: (context, state) {
          if (state is AssignedTripsLoading) {
            return const AssignedTripsSkeleton();
          }
          if (state is AssignedTripsError) {
            return SafeArea(
              child: AsyncStateView(
                status: AsyncViewStatus.error,
                errorMessage: state.message,
                onRetry: () => context.read<AssignedTripsCubit>().load(),
                child: const SizedBox.shrink(),
              ),
            );
          }

          final trips = state is AssignedTripsLoaded
              ? state.trips
              : const <AssignedTrip>[];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                AssignedTripsAppBar(
                  onAvatarTap: () => showCaptainDevModeSheet(context),
                ),
                if (trips.isNotEmpty) _overview(trips),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CaptainDesignTokens.s24,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: Offset(0, trips.isEmpty ? -24 : -16),
                      child: AssignedTripsSectionTitle(tripCount: trips.length),
                    ),
                  ),
                ),
                if (trips.isEmpty) _awaitingTrips() else _tripList(trips),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _overview(List<AssignedTrip> trips) {
    final passengers = trips.fold<int>(0, (sum, t) => sum + t.passengerCount);
    final boarded = trips.fold<int>(0, (sum, t) => sum + t.boardedCount);
    final active = trips
        .where(
          (t) =>
              t.status == AssignedTripStatus.boarding ||
              t.status == AssignedTripStatus.inProgress,
        )
        .length;

    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -40),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CaptainDesignTokens.s24,
          ),
          child: AssignedTripsOverviewPanel(
            trips: trips.length,
            passengers: passengers,
            boarded: boarded,
            activeTrips: active,
          ),
        ),
      ),
    );
  }

  Widget _awaitingTrips() {
    return SliverPadding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s8,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s48,
      ),
      sliver: SliverToBoxAdapter(
        child: CaptainAwaitingTripsView(
          onRefresh: _refresh,
          isRefreshing: _refreshing,
          title: 'لا توجد رحلات اليوم',
          message:
              'لم تُسند إليك أي رحلة حتى الآن. فور إسناد رحلة من قِبل العمليات '
              'ستظهر هنا تلقائياً — لا حاجة لإعادة تسجيل الدخول.',
        ),
      ),
    );
  }

  Widget _tripList(List<AssignedTrip> trips) {
    return SliverPadding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s16,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s48,
      ),
      sliver: SliverList.separated(
        itemCount: trips.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: CaptainDesignTokens.s24),
        itemBuilder: (context, index) {
          final trip = trips[index];
          return AssignedTripCard(
            trip: trip,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TripExecutionPage(trip: trip)),
            ),
            onManifest: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PassengerListPage(tripId: trip.id),
              ),
            ),
          );
        },
      ),
    );
  }
}
