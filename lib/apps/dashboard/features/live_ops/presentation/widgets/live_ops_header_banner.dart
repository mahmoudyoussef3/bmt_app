import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_pulse_chip.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/tracking/link_health.dart';

import '../../domain/entities/live_ops_snapshot.dart';
import '../bloc/fleet_tracking_bloc.dart';
import '../bloc/fleet_tracking_state.dart';

/// What the operations desk is looking at, when it was last true, and the one
/// action that makes it truer — a bare line on the page, not a card.
///
/// This is مركز العمليات المباشر's twin of Home's `HomeHeaderBanner`, built to
/// the same three parts in the same order: a title block, the module's actions
/// on its baseline, and a **pulse strip** of facts that are only true this
/// minute. The two screens are opened one after the other all day by the same
/// person, so they open the same way.
///
/// The strip is where this module differs from Home, and it should: Home's
/// pulse is the day's schedule, this one is the *link* — how many buses are
/// actually reporting, how far the worst delay has run, and how much of the
/// queue nobody has claimed. A KPI is a count and cannot say any of that.
///
/// The context line carries the read time, because a live board with no
/// freshness stamp is indistinguishable from a frozen one — the single most
/// reasonable suspicion an operator can have about this screen.
class LiveOpsHeaderBanner extends StatelessWidget {
  const LiveOpsHeaderBanner({
    super.key,
    required this.snapshot,
    required this.now,
    this.onRefresh,
    this.onOpenTrips,
  });

  final LiveOpsSnapshot snapshot;

  /// The board's clock. Every relative label on the page is measured against
  /// this one value so the header cannot disagree with the cards under it.
  final DateTime now;

  final VoidCallback? onRefresh;

  /// Opens the trips module — the screen that can actually change a board this
  /// one only reports on.
  final VoidCallback? onOpenTrips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final identity = _Identity(contextLine: _contextLine());
            final actions = _Actions(
              onRefresh: onRefresh,
              onOpenTrips: onOpenTrips,
            );

            if (constraints.maxWidth < 640) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  identity,
                  const SizedBox(height: AppSpacing.medium),
                  actions,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: identity),
                const SizedBox(width: AppSpacing.large),
                actions,
              ],
            );
          },
        ),
        _PulseStrip(snapshot: snapshot, now: now),
      ],
    );
  }

  /// Counts first, then when they were read. Same shape as Home's line, so an
  /// operator's eye lands on the freshness stamp in the same place on both.
  String _contextLine() {
    final active = snapshot.activeTrips.length;
    final open = snapshot.openIncidentCount;
    final parts = <String>[
      active == 0 ? 'لا رحلات على الطريق' : '$active رحلة على الطريق',
      open == 0 ? 'لا بلاغات مفتوحة' : '$open بلاغ مفتوح',
      'آخر قراءة ${_formatClock(snapshot.generatedAt)}',
    ];
    return parts.join(' · ');
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.contextLine});

  final String contextLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'مركز العمليات المباشر',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 3),
        Text(
          contextLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
      ],
    );
  }
}

/// One primary action, one secondary — the same pairing, in the same place, as
/// every other module header in the console.
class _Actions extends StatelessWidget {
  const _Actions({this.onRefresh, this.onOpenTrips});

  final VoidCallback? onRefresh;
  final VoidCallback? onOpenTrips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (onOpenTrips != null)
          FilledButton.icon(
            onPressed: onOpenTrips,
            icon: const Icon(DashboardIcons.tripsActive, size: 18),
            label: const Text('إدارة الرحلات'),
          ),
        if (onRefresh != null)
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(DashboardIcons.refresh, size: 18),
            label: const Text('تحديث'),
          ),
      ],
    );
  }
}

/// The facts that are only true this minute: how many buses are reporting their
/// position, the longest delay still on the board, and how much of the queue
/// nobody has claimed.
///
/// Only the first reads the feed, and only its count — so a position landing
/// repaints one chip, not the header.
///
/// Deliberately no «منذ N ثانية» freshness chip here: the board is rebuilt only
/// when the roster actually changes (see `LiveOpsScreen._sameRender`), so a
/// relative age printed at the top of the page would freeze between polls and
/// claim the screen is fresher than it is. The absolute read time in the context
/// line above cannot rot, which is why the freshness stamp lives there.
class _PulseStrip extends StatelessWidget {
  const _PulseStrip({required this.snapshot, required this.now});

  final LiveOpsSnapshot snapshot;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final overdue = snapshot.overdueTrips(now);
    final worst = overdue.isEmpty ? null : overdue.first;
    final delay = worst?.departureDelayAt(now);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.medium),
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        children: [
          const _FeedChip(),
          if (worst != null && delay != null)
            DashboardPulseChip(
              icon: Icons.running_with_errors_rounded,
              label: 'أطول تأخير',
              value:
                  '${_delayText(delay)}'
                  ' · ${worst.routeName.isEmpty ? 'رحلة بدون مسار' : worst.routeName}',
              tone: AppStatusTone.error,
            ),
          if (snapshot.unacknowledgedCount > 0)
            DashboardPulseChip(
              icon: DashboardIcons.incident,
              label: 'بانتظار الاستلام',
              value: '${snapshot.unacknowledgedCount} بلاغ',
              tone: AppStatusTone.warning,
            ),
        ],
      ),
    );
  }
}

/// How many vehicles the socket is actually carrying, and whether the socket is
/// still up.
///
/// Counted off the feed rather than off the roster's seed fixes: after the first
/// delivery those two numbers diverge, and the one worth printing at the top of
/// this page is the live one.
class _FeedChip extends StatelessWidget {
  const _FeedChip();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      FleetTrackingBloc,
      FleetTrackingState,
      ({int vehicles, TrackingLink link, bool failed})
    >(
      selector: (feed) => (
        vehicles: feed.vehicles.length,
        link: feed.link,
        failed: feed.hasFailure,
      ),
      builder: (context, view) {
        final broken = view.failed || view.link == TrackingLink.lost;
        final tone = broken
            ? AppStatusTone.error
            : view.link == TrackingLink.degraded
            ? AppStatusTone.warning
            : view.vehicles > 0
            ? AppStatusTone.success
            : AppStatusTone.neutral;

        return DashboardPulseChip(
          icon: broken ? Icons.cloud_off_rounded : DashboardIcons.liveOpsActive,
          label: 'البث المباشر',
          value: broken ? 'منقطع' : '${view.vehicles} مركبة ترسل موقعها',
          tone: tone,
        );
      },
    );
  }
}

/// Human delay text. Hours carry their minutes because "متأخرة ساعة" reads very
/// differently from "متأخرة ساعة و٥٠ د" to someone deciding what to do.
String _delayText(Duration delay) {
  final minutes = delay.inMinutes;
  if (minutes < 60) return '$minutes د';
  final hours = delay.inHours;
  final rest = minutes % 60;
  return rest == 0 ? '$hours س' : '$hours س و$rest د';
}

/// 24h clock, plain digits — matches every other timestamp in the console.
String _formatClock(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(at.hour)}:${two(at.minute)}';
}
