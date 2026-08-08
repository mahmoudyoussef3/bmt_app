import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/office_summary.dart';
import '../../domain/entities/office_trip.dart';
import '../cubit/office_profile_cubit.dart';
import '../cubit/office_profile_state.dart';
import '../widgets/office_departures_section.dart';
import '../widgets/office_empty_note.dart';
import '../widgets/office_nothing_listed_view.dart';
import '../widgets/office_profile_header.dart';
import '../widgets/office_profile_section.dart';
import '../widgets/office_profile_stats.dart';
import '../widgets/office_routes_section.dart';

/// One office's marketplace profile: identity + rating, the departures it is
/// selling right now, and the corridors it runs.
///
/// Departures come first because they are what a rider can act on today; the
/// route list is the fallback for a date the board does not reach. Both hand
/// off to the existing booking search — this screen owns no booking logic.
///
/// Packages are deliberately absent. A plan has no price until a route prices
/// it, so a catalogue here could only ever say "priced later" — the plans now
/// appear on Route Details, where the corridor exists to quote them against.
class OfficeProfileScreen extends StatelessWidget {
  OfficeProfileScreen({super.key, required this.office});

  final OfficeSummary office;

  // Stable for the screen's lifetime: the router constructs this widget once
  // per visit, and BlocBuilder only rebuilds the subtree below it.
  final _departuresKey = GlobalKey();
  final _routesKey = GlobalKey();

  void _openRoute(BuildContext context, String routeId) {
    Navigator.pushNamed(
      context,
      BookingRoutes.routeSelection,
      arguments: BookingSearchQuery(routeId: routeId),
    );
  }

  /// Carries the exact departure the rider tapped into the booking flow, so the
  /// route, date and time are already chosen when they land there.
  void _openTrip(BuildContext context, OfficeTrip trip) {
    Navigator.pushNamed(
      context,
      BookingRoutes.routeSelection,
      arguments: BookingSearchQuery(
        routeId: trip.routeId,
        pickup: trip.pickup,
        destination: trip.destination,
        date: trip.tripDate,
        time: trip.departureTime,
      ),
    );
  }

  Future<void> _scrollToSection(OfficeProfileSection section) async {
    final key = switch (section) {
      OfficeProfileSection.departures => _departuresKey,
      OfficeProfileSection.routes => _routesKey,
    };
    final target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: ClientMotion.base,
      curve: ClientMotion.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      appBar: ClientAppBar(
        title: office.name,
        subtitle: l10n.offices_directoryTitle,
      ),
      body: BlocBuilder<OfficeProfileCubit, OfficeProfileState>(
        builder: (context, state) {
          final loaded = state is OfficeProfileLoaded ? state : null;

          return RefreshIndicator(
            onRefresh: () => context.read<OfficeProfileCubit>().load(office.id),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                ClientSpacing.md,
                ClientSpacing.sm,
                ClientSpacing.md,
                ClientSpacing.xl,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                OfficeProfileHeader(
                  office: office,
                  stats: loaded == null
                      ? null
                      : OfficeProfileStats(
                          counts: (
                            departures: loaded.trips.length,
                            routes: loaded.routes.length,
                          ),
                          onSelect: _scrollToSection,
                        ),
                ),
                const SizedBox(height: ClientSpacing.lg),
                switch (state) {
                  OfficeProfileLoading() => const _ProfileSkeleton(),
                  OfficeProfileError(:final message) => ClientErrorCard(
                    message: message,
                    retryLabel: l10n.common_retry,
                    onRetry: () =>
                        context.read<OfficeProfileCubit>().load(office.id),
                  ),
                  // An office with nothing published is a dead end unless it
                  // ends somewhere: two "none" notes and no action was the
                  // whole screen.
                  OfficeProfileLoaded(:final routes, :final trips)
                      when routes.isEmpty && trips.isEmpty =>
                    const OfficeNothingListedView(),
                  OfficeProfileLoaded(:final routes, :final trips) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OfficeProfileSectionBlock(
                        key: _departuresKey,
                        icon: Icons.departure_board_rounded,
                        title: l10n.offices_departuresHeader,
                        count: trips.length,
                        child: trips.isEmpty
                            ? OfficeEmptyNote(
                                icon: Icons.event_busy_rounded,
                                message: l10n.offices_noDepartures,
                              )
                            : OfficeDeparturesSection(
                                trips: trips,
                                onOpenTrip: (trip) => _openTrip(context, trip),
                              ),
                      ),
                      OfficeProfileSectionBlock(
                        key: _routesKey,
                        icon: Icons.alt_route_rounded,
                        title: l10n.offices_routesHeader,
                        count: routes.length,
                        child: routes.isEmpty
                            ? OfficeEmptyNote(
                                icon: Icons.wrong_location_outlined,
                                message: l10n.offices_noRoutes,
                              )
                            : OfficeRoutesSection(
                                routes: routes,
                                onOpenRoute: (route) =>
                                    _openRoute(context, route.id),
                              ),
                      ),
                    ],
                  ),
                },
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SkeletonHeading(width: 160),
        SizedBox(height: ClientSpacing.sm),
        ClientSkeleton(height: 76, borderRadius: ClientRadius.lg),
        SizedBox(height: ClientSpacing.xs),
        ClientSkeleton(height: 76, borderRadius: ClientRadius.lg),
        SizedBox(height: ClientSpacing.lg),
        _SkeletonHeading(width: 120),
        SizedBox(height: ClientSpacing.sm),
        ClientSkeleton(height: 76, borderRadius: ClientRadius.lg),
      ],
    );
  }
}

/// A section title's placeholder — start-aligned so the stretched column does
/// not blow it out to the full width and lose the "this is a heading" shape.
class _SkeletonHeading extends StatelessWidget {
  const _SkeletonHeading({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ClientSkeleton(
        height: 20,
        width: width,
        borderRadius: ClientRadius.xs,
      ),
    );
  }
}
