import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/core/tracking/geo_math.dart';

/// GPS status, distance remaining, and expected arrival — all honestly
/// scoped to what a one-shot location send can actually support (see
/// `live_location`): no continuous tracking, so this shows the age of the
/// last sent fix explicitly rather than implying a live position.
class TripGpsStatusCard extends StatelessWidget {
  const TripGpsStatusCard({
    super.key,
    required this.lastLocation,
    required this.destination,
    required this.expectedArrivalTime,
    required this.onSendLocation,
  });

  final TripLastLocationFix? lastLocation;

  /// The trip's final stop, used to compute distance remaining — null when
  /// the route point has no saved coordinates.
  final AssignedTripStop? destination;
  final DateTime expectedArrivalTime;
  final VoidCallback onSendLocation;

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
          Row(
            children: [
              Text(
                'الموقع والوصول',
                style: CaptainTypography.titleSmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onSendLocation,
                icon: const Icon(Icons.my_location_rounded, size: 16),
                label: const Text('تحديث'),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          _GpsFreshnessRow(fix: fix),
          const SizedBox(height: CaptainDesignTokens.s12),
          Row(
            children: [
              Expanded(
                child: _Fact(
                  icon: Icons.flag_rounded,
                  label: 'الوصول المتوقع',
                  value: _timeLabel(expectedArrivalTime),
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

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
  const _GpsFreshnessRow({required this.fix});

  final TripLastLocationFix? fix;

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

    final age = DateTime.now().difference(fix!.recordedAt);
    final (color, label) = switch (age) {
      Duration(inMinutes: < 10) => (
        CaptainColors.success,
        'محدّث — منذ ${_ageLabel(age)}',
      ),
      Duration(inMinutes: < 30) => (
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
