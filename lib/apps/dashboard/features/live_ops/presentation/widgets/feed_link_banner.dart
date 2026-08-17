import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/tracking/link_health.dart';

import '../bloc/fleet_tracking_bloc.dart';
import '../bloc/fleet_tracking_event.dart';
import '../bloc/fleet_tracking_state.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// Tells the operator when the map itself has stopped being live.
///
/// This is the honesty half of removing the unconditional poll. A board that
/// silently stops receiving positions looks exactly like a board where every bus
/// happens to be parked — and the operator would go on trusting markers that had
/// quietly frozen. The old design could not tell the difference, because nothing
/// read the socket's status; now the link is a first-class fact.
///
/// It stays silent while the link is healthy: a banner that is always there is
/// one nobody reads.
class FeedLinkBanner extends StatelessWidget {
  const FeedLinkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FleetTrackingBloc, FleetTrackingState>(
      buildWhen: (prev, curr) =>
          prev.link != curr.link ||
          prev.failure != curr.failure ||
          prev.isConnecting != curr.isConnecting,
      builder: (context, state) {
        // Nothing to say while positions are flowing, and nothing useful to say
        // before the feed has reported for the first time.
        if (state.isConnecting) return const SizedBox.shrink();
        if (!state.hasFailure && state.link.isConnected) {
          return const SizedBox.shrink();
        }

        final failed = state.hasFailure;
        final tone = failed || state.link == TrackingLink.lost
            ? AppStatusTone.error
            : AppStatusTone.warning;
        final colors = context.status(tone);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.small),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            decoration: BoxDecoration(
              color: colors.tint,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              border: Border.all(color: colors.ink.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(
                  failed ? Icons.cloud_off_rounded : Icons.sync_problem_rounded,
                  size: 18,
                  color: colors.ink,
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    _message(state),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (failed)
                  TextButton(
                    onPressed: () => context.read<FleetTrackingBloc>().add(
                      const FleetTrackingRetryRequested(),
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Says what the operator can still rely on, not just what broke — the
  /// markers are still the last known positions either way.
  String _message(FleetTrackingState state) {
    if (state.hasFailure) {
      return 'انقطع بث المواقع المباشر. المعروض آخر موقع معروف لكل مركبة.';
    }
    return switch (state.link) {
      TrackingLink.degraded =>
        'الاتصال المباشر متعثّر — يجري تحديث المواقع بالاستعلام الدوري.',
      TrackingLink.lost =>
        'تعذّر الاتصال المباشر. المعروض آخر موقع معروف لكل مركبة.',
      TrackingLink.connected => '',
    };
  }
}
