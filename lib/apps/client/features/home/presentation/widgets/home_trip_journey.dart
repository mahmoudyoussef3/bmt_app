import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Pickup → destination as a vertical timeline, so stop names like "American
/// University in Cairo" stay readable instead of being squeezed side by side.
///
/// Two dressings of the same rail:
///
/// * the default — captioned stops, for the full-width booking card;
/// * [dense] — captions dropped and each name held in a fixed two-line slot,
///   for the ticket rail on Home. The fixed slot is what lets a rail of cards
///   share one height and put the drop-off line in the same place on every
///   card, so swiping compares departures rather than re-reading layouts.
class HomeTripJourney extends StatelessWidget {
  const HomeTripJourney({
    super.key,
    required this.pickup,
    required this.destination,
    this.dense = false,
  });

  final String pickup;
  final String destination;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (dense) {
      return _DenseJourney(pickup: pickup, destination: destination);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _JourneyTrack(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Stop(label: pickup, caption: context.l10n.common_pickup),
              const SizedBox(height: 14),
              _Stop(label: destination, caption: context.l10n.common_dropOff),
            ],
          ),
        ),
      ],
    );
  }
}

/// The rail card's journey: dot, name, connector, dot, name.
///
/// The captions are carried by the dots — cyan where the rider gets on, amber
/// where they get off, top to bottom — and by the semantics label, so a card
/// narrow enough to sit in a rail spends its width on the stop names.
class _DenseJourney extends StatelessWidget {
  const _DenseJourney({required this.pickup, required this.destination});

  final String pickup;
  final String destination;

  /// Gap between the two stop slots — the length of the connector.
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Two lines of the stop-name style, grown with the rider's text size, is
    // the slot every stop gets whether or not it fills it.
    final slot = MediaQuery.textScalerOf(context).scale(14) * 1.25 * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DenseStop(
          label: pickup,
          caption: l10n.common_pickup,
          color: ClientColors.journeyCyanFor(context),
          slot: slot,
          connectorHeight: slot + _gap - _DenseStop.dotSize,
        ),
        _DenseStop(
          label: destination,
          caption: l10n.common_dropOff,
          color: ClientColors.journeyAmberFor(context),
          slot: slot,
        ),
      ],
    );
  }
}

class _DenseStop extends StatelessWidget {
  const _DenseStop({
    required this.label,
    required this.caption,
    required this.color,
    required this.slot,
    this.connectorHeight,
  });

  final String label;
  final String caption;
  final Color color;

  /// Fixed height of the name block: two lines, filled or not.
  final double slot;

  /// Length of the rule down to the next stop's dot. Null on the last stop.
  final double? connectorHeight;

  static const double dotSize = 9;

  /// Drops the dot onto the middle of the name's first line.
  static const double _dotTop = 4;

  @override
  Widget build(BuildContext context) {
    final name = label.isEmpty ? context.l10n.home_stopNotSet : label;

    return Semantics(
      container: true,
      label: '$caption: $name',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: _dotTop),
            child: Column(
              children: [
                _TrackDot(color: color, size: dotSize),
                if (connectorHeight != null)
                  Container(
                    width: 2,
                    height: connectorHeight,
                    color: ClientColors.borderFor(context),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: slot,
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w700, height: 1.25),
              ),
            ),
          ),
        ],
      ),
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
          label.isEmpty ? context.l10n.home_stopNotSet : label,
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
          const _TrackDot(color: ClientColors.journeyCyan),
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
  const _TrackDot({required this.color, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        // The halo keeps its share of the dot at any size.
        border: Border.all(color: color.withAlpha(60), width: size * 0.3),
      ),
    );
  }
}
