import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_palette.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Where a stop sits relative to the vehicle.
enum ClientStopProgress {
  /// The vehicle has already passed here.
  passed,

  /// The vehicle is here now.
  current,

  /// Still ahead — and the state a static corridor listing uses throughout,
  /// where there is no vehicle to be anywhere.
  ahead,
}

/// One row of a [ClientJourneyTimeline].
@immutable
class ClientJourneyStop {
  const ClientJourneyStop({
    required this.name,
    this.subtitle,
    this.trailing,
    this.badge,
    this.progress = ClientStopProgress.ahead,
    this.emphasised = false,
    this.dimmed = false,
  });

  final String name;

  /// The small line under the name — an ETA, an area, "الموقع الحالي".
  final String? subtitle;

  /// Optional end-aligned text, e.g. a scheduled time.
  final String? trailing;

  final ClientStopProgress progress;

  /// A short brand pill beside the name — "Your stop", "Your drop-off". The
  /// rows that are about *this* reader, and the only ones that get one.
  final String? badge;

  /// Draws the name at full weight regardless of [progress]. Used for the two
  /// terminals of a corridor, which the design bolds even though nothing has
  /// happened at them yet.
  final bool emphasised;

  /// Fades the whole row. For stops that belong to other passengers' journeys:
  /// still listed, because they are *why* the trip takes as long as it does,
  /// but never competing with the reader's own.
  final bool dimmed;
}

/// The corridor of a route or a live trip, drawn as a connected spine.
///
/// The design uses two sizes of the same object and this widget is both:
/// [dense] is the 11px-dot station list on route and booking detail screens,
/// and the default is the 26px-marker live timeline on the active-trip screen,
/// where a passed stop carries a check, the current one a ringed brand dot, and
/// the rule behind the vehicle is brand-coloured while the rule ahead is not.
///
/// Keeping both in one widget is the point: a rider who learns the spine on the
/// route page reads the live one without relearning it.
class ClientJourneyTimeline extends StatelessWidget {
  const ClientJourneyTimeline({
    super.key,
    required this.stops,
    this.dense = false,
  });

  final List<ClientJourneyStop> stops;

  /// The compact station-list form: a small dot, no marker glyph.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stops.length; i++)
          _StopRow(stop: stops[i], isLast: i == stops.length - 1, dense: dense),
      ],
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.isLast,
    required this.dense,
  });

  final ClientJourneyStop stop;
  final bool isLast;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = ClientPalette.of(context);
    final passed = stop.progress == ClientStopProgress.passed;
    final current = stop.progress == ClientStopProgress.current;
    final gap = dense ? 14.0 : 18.0;

    return Opacity(
      opacity: stop.dimmed ? 0.45 : 1,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _marker(palette),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: BoxConstraints(minHeight: gap + 4),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: passed ? palette.primary : palette.border,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : gap),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  stop.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ClientTypography.bodyMedium(context)
                                      .copyWith(
                                        color:
                                            stop.progress ==
                                                    ClientStopProgress.ahead &&
                                                !stop.emphasised &&
                                                !dense
                                            ? palette.textMuted
                                            : palette.text,
                                        fontWeight: current || stop.emphasised
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                ),
                              ),
                              if (stop.badge case final badge?
                                  when badge.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                _StopBadge(label: badge),
                              ],
                            ],
                          ),
                          if (stop.subtitle case final subtitle?
                              when subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ClientTypography.labelSmall(context)
                                  .copyWith(
                                    color: current
                                        ? palette.primary
                                        : palette.textMuted,
                                    fontWeight: current
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (stop.trailing case final trailing?
                        when trailing.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        trailing,
                        style: ClientTypography.labelMedium(context).copyWith(
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
      ),
    );
  }

  Widget _marker(ClientPalette palette) {
    if (dense) {
      return Container(
        width: 11,
        height: 11,
        margin: const EdgeInsets.only(top: 5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: stop.progress == ClientStopProgress.ahead && !stop.emphasised
              ? palette.border
              : palette.primary,
        ),
      );
    }

    final current = stop.progress == ClientStopProgress.current;
    final passed = stop.progress == ClientStopProgress.passed;

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: current
            ? palette.primary
            : (passed ? palette.primary : palette.surface2),
        boxShadow: current
            ? [
                BoxShadow(
                  color: palette.primaryTint,
                  spreadRadius: 4,
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: passed
          ? Icon(Icons.check_rounded, size: 15, color: palette.onPrimary)
          : current
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.onPrimary,
              ),
            )
          : null,
    );
  }
}

/// "Your stop" / "Your drop-off" — the pill that marks a row as the reader's
/// own. Deliberately the same shape the live tracking sheet uses, so the two
/// station lists read as one object.
class _StopBadge extends StatelessWidget {
  const _StopBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = ClientColors.primaryFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
