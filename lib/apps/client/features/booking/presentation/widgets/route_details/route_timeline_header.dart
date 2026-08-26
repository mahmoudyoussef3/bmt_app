import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The header every Route Details section wears: a tinted icon square, a
/// title with a one-line explainer, and an optional neutral count pill.
///
/// One component rather than three near-identical hand-rolled rows, so the
/// stations card and the departures card read as the same kind of thing.
class RouteSectionHeader extends StatelessWidget {
  const RouteSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Neutral pill on the trailing edge — a stop count, a departure count.
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ClientColors.primaryContainerFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.md),
          ),
          child: Icon(
            icon,
            size: 21,
            color: ClientColors.onPrimaryContainerFor(context),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ClientTypography.headingSmall(context)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
        if (trailingLabel != null) ...[
          const SizedBox(width: 10),
          _CountPill(label: trailingLabel!),
        ],
      ],
    );
  }
}

/// The stations card's header.
class RouteTimelineHeader extends StatelessWidget {
  const RouteTimelineHeader({super.key, required this.stopCount});

  final int stopCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RouteSectionHeader(
      icon: Icons.route_rounded,
      title: l10n.booking_routeTimeline,
      subtitle: l10n.booking_whereGetOnOffShort,
      trailingLabel: stopCount == 0
          ? null
          : stopCount == 1
          ? l10n.booking_oneStop
          : l10n.booking_stopsCountLabel(stopCount),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        label,
        style: ClientTypography.labelSmall(context).copyWith(
          color: ClientColors.textSecondaryFor(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
