import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Shown above Route Details' content when the passenger's search had no
/// exact match — explains why the closest routes are being shown instead.
class ClosestMatchBanner extends StatelessWidget {
  const ClosestMatchBanner({super.key, required this.quality});

  final RouteMatchQuality quality;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPartial = quality == RouteMatchQuality.partial;
    final message = isPartial
        ? context.l10n.booking_noExactMatchCoversTrip
        : context.l10n.booking_noRouteMatchClosest;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withAlpha(70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.tertiary.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: scheme.tertiary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.booking_bestResultsForYou,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(170),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
