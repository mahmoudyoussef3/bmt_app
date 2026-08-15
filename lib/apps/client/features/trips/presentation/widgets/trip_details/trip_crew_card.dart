import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/driver_avatar.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/driver_identity.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_vehicle_photos_sheet.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_identity_labels.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// Who is driving and which bus, in one card.
///
/// These used to be two titled sections with a header, a subtitle and a divider
/// each. A passenger asks both questions at once — *who is picking me up, in
/// what* — so they are answered together: the captain on top, the bus beneath,
/// and the bus tappable when there are photos of it on file.
class TripCrewCard extends StatelessWidget {
  const TripCrewCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: ClientColors.shadowFor(context).withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CaptainRow(trip: trip),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: ClientColors.borderFor(context),
            ),
          ),
          _VehicleRow(trip: trip),
        ],
      ),
    );
  }
}

class _CaptainRow extends StatelessWidget {
  const _CaptainRow({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DriverAvatar(
          initials: trip.driverInitials,
          imageUrl: trip.driverPhotoUrl,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DriverIdentity(
            name: driverNameFor(context, trip),
            rating: trip.driverRating,
            ratingCount: trip.driverRatingCount,
          ),
        ),
        const SizedBox(width: 8),
        TripInlineBadge(
          label: context.l10n.tracking_captain,
          color: ClientColors.primaryFor(context),
        ),
      ],
    );
  }
}

/// The bus: what it is, its number, and — when the operator photographed it —
/// a way into those photos. With no photos on file the row is inert rather than
/// tappable, so nothing promises a gallery that would open empty.
class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final hasPhotos = trip.hasVehiclePhotos;

    final row = Row(
      children: [
        _VehicleThumb(trip: trip),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicleNameFor(context, trip),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingSmall(
                  context,
                ).copyWith(color: ClientColors.textPrimaryFor(context)),
              ),
              const SizedBox(height: 6),
              // Type, number and photo count all wrap together rather than
              // competing for one line: on a narrow phone the plate is the
              // string that must survive intact, so nothing sits beside it that
              // can push it into an ellipsis.
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
                  if (trip.vehicleNumber.isNotEmpty)
                    _VehicleNumberChip(number: trip.vehicleNumber),
                  if (hasPhotos)
                    TripPhotosChip(count: trip.vehicleImageUrls.length),
                ],
              ),
            ],
          ),
        ),
        if (hasPhotos)
          DirectionalIcon(
            Icons.chevron_right_rounded,
            size: 20,
            color: ClientColors.textTertiaryFor(context),
          ),
      ],
    );

    if (!hasPhotos) return row;

    return InkWell(
      onTap: () => showTripVehiclePhotos(context, trip),
      borderRadius: BorderRadius.circular(ClientRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }
}

/// The bus's first photo when there is one, else the generic bus mark. The
/// thumbnail is itself the hint that photos exist.
class _VehicleThumb extends StatelessWidget {
  const _VehicleThumb({required this.trip});

  final TripData trip;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final color = ClientColors.primaryFor(context);
    final placeholder = ColoredBox(
      color: color.withAlpha(32),
      child: Icon(Icons.directions_bus_filled_rounded, color: color, size: 22),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(ClientRadius.sm),
      child: SizedBox(
        width: _size,
        height: _size,
        child: trip.hasVehiclePhotos
            ? Image.network(
                trip.vehicleImageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : placeholder,
              )
            : placeholder,
      ),
    );
  }
}

/// The vehicle's number, set like a plate: tabular figures and wide tracking,
/// because it is read character by character off the back of a bus.
class _VehicleNumberChip extends StatelessWidget {
  const _VehicleNumberChip({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.trips_vehicleNumberLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: ClientColors.surfaceMutedFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.xs),
          border: Border.all(color: ClientColors.borderFor(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 13,
              color: ClientColors.textTertiaryFor(context),
            ),
            const SizedBox(width: 6),
            // Flexible, not bare: inside a Wrap this chip can be handed a
            // narrower box than its natural width, and a long plate must
            // ellipsize rather than overflow the card.
            Flexible(
              child: Text(
                number,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelMedium(context).copyWith(
                  color: ClientColors.textPrimaryFor(context),
                  letterSpacing: 1.2,
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
