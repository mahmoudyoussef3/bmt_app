import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// One thing being rated (the captain, the vehicle, or the route).
///
/// A [value] of 0 means "not rated yet" and renders as five empty stars —
/// pre-filling stars would collect praise the passenger never actually gave.
/// Pass a null [onChanged] to render the stars read-only.
class TripReviewRatingCard extends StatelessWidget {
  const TripReviewRatingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  final String title;
  final String subtitle;
  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isReadOnly = onChanged == null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                _Star(
                  filled: star <= value,
                  semanticLabel: context.l10n.trips_starRatingSemantic(
                    star,
                    title,
                  ),
                  onTap: isReadOnly ? null : () => onChanged!(star),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.filled,
    required this.semanticLabel,
    this.onTap,
  });

  final bool filled;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      filled ? Icons.star_rounded : Icons.star_outline_rounded,
      color: ClientColors.journeyAmber,
      size: 28,
      semanticLabel: semanticLabel,
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 4),
        child: icon,
      );
    }

    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: onTap,
      icon: icon,
    );
  }
}
