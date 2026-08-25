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
              color: CaptainColors.surfaceAltFor(context),
              borderRadius: const BorderRadius.vertical(
                top: CaptainDesignTokens.r20,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TripHistoryBoardingBar(
                  boarded: trip.boardedCount,
                  total: trip.passengerCount,
                ),
                const SizedBox(height: CaptainDesignTokens.s12),
                _Outcome(trip: trip),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How the trip turned out, said in words.
///
/// The bar above it plots the ratio; this states the conclusion the captain
/// came to the page for, so nobody has to subtract 18 from 20 to find out
/// whether anything went wrong.
class _Outcome extends StatelessWidget {
  const _Outcome({required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    final missing = trip.passengerCount - trip.boardedCount;
    final shortfall = trip.passengerCount > 0 && missing > 0;
    final tint = shortfall
        ? TripHistoryPalette.attention
        : TripHistoryPalette.neutral(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceAltFor(context),
        borderRadius: CaptainDesignTokens.br12,
      ),
      child: Row(
        children: [
          Icon(
            shortfall
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 16,
            color: tint,
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Expanded(
            child: Text(
              TripHistoryLabels.outcome(
                trip.boardedCount,
                trip.passengerCount,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.labelMedium(context).copyWith(
                color: shortfall
                    ? tint
                    : CaptainColors.textSecondaryFor(context),
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;

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
