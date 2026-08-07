import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/reviews_summary.dart';
import 'rating_stars.dart';

/// Captains ranked by what passengers said about them — the answer to "who
/// needs coaching, and who deserves the good routes".
class DriverStandingsPanel extends StatelessWidget {
  const DriverStandingsPanel({super.key, required this.standings});

  final List<DriverRatingStanding> standings;

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) return const SizedBox.shrink();

    return DashboardPanel(
      sectionId: DashboardSectionIds.reviewsDriverStandings,
      icon: Icons.military_tech_outlined,
      title: 'تقييم الكباتن',
      subtitle: 'مرتّب من الأعلى إلى الأقل تقييمًا',
      child: Column(
        children: [
          for (final standing in standings) _StandingRow(standing: standing),
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.standing});

  final DriverRatingStanding standing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ratingColor(context, standing.average);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  standing.driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${standing.reviewCount} تقييم',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          SizedBox(
            width: 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (standing.average / 5).clamp(0, 1),
                minHeight: 7,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            standing.average.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
