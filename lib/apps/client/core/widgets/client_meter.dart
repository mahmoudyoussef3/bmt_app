import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

/// How much of something a rider has spent: a subscription window that has
/// elapsed, an allowance of rides that has been used.
///
/// A bare [LinearProgressIndicator] leaves its track at the theme's default
/// grey and its fill square-ended, which reads as a download bar dropped into a
/// card. This keeps the brand tint on both halves and rounds the fill, so a
/// meter looks like the surface it sits in.
///
/// The fill grows from the leading edge, so it runs right-to-left in Arabic —
/// this is a quantity, not a gauge that must keep one physical direction.
class ClientMeter extends StatelessWidget {
  const ClientMeter({
    super.key,
    required this.value,
    this.color,
    this.height = 10,
  });

  /// Share of the meter that is filled, 0→1. Anything outside is clamped.
  final double value;

  /// Defaults to the brand blue.
  final Color? color;

  final double height;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? ClientColors.primaryFor(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(ClientRadius.pill),
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          Container(height: height, color: fill.withAlpha(36)),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(ClientRadius.pill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
