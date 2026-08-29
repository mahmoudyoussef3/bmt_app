import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Stop-name size on the dense rail — one step under the captioned rail's 17,
/// which is what lets a browsable card carry a whole journey in two lines.
const double _denseNameSize = 15;

/// Pickup → destination as a vertical timeline, so stop names like "American
/// University in Cairo (AUC)" stay readable instead of being squeezed side by
/// side.
///
/// The rail is drawn *per stop* rather than as one fixed dot–line–dot column
/// standing beside the names. A stop name that wraps to a second line pushes
/// everything under it down, and a rail of fixed height then leaves its bottom
/// dot floating somewhere in the middle of the card — the exact stop names this
/// marketplace carries are long enough for that to be the common case, not the
/// edge case. Here the connector stretches to whatever height the pickup block
/// actually took, and the drop-off's dot is met by a short segment above it, so
/// the line lands on the first line of both names at any text size.
class HomeTripJourney extends StatelessWidget {
  const HomeTripJourney({
    super.key,
    required this.pickup,
    required this.destination,
    this.dense = false,
    this.middle,
  });

  final String pickup;
  final String destination;

  /// The compact rail a browsable list card uses: no captions above the stop
  /// names, one line per name, and the type a step smaller. A rider scanning a
  /// board of departures reads the two names as a from/to pair from the rail
  /// alone — the captions are worth their height on a card the rider has
  /// stopped on (a seat they hold, a ticket they bought), not on three cards
  /// they are choosing between.
  final bool dense;

  /// Optional content parked in the gap the connector crosses — the trip's
  /// operator and ride time, on the line the rail is already drawing. [dense]
  /// only; it buys the meta line its own row for free.
  final Widget? middle;

  /// Gap between the rail and the stop names.
  static const double _railGap = 12;

  /// Air under the pickup block, crossed by the connector.
  static const double _stopGap = 14;

  /// The run of bare connector between two dense stops with nothing in it.
  static const double _denseGap = 14;

  /// Drops a dot onto the middle of its stop's *first* name line: clear the
  /// caption above it, then half a line of the name itself. Measured rather
  /// than nudged by hand so it still lands there at the rider's text size.
  static double _dotTop(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final caption = scaler.scale(_Stop.captionSize) * _Stop.captionHeight;
    final name = scaler.scale(_Stop.nameSize) * _Stop.nameHeight;
    return caption + _Stop.captionGap + name / 2 - _TrackDot.size / 2;
  }

  @override
  Widget build(BuildContext context) {
    if (dense) return _buildDense(context);

    final l10n = context.l10n;
    final dotTop = _dotTop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _TrackDot.size,
                child: Column(
                  children: [
                    SizedBox(height: dotTop),
                    _TrackDot(color: ClientColors.journeyCyanFor(context)),
                    const Expanded(child: _Connector()),
                  ],
                ),
              ),
              const SizedBox(width: _railGap),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: _stopGap),
                  child: _Stop(label: pickup, caption: l10n.common_pickup),
                ),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _TrackDot.size,
              child: Column(
                children: [
                  SizedBox(height: dotTop, child: const _Connector()),
                  _TrackDot(color: ClientColors.journeyAmberFor(context)),
                ],
              ),
            ),
            const SizedBox(width: _railGap),
            Expanded(
              child: _Stop(label: destination, caption: l10n.common_dropOff),
            ),
          ],
        ),
      ],
    );
  }

  /// The compact rail: dot, name, the connector crossing whatever [middle]
  /// carries, then dot and name again. The dots are centred on their own name
  /// line rather than measured against a caption, so nothing here has to be
  /// kept in step with a type size.
  Widget _buildDense(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DenseStop(
          label: pickup,
          semanticsLabel: l10n.common_pickup,
          color: ClientColors.journeyCyanFor(context),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                width: _TrackDot.size,
                child: Center(child: _Connector()),
              ),
              if (middle != null) ...[
                const SizedBox(width: _railGap),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: middle,
                  ),
                ),
              ],
            ],
          ),
        ),
        // With nothing in the gap the connector still needs a run of its own,
        // or the two dots meet and the rail reads as one mark.
        if (middle == null)
          const SizedBox(
            height: _denseGap,
            width: _TrackDot.size,
            child: Center(child: _Connector()),
          ),
        _DenseStop(
          label: destination,
          semanticsLabel: l10n.common_dropOff,
          color: ClientColors.journeyAmberFor(context),
        ),
      ],
    );
  }
}

/// One stop on the [HomeTripJourney.dense] rail: its dot, then its name.
///
/// The name carries the caption the dense rail drops as its semantics label,
/// so a screen reader still hears "Pickup: El-Marg" rather than a bare place
/// name whose role is carried only by the colour of a dot.
class _DenseStop extends StatelessWidget {
  const _DenseStop({
    required this.label,
    required this.semanticsLabel,
    required this.color,
  });

  final String label;
  final String semanticsLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final name = label.isEmpty ? context.l10n.home_stopNotSet : label;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Half a line of the name, less half the dot: the mark lands on the
        // middle of the text it belongs to at any text size.
        Padding(
          padding: EdgeInsets.only(
            top:
                MediaQuery.textScalerOf(context).scale(_denseNameSize) *
                    _Stop.nameHeight /
                    2 -
                _TrackDot.size / 2,
          ),
          child: _TrackDot(color: color),
        ),
        const SizedBox(width: HomeTripJourney._railGap),
        Expanded(
          child: Semantics(
            label: '$semanticsLabel: $name',
            excludeSemantics: true,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.headingSmall(context).copyWith(
                fontSize: _denseNameSize,
                fontWeight: FontWeight.w700,
                height: _Stop.nameHeight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The rule running between two stops. Takes its height from the slot it is
/// given — stretched under the pickup, fixed above the drop-off.
class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) {
    return Container(width: 2, color: ClientColors.borderFor(context));
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.label, required this.caption});

  final String label;
  final String caption;

  /// The two type sizes the rail measures itself against; kept here so the dot
  /// offset and the text it aligns to can never drift apart.
  static const double captionSize = 10;
  static const double captionHeight = 1.1;
  static const double captionGap = 2;
  static const double nameSize = 17;
  static const double nameHeight = 1.25;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.labelSmall(context).copyWith(
            fontSize: captionSize,
            color: ClientColors.textTertiaryFor(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            height: captionHeight,
          ),
        ),
        const SizedBox(height: captionGap),
        Text(
          label.isEmpty ? context.l10n.home_stopNotSet : label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(context).copyWith(
            fontSize: nameSize,
            fontWeight: FontWeight.w700,
            height: nameHeight,
          ),
        ),
      ],
    );
  }
}

class _TrackDot extends StatelessWidget {
  const _TrackDot({required this.color});

  final Color color;

  /// Full extent of the dot, halo included — and so the width of the rail.
  static const double size = 10;

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
