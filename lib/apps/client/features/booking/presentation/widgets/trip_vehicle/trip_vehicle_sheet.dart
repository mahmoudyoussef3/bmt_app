import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/trip_vehicle/trip_vehicle_gallery.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Shows the bus and captain behind a trip before the rider commits to it.
///
/// Returns `true` when the rider chose this trip from inside the sheet, so the
/// caller can select it and move on — inspecting a vehicle and picking it are
/// one decision, and making them two taps in two places loses people.
Future<bool?> showTripVehicleSheet(
  BuildContext context, {
  required RouteTripOptionData trip,
  required bool isSelected,
}) {
  return showClientBottomSheet<bool>(
    context: context,
    builder: (_) => TripVehicleSheet(trip: trip, isSelected: isSelected),
  );
}

class TripVehicleSheet extends StatelessWidget {
  const TripVehicleSheet({
    super.key,
    required this.trip,
    required this.isSelected,
  });

  final RouteTripOptionData trip;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final vehicle = trip.vehicle;
    final title = vehicle.displayName.isNotEmpty
        ? vehicle.displayName
        : trip.vehicleType;

    return ClientBottomSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetTitle(title: title, subtitle: trip.vehicleType),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TripVehicleGallery(imageUrls: vehicle.imageUrls),
                    const SizedBox(height: 24),
                    _CaptainRow(vehicle: vehicle),
                    const SizedBox(height: 20),
                    _SpecsGrid(trip: trip, vehicle: vehicle),
                    if (vehicle.features.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _Amenities(features: vehicle.features),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ClientButton(
              label: isSelected
                  ? context.l10n.common_dismiss
                  : context.l10n.booking_selectVehicle,
              onPressed: () => Navigator.of(context).pop(!isSelected),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.trim().isEmpty ? context.l10n.tracking_vehicle : title,
          style: ClientTypography.headingMedium(
            context,
          ).copyWith(color: ClientColors.textPrimaryFor(context)),
        ),
        if (subtitle.trim().isNotEmpty && subtitle.trim() != title.trim()) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ],
    );
  }
}

/// Who is driving. The captain is the part of the booking a rider is most
/// likely to be anxious about, so it sits directly under the photos rather
/// than at the bottom of a spec list.
class _CaptainRow extends StatelessWidget {
  const _CaptainRow({required this.vehicle});

  final TripVehicleProfile vehicle;

  @override
  Widget build(BuildContext context) {
    final name = vehicle.driverName.trim();
    if (name.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _CaptainAvatar(imageUrl: vehicle.driverImageUrl, name: name),
          const SizedBox(width: 14),
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
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          _RatingChip(
            rating: vehicle.driverRating,
            count: vehicle.driverRatingCount,
            rated: vehicle.hasDriverRating,
          ),
        ],
      ),
    );
  }
}

class _CaptainAvatar extends StatelessWidget {
  const _CaptainAvatar({required this.imageUrl, required this.name});

  final String imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: ClientColors.primaryLight,
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: ClientTypography.bodyMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w800, color: ClientColors.primary),
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: 46,
        height: 46,
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

/// A star and a number, or an honest "not rated yet".
///
/// A captain nobody has reviewed is not a bad captain, so an unrated one must
/// never be drawn as zero stars.
class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.rating,
    required this.count,
    required this.rated,
  });

  final double rating;
  final int count;
  final bool rated;

  @override
  Widget build(BuildContext context) {
    if (!rated) {
      return Text(
        context.l10n.booking_noRatingsYet,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: ClientColors.textTertiaryFor(context)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: ClientColors.primaryFor(context).withAlpha(20),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 14,
            color: ClientColors.primaryFor(context),
          ),
          const SizedBox(width: 3),
          Text(
            context.l10n.booking_ratingWithCount(
              rating.toStringAsFixed(1),
              count,
            ),
            style: ClientTypography.labelMedium(context).copyWith(
              fontWeight: FontWeight.w800,
              color: ClientColors.primaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// The facts a rider actually checks: how full the bus is, what it looks like,
/// and whether it is air conditioned. Empty fields are dropped rather than
/// rendered as dashes, so a thin fleet record still reads as a clean card.
class _SpecsGrid extends StatelessWidget {
  const _SpecsGrid({required this.trip, required this.vehicle});

  final RouteTripOptionData trip;
  final TripVehicleProfile vehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final specs = <_Spec>[
      _Spec(
        icon: Icons.event_seat_rounded,
        label: l10n.booking_availableSeats,
        value: '${trip.availableSeats}',
      ),
      if (vehicle.capacity > 0)
        _Spec(
          icon: Icons.groups_rounded,
          label: l10n.booking_vehicleCapacityLabel,
          value: l10n.booking_vehicleSeatsCount(vehicle.capacity),
        ),
      if (vehicle.plateNumber.isNotEmpty)
        _Spec(
          icon: Icons.confirmation_number_rounded,
          label: l10n.booking_vehiclePlate,
          value: vehicle.plateNumber,
        ),
      if (vehicle.manufactureYear > 0)
        _Spec(
          icon: Icons.calendar_month_rounded,
          label: l10n.booking_vehicleYear,
          value: '${vehicle.manufactureYear}',
        ),
      if (vehicle.color.isNotEmpty)
        _Spec(
          icon: Icons.palette_rounded,
          label: l10n.booking_vehicleColor,
          value: vehicle.color,
        ),
      if (vehicle.seatLayoutType.isNotEmpty)
        _Spec(
          icon: Icons.airline_seat_recline_normal_rounded,
          label: l10n.booking_seatType,
          value: vehicle.seatLayoutType,
        ),
      if (vehicle.hasAirConditioning)
        _Spec(
          icon: Icons.ac_unit_rounded,
          label: l10n.booking_ac,
          value: l10n.common_yes,
        ),
      if (vehicle.hasVehicleRating)
        _Spec(
          icon: Icons.star_rounded,
          label: l10n.trips_ratingVehicle,
          value: l10n.booking_ratingWithCount(
            vehicle.vehicleRating.toStringAsFixed(1),
            vehicle.vehicleRatingCount,
          ),
        ),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 16.0;
          final itemWidth = (constraints.maxWidth - spacing) / 2;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing * 1.5,
            children: specs.map((spec) => SizedBox(
              width: itemWidth,
              child: _SpecTile(spec: spec),
            )).toList(),
          );
        },
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

class _SpecTile extends StatelessWidget {
  const _SpecTile({required this.spec});

  final _Spec spec;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                spec.label,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: 4),
              Text(
                spec.value,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(
                  fontWeight: FontWeight.w700,
                  color: ClientColors.textPrimaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Amenities extends StatelessWidget {
  const _Amenities({required this.features});

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.booking_comfortAndAmenities,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(
              fontWeight: FontWeight.w600,
              color: ClientColors.textSecondaryFor(context),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features
                .map(
                  (feature) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ClientColors.primaryFor(context).withAlpha(18),
                      borderRadius: BorderRadius.circular(ClientRadius.pill),
                    ),
                    child: Text(
                      feature,
                      style: ClientTypography.labelMedium(context).copyWith(
                        color: ClientColors.primaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
