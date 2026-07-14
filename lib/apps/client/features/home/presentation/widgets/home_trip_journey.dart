import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Pickup → destination as a vertical timeline. Full width by design: stop
/// names like "American University in Cairo" must stay readable, which the
/// old side-by-side carousel cards could not do.
class HomeTripJourney extends StatelessWidget {
  const HomeTripJourney({
    super.key,
    required this.pickup,
    required this.destination,
  });

  final String pickup;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _JourneyTrack(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Stop(label: pickup, caption: 'Pickup'),
              const SizedBox(height: 14),
              _Stop(label: destination, caption: 'Drop-off'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.label, required this.caption});

  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption.toUpperCase(),
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.textTertiaryFor(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.isEmpty ? 'Stop not set' : label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(fontWeight: FontWeight.w700, height: 1.25),
        ),
      ],
    );
  }
}

/// Dot – line – dot rail sized to sit beside the two stop blocks.
class _JourneyTrack extends StatelessWidget {
  const _JourneyTrack();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          const _TrackDot(color: ClientColors.journeyGreen),
          Container(
            width: 2,
            height: 30,
            margin: const EdgeInsets.symmetric(vertical: 3),
            color: ClientColors.borderFor(context),
          ),
          const _TrackDot(color: ClientColors.journeyAmber),
        ],
      ),
    );
  }
}

class _TrackDot extends StatelessWidget {
  const _TrackDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(60), width: 3),
      ),
    );
  }
}
