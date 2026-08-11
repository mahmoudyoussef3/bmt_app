import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_awaiting_trips_view.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_dev_mode_sheet.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';

import '../../domain/entities/assigned_trip.dart';
import '../../domain/entities/captain_day_summary.dart';
import '../cubit/assigned_trips_cubit.dart';
import '../cubit/assigned_trips_state.dart';
import '../widgets/assigned_trip_card.dart';
import '../widgets/assigned_trips_header.dart';
import '../widgets/assigned_trips_section_title.dart';
import '../widgets/assigned_trips_skeleton.dart';
import '../widgets/assigned_trips_stats_strip.dart';
import '../widgets/captain_day_complete_view.dart';
import '../widgets/captain_focus_card.dart';
import '../widgets/new_assignments_banner.dart';

class AssignedTripsPage extends StatelessWidget {
  const AssignedTripsPage({
    super.key,
    required this.onOpenHistory,
    required this.onOpenProfile,
  });

  final VoidCallback onOpenHistory;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: BlocBuilder<AssignedTripsCubit, AssignedTripsState>(
        builder: (context, state) => switch (state) {
          AssignedTripsLoading() => const AssignedTripsSkeleton(),
          AssignedTripsError(:final message) => _ErrorBody(message: message),
          AssignedTripsLoaded() => _Content(
            state: state,
            onOpenHistory: onOpenHistory,
            onOpenProfile: onOpenProfile,
          ),
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
        onRetry: () => context.read<AssignedTripsCubit>().load(),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.onOpenHistory,
    required this.onOpenProfile,
  });

  final AssignedTripsLoaded state;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenProfile;

  List<Widget> _idleShortcuts(BuildContext context) {
    return [
      CaptainListRow(
        icon: Icons.history_rounded,
        label: 'سجل رحلاتك',
        detail: 'الرحلات التي أنهيتها سابقاً',
        iconColor: CaptainColors.primary,
        showChevron: true,
        onTap: onOpenHistory,
      ),
      CaptainListRow(
        icon: Icons.notifications_none_rounded,
        label: 'الإشعارات',
        detail: 'آخر ما وصلك من العمليات',
        iconColor: CaptainColors.primary,
        showChevron: true,
        onTap: () => context.openNotifications(),
      ),
      CaptainListRow(
        icon: Icons.badge_outlined,
        label: 'ملفي وحالة التوثيق',
        detail: 'بياناتك والمركبة المخصصة لك',
        iconColor: CaptainColors.primary,
        showChevron: true,
        onTap: onOpenProfile,
      ),
    ];
  }

  Future<void> _refresh(BuildContext context) async {
    final succeeded = await context.read<AssignedTripsCubit>().refresh();
    if (!succeeded && context.mounted) {
      AppSnackbar.error(
        context,
        'تعذر تحديث الرحلات، تحقق من الاتصال وحاول مجدداً',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = CaptainDaySummary.fromTrips(state.trips);
    final focus = summary.focusTrip;
    final rest = focus == null
        ? state.trips
        : [
            for (final t in state.trips)
              if (t.id != focus.id) t,
          ];

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          AssignedTripsHeader(
            onAvatarTap: kDebugMode
                ? () => showCaptainDevModeSheet(context)
                : null,
            onNotificationsTap: () => context.openNotifications(),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              CaptainDesignTokens.s20,
              CaptainDesignTokens.s20,
              CaptainDesignTokens.s20,
              CaptainBottomNav.reservedSpace(context),
            ),
            sliver: summary.isEmpty
                ? SliverToBoxAdapter(
                    child: CaptainAwaitingTripsView(
                      onRefresh: () => _refresh(context),
                      isRefreshing: state.isRefreshing,
                      title: 'لا توجد رحلات اليوم',
                      message:
                          'فور إسناد رحلة من العمليات ستظهر هنا تلقائياً — '
                          'لا حاجة لإعادة تسجيل الدخول.',
                      shortcuts: _idleShortcuts(context),
                    ),
                  )
                : _DaySlivers(
                    state: state,
                    summary: summary,
                    focus: focus,
                    rest: rest,
                    onRefresh: () => _refresh(context),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DaySlivers extends StatelessWidget {
  const _DaySlivers({
    required this.state,
    required this.summary,
    required this.focus,
    required this.rest,
    required this.onRefresh,
  });

  final AssignedTripsLoaded state;
  final CaptainDaySummary summary;
  final AssignedTrip? focus;
  final List<AssignedTrip> rest;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final newTripCount = state.newTripIds.length;
    final focusTrip = focus;

    return SliverMainAxisGroup(
      slivers: [
        SliverList.list(
          children: [
            if (newTripCount > 0) ...[
              NewAssignmentsBanner(
                count: newTripCount,
                onAcknowledge: () =>
                    context.read<AssignedTripsCubit>().acknowledgeNewTrips(),
              ),
              const SizedBox(height: CaptainDesignTokens.s16),
            ],
            if (focusTrip != null) ...[
              CaptainFocusCard(
                trip: focusTrip,
                onOpen: () => context.openTripExecution(focusTrip),
              ),
              const SizedBox(height: CaptainDesignTokens.s20),
              AssignedTripsStatsStrip(summary: summary),
            ] else
              CaptainDayCompleteView(
                summary: summary,
                onRefresh: onRefresh,
                isRefreshing: state.isRefreshing,
              ),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: CaptainDesignTokens.s24),
              AssignedTripsSectionTitle(
                title: focusTrip == null ? 'رحلات اليوم' : 'بقية رحلات اليوم',
                count: rest.length,
              ),
              const SizedBox(height: CaptainDesignTokens.s12),
            ],
          ],
        ),
        SliverList.builder(
          itemCount: rest.length,
          itemBuilder: (context, i) {
            final trip = rest[i];
            return Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: CaptainDesignTokens.s12,
              ),
              child: AssignedTripCard(
                trip: trip,
                onOpen: () => context.openTripExecution(trip),
                onManifest: () => context.openPassengerManifest(trip.id),
              ),
            );
          },
        ),
      ],
    );
  }
}
