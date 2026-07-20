import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';

import '../cubit/live_location_cubit.dart';
import '../cubit/live_location_state.dart';

/// Reports the vehicle's position for a running trip, automatically and on
/// demand.
///
/// Both paths are live at once, deliberately: the minute timer is what keeps
/// the client's tracking map moving without the captain touching anything,
/// and the button is what a captain reaches for when a passenger on the phone
/// asks "where are you now?" and a stale fix isn't good enough.
///
/// Sharing is bound to [enabled] — the trip actually being under way — so the
/// timer starts on departure and stops the moment the trip ends or the
/// captain leaves the screen. Nothing runs in the background.
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
    return BlocProvider<LiveLocationCubit>(
      create: (_) => captainGetIt<LiveLocationCubit>(),
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

class _AutoShareControllerState extends State<_AutoShareController> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_AutoShareController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.tripId != widget.tripId) {
      _sync();
    }
  }

  /// Deferred past the current frame: this runs from `initState` /
  /// `didUpdateWidget`, and `startAutoSharing` emits synchronously.
  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<LiveLocationCubit>();
      if (widget.enabled) {
        cubit.startAutoSharing(widget.tripId);
      } else {
        cubit.stopAutoSharing();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        final error = switch (state) {
          LiveLocationReady(:final lastError) => lastError,
          LiveLocationError(:final message) => message,
          _ => null,
        };

        return Container(
          padding: const EdgeInsets.all(CaptainDesignTokens.s20),
          decoration: BoxDecoration(
            color: CaptainColors.surfaceFor(context),
            borderRadius: CaptainDesignTokens.br24,
            border: Border.all(color: CaptainColors.dividerFor(context)),
            boxShadow: CaptainDesignTokens.softShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    state.isAutoSharing
                        ? Icons.share_location_rounded
                        : Icons.location_disabled_rounded,
                    size: 20,
                    color: state.isAutoSharing
                        ? CaptainColors.success
                        : CaptainColors.textSecondaryFor(context),
                  ),
                  const SizedBox(width: CaptainDesignTokens.s8),
                  Expanded(
                    child: Text(
                      state.isAutoSharing
                          ? 'مشاركة الموقع تلقائياً كل دقيقة'
                          : 'المشاركة التلقائية متوقفة',
                      style: CaptainTypography.titleSmall(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                lastSentAt == null
                    ? 'جارٍ تحديد موقعك...'
                    : 'آخر إرسال ${CaptainFormats.clock(lastSentAt.toLocal())}',
                style: CaptainTypography.bodySmall(
                  context,
                ).copyWith(color: CaptainColors.textSecondaryFor(context)),
              ),
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
      },
    );
  }
}
