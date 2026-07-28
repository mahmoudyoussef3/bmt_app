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

/// Reports the vehicle's position for a running trip, automatically and on
/// demand.
///
/// Both paths are live at once, deliberately: the 30-second timer is what keeps
/// the client's tracking map moving without the captain touching anything,
/// and the button is what a captain reaches for when a passenger on the phone
/// asks "where are you now?" and a stale fix isn't good enough.
///
/// Sharing is bound to [enabled] — the trip actually being under way — and to
/// nothing else. It starts on departure and stops when the trip stops or the
/// captain signs out; it explicitly does **not** stop because this card was
/// scrolled past, rebuilt, or left behind when the captain opened the map or
/// the chat. The publisher is an app-lifetime singleton, so this widget is a
/// view onto it rather than its owner.
///
/// Still foreground only: a minimised app stops reporting, and the card's
/// health line is derived from when a fix last landed so it says so.
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
    // `.value`, never `create:` — the cubit is a singleton owned by the app, and
    // `create:` would hand this widget's disposal the power to close it and kill
    // a running trip's reporting.
    return BlocProvider<LiveLocationCubit>.value(
      value: captainGetIt<LiveLocationCubit>(),
      child: _AutoShareController(tripId: tripId, enabled: enabled),
    );
  }
}

/// Owns the start/stop lifecycle. Stateful because the timer has to follow
/// the trip's status as it changes underneath a screen that stays open.
class _AutoShareController extends StatefulWidget {
  const _AutoShareController({required this.tripId, required this.enabled});

  final String tripId;
  final bool enabled;

  @override
  State<_AutoShareController> createState() => _AutoShareControllerState();
}

class _AutoShareControllerState extends State<_AutoShareController>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  /// The card is one child of the trip-execution page's `SliverList`, and a
  /// sliver list disposes children scrolled past its cache extent. The timer no
  /// longer rides on this element's life — the publisher is a singleton — but
  /// keeping the element alive while a trip is under way still avoids the
  /// rebuild churn of tearing the card down and rebuilding it on every scroll
  /// past the cache extent.
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
    // Deliberately does not stop reporting. This widget going away means the
    // captain navigated, scrolled, or rotated — none of which is the trip
    // ending, and all of which used to take the client's map down with them.
    super.dispose();
  }

  /// Timers do not survive backgrounding, so a resumed app has a gap to close.
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
      // `enabled` drives whether this element is worth holding across a
      // scroll, so the keep-alive has to be re-evaluated with it.
      updateKeepAlive();
    }
  }

  /// Deferred past the current frame: this runs from `initState` /
  /// `didUpdateWidget`, and `startAutoSharing` emits synchronously.
  void _sync({String? previousTripId}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<LiveLocationCubit>();
      if (widget.enabled) {
        cubit.startAutoSharing(widget.tripId);
      } else {
        // Named, so this can only ever stop the trip this card is about. With a
        // shared publisher an unnamed stop would let a card rebuilding for a
        // finished trip silence a different trip that is still running.
        cubit.stopAutoSharing(tripId: previousTripId ?? widget.tripId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin

    // Occupies no space when there is nothing to report — the card and its
    // trailing gap appear and disappear together.
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

        // Ticked rather than sampled once: a fix goes stale while the captain
        // is looking at the card, and the headline has to notice.
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
        borderRadius: CaptainDesignTokens.br24,
        border: Border.all(
          // A stale card is bordered in its own tone: at a glance from the
          // driving position the border is what carries, not the sentence.
          color: status.health == LocationSharingHealth.stale
              ? CaptainColors.error.withValues(alpha: 0.5)
              : CaptainColors.dividerFor(context),
        ),
        boxShadow: CaptainDesignTokens.softShadow(context),
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
          // The clock of the last successful send, kept as supporting detail
          // under a headline that now states the health itself.
          if (lastSentAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'آخر إرسال ${CaptainFormats.clock(lastSentAt.toLocal())}',
              style: CaptainTypography.bodySmall(
                context,
              ).copyWith(color: CaptainColors.textSecondaryFor(context)),
            ),
          ],
          // A single dropped tick is a pothole in the signal and is not worth a
          // word. A run of them means the client's map has been frozen for
          // minutes, and the captain — the only person who can move the phone,
          // check the signal, or call the office — is told plainly.
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
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                isSending ? 'جارٍ تحديد الموقع...' : 'إرسال الموقع الآن',
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
      ),
    );
  }
}
