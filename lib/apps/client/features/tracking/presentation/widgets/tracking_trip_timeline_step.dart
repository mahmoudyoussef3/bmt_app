import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// One row of [TrackingTripTimeline]: a dot-and-line marker plus the step's
/// label, with an expanded description shown only while active.
class TrackingTripTimelineStep extends StatelessWidget {
  const TrackingTripTimelineStep({
    super.key,
    required this.label,
    required this.description,
    required this.isCompleted,
    required this.isActive,
    required this.isRemaining,
    required this.isLast,
  });

  final String label;
  final String description;
  final bool isCompleted;
  final bool isActive;
  final bool isRemaining;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final stepColor = isCompleted
        ? ClientColors.journeyCyan
        : isActive
        ? ClientColors.primary
        : ClientColors.borderFor(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? stepColor.withAlpha(40)
                      : isCompleted
                      ? stepColor
                      : Colors.transparent,
                  border: Border.all(color: stepColor, width: isActive ? 5 : 2),
                ),
                child: isCompleted
                    ? const Center(
                        child: Icon(Icons.check, size: 10, color: Colors.white),
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? ClientColors.journeyCyan
                        : ClientColors.borderFor(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive
                          ? ClientColors.primary
                          : isRemaining
                          ? ClientColors.textSecondaryFor(context)
                          : ClientColors.textPrimaryFor(context),
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: ClientColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
