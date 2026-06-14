import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_image_strip.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

/// Simple vehicle card for listing screen.
/// Focus: price, seats, ETA, rating, and main actions only.
class VehicleCompareCard extends StatelessWidget {
  const VehicleCompareCard({
    super.key,
    required this.vehicle,
    required this.onViewDetails,
    required this.onSelect,
    this.compact = false,
  });

  final VehicleDetailData vehicle;
  final VoidCallback onViewDetails;
  final VoidCallback onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lowSeats = vehicle.availableSeats <= 4;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _VehicleImageHeader(
              vehicle: vehicle,
              compact: compact,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VehicleMainInfo(vehicle: vehicle),
                  const SizedBox(height: 12),
                  _MainStatsRow(
                    vehicle: vehicle,
                    lowSeats: lowSeats,
                  ),
                  const SizedBox(height: 12),
                  _DriverCompactRow(vehicle: vehicle),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'التفاصيل',
                          outline: true,
                          height: 48,
                          onPressed: onViewDetails,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          label: 'اختيار العربية',
                          height: 48,
                          onPressed: onSelect,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleImageHeader extends StatelessWidget {
  const _VehicleImageHeader({
    required this.vehicle,
    required this.compact,
  });

  final VehicleDetailData vehicle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(18),
          ),
          child: VehicleImageStrip(
            labels: vehicle.imageLabels,
            height: compact ? 118 : 132,
          ),
        ),
        if (vehicle.isRecommended)
          PositionedDirectional(
            top: 10,
            start: 10,
            child: AppBadge(text: 'مقترحة'),
          ),
        PositionedDirectional(
          top: 10,
          end: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surface.withAlpha(235),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              vehicle.price,
              style: AppTextThemes.priceEmphasis(scheme).copyWith(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleMainInfo extends StatelessWidget {
  const _VehicleMainInfo({required this.vehicle});

  final VehicleDetailData vehicle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                vehicle.model,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(150),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        StatusChip(label: vehicle.vehicleType),
      ],
    );
  }
}

class _MainStatsRow extends StatelessWidget {
  const _MainStatsRow({
    required this.vehicle,
    required this.lowSeats,
  });

  final VehicleDetailData vehicle;
  final bool lowSeats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.schedule_rounded,
            label: 'المدة',
            value: vehicle.routeDuration,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.event_seat_rounded,
            label: 'المقاعد',
            value: lowSeats
                ? '${vehicle.availableSeats} فقط'
                : '${vehicle.availableSeats} متاح',
            warning: lowSeats,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.near_me_rounded,
            label: 'الوصول',
            value: vehicle.estimatedArrival,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.warning = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = warning ? scheme.tertiary : scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withAlpha(135),
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _DriverCompactRow extends StatelessWidget {
  const _DriverCompactRow({required this.vehicle});

  final VehicleDetailData vehicle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AppAvatar(initials: vehicle.driverInitials, radius: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              vehicle.driverName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Icon(Icons.star_rounded, size: 16, color: scheme.tertiary),
          const SizedBox(width: 4),
          Text(
            vehicle.driverRating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}