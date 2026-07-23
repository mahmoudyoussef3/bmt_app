import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';

import '../utils/trip_history_palette.dart';

/// Departure, arrival, and the time the trip spent between them.
///
/// The two ends used to be one string — `'07:05 → 08:30'` — which is exactly
/// the shape Arabic breaks. The clock runs are digits, so bidi keeps them
/// left-to-right, but the arrow between them is neutral and takes the
/// paragraph's RTL direction instead; the runs are then reordered around it and
/// the line renders as `08:30 → 07:05`: arrival first, arrow aimed back at the
/// departure it came from.
///
/// Laying the ends out as real widgets lets the row order itself from the
/// ambient direction — departure leads on the right, where Arabic starts
/// reading — and leaves no arrow glyph to point the wrong way.
class TripHistoryTimeStrip extends StatelessWidget {
  const TripHistoryTimeStrip({
    super.key,
    required this.departure,
    required this.arrival,
    required this.duration,
  });

  final DateTime departure;
  final DateTime arrival;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // The ends are Flexible rather than fixed: at an enlarged system font
    // "المغادرة" and "الوصول" grow until the two of them alone exceed the card,
    // and an unconstrained pair overflows the row no matter how far the link
    // between them shrinks.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: _Endpoint(
            label: 'المغادرة',
            time: CaptainFormats.clock(departure),
            alignment: CrossAxisAlignment.start,
          ),
        ),
        Expanded(child: _Link(duration: duration)),
        Flexible(
          child: _Endpoint(
            label: 'الوصول',
            time: CaptainFormats.clock(arrival),
            alignment: CrossAxisAlignment.end,
          ),
        ),
      ],
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.label,
    required this.time,
    required this.alignment,
  });

  final String label;
  final String time;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CaptainTypography.labelSmall(
            context,
          ).copyWith(color: TripHistoryPalette.neutral(context)),
        ),
        const SizedBox(height: 2),
        // The clock is the value the captain came for — it stays on one line
        // and never wraps, whatever the label above it does.
        Text(
          time,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CaptainTypography.titleSmall(
            context,
          ).copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

/// The run between the two ends, carrying the duration it took.
class _Link extends StatelessWidget {
  const _Link({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CaptainDesignTokens.s8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CaptainFormats.duration(duration),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaptainTypography.labelSmall(context).copyWith(
              color: TripHistoryPalette.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s4),
          Row(
            children: [
              const _Dot(),
              Expanded(
                child: Container(
                  height: 2,
                  color: CaptainColors.dividerFor(context),
                ),
              ),
              const _Dot(),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: TripHistoryPalette.accent,
        shape: BoxShape.circle,
      ),
    );
  }
}
