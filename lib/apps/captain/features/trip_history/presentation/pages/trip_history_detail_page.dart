import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../../domain/entities/trip_history_item.dart';
import '../../domain/entities/trip_history_stop.dart';
import '../cubit/trip_history_detail_cubit.dart';
import '../cubit/trip_history_detail_state.dart';

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
        appBar: AppBar(title: Text(trip.route)),
        body: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            CaptainDesignTokens.s16,
            CaptainDesignTokens.s16,
            CaptainDesignTokens.s16,
            CaptainDesignTokens.s24,
          ),
          children: [
            _TripSummaryCard(trip: trip),
            const SizedBox(height: CaptainDesignTokens.s24),
            Text(
              'مسار الرحلة',
              style: CaptainTypography.titleSmall(
                context,
              ).copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: CaptainDesignTokens.s12),
            BlocBuilder<TripHistoryDetailCubit, TripHistoryDetailState>(
              builder: (context, state) {
                return switch (state) {
                  TripHistoryDetailLoading() => const _StopsSkeleton(),
                  TripHistoryDetailError(:final message) => AsyncStateView(
                    status: AsyncViewStatus.error,
                    errorMessage: message,
                    onRetry: () =>
                        context.read<TripHistoryDetailCubit>().load(trip.id),
                    child: const SizedBox.shrink(),
                  ),
                  TripHistoryDetailLoaded(:final stops) =>
                    stops.isEmpty
                        ? const _NoStopsRecorded()
                        : _StopsTimeline(stops: stops),
                };
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  const _TripSummaryCard({required this.trip});

  final TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    final dateLabel = CaptainFormats.fullDate(trip.tripDate);
    final departure = CaptainFormats.clock(trip.departureTime);
    final arrival = CaptainFormats.clock(trip.arrivalTime);

    return CaptainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: CaptainTypography.titleSmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$departure → $arrival',
                style: CaptainTypography.labelLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s16),
          Row(
            children: [
              Expanded(
                child: _Fact(
                  icon: Icons.people_alt_rounded,
                  label: 'الركاب',
                  value: '${trip.boardedCount}/${trip.passengerCount}',
                ),
              ),
              Expanded(
                child: _Fact(
                  icon: Icons.directions_bus_rounded,
                  label: 'المركبة',
                  value: trip.vehicleNumber.isNotEmpty
                      ? trip.vehicleNumber
                      : '—',
                ),
              ),
              Expanded(
                child: _Fact(
                  icon: Icons.timer_rounded,
                  label: 'المدة',
                  value: CaptainFormats.duration(trip.duration),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: CaptainColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: CaptainTypography.labelLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: CaptainTypography.labelSmall(
            context,
          ).copyWith(color: CaptainColors.textSecondaryFor(context)),
        ),
      ],
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
            name: stops[i].name,
            scheduledTime: stops[i].scheduledTime,
            isFirst: i == 0,
            isLast: i == stops.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.name,
    required this.scheduledTime,
    required this.isFirst,
    required this.isLast,
  });

  final String name;
  final String? scheduledTime;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst || isLast
                        ? CaptainColors.primary
                        : CaptainColors.success,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: CaptainColors.dividerFor(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: CaptainDesignTokens.s20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: CaptainTypography.bodyMedium(context).copyWith(
                        fontWeight: isFirst || isLast
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (scheduledTime != null)
                    Text(
                      scheduledTime!,
                      style: CaptainTypography.labelMedium(context).copyWith(
                        color: CaptainColors.textSecondaryFor(context),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoStopsRecorded extends StatelessWidget {
  const _NoStopsRecorded();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CaptainDesignTokens.s24),
      child: Center(
        child: Text(
          'لا توجد محطات مسجلة لهذه الرحلة',
          style: CaptainTypography.bodyMedium(
            context,
          ).copyWith(color: CaptainColors.textSecondaryFor(context)),
        ),
      ),
    );
  }
}

class _StopsSkeleton extends StatelessWidget {
  const _StopsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: CaptainDesignTokens.s32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}
