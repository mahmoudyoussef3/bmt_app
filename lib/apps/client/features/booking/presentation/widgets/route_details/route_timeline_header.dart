import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// `RouteStopTimeline`'s header: title, one-line explainer, and a neutral
/// stop-count pill so the length of the route is legible before scrolling it.
class RouteTimelineHeader extends StatelessWidget {
  const RouteTimelineHeader({super.key, required this.stopCount});

  final int stopCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(isDark ? 30 : 25),
            borderRadius: BorderRadius.circular(ClientRadius.md),
          ),
          child: Icon(
            Icons.alt_route_rounded,
            size: 22,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.booking_routeTimeline,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.l10n.booking_whereGetOnOffShort,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ClientColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (stopCount > 0) ...[
          const SizedBox(width: 10),
          _StopCountPill(stopCount: stopCount),
        ],
      ],
    );
  }
}

class _StopCountPill extends StatelessWidget {
  const _StopCountPill({required this.stopCount});

  final int stopCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        stopCount == 1
            ? context.l10n.booking_oneStop
            : context.l10n.booking_stopsCountLabel(stopCount),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: ClientColors.textSecondaryFor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
