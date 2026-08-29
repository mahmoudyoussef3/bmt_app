import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/core/theme/colors.dart';

import '../../domain/entities/reviews_summary.dart';
import '../cubit/reviews_state.dart';
import 'rating_stars.dart';
import 'reviews_format.dart';

/// التقييمات' headline numbers.
///
/// ## Four tiles, three of them queues
///
/// Same rule as الشكاوى and العملاء: a count is only useful if *which ones* is
/// one press away, so each of the first three tiles opens the queue that
/// produced it and can never disagree with the tab under it — they are the same
/// predicate, asked of the same function.
///
/// The fourth is the exception, and deliberately so. The overall average is not
/// a population you can open; it is the module's one quality number. It carries
/// the three dimensions on its detail line rather than spending three tiles on
/// them, which is what keeps this header one row wide at every console width —
/// the same shape its neighbours wear.
class ReviewsKpiStrip extends StatelessWidget {
  const ReviewsKpiStrip({
    super.key,
    required this.state,
    required this.onOpenQueue,
  });

  final ReviewsLoaded state;
  final ValueChanged<ReviewsFilter> onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;

    return DashboardKpiGrid(
      maxColumns: 4,
      itemExtent: 132,
      children: [
        _tile(
          context,
          tab: ReviewsFilter.all,
          label: 'إجمالي التقييمات',
          value: ReviewsFormat.count(summary.total),
          icon: DashboardIcons.reviews,
          detail: 'كل ما وصل من الركاب',
          tone: AppStatusTone.info,
          hint: 'عرض كل التقييمات',
        ),
        _tile(
          context,
          tab: ReviewsFilter.needsAttention,
          label: 'تحتاج متابعة',
          value: ReviewsFormat.count(summary.needsAttentionCount),
          icon: Icons.report_gmailerrorred_outlined,
          detail: 'نجمتان أو أقل في أي بند',
          // The one tile that changes colour with its own number: an empty
          // follow-up queue is the good news, and saying so in red would train
          // the operator to stop reading it.
          tone: summary.needsAttentionCount > 0
              ? AppStatusTone.error
              : AppStatusTone.success,
          hint: 'عرض التقييمات التي تحتاج متابعة',
        ),
        _tile(
          context,
          tab: ReviewsFilter.withComments,
          label: 'بها تعليقات',
          value: ReviewsFormat.count(summary.commentedCount),
          icon: Icons.mode_comment_outlined,
          detail: 'كتب فيها الراكب سببًا',
          tone: AppStatusTone.special,
          hint: 'عرض التقييمات المكتوبة',
        ),
        DashboardKpiCard(
          label: 'متوسط التقييم',
          value: ReviewsFormat.rating(
            summary.overallAverage,
            outOf: summary.total,
          ),
          icon: Icons.star_half_rounded,
          detail: _averagesLine(summary),
          color: summary.total == 0
              ? DashboardColors.mutedInk(context)
              : ratingColor(context, summary.overallAverage),
          emphasized: true,
        ),
      ],
    );
  }

  /// The three dimensions on one line. They were three tiles of their own until
  /// this pass, which made this module's header a different shape from every
  /// other list module's.
  String _averagesLine(ReviewsSummary summary) {
    if (summary.total == 0) return 'لا توجد تقييمات بعد';
    final driver = ReviewsFormat.rating(
      summary.driverAverage,
      outOf: summary.total,
    );
    final vehicle = ReviewsFormat.rating(
      summary.vehicleAverage,
      outOf: summary.total,
    );
    final route = ReviewsFormat.rating(
      summary.routeAverage,
      outOf: summary.total,
    );
    return 'السائق $driver · المركبة $vehicle · المسار $route';
  }

  Widget _tile(
    BuildContext context, {
    required ReviewsFilter tab,
    required String label,
    required String value,
    required IconData icon,
    required String detail,
    required AppStatusTone tone,
    required String hint,
  }) {
    return DashboardKpiCard(
      label: label,
      value: value,
      icon: icon,
      detail: detail,
      // The tone's `accent`, not its `ink`: a tile's fill is near-white, and
      // `ink` is the *container* ink, which on it reads as black type rather
      // than as a status.
      color: DashboardColors.status(context, tone).accent,
      emphasized: true,
      onTap: () => onOpenQueue(tab),
      tapHint: hint,
    );
  }
}
