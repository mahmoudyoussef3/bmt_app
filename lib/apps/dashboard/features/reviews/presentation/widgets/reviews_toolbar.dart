import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_filter_bar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_queue_tabs.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../cubit/reviews_cubit.dart';
import '../cubit/reviews_state.dart';
import '../models/review_queue_tab.dart';
import '../models/review_sort.dart';
import 'reviews_format.dart';

/// التقييمات' toolbar — the shared [DashboardFilterBar], the same control
/// الشكاوى next door and the three المبيعات modules wear: the queue strip, then
/// the pinned search and ordering, then the rest behind one fold.
///
/// The module used to render bare [ChoiceChip]s beside a search field, with no
/// ordering control and no way to narrow to one captain or one corridor. The
/// slices are the same three; what changed is that they now look and behave
/// like every other queue strip in the console.
class ReviewsToolbar extends StatelessWidget {
  const ReviewsToolbar({super.key, required this.state});

  final ReviewsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReviewsCubit>();

    return DashboardFilterBar(
      sectionId: DashboardSectionIds.reviewsFilters,
      tabs: DashboardQueueTabBar(
        tabs: [
          for (final tab in ReviewsFilter.values)
            DashboardQueueTab(
              label: tab.label,
              count: ReviewsFormat.count(tab.countIn(state)),
              selected: state.filter == tab,
              urgent: tab.isWorkQueue,
              onTap: () => cubit.setFilter(tab),
            ),
        ],
      ),
      search: DebouncedSearchField(
        // Keyed on the term so clearing the filters from anywhere else — the
        // reset button, the empty state — resets the field rather than leaving
        // stale text above an unfiltered feed.
        key: ValueKey('review-search-${state.query}'),
        initialValue: state.query,
        hintText: 'ابحث باسم العميل أو الكابتن أو رقم الحجز أو نص التعليق',
        onChanged: cubit.search,
      ),
      // Both directions are real questions here: the newest review and the
      // oldest unanswered one, the worst score and the best.
      sort: DashboardSortControl<ReviewSort>(
        value: state.sort,
        values: ReviewSort.values,
        labelOf: (sort) => sort.label,
        onChanged: cubit.setSort,
        ascending: state.sortAscending,
        // `setSort` flips the direction when handed the key already in force,
        // which is exactly what the arrow means.
        onToggleDirection: () => cubit.setSort(state.sort),
      ),
      filters: _Filters(state: state, cubit: cubit),
      filterSummary: _summary(state),
      activeFilterCount: state.activeFilterCount,
      onClearFilters: cubit.clearFilters,
    );
  }

  /// What the folded filter row is still doing, in the operator's own words — a
  /// narrowing they have forgotten they set is how a partial feed gets read as
  /// the whole feed.
  static List<String> _summary(ReviewsLoaded state) {
    if (state.activeFilterCount == 0) return const ['بدون تصفية'];
    return [
      if (state.query.trim().isNotEmpty) 'بحث: ${state.query.trim()}',
      if (state.filter != ReviewsFilter.all) state.filter.label,
      if (state.band != ReviewRatingBand.any) state.band.label,
      if (state.driverName != null) 'السائق: ${state.driverName}',
      if (state.routeLabel != null) 'المسار: ${state.routeLabel}',
    ];
  }
}

/// The narrowings the queue strip has no room for: the star band, and the two
/// axes an office actually investigates a bad week along — one captain, one
/// corridor.
class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.cubit});

  final ReviewsLoaded state;
  final ReviewsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return DashboardFilterFields(
      fields: [
        DashboardFilterDropdown<ReviewRatingBand>(
          label: 'التقييم',
          icon: Icons.star_outline_rounded,
          value: state.band,
          values: ReviewRatingBand.values,
          labelOf: (band) => band.label,
          onChanged: cubit.setBand,
        ),
        DashboardFilterDropdown<String?>(
          label: 'السائق',
          icon: Icons.person_outline,
          value: state.driverName,
          values: [null, ...state.driverNames],
          emptyHint: 'لا يوجد سائقون في هذه التقييمات',
          labelOf: (name) => name ?? 'كل السائقين',
          onChanged: cubit.setDriver,
        ),
        DashboardFilterDropdown<String?>(
          label: 'المسار',
          icon: Icons.alt_route_rounded,
          value: state.routeLabel,
          values: [null, ...state.routeLabels],
          emptyHint: 'لا توجد مسارات في هذه التقييمات',
          labelOf: (label) => label ?? 'كل المسارات',
          onChanged: cubit.setRoute,
        ),
      ],
    );
  }
}
