import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

/// The semantic role a rating carries operationally: 1–2 is a problem, 3 is a
/// warning, 4–5 is fine. Operations should be able to read the board without
/// reading the numbers.
///
/// A tone rather than a colour, so the board's rating column matches the status
/// badges beside it in both themes. "Good" is the palette's positive cyan, not
/// the `#16A34A` green this file used to carry — the only green left in the
/// product.
AppStatusTone ratingTone(num rating) {
  if (rating <= 0) return AppStatusTone.warning;
  if (rating <= 2) return AppStatusTone.error;
  if (rating < 4) return AppStatusTone.warning;
  return AppStatusTone.success;
}

/// The ink for [ratingTone], resolved against the current theme.
Color ratingColor(BuildContext context, num rating) =>
    AppStatusStyle.of(context, ratingTone(rating)).accent;

/// A labelled star row, e.g. "السائق ★★★★☆ 4".
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.label,
    required this.rating,
    this.compact = false,
  });

  final String label;
  final int rating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ratingColor(context, rating);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.xSmall),
        for (var star = 1; star <= 5; star++)
          Icon(
            star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: compact ? 14 : 16,
            color: color,
          ),
        const SizedBox(width: AppSpacing.xSmall),
        Text(
          '$rating',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
