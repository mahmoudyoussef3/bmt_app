import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_danger_button.dart';

/// Trip Details' sticky bottom action bar — exactly one primary action set
/// per trip status, never a stray duplicate action (a previous version
/// showed a "Track Vehicle" button here for upcoming trips, which cannot be
/// tracked yet since they haven't started).
///
/// Cancelling is the destructive path and is styled as one; when a trip can be
/// both tracked and cancelled, tracking keeps the filled CTA.
class TripActionsBar extends StatelessWidget {
  const TripActionsBar({
    super.key,
    required this.trip,
    required this.canCancel,
    required this.canReview,
    required this.canTrack,
    required this.onCancel,
    required this.onReview,
    this.cancelInFlight = false,
  });

  final TripData trip;
  final bool canCancel;
  final bool canReview;
  final bool canTrack;
  final VoidCallback onCancel;
  final VoidCallback onReview;
  final bool cancelInFlight;

  /// Rating is a one-time act, so once the passenger has rated the trip the
  /// only thing left to offer them is booking the same journey again.
  bool get _isCompleted => trip.status == TripStatus.completed;

  @override
  Widget build(BuildContext context) {
    if (!canCancel && !canReview && !canTrack && !_isCompleted) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        border: Border(top: BorderSide(color: ClientColors.borderFor(context))),
        boxShadow: [
          BoxShadow(
            color: ClientColors.shadowFor(context).withAlpha(14),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canTrack)
                ClientButton(
                  label: 'Track Vehicle',
                  icon: const Icon(Icons.my_location_rounded, size: 20),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/tracking',
                    arguments: {'bookingId': trip.id},
                  ),
                ),
              if (canTrack && canCancel) const SizedBox(height: 10),
              if (canCancel)
                TripDangerButton(
                  label: cancelInFlight ? 'Cancelling…' : 'Cancel Trip',
                  isLoading: cancelInFlight,
                  onPressed: onCancel,
                ),
              if (_isCompleted)
                Row(
                  children: [
                    if (canReview) ...[
                      Expanded(
                        child: ClientButton(
                          label: 'Rate Trip',
                          onPressed: onReview,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ClientButton.secondary(
                        label: 'Book Again',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/booking/search'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
