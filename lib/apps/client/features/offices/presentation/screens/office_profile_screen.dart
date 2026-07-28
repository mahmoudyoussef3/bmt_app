import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/routes/packages_routes.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/office_summary.dart';
import '../../domain/entities/office_trip.dart';
import '../cubit/office_profile_cubit.dart';
import '../cubit/office_profile_state.dart';
import '../widgets/office_nothing_listed_view.dart';
import '../widgets/office_package_tile.dart';
import '../widgets/office_profile_header.dart';
import '../widgets/office_route_tile.dart';
import '../widgets/office_trip_tile.dart';

/// One office's marketplace profile: identity + rating, the departures it is
/// selling right now, then the corridors it runs.
///
/// Departures come first because they are what a rider can act on today; the
/// route list is the fallback for a date the board does not reach. Both hand
/// off to the existing booking search — this screen owns no booking logic.
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

  /// Opens the packages marketplace already filtered to this office, so the
  /// rider lands on exactly this seller's plans and can compare and subscribe.
  void _openPackages(BuildContext context) {
    Navigator.pushNamed(
      context,
      PackagesRoutes.subscription,
      arguments: <String, dynamic>{'initialOfficeId': office.id},
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
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: ClientAppBar(
        title: office.name,
        subtitle: l10n.offices_directoryTitle,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          OfficeProfileHeader(office: office),
          const SizedBox(height: ClientSpacing.lg),
          BlocBuilder<OfficeProfileCubit, OfficeProfileState>(
            builder: (context, state) => switch (state) {
              OfficeProfileLoading() => const _ProfileSkeleton(),
              OfficeProfileError(:final message) => ClientErrorCard(
                message: message,
                retryLabel: l10n.common_retry,
                onRetry: () =>
                    context.read<OfficeProfileCubit>().load(office.id),
              ),
              // An office with nothing published is a dead end unless it ends
              // somewhere: two "none" notes and no action was the whole screen.
              OfficeProfileLoaded(:final routes, :final trips) when
                  routes.isEmpty && trips.isEmpty =>
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
                      title: l10n.offices_departuresHeader,
                      child: trips.isEmpty
                          ? _EmptyNote(message: l10n.offices_noDepartures)
                          : Column(
                              children: [
                                for (final trip in trips) ...[
                                  OfficeTripTile(
                                    trip: trip,
                                    onTap: () => _openTrip(context, trip),
                                  ),
                                  const SizedBox(height: ClientSpacing.sm),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: ClientSpacing.md),
                    _Section(
                      title: l10n.offices_routesHeader,
                      child: routes.isEmpty
                          ? _EmptyNote(message: l10n.offices_noRoutes)
                          : Column(
                              children: [
                                for (final route in routes) ...[
                                  OfficeRouteTile(
                                    route: route,
                                    onTap: () => _openRoute(context, route.id),
                                  ),
                                  const SizedBox(height: ClientSpacing.sm),
                                ],
                              ],
                            ),
                    ),
                    // Packages are supplementary, so the section only appears
                    // when this office actually sells any — no empty note.
                    if (packages.isNotEmpty) ...[
                      const SizedBox(height: ClientSpacing.md),
                      _Section(
                        title: l10n.packages_commutePackages,
                        child: Column(
                          children: [
                            for (final package in packages) ...[
                              OfficePackageTile(
                                package: package,
                                onTap: () => _openPackages(context),
                              ),
                              const SizedBox(height: ClientSpacing.sm),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientSectionHeader(title: title),
        const SizedBox(height: ClientSpacing.xs),
        child,
      ],
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClientSpacing.md),
      child: Text(message, style: ClientTypography.bodyMedium(context)),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ClientSkeleton(height: 68, borderRadius: 16),
        SizedBox(height: ClientSpacing.sm),
        ClientSkeleton(height: 68, borderRadius: 16),
        SizedBox(height: ClientSpacing.sm),
        ClientSkeleton(height: 68, borderRadius: 16),
      ],
    );
  }
}
