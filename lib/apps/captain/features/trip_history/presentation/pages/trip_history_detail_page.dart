import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_detail_row.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_loading_state.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_sliver_header.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../../domain/entities/trip_history_item.dart';
import '../../domain/entities/trip_history_stop.dart';
import '../cubit/trip_history_detail_cubit.dart';
import '../cubit/trip_history_detail_state.dart';
import '../utils/trip_history_labels.dart';
import '../utils/trip_history_palette.dart';
import '../widgets/trip_history_boarding_bar.dart';
import '../widgets/trip_history_time_strip.dart';

/// A completed trip's detail: the journey's real, saved stations in order
/// (the "timeline"), plus the same facts already on its history card.
class TripHistoryDetailPage extends StatelessWidget {
  const TripHistoryDetailPage({super.key, required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TripHistoryDetailCubit>(
      create: (_) => captainGetIt<TripHistoryDetailCubit>()..load(trip.id),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        body: CustomScrollView(
          slivers: [
            // The same header the rest of the captain's sub-screens use, rather
            // than a bare AppBar carrying the route as a title: the date is a
            // fact about *this* trip and belongs beside its name, not buried in
            // the first card.
            CaptainSliverHeader(
              title: trip.route,
              subtitle: CaptainFormats.fullDate(trip.tripDate),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                CaptainDesignTokens.s16,
                CaptainDesignTokens.s8,
                CaptainDesignTokens.s16,
                CaptainDesignTokens.s24,
              ),
              sliver: SliverList.list(
                children: [
                  // Named from the background like the two blocks under it. It
                  // used to be the one section on the page with no heading at
                  // all, which read as a stray card rather than as the first of
                  // three parts.
                  const _SectionTitle(title: 'ملخص الرحلة'),
                  const SizedBox(height: CaptainDesignTokens.s12),
                  _JourneyCard(trip: trip),
                  const SizedBox(height: CaptainDesignTokens.s24),
                  _VehicleSection(trip: trip),
                  const SizedBox(height: CaptainDesignTokens.s24),
                  _StopsSection(tripId: trip.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// When the trip ran, how long it took, who was actually on it — and, at its
/// foot, what all of that adds up to.
class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    return CaptainCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s16),
            decoration: BoxDecoration(
              color: TripHistoryPalette.wash(context),
              borderRadius: const BorderRadius.vertical(
                top: CaptainDesignTokens.r24,
              ),
            ),
            child: TripHistoryTimeStrip(
              departure: trip.departureTime,
              arrival: trip.arrivalTime,
              duration: trip.duration,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(CaptainDesignTokens.s16),
            child: Column(
              children: [
                TripHistoryBoardingBar(
                  boarded: trip.boardedCount,
                  total: trip.passengerCount,
                ),
                const SizedBox(height: CaptainDesignTokens.s16),
                _OutcomeLine(trip: trip),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The trip's result, said outright.
///
/// The card above it states a booked count, a boarded count and a bar, and
/// leaves the captain to work out whether that was a good trip. This is the
/// answer those three were circling, in the tinted-panel shape the focus card
/// already uses for "here is where this stands".
class _OutcomeLine extends StatelessWidget {
  const _OutcomeLine({required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    final missing = trip.passengerCount - trip.boardedCount;
    // Nobody booked means nobody failed to board — a quiet fact, not a
    // shortfall, so it must not take the attention colour.
    final Color color;
    final IconData icon;
    if (trip.passengerCount == 0) {
      color = TripHistoryPalette.neutral(context);
      icon = Icons.person_off_rounded;
    } else if (missing > 0) {
      color = TripHistoryPalette.attention;
      icon = Icons.error_outline_rounded;
    } else {
      color = TripHistoryPalette.accent;
      icon = Icons.check_circle_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CaptainDesignTokens.s12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: CaptainDesignTokens.br16,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: CaptainDesignTokens.s8),
          Expanded(
            child: Text(
              TripHistoryLabels.outcome(
                boarded: trip.boardedCount,
                total: trip.passengerCount,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.bodySmall(context).copyWith(
                color: CaptainColors.textPrimaryFor(context),
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bus the trip ran on.
///
/// The plate is new here — the entity always carried it and the screen never
/// showed it, which is the one identifier a captain would come back to a
/// finished trip to check.
///
/// Its heading sits outside the card, the way the route section's already did.
/// The page used to name this one section from *inside* its own card and the
/// other from above it, so two adjacent blocks stated their titles in two
/// different places on the same screen.
class _VehicleSection extends StatelessWidget {
  const _VehicleSection({required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    final vehicle = trip.vehicleNumber.isEmpty ? '—' : trip.vehicleNumber;
    final plate = trip.plateNumber.isEmpty ? '—' : trip.plateNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'المركبة'),
        const SizedBox(height: CaptainDesignTokens.s12),
        CaptainCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CaptainDetailRow(
                icon: Icons.directions_bus_rounded,
                label: 'رقم المركبة',
                value: vehicle,
                valueIsIdentifier: true,
              ),
              CaptainDetailRow(
                icon: Icons.confirmation_number_rounded,
                label: 'لوحة الترخيص',
                value: plate,
                valueIsIdentifier: true,
                bottomSpacing: 0,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StopsSection extends StatelessWidget {
  const _StopsSection({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripHistoryDetailCubit, TripHistoryDetailState>(
      builder: (context, state) {
        final stops = switch (state) {
          TripHistoryDetailLoaded(:final stops) => stops,
          _ => const <TripHistoryStop>[],
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: 'مسار الرحلة',
              trailing: stops.isEmpty
                  ? null
                  : TripHistoryLabels.stops(stops.length),
            ),
            const SizedBox(height: CaptainDesignTokens.s12),
            switch (state) {
              TripHistoryDetailLoading() => const _StopsSkeleton(),
              TripHistoryDetailError(:final message) => AsyncStateView(
                status: AsyncViewStatus.error,
                errorMessage: message,
                onRetry: () =>
                    context.read<TripHistoryDetailCubit>().load(tripId),
                child: const SizedBox.shrink(),
              ),
              TripHistoryDetailLoaded() =>
                stops.isEmpty
                    ? const _NoStopsRecorded()
                    : CaptainCard(child: _StopsTimeline(stops: stops)),
            },
          ],
        );
      },
    );
  }
}

/// Names the block beneath it, from the page background rather than from inside
/// the card. The inset is carried here rather than at each call site so the
/// screen's headings line up with each other by construction.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;

  /// A count or aside, aligned to the heading's trailing edge.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: CaptainDesignTokens.s4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.titleSmall(
                context,
              ).copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: CaptainTypography.labelMedium(
                context,
              ).copyWith(color: TripHistoryPalette.neutral(context)),
            ),
        ],
      ),
    );
  }
}

/// The stations in the order the trip drove them.
///
/// The ends of the line are what a captain looks for first, so they carry the
/// filled marks and the icons; the stations between them are steps on the way
/// and are drawn as hollow marks, in the same family, so the line reads as one
/// journey instead of a stack of equal rows.
class _StopsTimeline extends StatelessWidget {
  const _StopsTimeline({required this.stops});

  final List<TripHistoryStop> stops;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < stops.length; i++)
          _TimelineRow(
            stop: stops[i],
            isFirst: i == 0,
            isLast: i == stops.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.stop,
    required this.isFirst,
    required this.isLast,
  });

  final TripHistoryStop stop;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isEnd = isFirst || isLast;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Rail(isFirst: isFirst, isLast: isLast),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                bottom: isLast ? 0 : CaptainDesignTokens.s20,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      stop.name,
                      style: CaptainTypography.bodyMedium(context).copyWith(
                        fontWeight: isEnd ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (stop.scheduledTime != null) ...[
                    const SizedBox(width: CaptainDesignTokens.s8),
                    _StopTime(time: stop.scheduledTime!, isEnd: isEnd),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.isFirst, required this.isLast});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isEnd = isFirst || isLast;

    return SizedBox(
      width: 24,
      child: Column(
        children: [
          Container(
            width: isEnd ? 22 : 12,
            height: isEnd ? 22 : 12,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnd
                  ? TripHistoryPalette.accent
                  : CaptainColors.surfaceFor(context),
              border: isEnd
                  ? null
                  : Border.all(
                      color: TripHistoryPalette.accent.withValues(alpha: 0.45),
                      width: 2,
                    ),
            ),
            child: isEnd
                ? Icon(
                    isFirst ? Icons.my_location_rounded : Icons.flag_rounded,
                    size: 12,
                    color: CaptainColors.onPrimary,
                  )
                : null,
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                color: TripHistoryPalette.accent.withValues(alpha: 0.20),
              ),
            ),
        ],
      ),
    );
  }
}

class _StopTime extends StatelessWidget {
  const _StopTime({required this.time, required this.isEnd});

  final String time;
  final bool isEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isEnd
            ? TripHistoryPalette.accent.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: CaptainDesignTokens.brPill,
      ),
      child: Text(
        time,
        style: CaptainTypography.labelMedium(context).copyWith(
          color: isEnd
              ? TripHistoryPalette.accent
              : TripHistoryPalette.neutral(context),
          fontWeight: isEnd ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoStopsRecorded extends StatelessWidget {
  const _NoStopsRecorded();

  @override
  Widget build(BuildContext context) {
    return CaptainCard(
      child: Row(
        children: [
          Icon(
            Icons.wrong_location_rounded,
            size: 18,
            color: TripHistoryPalette.neutral(context),
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Text(
              'لا توجد محطات مسجلة لهذه الرحلة',
              style: CaptainTypography.bodyMedium(
                context,
              ).copyWith(color: TripHistoryPalette.neutral(context)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder rows shaped like the timeline they stand in for, rather than a
/// spinner: the stops arrive in one shot, and a bare spinner here made a fast
/// load flash an empty page between two full ones.
class _StopsSkeleton extends StatelessWidget {
  const _StopsSkeleton();

  @override
  Widget build(BuildContext context) {
    return CaptainCard(
      child: Column(
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: EdgeInsetsDirectional.only(
                bottom: i == 3 ? 0 : CaptainDesignTokens.s20,
              ),
              child: Row(
                children: [
                  const CaptainSkeleton(
                    width: 22,
                    height: 22,
                    borderRadius: CaptainDesignTokens.brPill,
                  ),
                  const SizedBox(width: CaptainDesignTokens.s12),
                  CaptainSkeleton(width: 140 - (i * 20).toDouble(), height: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
