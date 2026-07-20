import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/trip_vehicle/trip_vehicle_sheet.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

class WizardTripStep extends StatelessWidget {
  const WizardTripStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
      builder: (context, session) {
        final trips = session.route.availableTrips;
        if (trips.isEmpty) {
          return _EmptyTrips(routeName: session.route.routeName);
        }
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  BookingStepIntro(
                    icon: Icons.directions_bus_rounded,
                    title: context.l10n.booking_chooseYourDeparture,
                    subtitle: context.l10n.booking_pickupToDropoff(
                      session.pickupStop?.name ?? '',
                      session.dropoffStop?.name ?? '',
                    ),
                    trailing: BookingCountPill(
                      label: context.l10n.home_seatsAvailable(trips.length),
                      color: ClientColors.journeyCyan,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...trips.indexed.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TripCard(
                        trip: entry.$2,
                        index: entry.$1,
                        isSelected: session.selectedTrip?.id == entry.$2.id,
                        onTap: () => context
                            .read<BookingWizardCubit>()
                            .selectTrip(entry.$2),
                        onViewDetails: () => _openVehicleSheet(
                          context,
                          trip: entry.$2,
                          isSelected: session.selectedTrip?.id == entry.$2.id,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            BookingBottomAction(
              summary: session.selectedTrip == null
                  ? null
                  : Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: ClientColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _departureSummary(context, session.selectedTrip!),
                            style: ClientTypography.bodySmall(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          context.l10n.packages_egpAmount(
                            session.selectedTrip!.price,
                          ),
                          style: ClientTypography.priceSmall(
                            context,
                          ).copyWith(color: ClientColors.primary),
                        ),
                      ],
                    ),
              child: ClientButton(
                label: context.l10n.booking_chooseASeat,
                icon: const DirectionalIcon(Icons.arrow_forward_rounded),
                onPressed: session.tripValid ? onNext : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Opens the vehicle sheet, and selects the trip if the rider chose it from
/// inside. Inspecting the bus and picking it is one decision to the rider, so
/// the sheet is allowed to complete it rather than sending them back to tap
/// the card again.
Future<void> _openVehicleSheet(
  BuildContext context, {
  required RouteTripOptionData trip,
  required bool isSelected,
}) async {
  final cubit = context.read<BookingWizardCubit>();
  final chose = await showTripVehicleSheet(
    context,
    trip: trip,
    isSelected: isSelected,
  );
  if (chose == true) cubit.selectTrip(trip);
}

/// "Departs Tomorrow · 8:00 AM" — the day is part of the commitment, not just
/// the clock, so it travels with the summary the rider confirms on.
String _departureSummary(BuildContext context, RouteTripOptionData trip) {
  final day = formatTripDay(context, trip.tripDate);
  final time = formatTripTime(context, trip.departureTime);
  if (day.isEmpty) return context.l10n.booking_departsAtTime(time);
  return context.l10n.booking_departsOnDayAtTime(day, time);
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.onViewDetails,
  });
  final RouteTripOptionData trip;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BookingSurfaceCard(
        selected: isSelected,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // The day the rider travels. It is also the day any package they
            // buy starts running, so it must never be a hidden detail.
            if (trip.tripDate.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 15,
                    color: ClientColors.textSecondaryFor(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatTripDay(context, trip.tripDate),
                    style: ClientTypography.labelSmall(context).copyWith(
                      color: ClientColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ClientColors.primary
                        : ClientColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    index == 0
                        ? Icons.bolt_rounded
                        : Icons.directions_bus_rounded,
                    color: isSelected ? Colors.white : ClientColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        formatTripTime(context, trip.departureTime),
                        style: ClientTypography.headingMedium(
                          context,
                        ).copyWith(fontWeight: FontWeight.w900),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: ClientColors.borderStrongFor(context),
                                ),
                              ),
                              const DirectionalIcon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: ClientColors.journeySlate,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        formatTripTime(context, trip.arrivalTime),
                        style: ClientTypography.bodyMedium(context).copyWith(
                          color: ClientColors.textSecondaryFor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: ClientColors.primary,
                    size: 24,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: ClientColors.borderFor(context)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _chip(
                    context,
                    Icons.airline_seat_recline_extra_rounded,
                    trip.vehicle.displayName.isNotEmpty
                        ? trip.vehicle.displayName
                        : trip.vehicleType,
                  ),
                ),
                Expanded(
                  child: _chip(
                    context,
                    Icons.event_seat_rounded,
                    '${trip.availableSeats} ${context.l10n.seatSelection_seatsLeftLabel}',
                    color: trip.availableSeats <= 3
                        ? ClientColors.journeyAmber
                        : ClientColors.journeyCyan,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.l10n.packages_egpAmount(trip.price),
                      style: ClientTypography.priceSmall(context).copyWith(
                        color: isSelected
                            ? ClientColors.primary
                            : ClientColors.textPrimaryFor(context),
                      ),
                    ),
                    Text(
                      context.l10n.booking_perRide,
                      style: ClientTypography.labelSmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ],
            ),
            // Riders commit more readily to a bus they have seen and a captain
            // they can name, so the card offers both before the seat step —
            // even when the route runs a single vehicle and there is nothing
            // to compare it against.
            const SizedBox(height: 14),
            Divider(height: 1, color: ClientColors.borderFor(context)),
            const SizedBox(height: 12),
            _VehicleFooter(
              vehicle: trip.vehicle,
              onViewDetails: onViewDetails,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    IconData icon,
    String label, {
    Color? color,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 15,
        color: color ?? ClientColors.textSecondaryFor(context),
      ),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.labelSmall(context).copyWith(
            color: color ?? ClientColors.textSecondaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

/// The captain's face and name on the left, the way into the photos on the
/// right. When the operator has filed nothing about the bus, the row collapses
/// to the button alone rather than showing empty labels.
class _VehicleFooter extends StatelessWidget {
  const _VehicleFooter({required this.vehicle, required this.onViewDetails});

  final TripVehicleProfile vehicle;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final driver = vehicle.driverName.trim();

    return Row(
      children: [
        if (driver.isNotEmpty) ...[
          _DriverThumb(imageUrl: vehicle.driverImageUrl, name: driver),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.booking_driver,
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textTertiaryFor(context)),
                ),
                Text(
                  driver,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ] else
          const Spacer(),
        TextButton.icon(
          onPressed: onViewDetails,
          style: TextButton.styleFrom(
            foregroundColor: ClientColors.primaryFor(context),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(
            vehicle.hasImages
                ? Icons.photo_library_rounded
                : Icons.info_outline_rounded,
            size: 16,
          ),
          label: Text(
            context.l10n.booking_viewVehicleAndPhotos,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _DriverThumb extends StatelessWidget {
  const _DriverThumb({required this.imageUrl, required this.name});

  final String imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: ClientColors.primaryLight,
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: ClientTypography.labelMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w800, color: ClientColors.primary),
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: 30,
        height: 30,
        child: imageUrl.trim().isEmpty
            ? placeholder
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : placeholder,
              ),
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({required this.routeName});
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_bus_outlined,
              size: 64,
              color: ClientColors.journeySlate,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.booking_noTripsAvailable,
              style: ClientTypography.headingSmall(context),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.booking_noTripsFoundForRoute(routeName),
              textAlign: TextAlign.center,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ],
        ),
      ),
    );
  }
}
