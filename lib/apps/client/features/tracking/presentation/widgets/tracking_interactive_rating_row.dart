import 'package:flutter/material.dart';

/// A labelled row of 5 tappable stars for post-trip ratings.
class TrackingInteractiveRatingRow extends StatelessWidget {
  const TrackingInteractiveRatingRow({
    super.key,
    required this.label,
    required this.currentRating,
    required this.onRatingChanged,
    required this.scheme,
  });

  final String label;
  final int currentRating;
  final ValueChanged<int> onRatingChanged;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = starIndex <= currentRating;
            return GestureDetector(
              onTap: () => onRatingChanged(starIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFilled ? scheme.tertiary : Colors.grey.withAlpha(150),
                  size: 20,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
