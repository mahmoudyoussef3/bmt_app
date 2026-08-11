import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_dev_mode_sheet.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_empty_state.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_root_header.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../cubit/trip_history_cubit.dart';
import '../cubit/trip_history_state.dart';
import '../utils/trip_history_labels.dart';
import '../widgets/trip_history_list.dart';
import '../widgets/trip_history_search_bar.dart';
import '../widgets/trip_history_skeleton.dart';
import '../widgets/trip_history_summary_row.dart';

class TripHistoryPage extends StatelessWidget {
  const TripHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: BlocBuilder<TripHistoryCubit, TripHistoryState>(
        builder: (context, state) => switch (state) {
          TripHistoryLoading() => const TripHistorySkeleton(),
          TripHistoryError(:final message) => _ErrorBody(message: message),
          TripHistoryLoaded() => _LoadedBody(state: state),
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AsyncStateView(
        status: AsyncViewStatus.error,
        errorMessage: message,
        onRetry: () => context.read<TripHistoryCubit>().load(),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state});

  final TripHistoryLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripHistoryCubit>();

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: CustomScrollView(
        slivers: [
          CaptainRootHeader(
            title: CaptainRootHeader.titleSubtitle(
              context,
              title: 'سجل الرحلات',
              subtitle: TripHistoryLabels.completedTrips(state.totalTrips),
            ),
            onNotificationsTap: () => context.openNotifications(),
            onAvatarTap: kDebugMode
                ? () => showCaptainDevModeSheet(context)
                : null,
          ),
          if (state.hasNoTrips)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CaptainEmptyState(
                  title: 'لا توجد رحلات مكتملة',
                  subtitle: 'ستظهر رحلاتك المنجزة هنا بعد إتمامها.',
                  icon: Icons.history_rounded,
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: TripHistorySummaryRow(
                totalTrips: state.totalTrips,
                totalPassengers: state.totalPassengers,
                averagePassengers: state.averagePassengers,
              ),
            ),
            SliverToBoxAdapter(
              child: TripHistorySearchBar(
                dateFilter: state.dateFilter,
                filterCounts: state.filterCounts,
                matchCount: state.matchCount,
                isFiltering: state.isFiltering,
                onQueryChanged: cubit.search,
                onDateFilterChanged: cubit.filterByDate,
                onClearFilters: cubit.clearFilters,
              ),
            ),
            if (state.hasNoMatches)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CaptainEmptyState(
                    title: 'لا نتائج مطابقة',
                    subtitle: 'جرّب كلمة بحث مختلفة أو غيّر الفترة الزمنية.',
                    icon: Icons.search_off_rounded,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  CaptainDesignTokens.s24,
                  CaptainDesignTokens.s8,
                  CaptainDesignTokens.s24,
                  CaptainBottomNav.reservedSpace(context),
                ),
                sliver: TripHistoryList(groups: state.groups),
              ),
          ],
        ],
      ),
    );
  }
}
