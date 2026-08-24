import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Where an operator drives, as one pinned line rather than a chip row.
///
/// Sits opposite the rating in a card's info row, so it must stay to a single
/// line no matter how many governorates an office serves — the chip listing
/// ([OfficeServiceAreas]) still owns the fuller picture on the profile
/// masthead.
class OfficeLocationLine extends StatelessWidget {
  const OfficeLocationLine({super.key, required this.areas});

  final List<String> areas;

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.place_rounded,
          size: 13,
          color: ClientColors.primaryFor(context),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            areas.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
