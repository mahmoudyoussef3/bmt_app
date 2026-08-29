import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../cubit/reviews_cubit.dart';
import '../cubit/reviews_state.dart';
import '../widgets/driver_standings_panel.dart';
import '../widgets/reviews_board.dart';
import '../widgets/reviews_format.dart';
import '../widgets/reviews_kpi_strip.dart';
import '../widgets/reviews_toolbar.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_cap_notice.dart';

/// التقييمات — every passenger review of every completed trip.
///
/// This screen is the only window onto individual reviews in the whole
/// platform. Passengers see aggregates, captains see their own average, and
/// the written feedback lands here and nowhere else.
///
/// ## One shape for the whole الدعم section
///
/// Header with its foldable KPI strip → the shared filter bar (queue strip,
/// pinned search and ordering, the rest behind one fold) → the results header →
/// the rows. الشكاوى next door is composed the same way, and so are the three
/// المبيعات modules: the section an operator is in should never change what the
/// controls are or where they live.
class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewsCubit, ReviewsState>(
      builder: (context, state) {
        return switch (state) {
          ReviewsLoading() => const DashboardLoading(rows: 6),
          ReviewsError(:final message) => DashboardErrorState(
            title: 'تعذر تحميل التقييمات',
            message: message,
            onRetry: () => context.read<ReviewsCubit>().load(),
          ),
          ReviewsLoaded() => _LoadedView(state: state),
        };
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final ReviewsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReviewsCubit>();
    final summary = state.summary;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.reviewsActive,
          title: 'التقييمات',
          subtitle:
              'آراء الركاب في السائقين والمركبات والمسارات — مرئية للإدارة فقط',
          actions: [
            if (state.capReached)
              const DashboardCapNotice(
                rowCap: DashboardQueryCaps.reviews,
                noun: 'تقييم',
                // The averages are computed over the loaded set, and no filter
                // on this screen reaches the query, so there is nothing the
                // operator can narrow to see further back.
                hint: '',
              ),
            FilledButton.tonalIcon(
              onPressed: cubit.load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث'),
            ),
          ],
          sectionId: DashboardSectionIds.reviewsHeader,
          // Open, like every other list module's header: the four numbers *are*
          // what the module is opened to read, and three of the tiles are the
          // shortcut to the queue behind them.
          initiallyExpanded: true,
          collapsedSummary: DashboardSectionSummary(
            items: [
              'إجمالي ${ReviewsFormat.count(summary.total)}',
              'تحتاج متابعة ${ReviewsFormat.count(summary.needsAttentionCount)}',
              'بها تعليقات ${ReviewsFormat.count(summary.commentedCount)}',
              'المتوسط '
                  '${ReviewsFormat.rating(summary.overallAverage, outOf: summary.total)}',
            ],
          ),
          summary: ReviewsKpiStrip(state: state, onOpenQueue: cubit.setFilter),
        ),
        const SizedBox(height: AppSpacing.medium),
        ReviewsToolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        ReviewsBoard(state: state),
        const SizedBox(height: AppSpacing.medium),
        DriverStandingsPanel(standings: state.driverStandings),
      ],
    );
  }
}
