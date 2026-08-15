import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/trip_vehicle/trip_vehicle_gallery.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_identity_labels.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The photos of the bus on this trip — the same gallery a rider swiped through
/// while booking, reached here from the crew card.
///
/// It reuses booking's [TripVehicleGallery] rather than growing a second photo
/// viewer: the fleet stores one comma-joined `image_url` per vehicle, and both
/// surfaces are showing the very same pictures of the very same bus.
Future<void> showTripVehiclePhotos(BuildContext context, TripData trip) {
  return showClientBottomSheet<void>(
    context: context,
    builder: (_) => _TripVehiclePhotosSheet(trip: trip),
  );
}

class _TripVehiclePhotosSheet extends StatelessWidget {
  const _TripVehiclePhotosSheet({required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final number = trip.vehicleNumber;

    return ClientBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            vehicleNameFor(context, trip),
            style: ClientTypography.headingMedium(
              context,
            ).copyWith(color: ClientColors.textPrimaryFor(context)),
          ),
          const SizedBox(height: 6),
          Text(
            number.isEmpty
                ? trip.vehicleType
                : '${trip.vehicleType} · $number',
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: 18),
          TripVehicleGallery(imageUrls: trip.vehicleImageUrls),
          const SizedBox(height: 20),
          ClientButton.secondary(
            label: context.l10n.common_dismiss,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// The tinted "N photos" affordance on the crew card. Drawn only when the bus
/// actually has photos on file, so the row never invites a tap that opens an
/// empty gallery.
class TripPhotosChip extends StatelessWidget {
  const TripPhotosChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final color = ClientColors.primaryFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            context.l10n.trips_vehiclePhotosCount(count),
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
