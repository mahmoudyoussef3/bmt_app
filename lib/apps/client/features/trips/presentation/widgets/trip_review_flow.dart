import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

/// Post-trip review sheet: driver, vehicle, route ratings (UI only).
Future<void> showTripReviewFlow(
  BuildContext context, {
  required String tripReference,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _TripReviewSheet(tripReference: tripReference),
  );
}

class _TripReviewSheet extends StatefulWidget {
  const _TripReviewSheet({required this.tripReference});

  final String tripReference;

  @override
  State<_TripReviewSheet> createState() => _TripReviewSheetState();
}

class _TripReviewSheetState extends State<_TripReviewSheet> {
  int _driverRating = 5;
  int _vehicleRating = 5;
  int _routeRating = 4;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rate your trip',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 6),
            Text(
              widget.tripReference,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withAlpha(170),
              ),
            ),
            const SizedBox(height: 20),
            _RatingRow(
              title: 'Driver rating',
              subtitle: 'Ahmed Mohamed',
              value: _driverRating,
              onChanged: (v) => setState(() => _driverRating = v),
            ),
            const SizedBox(height: 16),
            _RatingRow(
              title: 'Vehicle rating',
              subtitle: 'Mega Coach Elite',
              value: _vehicleRating,
              onChanged: (v) => setState(() => _vehicleRating = v),
            ),
            const SizedBox(height: 16),
            _RatingRow(
              title: 'Route rating',
              subtitle: 'Banha Station → Smart Village',
              value: _routeRating,
              onChanged: (v) => setState(() => _routeRating = v),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share feedback (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Submit review',
              height: 50,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your review (demo)'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withAlpha(160),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => onChanged(star),
                icon: Icon(
                  star <= value
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: scheme.tertiary,
                  size: 28,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
