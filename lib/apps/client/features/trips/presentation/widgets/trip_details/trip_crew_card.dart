import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/driver_avatar.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/driver_identity.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_identity_labels.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Who is driving, in one row.
///
/// The bus used to share this card, as a single line naming it and its plate.
/// It has moved out into [TripVehicleCard], where the photos, the plate and the
/// fleet record's specs have room — the captain is one fact and reads as one
/// row, and the bus turned out to be several.
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
      child: Row(
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
      ),
    );
  }
}
