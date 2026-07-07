import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The driver's name and star-rating row inside [TripDriverCard].
class DriverIdentity extends StatelessWidget {
  const DriverIdentity({super.key, required this.name, required this.rating});

  final String name;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: ClientColors.textPrimaryFor(context)),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(
              Icons.star_rounded,
              size: 17,
              color: ClientColors.journeyAmber,
            ),
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: ClientTypography.bodySmall(context).copyWith(
                fontWeight: FontWeight.w900,
                color: ClientColors.textPrimaryFor(context),
              ),
            ),
            Text(
              ' · Verified captain',
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ],
        ),
      ],
    );
  }
}
