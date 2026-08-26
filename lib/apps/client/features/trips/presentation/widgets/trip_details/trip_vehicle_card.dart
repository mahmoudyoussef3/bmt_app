import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/trip_vehicle/trip_vehicle_gallery.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_detail_section.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_vehicle_photos_sheet.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_identity_labels.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The bus on this trip, given the room it was always owed.
///
/// It used to be one line inside the crew card — a name, a type pill and a
/// plate — which answered "which bus?" but none of the questions a rider
/// standing at a curb actually asks: *what does it look like, what colour is
/// it, how new is it, how full will it be.* The fleet record carries all of
/// that already (`public_trips` publishes the sanitised vehicle jsonb), so the
/// card now shows the photos first, the plate at plate scale, and the specs
/// underneath. Fields the office never filled in are dropped rather than drawn
/// as dashes, so a thin fleet record still reads as a finished card.
class TripVehicleCard extends StatelessWidget {
  const TripVehicleCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final specs = _specs(context);

    return TripDetailSection(
      title: context.l10n.trips_vehicleTitle,
      subtitle: context.l10n.trips_vehicleSubtitle,
      icon: Icons.directions_bus_filled_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VehiclePhotos(trip: trip),
          const SizedBox(height: 16),
          _VehicleIdentity(trip: trip),
          if (trip.vehicleNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            VehiclePlate(number: trip.vehicleNumber),
          ],
          if (specs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: ClientColors.borderFor(context),
            ),
            const SizedBox(height: 16),
            _SpecsGrid(specs: specs),
          ],
        ],
      ),
    );
  }

  /// The facts the fleet record actually carries, in the order a rider checks
  /// them: how full the bus is, then what it is.
  List<_Spec> _specs(BuildContext context) {
    final l10n = context.l10n;

    return [
      if (trip.vehicleCapacity > 0)
        _Spec(
          icon: Icons.event_seat_rounded,
          label: l10n.booking_availableSeats,
          value: l10n.trips_seatsAvailableOfTotal(
            trip.availableSeatCount,
            trip.vehicleCapacity,
          ),
        ),
      if (trip.vehicleSeatCapacity > 0)
        _Spec(
          icon: Icons.groups_rounded,
          label: l10n.booking_vehicleCapacityLabel,
          value: l10n.booking_vehicleSeatsCount(trip.vehicleSeatCapacity),
        ),
      if (trip.vehicleYear > 0)
        _Spec(
          icon: Icons.calendar_month_rounded,
          label: l10n.booking_vehicleYear,
          value: '${trip.vehicleYear}',
        ),
      if (trip.vehicleColor.isNotEmpty)
        _Spec(
          icon: Icons.palette_rounded,
          label: l10n.booking_vehicleColor,
          value: trip.vehicleColor,
        ),
      if (trip.vehicleSeatLayout.isNotEmpty)
        _Spec(
          icon: Icons.airline_seat_recline_normal_rounded,
          label: l10n.booking_seatType,
          value: trip.vehicleSeatLayout,
        ),
    ];
  }
}

/// The bus's own photos, swipeable in place.
///
/// Tapping opens the same sheet the crew row used to lead to — the gallery here
/// is a card-sized preview, and a rider who wants to look properly gets the
/// full-width one. With no photos on file the frame still draws, labelled: an
/// empty gap reads as a broken screen where a labelled placeholder reads as
/// "not photographed yet".
class _VehiclePhotos extends StatelessWidget {
  const _VehiclePhotos({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final gallery = TripVehicleGallery(
      imageUrls: trip.vehicleImageUrls,
      height: 170,
    );

    if (!trip.hasVehiclePhotos) return gallery;

    return GestureDetector(
      onTap: () => showTripVehiclePhotos(context, trip),
      behavior: HitTestBehavior.opaque,
      child: gallery,
    );
  }
}

/// What the bus is called, what class it is, and how it has been rated.
class _VehicleIdentity extends StatelessWidget {
  const _VehicleIdentity({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final name = trip.vehicleFullName.isEmpty
        ? vehicleNameFor(context, trip)
        : trip.vehicleFullName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingSmall(
                  context,
                ).copyWith(color: ClientColors.textPrimaryFor(context)),
              ),
            ),
            const SizedBox(width: 10),
            _VehicleRating(trip: trip),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (trip.vehicleType.trim().isNotEmpty)
              TripInlineBadge(
                label: trip.vehicleType,
                color: ClientColors.primaryFor(context),
              ),
            // The chip is an affordance as much as a count, so it opens the
            // gallery too — a rider who reads "3 photos" and taps it must not
            // find that only the picture above it was the button.
            if (trip.hasVehiclePhotos)
              GestureDetector(
                onTap: () => showTripVehiclePhotos(context, trip),
                child: TripPhotosChip(count: trip.vehicleImageUrls.length),
              ),
          ],
        ),
      ],
    );
  }
}

/// A star and a number, or an honest "not rated yet" — a bus nobody has
/// reviewed is not a bad bus, and must never be drawn as zero stars.
class _VehicleRating extends StatelessWidget {
  const _VehicleRating({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    if (!trip.hasVehicleRating) {
      return Text(
        context.l10n.booking_noRatingsYet,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: ClientColors.textTertiaryFor(context)),
      );
    }

    final color = ClientColors.ratingFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            context.l10n.booking_ratingWithCount(
              trip.vehicleRating.toStringAsFixed(1),
              trip.vehicleRatingCount,
            ),
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// The number on the outside of the bus, set the way a plate is: tabular
/// figures, wide tracking, its own framed field — because it is the one string
/// a rider matches character by character against a bus at the curb.
class VehiclePlate extends StatelessWidget {
  const VehiclePlate({super.key, required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.trips_vehicleNumberLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ClientColors.surfaceMutedFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.sm),
          border: Border.all(
            color: ClientColors.borderStrongFor(context),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 16,
              color: ClientColors.textTertiaryFor(context),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.booking_vehiclePlate,
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: ClientColors.textTertiaryFor(context)),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                number,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingSmall(context).copyWith(
                  fontSize: 17,
                  color: ClientColors.textPrimaryFor(context),
                  letterSpacing: 1.6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spec {
  const _Spec({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

/// Two columns on any surface wide enough for them, one on the narrowest
/// phones — a spec whose value has been squeezed into an ellipsis has stopped
/// being a spec.
class _SpecsGrid extends StatelessWidget {
  const _SpecsGrid({required this.specs});

  final List<_Spec> specs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final twoUp = constraints.maxWidth >= 300;
        final width = twoUp
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: 18,
          children: [
            for (final spec in specs)
              SizedBox(
                width: width,
                child: _SpecTile(spec: spec),
              ),
          ],
        );
      },
    );
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({required this.spec});

  final _Spec spec;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            spec.icon,
            size: 18,
            color: ClientColors.primaryFor(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: 3),
              Text(
                spec.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: ClientColors.textPrimaryFor(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
