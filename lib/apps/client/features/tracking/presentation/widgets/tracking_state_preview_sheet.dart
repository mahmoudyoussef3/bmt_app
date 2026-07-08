import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';

/// Debug-only sheet (shell-mode preview) letting a developer jump the screen
/// through every trip state without live data.
void showTrackingStatePreviewSheet(
  BuildContext context, {
  required TrackingTripState currentState,
  required ValueChanged<TrackingTripState> onChangeState,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Preview trip state',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in const {
                    'Waiting': TrackingTripState.notStarted,
                    'Heading': TrackingTripState.driverOnWay,
                    'Boarding': TrackingTripState.boarding,
                    'In route': TrackingTripState.inProgress,
                    'Done': TrackingTripState.completed,
                  }.entries)
                    _StateTab(
                      label: entry.key,
                      state: entry.value,
                      selected: currentState == entry.value,
                      onTap: () => onChangeState(entry.value),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StateTab extends StatelessWidget {
  const _StateTab({
    required this.label,
    required this.state,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final TrackingTripState state;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? ClientColors.primary : ClientColors.surfaceMutedFor(context).withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? ClientColors.primary : ClientColors.borderFor(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : ClientColors.textSecondaryFor(context),
          ),
        ),
      ),
    );
  }
}
