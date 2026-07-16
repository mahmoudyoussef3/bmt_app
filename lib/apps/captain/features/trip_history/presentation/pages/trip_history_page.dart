import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_empty_state.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_sliver_header.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../cubit/trip_history_cubit.dart';
import '../cubit/trip_history_state.dart';
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
          CaptainSliverHeader(
            title: 'سجل الرحلات',
            subtitle: '${state.totalTrips} رحلة مكتملة',
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
              ),
            ),
            SliverToBoxAdapter(
              child: TripHistorySearchBar(
                dateFilter: state.dateFilter,
                onQueryChanged: cubit.search,
                onDateFilterChanged: cubit.filterByDate,
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
                  // Cleared for the shell's floating nav bar.
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
