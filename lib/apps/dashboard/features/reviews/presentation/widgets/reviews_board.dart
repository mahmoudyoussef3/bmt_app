import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_pager.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_results_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/trip_review_entry.dart';
import '../cubit/reviews_cubit.dart';
import '../cubit/reviews_state.dart';
import 'rating_stars.dart';
import 'review_details_dialog.dart';
import 'reviews_format.dart';
import 'reviews_table.dart';

/// The review feed: the shared results header, then the table at desktop widths
/// and a card list below [kDashboardTableBreakpoint] — both paged by the same
/// index, so narrowing the window never moves the operator to a different set
/// of rows.
///
/// Composed exactly like [TicketsBoard] next door, which is what makes the
/// الدعم section read as one console: results header → rows → one pagination
/// bar, whichever layout is on screen.
class ReviewsBoard extends StatefulWidget {
  const ReviewsBoard({super.key, required this.state});

  final ReviewsLoaded state;

  @override
  State<ReviewsBoard> createState() => _ReviewsBoardState();
}

class _ReviewsBoardState extends State<ReviewsBoard> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant ReviewsBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new filter or queue can shrink the result set out from under the
    // current page — land back on the last real page rather than an empty one.
    final maxPage = _pageCount - 1;
    if (_page > maxPage) _page = maxPage;
  }

  List<TripReviewEntry> get _ordered => widget.state.visibleReviews;

  int get _pageCount =>
      (_ordered.length / reviewsPageSize).ceil().clamp(1, 99999);

  List<TripReviewEntry> get _pageItems {
    final ordered = _ordered;
    final start = (_page * reviewsPageSize).clamp(0, ordered.length);
    final end = (start + reviewsPageSize).clamp(0, ordered.length);
    return ordered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _pageItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultsHeader(
          total: _ordered.length,
          page: _page,
          showing: rows.length,
        ),
        const SizedBox(height: AppSpacing.small),
        if (rows.isEmpty)
          // Bare, not inside an AppCard: DashboardEmptyState draws its own
          // bordered surface, and the two together read as a panel in a panel.
          _EmptyFeed(state: widget.state)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < kDashboardTableBreakpoint) {
                return _ReviewCardList(
                  rows: rows,
                  total: _ordered.length,
                  page: _page,
                  pages: _pageCount,
                  onPageChanged: (page) => setState(() => _page = page),
                );
              }
              return ReviewsTable(
                state: widget.state,
                rows: rows,
                pageIndex: _page,
                onPageChanged: (page) => setState(() => _page = page),
                onSort: (sort) {
                  context.read<ReviewsCubit>().setSort(sort);
                  setState(() => _page = 0);
                },
                onOpen: (review) => showReviewDetailsDialog(context, review),
              );
            },
          ),
      ],
    );
  }
}

/// What this list is, and how much of it is on screen — the same strip every
/// other list module puts above its rows.
class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.total,
    required this.page,
    required this.showing,
  });

  final int total;
  final int page;
  final int showing;

  @override
  Widget build(BuildContext context) {
    final first = showing == 0 ? 0 : page * reviewsPageSize + 1;
    final last = first == 0 ? 0 : first + showing - 1;

    return DashboardResultsHeader(
      icon: DashboardIcons.reviews,
      title: 'قائمة التقييمات',
      subtitle: showing == 0
          ? 'لا نتائج'
          : 'عرض ${ReviewsFormat.count(first)}–${ReviewsFormat.count(last)} '
                'من ${ReviewsFormat.count(total)}',
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.state});

  final ReviewsLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.isFiltered) {
      return DashboardEmptyState(
        icon: Icons.search_off_rounded,
        title: 'لا توجد تقييمات مطابقة',
        message: 'جرّب تغيير الفلتر أو مسح كلمة البحث.',
        action: OutlinedButton.icon(
          onPressed: () => context.read<ReviewsCubit>().clearFilters(),
          icon: const Icon(Icons.filter_alt_off_rounded),
          label: const Text('عرض الكل'),
        ),
      );
    }

    return const DashboardEmptyState(
      icon: DashboardIcons.reviews,
      title: 'لا توجد تقييمات بعد',
      message: 'تظهر هنا تقييمات الركاب فور إنهاء رحلاتهم وتقييمها من التطبيق.',
    );
  }
}

/// Below the table's breakpoint the same rows render as cards, because six
/// truncated columns answer none of the questions the operator opened this
/// screen with.
class _ReviewCardList extends StatelessWidget {
  const _ReviewCardList({
    required this.rows,
    required this.total,
    required this.page,
    required this.pages,
    required this.onPageChanged,
  });

  final List<TripReviewEntry> rows;
  final int total;
  final int page;
  final int pages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final review in rows) ...[
          _ReviewCard(review: review),
          const SizedBox(height: AppSpacing.small),
        ],
        // The same bar the table closes with, so both layouts page identically.
        AppCard(
          padding: EdgeInsets.zero,
          child: DashboardPagerBar(
            totalLabel: 'الإجمالي ${ReviewsFormat.count(total)} تقييم',
            currentPage: page,
            pages: pages,
            onPageChanged: onPageChanged,
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final TripReviewEntry review;

  @override
  Widget build(BuildContext context) {
    final flagged = review.needsAttention;
    final tone = context.status(
      flagged ? AppStatusTone.error : AppStatusTone.success,
    );

    return AppCard(
      child: InkWell(
        onTap: () => showReviewDetailsDialog(context, review),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.hasComment
                        ? '«${review.comment.trim()}»'
                        : 'بدون تعليق',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontStyle: review.hasComment
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Text(
                  review.averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: ratingColor(context, review.averageRating),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.xSmall,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DashboardStatusChip(
                  label: flagged ? 'تحتاج متابعة' : 'منشور',
                  color: tone.tint,
                  textColor: tone.ink,
                ),
                _Fact(label: 'السائق', value: review.driverName),
                _Fact(label: 'المسار', value: review.routeLabel),
                _Fact(label: 'العميل', value: review.clientName),
                _Fact(
                  label: 'التاريخ',
                  value: ReviewsFormat.shortStamp(review.createdAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: DashboardColors.mutedInk(context),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
