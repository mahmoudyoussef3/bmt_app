import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

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
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(
              _isRated ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 17,
              color: ClientColors.journeyAmber,
            ),
            const SizedBox(width: 4),
            Text(
              _isRated ? rating.toStringAsFixed(1) : 'New captain',
              style: ClientTypography.bodySmall(context).copyWith(
                fontWeight: FontWeight.w900,
                color: ClientColors.textPrimaryFor(context),
              ),
            ),
            // A long captain name — or a narrow phone — used to push this
            // straight off the card's right edge.
            Flexible(
              child: Text(
                _isRated ? ' · $ratingCount ratings' : ' · Verified captain',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
