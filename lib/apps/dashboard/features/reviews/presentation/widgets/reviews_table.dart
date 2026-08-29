import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/core/theme/colors.dart';

import '../../domain/entities/trip_review_entry.dart';
import '../cubit/reviews_state.dart';
import '../models/review_sort.dart';
import 'rating_stars.dart';
import 'reviews_format.dart';

/// The review feed as an [OpsDataTable] — the same table shell الشكاوى next
/// door and the three المبيعات modules render.
///
/// The ordering and the page live in [ReviewsLoaded] and in the board above
/// this widget rather than in private state here: the toolbar's pinned sort
/// control and these column headers must drive one value, and the results
/// header above the rows has to know which slice is on screen.
class ReviewsTable extends StatelessWidget {
  const ReviewsTable({
    super.key,
    required this.state,
    required this.rows,
    required this.pageIndex,
    required this.onPageChanged,
    required this.onSort,
    required this.onOpen,
  });

  final ReviewsLoaded state;

  /// The page of rows to draw, already ordered and sliced by the board.
  final List<TripReviewEntry> rows;

  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ReviewSort> onSort;
  final ValueChanged<TripReviewEntry> onOpen;

  /// Column index → sort key. Indices absent from this map are not sortable.
  static const _sortColumns = <int, ReviewSort>{
    1: ReviewSort.driver,
    3: ReviewSort.rating,
  };

  int? get _sortColumnIndex {
    for (final entry in _sortColumns.entries) {
      if (entry.value == state.sort) return entry.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final attentionTint = context.status(AppStatusTone.error).tint;
    final total = state.visibleReviews.length;

    return OpsDataTable(
      columns: const [
        OpsColumn('التقييم', flex: 3, minWidth: 220),
        OpsColumn('السائق', flex: 2, minWidth: 120, sortable: true),
        OpsColumn('المسار', flex: 2, minWidth: 140),
        OpsColumn(
          'الدرجة',
          flex: 1,
          minWidth: 84,
          numeric: true,
          sortable: true,
        ),
        OpsColumn('الحالة', flex: 2, minWidth: 116),
        OpsColumn('', minWidth: 56),
      ],
      rows: [for (final r in rows) _cells(context, r)],
      onRowTap: [for (final r in rows) () => onOpen(r)],
      rowTints: [for (final r in rows) r.needsAttention ? attentionTint : null],
      total: total,
      totalLabel: 'الإجمالي ${ReviewsFormat.count(total)} تقييم',
      currentPage: pageIndex,
      pageSize: reviewsPageSize,
      onPageChanged: onPageChanged,
      sortColumnIndex: _sortColumnIndex,
      sortDirection: state.sortAscending ? OpsSort.asc : OpsSort.desc,
      onSort: (index) {
        final key = _sortColumns[index];
        if (key != null) onSort(key);
      },
    );
  }

  List<Widget> _cells(BuildContext context, TripReviewEntry r) {
    final flagged = r.needsAttention;
    final tone = context.status(
      flagged ? AppStatusTone.error : AppStatusTone.success,
    );

    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            r.hasComment ? '«${r.comment.trim()}»' : 'بدون تعليق',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontStyle: r.hasComment ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          Text(
            '${r.clientName} · ${ReviewsFormat.shortStamp(r.createdAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ],
      ),
      Text(r.driverName, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(r.routeLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(
        r.averageRating.toStringAsFixed(1),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: ratingColor(context, r.averageRating),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      DashboardStatusChip(
        label: flagged ? 'تحتاج متابعة' : 'منشور',
        color: tone.tint,
        textColor: tone.ink,
      ),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: IconButton(
          tooltip: 'عرض التفاصيل',
          onPressed: () => onOpen(r),
          icon: const Icon(Icons.visibility_outlined, size: 19),
          visualDensity: VisualDensity.compact,
        ),
      ),
    ];
  }
}
