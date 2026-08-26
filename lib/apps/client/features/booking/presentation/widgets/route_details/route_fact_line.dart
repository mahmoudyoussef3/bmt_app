import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A dot-separated line of small facts — "1h 6m · Coaster · 3 seats available".
///
/// Each fact is its own [Text], never `parts.join(' · ')`. A joined string is
/// one bidi paragraph, so a line that mixes scripts — an Arabic duration
/// beside an English seat count, which is exactly what this app produces —
/// gets reordered by UAX#9 and prints as `58 2 · كم 74 · د stops`. Separate
/// widgets are separate paragraphs, and the [Wrap] lays them out in the
/// reader's direction, so the order is the order they were passed in.
class RouteFactLine extends StatelessWidget {
  const RouteFactLine({super.key, required this.facts, this.style});

  /// Facts in reading order. Empty entries are dropped, so callers can pass
  /// values that may not be set without guarding each one.
  final List<String> facts;

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final parts = facts
        .map((fact) => fact.trim())
        .where((fact) => fact.isNotEmpty)
        .toList();
    if (parts.isEmpty) return const SizedBox.shrink();

    final resolved =
        style ??
        ClientTypography.bodySmall(
          context,
        ).copyWith(color: ClientColors.textSecondaryFor(context));

    return Wrap(
      spacing: 7,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0)
            Text(
              '·',
              style: resolved.copyWith(
                color: ClientColors.textTertiaryFor(context),
              ),
            ),
          Text(parts[i], style: resolved),
        ],
      ],
    );
  }
}
