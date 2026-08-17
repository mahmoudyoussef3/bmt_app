import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../../domain/entities/reviews_summary.dart';
import '../cubit/reviews_cubit.dart';
import '../cubit/reviews_state.dart';
import '../widgets/driver_standings_panel.dart';
import '../widgets/rating_stars.dart';
import '../widgets/review_card.dart';
import '../widgets/reviews_filter_bar.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_cap_notice.dart';

/// التقييمات — every passenger review of every completed trip.
///
/// This screen is the only window onto individual reviews in the whole
/// platform. Passengers see aggregates, captains see their own average, and
/// the written feedback lands here and nowhere else.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewsCubit, ReviewsState>(
      builder: (context, state) {
        return switch (state) {
          ReviewsLoading() => const DashboardLoading(),
          ReviewsError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<ReviewsCubit>().load(),
          ),
          ReviewsLoaded() => _loaded(context, state),
        };
      },
    );
  }

  Widget _loaded(BuildContext context, ReviewsLoaded state) {
    final cubit = context.read<ReviewsCubit>();
    final summary = state.summary;
    final visible = state.visibleReviews;

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
          ],
          sectionId: DashboardSectionIds.reviewsHeader,
          summary: _Kpis(summary: summary),
        ),
        const SizedBox(height: AppSpacing.large),
        if (state.isEmpty)
          const EmptyState(
            emoji: '⭐',
            title: 'لا توجد تقييمات بعد',
            subtitle:
                'تظهر هنا تقييمات الركاب فور إنهاء رحلاتهم وتقييمها من التطبيق.',
          )
        else ...[
          DashboardCollapsibleSection(
            sectionId: DashboardSectionIds.reviewsFilters,
            icon: Icons.filter_alt_outlined,
            title: 'البحث والتصفية',
            collapsedSummary: DashboardSectionSummary(
              items: [
                state.filter.label,
                if (_search.text.trim().isNotEmpty)
                  'بحث: ${_search.text.trim()}',
                '${visible.length} تقييم ظاهر',
              ],
            ),
            child: ReviewsFilterBar(
              filter: state.filter,
              needsAttentionCount: summary.needsAttentionCount,
              onFilterChanged: cubit.setFilter,
              onSearch: (query) {
                cubit.search(query);
                setState(() {});
              },
              searchController: _search,
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          if (state.isFilteredEmpty)
            const EmptyState(
              emoji: '🔍',
              title: 'لا توجد تقييمات مطابقة',
              subtitle: 'جرّب تغيير الفلتر أو مسح كلمة البحث.',
            )
          else
            for (final review in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                child: ReviewCard(review: review),
              ),
          const SizedBox(height: AppSpacing.medium),
          DriverStandingsPanel(standings: state.driverStandings),
        ],
      ],
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.summary});

  final ReviewsSummary summary;

  @override
  Widget build(BuildContext context) {
    return DashboardKpiGrid(
      children: [
        DashboardKpiCard(
          label: 'إجمالي التقييمات',
          value: '${summary.total}',
          icon: Icons.reviews_outlined,
        ),
        DashboardKpiCard(
          label: 'متوسط تقييم السائق',
          value: _avg(summary.driverAverage),
          icon: Icons.person_outline,
          color: ratingColor(context, summary.driverAverage),
        ),
        DashboardKpiCard(
          label: 'متوسط تقييم المركبة',
          value: _avg(summary.vehicleAverage),
          icon: Icons.directions_bus_outlined,
          color: ratingColor(context, summary.vehicleAverage),
        ),
        DashboardKpiCard(
          label: 'تحتاج متابعة',
          value: '${summary.needsAttentionCount}',
          detail: 'تقييم بنجمتين أو أقل',
          icon: Icons.report_gmailerrorred_outlined,
          color: context
              .status(
                summary.needsAttentionCount > 0
                    ? AppStatusTone.error
                    : AppStatusTone.success,
              )
              .accent,
        ),
      ],
    );
  }

  String _avg(double value) =>
      summary.total == 0 ? '—' : value.toStringAsFixed(1);
}
