import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_awaiting_trips_view.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_dev_mode_sheet.dart';

import '../../domain/entities/assigned_trip.dart';
import '../../domain/entities/captain_day_summary.dart';
import '../cubit/assigned_trips_cubit.dart';
import '../cubit/assigned_trips_state.dart';
import '../widgets/assigned_trip_card.dart';
import '../widgets/assigned_trips_header.dart';
import '../widgets/assigned_trips_section_title.dart';
import '../widgets/assigned_trips_skeleton.dart';
import '../widgets/assigned_trips_stats_strip.dart';
import '../widgets/captain_day_complete_card.dart';
import '../widgets/captain_focus_card.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/new_assignments_banner.dart';

class AssignedTripsPage extends StatefulWidget {
  const AssignedTripsPage({super.key});

  @override
  State<AssignedTripsPage> createState() => _AssignedTripsPageState();
}

class _AssignedTripsPageState extends State<AssignedTripsPage> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    context.read<AssignedTripsCubit>().load();
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final succeeded = await context.read<AssignedTripsCubit>().refresh();
      if (!succeeded && mounted) {
        AppSnackbar.error(
          context,
          'تعذر تحديث الرحلات، تحقق من الاتصال وحاول مجدداً',
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _openTrip(AssignedTrip trip) => context.openTripExecution(trip);

  void _openManifest(AssignedTrip trip) =>
      context.openPassengerManifest(trip.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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
          final newTripIds = state is AssignedTripsLoaded
              ? state.newTripIds
              : const <String>{};

          return RefreshIndicator(
            onRefresh: _refresh,
            child: _Content(
              summary: CaptainDaySummary.fromTrips(trips),
              trips: trips,
              newTripCount: newTripIds.length,
              isRefreshing: _refreshing,
              onRefresh: _refresh,
              onOpenTrip: _openTrip,
              onOpenManifest: _openManifest,
              onAcknowledgeNewTrips: () =>
                  context.read<AssignedTripsCubit>().acknowledgeNewTrips(),
            ),
          );
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.summary,
    required this.trips,
    required this.newTripCount,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onOpenTrip,
    required this.onOpenManifest,
    required this.onAcknowledgeNewTrips,
  });

  final CaptainDaySummary summary;
  final List<AssignedTrip> trips;
  final int newTripCount;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final ValueChanged<AssignedTrip> onOpenTrip;
  final ValueChanged<AssignedTrip> onOpenManifest;
  final VoidCallback onAcknowledgeNewTrips;

  @override
  Widget build(BuildContext context) {
    final focus = summary.focusTrip;
    // The focus trip is already shown as the hero above, so the list carries
    // the rest of the day.
    final rest = trips.where((t) => t.id != focus?.id).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        AssignedTripsHeader(
          onAvatarTap: () => showCaptainDevModeSheet(context),
          onNotificationsTap: () => context.openNotifications(),
        ),
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(
            CaptainDesignTokens.s20,
            CaptainDesignTokens.s20,
            CaptainDesignTokens.s20,
            // The shell paints this page under its floating nav bar.
            CaptainBottomNav.reservedSpace(context),
          ),
          sliver: SliverList.list(
            children: [
              if (summary.isEmpty)
                CaptainAwaitingTripsView(
                  onRefresh: onRefresh,
                  isRefreshing: isRefreshing,
                  title: 'لا توجد رحلات اليوم',
                  message:
                      'لم تُسند إليك أي رحلة حتى الآن. فور إسناد رحلة من قِبل '
                      'العمليات ستظهر هنا تلقائياً — لا حاجة لإعادة تسجيل الدخول.',
                )
              else ...[
                if (newTripCount > 0) ...[
                  NewAssignmentsBanner(
                    count: newTripCount,
                    onAcknowledge: onAcknowledgeNewTrips,
                  ),
                  const SizedBox(height: CaptainDesignTokens.s16),
                ],
                if (focus != null)
                  CaptainFocusCard(trip: focus, onOpen: () => onOpenTrip(focus))
                else
                  CaptainDayCompleteCard(tripCount: summary.totalTrips),
                if (focus != null) ...[
                  const SizedBox(height: CaptainDesignTokens.s16),
                  HomeQuickActions(tripId: focus.id),
                ],
                const SizedBox(height: CaptainDesignTokens.s16),
                AssignedTripsStatsStrip(summary: summary),
                if (rest.isNotEmpty) ...[
                  const SizedBox(height: CaptainDesignTokens.s24),
                  AssignedTripsSectionTitle(
                    title: focus == null ? 'رحلات اليوم' : 'بقية رحلات اليوم',
                    count: rest.length,
                  ),
                  const SizedBox(height: CaptainDesignTokens.s12),
                  for (final trip in rest) ...[
                    AssignedTripCard(
                      trip: trip,
                      onOpen: () => onOpenTrip(trip),
                      onManifest: () => onOpenManifest(trip),
                    ),
                    const SizedBox(height: CaptainDesignTokens.s12),
                  ],
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
