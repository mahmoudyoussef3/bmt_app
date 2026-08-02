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
import '../widgets/office_package_tile.dart';
import '../widgets/office_profile_header.dart';
import '../widgets/office_route_tile.dart';
import '../widgets/office_section_header.dart';

/// One office's marketplace profile: identity + rating, the departures it is
/// selling right now, the corridors it runs, and the commute packages it sells.
///
/// Departures come first because they are what a rider can act on today; the
/// route list is the fallback for a date the board does not reach. Both hand
/// off to the existing booking search — this screen owns no booking logic.
///
/// The whole screen is one scroll under a single masthead rather than a tab
/// bar: the three lists answer different questions ("can I travel today?",
/// "does this company go where I go?", "is a plan worth it?") and a rider
/// usually asks them in that order, so hiding two behind tabs would cost a tap
/// each without shortening anything. The masthead's count band and the section
/// glyphs do the wayfinding instead.
class OfficeProfileScreen extends StatelessWidget {
  const OfficeProfileScreen({super.key, required this.office});

  final OfficeSummary office;

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
        builder: (context, state) => ListView(
          padding: const EdgeInsets.fromLTRB(
            ClientSpacing.md,
            ClientSpacing.sm,
            ClientSpacing.md,
            ClientSpacing.xl,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            OfficeProfileHeader(office: office, counts: _countsOf(state)),
            const SizedBox(height: ClientSpacing.lg),
            switch (state) {
              OfficeProfileLoading() => const _ProfileSkeleton(),
              OfficeProfileError(:final message) => ClientErrorCard(
                message: message,
                retryLabel: l10n.common_retry,
                onRetry: () =>
                    context.read<OfficeProfileCubit>().load(office.id),
              ),
              // An office with nothing published is a dead end unless it ends
              // somewhere: two "none" notes and no action was the whole screen.
              OfficeProfileLoaded(:final routes, :final trips)
                  when routes.isEmpty && trips.isEmpty =>
                const OfficeNothingListedView(),
              OfficeProfileLoaded(
                :final routes,
                :final trips,
                :final packages,
              ) =>
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Section(
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
                    _Section(
                      icon: Icons.alt_route_rounded,
                      title: l10n.offices_routesHeader,
                      count: routes.length,
                      child: routes.isEmpty
                          ? OfficeEmptyNote(
                              icon: Icons.wrong_location_outlined,
                              message: l10n.offices_noRoutes,
                            )
                          : Column(
                              children: [
                                for (final route in routes) ...[
                                  OfficeRouteTile(
                                    route: route,
                                    onTap: () => _openRoute(context, route.id),
                                  ),
                                  const SizedBox(height: ClientSpacing.xs),
                                ],
                              ],
                            ),
                    ),
                    // Packages are supplementary, so the section only appears
                    // when this office actually sells any — no empty note.
                    //
                    // The tiles are read-only: a package has no price until a
                    // route prices it, so the rider picks one in the booking
                    // wizard's package step, not here.
                    if (packages.isNotEmpty)
                      _Section(
                        icon: Icons.card_membership_rounded,
                        title: l10n.packages_commutePackages,
                        count: packages.length,
                        child: Column(
                          children: [
                            for (final package in packages) ...[
                              OfficePackageTile(package: package),
                              const SizedBox(height: ClientSpacing.xs),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
            },
          ],
        ),
      ),
    );
  }

  /// The masthead's count band, once there is something to count.
  OfficeProfileCounts? _countsOf(OfficeProfileState state) => switch (state) {
    OfficeProfileLoaded(:final routes, :final trips, :final packages) => (
      departures: trips.length,
      routes: routes.length,
      packages: packages.length,
    ),
    _ => null,
  };
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.count,
    required this.child,
  });

  final IconData icon;
  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ClientSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OfficeSectionHeader(icon: icon, title: title, count: count),
          const SizedBox(height: ClientSpacing.sm),
          child,
        ],
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
