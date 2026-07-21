import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/transport_office.dart';

/// Names the transport office operating a route or trip, with its rating.
///
/// EWT lists several offices on the same corridor, so this is what stops two
/// providers' departures from reading as one timetable. It renders nothing for a route
/// with no attributed office rather than showing an empty chip.
class RouteOfficeChip extends StatelessWidget {
  const RouteOfficeChip({super.key, required this.office, this.compact = false});

  final TransportOffice office;

  /// Tighter styling for dense rows such as a per-departure tile.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!office.isKnown || office.name.isEmpty) return const SizedBox.shrink();

    final textStyle = compact
        ? ClientTypography.labelSmall(context)
        : ClientTypography.labelMedium(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.storefront_rounded,
          size: compact ? 13 : 15,
          color: ClientColors.textSecondaryFor(context),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            office.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(
              color: ClientColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (office.hasRating) ...[
          const SizedBox(width: 8),
          Icon(Icons.star_rounded, size: compact ? 13 : 15, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            office.rating.toStringAsFixed(1),
            style: textStyle.copyWith(
              color: ClientColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
