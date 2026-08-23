import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/core/theme/colors.dart';

import '../../domain/entities/trip_review_entry.dart';
import '../cubit/reviews_cubit.dart';
import '../cubit/reviews_state.dart';
import 'rating_stars.dart';
import 'review_details_dialog.dart';

/// The review feed as an EWT table: same [OpsDataTable] shell as every other
/// module, a two-line comment cell in place of the old card list, and a
/// [ReviewDetailsDialog] on tap for the parts a row has no room for.
class ReviewsTable extends StatefulWidget {
  const ReviewsTable({super.key, required this.state, this.toolbar});

  final ReviewsLoaded state;

  /// Search + quick filters, rendered inside the table's own card above the
  /// sticky column header.
  final Widget? toolbar;

  @override
  State<ReviewsTable> createState() => _ReviewsTableState();
}

class _ReviewsTableState extends State<ReviewsTable> {
  static const _pageSize = 10;

  int _page = 0;
  bool _sortByRating = false;
  OpsSort _direction = OpsSort.desc;

  int? get _sortColumnIndex => _sortByRating ? 3 : null;

  void _onSort(int index) {
    if (index != 3) return;
    setState(() {
      if (_sortByRating) {
        _direction = _direction == OpsSort.desc ? OpsSort.asc : OpsSort.desc;
      } else {
        _sortByRating = true;
        _direction = OpsSort.desc;
      }
      _page = 0;
    });
  }

  List<TripReviewEntry> _ordered(List<TripReviewEntry> reviews) {
    if (!_sortByRating) return reviews;
    final sorted = [...reviews]
      ..sort((a, b) => a.averageRating.compareTo(b.averageRating));
    return _direction == OpsSort.asc ? sorted : sorted.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered(widget.state.visibleReviews);
    final start = (_page * _pageSize).clamp(0, ordered.length);
    final end = (start + _pageSize).clamp(0, ordered.length);
    final pageItems = ordered.sublist(start, end);
    final attentionTint = context.status(AppStatusTone.error).tint;

    return OpsDataTable(
      toolbar: widget.toolbar,
      columns: const [
        OpsColumn('التقييم', flex: 3, minWidth: 220),
        OpsColumn('السائق', flex: 2, minWidth: 120),
        OpsColumn('المسار', flex: 2, minWidth: 140),
        OpsColumn(
          'التقييم',
          flex: 1,
          minWidth: 84,
          numeric: true,
          sortable: true,
        ),
        OpsColumn('الحالة', flex: 2, minWidth: 116),
        OpsColumn('', minWidth: 56),
      ],
      rows: [for (final r in pageItems) _cells(context, r)],
      onRowTap: [
        for (final r in pageItems)
          () => showReviewDetailsDialog(context, r),
      ],
      rowTints: [
        for (final r in pageItems) r.needsAttention ? attentionTint : null,
      ],
      total: ordered.length,
      currentPage: _page,
      pageSize: _pageSize,
      onPageChanged: (p) => setState(() => _page = p),
      sortColumnIndex: _sortColumnIndex,
      sortDirection: _direction,
      onSort: _onSort,
      emptyState: _emptyState(context),
    );
  }

  Widget _emptyState(BuildContext context) {
    final state = widget.state;
    final isFiltered =
        state.query.trim().isNotEmpty || state.filter != ReviewsFilter.all;

    if (isFiltered) {
      return DashboardEmptyState(
        icon: Icons.search_off_rounded,
        title: 'لا توجد تقييمات مطابقة',
        message: 'جرّب تغيير الفلتر أو مسح كلمة البحث.',
        action: OutlinedButton.icon(
          onPressed: () =>
              context.read<ReviewsCubit>().setFilter(ReviewsFilter.all),
          icon: const Icon(Icons.filter_alt_off_rounded),
          label: const Text('عرض الكل'),
        ),
      );
    }

    return const DashboardEmptyState(
      icon: DashboardIcons.reviews,
      title: 'لا توجد تقييمات بعد',
      message:
          'تظهر هنا تقييمات الركاب فور إنهاء رحلاتهم وتقييمها من التطبيق.',
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
            '${r.clientName} · ${_formatDate(r.createdAt)}',
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
          onPressed: () => showReviewDetailsDialog(context, r),
          icon: const Icon(Icons.visibility_outlined, size: 19),
          visualDensity: VisualDensity.compact,
        ),
      ),
    ];
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$d/$m · $hh:$mm';
  }
}
