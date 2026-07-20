import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/core/tracking/geo_math.dart';

/// GPS status, distance remaining, and expected arrival.
///
/// Reports the age of the last *stored* fix rather than implying a live
/// position: a running trip reports automatically every minute (see
/// `TripLocationAutoShare`), but a tunnel, a denied permission or a dead
/// signal all show up here as a fix going stale — which is exactly what the
/// captain needs to see before operations calls to ask where they are.
class TripGpsStatusCard extends StatelessWidget {
  const TripGpsStatusCard({
    super.key,
    required this.lastLocation,
    required this.destination,
    required this.expectedArrivalTime,
  });

  final TripLastLocationFix? lastLocation;

  /// The trip's final stop, used to compute distance remaining — null when
  /// the route point has no saved coordinates.
  final AssignedTripStop? destination;
  final DateTime expectedArrivalTime;

  @override
  Widget build(BuildContext context) {
    final fix = lastLocation;

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
          Text(
            'الموقع والوصول',
            style: CaptainTypography.titleSmall(
              context,
            ).copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          // Ticked, not sampled at build: "منذ 3 دقائق" has to keep counting
          // while the captain looks at it.
          CaptainTicker(
            builder: (context, now) => _GpsFreshnessRow(fix: fix, now: now),
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          Row(
            children: [
              Expanded(
                child: _Fact(
                  icon: Icons.flag_rounded,
                  label: 'الوصول المتوقع',
                  value: CaptainFormats.clock(expectedArrivalTime),
                ),
              ),
              Expanded(
                child: _Fact(
                  icon: Icons.social_distance_rounded,
                  label: 'المسافة المتبقية',
                  value: _distanceLabel(fix, destination),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _distanceLabel(TripLastLocationFix? fix, AssignedTripStop? dest) {
    if (fix == null || dest == null || !dest.hasCoordinates) return '—';
    final meters = GeoMath.distanceMeters(
      fix.latitude,
      fix.longitude,
      dest.latitude!,
      dest.longitude!,
    );
    if (meters < 1000) return '${meters.round()} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }
}

class _GpsFreshnessRow extends StatelessWidget {
  const _GpsFreshnessRow({required this.fix, required this.now});

  final TripLastLocationFix? fix;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (fix == null) {
      return Row(
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 16,
            color: CaptainColors.textSecondaryFor(context),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Expanded(
            child: Text(
              'لم يُرسل أي موقع لهذه الرحلة بعد',
              style: CaptainTypography.bodySmall(
                context,
              ).copyWith(color: CaptainColors.textSecondaryFor(context)),
            ),
          ),
        ],
      );
    }

    final age = now.difference(fix!.recordedAt);
    // Thresholds are tighter than the old one-shot model warranted: automatic
    // reporting runs every minute, so anything past a few minutes means the
    // sends are actually failing, not that the captain simply hasn't tapped.
    final (color, label) = switch (age) {
      Duration(inMinutes: < 3) => (
        CaptainColors.success,
        'محدّث — منذ ${_ageLabel(age)}',
      ),
      Duration(inMinutes: < 10) => (
        CaptainColors.warning,
        'قد يكون قديماً — منذ ${_ageLabel(age)}',
      ),
      _ => (CaptainColors.error, 'قديم — منذ ${_ageLabel(age)}'),
    };

    return Row(
      children: [
        Icon(Icons.gps_fixed_rounded, size: 16, color: color),
        const SizedBox(width: CaptainDesignTokens.s8),
        Expanded(
          child: Text(
            label,
            style: CaptainTypography.bodySmall(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  String _ageLabel(Duration age) {
    if (age.inMinutes < 1) return 'أقل من دقيقة';
    if (age.inMinutes < 60) return '${age.inMinutes} دقيقة';
    final hours = age.inHours;
    final minutes = age.inMinutes.remainder(60);
    return minutes == 0 ? '$hours ساعة' : '$hoursس $minutesد';
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: CaptainColors.primary),
        const SizedBox(width: CaptainDesignTokens.s8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        ),
      ],
    );
  }
}
