import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/package_plan.dart';

/// How long a package lasts and how many rides it holds — the two facts that
/// define a plan now that price has moved to the booking flow.
///
/// Shared by every surface that names a package outside booking (the office
/// profile, the marketplace card, the detail hero) so the same plan reads the
/// same way wherever a rider meets it.
class PackageShapeChips extends StatelessWidget {
  const PackageShapeChips({
    super.key,
    required this.package,
    required this.accent,
  });

  final PackagePlan package;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
      spacing: ClientSpacing.xs,
      runSpacing: ClientSpacing.xxs,
      children: [
        _Chip(
          icon: Icons.calendar_month_rounded,
          label: l10n.packages_daysCount(package.durationDays),
          accent: accent,
        ),
        _Chip(
          icon: Icons.event_seat_rounded,
          label: l10n.packages_ridesCount(package.rideCount),
          accent: accent,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.accent});

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withAlpha(20),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: accent, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
