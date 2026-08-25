import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';

import '../../domain/entities/location_sharing_health.dart';
import '../cubit/live_location_cubit.dart';
import '../cubit/live_location_state.dart';

class TripLocationAutoShare extends StatelessWidget {
  const TripLocationAutoShare({
    super.key,
    required this.tripId,
    required this.enabled,
  });

  final String tripId;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveLocationCubit>.value(
      value: captainGetIt<LiveLocationCubit>(),
      child: _AutoShareController(tripId: tripId, enabled: enabled),
    );
  }
}

class _AutoShareController extends StatefulWidget {
  const _AutoShareController({required this.tripId, required this.enabled});

  final String tripId;
  final bool enabled;

  @override
  State<_AutoShareController> createState() => _AutoShareControllerState();
}

class _AutoShareControllerState extends State<_AutoShareController>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => widget.enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<LiveLocationCubit>().resumeIfStale();
    }
  }

  @override
  void didUpdateWidget(_AutoShareController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.tripId != widget.tripId) {
      _sync(previousTripId: oldWidget.tripId);
      updateKeepAlive();
    }
  }

  void _sync({String? previousTripId}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<LiveLocationCubit>();
      if (widget.enabled) {
        cubit.startAutoSharing(widget.tripId);
      } else {
        cubit.stopAutoSharing(tripId: previousTripId ?? widget.tripId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.enabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        bottom: CaptainDesignTokens.s24,
      ),
      child: _AutoShareCard(tripId: widget.tripId),
    );
  }
}

class _AutoShareCard extends StatelessWidget {
  const _AutoShareCard({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveLocationCubit, LiveLocationState>(
      builder: (context, state) {
        final isSending = state is LiveLocationLoading;
        final lastSentAt = state is LiveLocationReady ? state.lastSentAt : null;
        final failures = state is LiveLocationReady
            ? state.consecutiveFailures
            : 0;
        final error = switch (state) {
          LiveLocationReady(:final lastError) => lastError,
          LiveLocationError(:final message) => message,
          _ => null,
        };

        return CaptainTicker(
          builder: (context, now) => _card(
            context,
            status: LocationSharingStatus.evaluate(
              isAutoSharing: state.isAutoSharing,
              lastSentAt: lastSentAt,
              now: now,
            ),
            lastSentAt: lastSentAt,
            error: error,
            isSending: isSending,
            failures: failures,
          ),
        );
      },
    );
  }

  Widget _card(
    BuildContext context, {
    required LocationSharingStatus status,
    required DateTime? lastSentAt,
    required String? error,
    required bool isSending,
    required int failures,
  }) {
    final needsRetry =
        status.health == LocationSharingHealth.stale || error != null;

    final (icon, tone) = switch (status.health) {
      LocationSharingHealth.live => (
        Icons.share_location_rounded,
        CaptainColors.success,
      ),
      LocationSharingHealth.acquiring => (
        Icons.gps_not_fixed_rounded,
        CaptainColors.warning,
      ),
      LocationSharingHealth.stale => (
        Icons.location_disabled_rounded,
        CaptainColors.error,
      ),
      LocationSharingHealth.off => (
        Icons.location_disabled_rounded,
        CaptainColors.textSecondaryFor(context),
      ),
    };

    return Container(
      padding: const EdgeInsets.all(CaptainDesignTokens.s20),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(
          color: status.health == LocationSharingHealth.stale
              ? CaptainColors.error.withValues(alpha: 0.5)
              : CaptainColors.dividerFor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: tone),
              const SizedBox(width: CaptainDesignTokens.s8),
              Expanded(
                child: Text(
                  status.headline,
                  style: CaptainTypography.titleSmall(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: status.health == LocationSharingHealth.stale
                        ? CaptainColors.error
                        : null,
                  ),
                ),
              ),
            ],
          ),
          if (lastSentAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'آخر إرسال ${CaptainFormats.clock(lastSentAt.toLocal())}',
              style: CaptainTypography.bodySmall(
                context,
              ).copyWith(color: CaptainColors.textSecondaryFor(context)),
            ),
          ],
          if (failures >= 2) ...[
            const SizedBox(height: 4),
            Text(
              'فشل آخر $failures محاولات إرسال — خريطة الركاب متوقفة',
              style: CaptainTypography.bodySmall(context).copyWith(
                color: CaptainColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: CaptainDesignTokens.s8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: CaptainColors.error,
                ),
                const SizedBox(width: CaptainDesignTokens.s8),
                Expanded(
                  child: Text(
                    error,
                    style: CaptainTypography.bodySmall(context).copyWith(
                      color: CaptainColors.error,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Only when the pipeline is actually failing. While it is healthy the
          // captain has nothing to do here — offering a send button would say
          // the opposite, and a captain who believes the riders' map depends on
          // their taps is a captain who stops driving to tap.
          if (needsRetry) ...[
            const SizedBox(height: CaptainDesignTokens.s12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isSending
                    ? null
                    : () => context.read<LiveLocationCubit>().send(tripId),
                icon: isSending
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  isSending ? 'جارٍ تحديد الموقع...' : 'إعادة المحاولة الآن',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: CaptainDesignTokens.s12,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: CaptainDesignTokens.br16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
