import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The driver's name and public star-rating row inside [TripDriverCard].
///
/// The rating is the average of every passenger review of this captain. A
/// captain nobody has reviewed yet reads as "New captain" — showing them as
/// 0.0 stars would punish them for having no history.
class DriverIdentity extends StatelessWidget {
  const DriverIdentity({
    super.key,
    required this.name,
    required this.rating,
    this.ratingCount = 0,
  });

  final String name;
  final double rating;
  final int ratingCount;

  bool get _isRated => ratingCount > 0 && rating > 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: ClientColors.textPrimaryFor(context)),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              _isRated ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 15,
              // Gold is the rating color; amber is reserved for warnings.
              color: ClientColors.ratingFor(context),
            ),
            const SizedBox(width: 4),
            Text(
              _isRated
                  ? rating.toStringAsFixed(1)
                  : context.l10n.trips_newCaptain,
              style: ClientTypography.labelMedium(context).copyWith(
                fontWeight: FontWeight.w800,
                color: ClientColors.textPrimaryFor(context),
              ),
            ),
            Flexible(
              child: Text(
                _isRated
                    ? ' · ${context.l10n.trips_ratingsCount(ratingCount)}'
                    : ' · ${context.l10n.trips_verifiedCaptain}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textTertiaryFor(context)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
