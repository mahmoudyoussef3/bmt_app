import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_palette.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The booking wizard's step header.
///
/// A numbered rail tells a rider two things a bare progress bar cannot: which
/// step they are on *by name*, and how many are left. Each step is a numbered
/// marker — a check once it is behind them, a filled brand disc for where they
/// stand, a hairline disc carrying its number for what is still ahead — joined
/// by a rule that is brand-coloured only up to the marker they are on.
///
/// **Geometry.** Every step owns an equal-width column and the marker sits at
/// that column's centre, so the connectors between markers are all the same
/// length and each label is centred under its own marker. The earlier version
/// let the label decide its column's width, which made a long word push its
/// marker sideways and left the connectors visibly uneven across the row.
///
/// The row lays out in the ambient direction, so in the Arabic UI step one sits
/// on the right and progress runs leftward without any mirroring here.
class ClientStepProgress extends StatelessWidget {
  const ClientStepProgress({
    super.key,
    required this.labels,
    required this.currentIndex,
  });

  /// One label per step, in order.
  final List<String> labels;

  /// Zero-based index of the step being shown. Everything before it is done.
  final int currentIndex;

  /// The band the markers are centred in. Fixed so a bigger current marker
  /// cannot shift the row, and so the wizard app bar can reserve an exact
  /// height for the header.
  static const double markerBand = 28;

  /// Marker sizes: the step being shown is a step larger than the rest.
  static const double _markerSize = 22;
  static const double _currentMarkerSize = 26;

  /// Height of the connecting rule, and its clearance from a marker.
  static const double _trackHeight = 3;
  static const double _trackGap = 5;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final active = currentIndex.clamp(0, labels.length - 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: _Step(
              label: labels[i],
              number: i + 1,
              state: i < active
                  ? _StepState.done
                  : i == active
                  ? _StepState.current
                  : _StepState.upcoming,
              // The rule on a marker's leading side belongs to the step before
              // it, so progress stops exactly at the marker being shown.
              trackBefore: i == 0 ? null : i <= active,
              trackAfter: i == labels.length - 1 ? null : i < active,
            ),
          ),
      ],
    );
  }
}

enum _StepState { done, current, upcoming }

/// One equal-width column: half a rule, a marker, half a rule, then the label.
class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.number,
    required this.state,
    required this.trackBefore,
    required this.trackAfter,
  });

  final String label;
  final int number;
  final _StepState state;

  /// Whether the rule on each side is walked. Null where there is no rule —
  /// the leading edge of the first step and the trailing edge of the last.
  final bool? trackBefore;
  final bool? trackAfter;

  @override
  Widget build(BuildContext context) {
    final palette = ClientPalette.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: ClientStepProgress.markerBand,
          child: Row(
            children: [
              Expanded(child: _Track(walked: trackBefore, leading: true)),
              _Marker(number: number, state: state),
              Expanded(child: _Track(walked: trackAfter, leading: false)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.labelSmall(context).copyWith(
            fontSize: 11,
            height: 1.2,
            letterSpacing: 0,
            color: switch (state) {
              _StepState.current => palette.primary,
              _StepState.done => palette.text,
              _StepState.upcoming => palette.textMuted,
            },
            fontWeight: state == _StepState.current
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Half of the rule between two markers. [walked] null draws nothing, which is
/// what keeps the first and last markers at their own column's centre.
///
/// The clearance is only ever on the marker's side: the outer edge runs flush
/// to the column boundary, where it meets the neighbouring column's half and
/// the two read as one rule. Padding both sides instead left a hole in the
/// middle of every gap, so the rail came out looking dashed.
class _Track extends StatelessWidget {
  const _Track({required this.walked, required this.leading});

  final bool? walked;

  /// True for the half drawn before the marker in reading order.
  final bool leading;

  @override
  Widget build(BuildContext context) {
    final walked = this.walked;
    if (walked == null) return const SizedBox.expand();

    return Center(
      child: Padding(
        padding: leading
            ? const EdgeInsetsDirectional.only(
                end: ClientStepProgress._trackGap,
              )
            : const EdgeInsetsDirectional.only(
                start: ClientStepProgress._trackGap,
              ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: ClientStepProgress._trackHeight,
          decoration: BoxDecoration(
            color: walked
                ? ClientColors.primaryFor(context)
                : ClientColors.borderFor(context),
            borderRadius: BorderRadius.circular(
              ClientStepProgress._trackHeight,
            ),
          ),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.number, required this.state});

  final int number;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final palette = ClientPalette.of(context);
    final isCurrent = state == _StepState.current;
    final size = isCurrent
        ? ClientStepProgress._currentMarkerSize
        : ClientStepProgress._markerSize;

    return SizedBox(
      // Both marker sizes reserve the wider box, so the rules on either side
      // keep the same length whichever step is being shown.
      width: ClientStepProgress._currentMarkerSize,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: switch (state) {
              _StepState.done || _StepState.current => palette.primary,
              _StepState.upcoming => palette.surface,
            },
            // An upcoming disc is drawn, not implied: on a white app bar a
            // bare `--surface-2` fill all but disappears.
            border: state == _StepState.upcoming
                ? Border.all(color: palette.border, width: 1.5)
                : null,
            // `box-shadow:0 0 0 4px var(--primary-tint)` — a halo, not a blur,
            // which is why the spread carries it and the blur is zero.
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: palette.primaryTint,
                      spreadRadius: 4,
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: switch (state) {
            _StepState.done => Icon(
              Icons.check_rounded,
              size: 14,
              color: palette.onPrimary,
            ),
            _StepState.current => _Numeral(
              number: number,
              size: 12,
              color: palette.onPrimary,
              weight: FontWeight.w800,
            ),
            _StepState.upcoming => _Numeral(
              number: number,
              size: 11,
              color: palette.textMuted,
              weight: FontWeight.w600,
            ),
          },
        ),
      ),
    );
  }
}

/// The step's number, pinned to Western digits and left-to-right.
///
/// A marker is a badge, not running text: a lone digit inside a 22px circle
/// should look the same in both languages, and forcing the direction keeps it
/// centred rather than nudged by the ambient RTL text direction.
class _Numeral extends StatelessWidget {
  const _Numeral({
    required this.number,
    required this.size,
    required this.color,
    required this.weight,
  });

  final int number;
  final double size;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$number',
      textDirection: TextDirection.ltr,
      style: ClientTypography.labelSmall(context).copyWith(
        fontSize: size,
        height: 1,
        letterSpacing: 0,
        color: color,
        fontWeight: weight,
      ),
    );
  }
}
