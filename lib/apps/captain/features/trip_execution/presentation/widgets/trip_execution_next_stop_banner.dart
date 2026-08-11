import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';

import '../cubit/trip_execution_cubit.dart';

class TripExecutionNextStopBanner extends StatefulWidget {
  const TripExecutionNextStopBanner({
    super.key,
    required this.tripId,
    required this.stops,
    required this.arrivedStationsCount,
  });

  final String tripId;
  final List<AssignedTripStop> stops;

  final int arrivedStationsCount;

  @override
  State<TripExecutionNextStopBanner> createState() =>
      _TripExecutionNextStopBannerState();
}

class _TripExecutionNextStopBannerState
    extends State<TripExecutionNextStopBanner> {
  bool _isSubmitting = false;

  int? _optimisticIndex;

  int get _currentIndex {
    final live = widget.arrivedStationsCount.clamp(0, widget.stops.length);
    final optimistic = _optimisticIndex;
    if (optimistic == null || live >= optimistic) return live;
    return optimistic;
  }

  Future<void> _markCurrentStopArrived() async {
    final index = _currentIndex;
    if (_isSubmitting || index >= widget.stops.length) return;
    final stop = widget.stops[index];
    setState(() => _isSubmitting = true);
    try {
      await context.read<TripExecutionCubit>().markStationArrived(
        tripId: widget.tripId,
        pointId: stop.id,
        pointName: stop.name,
      );
      if (!mounted) return;
      setState(() {
        _optimisticIndex = index + 1;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackbar.error(context, 'تعذر تسجيل الوصول للمحطة، حاول مجدداً');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    final isLast = currentIndex >= widget.stops.length;

    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br20,
        boxShadow: CaptainDesignTokens.softShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: CaptainColors.primary.withValues(alpha: 0.10),
            padding: const EdgeInsets.symmetric(
              horizontal: CaptainDesignTokens.s20,
              vertical: CaptainDesignTokens.s12,
            ),
            child: _BannerHeader(
              isLast: isLast,
              remaining: widget.stops.length - currentIndex,
            ),
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.all(CaptainDesignTokens.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.stops[currentIndex].name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CaptainTypography.titleLarge(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: CaptainColors.textPrimaryFor(context),
                    ),
                  ),
                  const SizedBox(height: CaptainDesignTokens.s16),
                  CaptainButton(
                    label: 'تم الوصول للمحطة',
                    icon: Icons.check_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _markCurrentStopArrived,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BannerHeader extends StatelessWidget {
  const _BannerHeader({required this.isLast, required this.remaining});

  final bool isLast;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.location_on_rounded,
          color: CaptainColors.primary,
          size: 20,
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        Text(
          isLast ? 'تم الوصول للوجهة' : 'المحطة القادمة',
          style: CaptainTypography.titleSmall(
            context,
          ).copyWith(color: CaptainColors.primary, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (!isLast) _RemainingCount(remaining: remaining),
      ],
    );
  }
}

class _RemainingCount extends StatelessWidget {
  const _RemainingCount({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s12,
        vertical: CaptainDesignTokens.s8,
      ),
      decoration: const BoxDecoration(
        color: CaptainColors.primary,
        borderRadius: CaptainDesignTokens.brPill,
      ),
      child: Text(
        '$remaining محطة',
        style: CaptainTypography.labelSmall(
          context,
        ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}
