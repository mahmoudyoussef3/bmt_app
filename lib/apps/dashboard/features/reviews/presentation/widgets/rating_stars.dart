import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

const Color kRatingAmber = Color(0xFFD97706);
const Color kRatingRed = Color(0xFFDC2626);
const Color kRatingGreen = Color(0xFF16A34A);

/// Colours a rating by what it means operationally: 1–2 is a problem, 3 is a
/// warning, 4–5 is fine. Operations should be able to read the board without
/// reading the numbers.
Color ratingColor(num rating) {
  if (rating <= 0) return kRatingAmber;
  if (rating <= 2) return kRatingRed;
  if (rating < 4) return kRatingAmber;
  return kRatingGreen;
}

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
    final color = ratingColor(rating);

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
