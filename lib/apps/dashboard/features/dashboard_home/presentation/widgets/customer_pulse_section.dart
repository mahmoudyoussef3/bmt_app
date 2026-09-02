import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import 'package:bmt_app/apps/dashboard/features/reviews/domain/entities/reviews_summary.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// How passengers rated the service, across the three things they are asked
/// about: the captain, the bus and the route.
///
/// [DashboardHomeSummary.reviewsSummary] was already assembled on every load
/// and shown nowhere, which left Home able to report money and buses but not
/// whether anyone was happy with either. The averages are the whole point of
/// the Reviews feed — individual reviews are owner-only and belong on their own
/// screen — so this panel shows exactly those three numbers, the sample size
/// behind them, and the count that needs somebody to reply.
///
/// Nothing here is a queue: a low average is not a task, it is a standing fact.
/// Reviews that *do* need an answer are counted on their own line with a way
/// into the module, and urgent complaints stay in the attention panel where a
/// decision belongs.
class CustomerPulseSection extends StatelessWidget {
  const CustomerPulseSection({
    super.key,
    required this.summary,
    required this.onOpenModule,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final reviews = summary.reviewsSummary;
    final palette = DashboardChartPalette.of(context);

    return DashboardPanel(
      sectionId: DashboardSectionIds.homeCustomerPulse,
      icon: DashboardIcons.reviewsActive,
      title: 'رضا العملاء',
      // Phrased as a labelled count rather than "متوسط N تقييم": Arabic agrees
      // the noun with the number (تقييم / تقييمان / تقييمات / تقييماً across
      // four bands), and a template that picks one form is wrong for most
      // values. A colon sidesteps the agreement entirely.
      subtitle: reviews.total == 0
          ? null
          : 'إجمالي التقييمات: ${reviews.total}',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.reviews),
        child: const Text('التقييمات'),
      ),
      child: reviews.total == 0
          ? const DashboardEmptyState(
              icon: DashboardIcons.reviews,
              title: 'لا تقييمات بعد',
              message: 'تظهر المتوسطات بعد أول تقييم من راكب.',
            )
          : Column(
              children: [
                _OverallRating(summary: reviews, palette: palette),
                const Divider(height: AppSpacing.large),
                _RatingRow(
                  label: 'السائق',
                  icon: DashboardIcons.captain,
                  average: reviews.driverAverage,
                  palette: palette,
                ),
                const SizedBox(height: AppSpacing.medium),
                _RatingRow(
                  label: 'المركبة',
                  icon: DashboardIcons.vehicle,
                  average: reviews.vehicleAverage,
                  palette: palette,
                ),
                const SizedBox(height: AppSpacing.medium),
                _RatingRow(
                  label: 'المسار',
                  icon: DashboardIcons.routes,
                  average: reviews.routeAverage,
                  palette: palette,
                ),
                if (reviews.needsAttentionCount > 0) ...[
                  const Divider(height: AppSpacing.large),
                  _NeedsReply(
                    count: reviews.needsAttentionCount,
                    onOpen: () => onOpenModule(DashboardRoutes.reviews),
                  ),
                ],
              ],
            ),
    );
  }
}

/// The one number the module itself calls its headline — the mean across all
/// three dimensions — with the star row that makes it readable at a glance and
/// the sample behind it.
///
/// [ReviewsSummary.overallAverage] and `commentedCount` were both computed on
/// every load and drawn nowhere, so the panel opened on three tracks and left
/// the reader to average them in their head. The comment count is the more
/// useful of the two: stars say *how* it went, and a written comment is the
/// only place that says why.
class _OverallRating extends StatelessWidget {
  const _OverallRating({required this.summary, required this.palette});

  final ReviewsSummary summary;
  final DashboardChartPalette palette;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final average = summary.overallAverage;
    final tone = average >= 4
        ? palette.positive
        : average >= 3
        ? palette.warning
        : palette.negative;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          average.toStringAsFixed(1),
          style: text.displayMedium?.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 3),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '/ ٥',
            style: text.labelMedium?.copyWith(
              color: DashboardColors.faintInk(context),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Stars(average: average, tone: tone),
              const SizedBox(height: 3),
              Text(
                summary.commentedCount == 0
                    ? 'متوسط عام · لا تعليقات مكتوبة'
                    : 'متوسط عام · تعليقات مكتوبة: ${summary.commentedCount}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Five glyphs, the last of which is half-filled when the average lands
/// mid-star. Drawn from the rating rather than rounded to it: a 3.5 shown as
/// four full stars is a better score than the passengers gave.
class _Stars extends StatelessWidget {
  const _Stars({required this.average, required this.tone});

  final double average;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 2),
            child: Icon(
              average >= i
                  ? Icons.star_rounded
                  : average >= i - 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
              size: 16,
              color: average >= i - 0.5
                  ? tone
                  : DashboardColors.borderStrong(context),
            ),
          ),
      ],
    );
  }
}

/// One dimension: what it is, the average to one decimal, and a five-point
/// track. The track is out of five rather than normalised, so a 3.9 and a 4.1
/// sit visibly on either side of the same midpoint on all three rows.
class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.label,
    required this.icon,
    required this.average,
    required this.palette,
  });

  final String label;
  final IconData icon;
  final double average;
  final DashboardChartPalette palette;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // The service bands an operator already thinks in: four and up is fine,
    // three-something is worth watching, below three is a problem.
    final tone = average >= 4
        ? palette.positive
        : average >= 3
        ? palette.warning
        : palette.negative;

    return Row(
      children: [
        Icon(icon, size: 15, color: DashboardColors.mutedInk(context)),
        const SizedBox(width: AppSpacing.small),
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: text.labelMedium?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (average / 5).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: DashboardColors.well(context),
              valueColor: AlwaysStoppedAnimation(tone),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(DashboardIcons.reviewsActive, size: 14, color: tone),
            const SizedBox(width: 3),
            Text(
              average.toStringAsFixed(1),
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NeedsReply extends StatelessWidget {
  const _NeedsReply({required this.count, required this.onOpen});

  final int count;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(8);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onOpen,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: 6,
          ),
          child: Row(
            children: [
              Icon(
                DashboardIcons.attention,
                size: 15,
                color: DashboardColors.status(context, _attentionTone).accent,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  'تقييمات تحتاج متابعة',
                  style: text.labelMedium?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
              ),
              Text(
                '$count',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Icon(
                DashboardIcons.openModule,
                size: 16,
                color: DashboardColors.faintInk(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _attentionTone = AppStatusTone.warning;
