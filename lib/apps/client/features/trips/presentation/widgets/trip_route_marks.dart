import 'package:flutter/material.dart';

/// The pickup/drop-off dot-and-line marker beside a trip card's route text.
class TripRouteMarks extends StatelessWidget {
  const TripRouteMarks({
    super.key,
    required this.pickupColor,
    required this.dropoffColor,
  });

  final Color pickupColor;
  final Color dropoffColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: pickupColor, shape: BoxShape.circle),
        ),
        Container(
          width: 2,
          height: 22,
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: pickupColor.withAlpha(90),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Icon(Icons.location_on_rounded, size: 14, color: dropoffColor),
      ],
    );
  }
}
