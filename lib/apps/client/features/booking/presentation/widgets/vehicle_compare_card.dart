import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/vehicle_image_strip.dart';

/// Rich vehicle card for side-by-side comparison on the listing screen.
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

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: VehicleImageStrip(
                  labels: vehicle.imageLabels,
                  height: compact ? 130 : 150,
                ),
              ),
              if (vehicle.isRecommended)
                Positioned(
                  top: 12,
                  left: 12,
                  child: AppBadge(text: 'Recommended'),
                ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withAlpha(230),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vehicle.price,
                    style: AppTextThemes.priceEmphasis(
                      scheme,
                    ).copyWith(fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VehicleInfoHeader(vehicle: vehicle),
                const SizedBox(height: 14),
                _SectionLabel(
                  title: 'Comfort',
                  icon: Icons.airline_seat_recline_normal_rounded,
                ),
                const SizedBox(height: 8),
                _ComfortRow(vehicle: vehicle),
                const SizedBox(height: 14),
                _SectionLabel(title: 'Driver', icon: Icons.person_rounded),
                const SizedBox(height: 8),
                _DriverRow(vehicle: vehicle),
                const SizedBox(height: 14),
                const AppSeparator(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _PricingChip(
                      icon: Icons.payments_outlined,
                      label: vehicle.price,
                    ),
                    const SizedBox(width: 10),
                    _PricingChip(
                      icon: Icons.event_seat_outlined,
                      label: lowSeats
                          ? '${vehicle.availableSeats} seats left'
                          : '${vehicle.availableSeats} seats',
                    ),
                    const Spacer(),
                    Text(
                      'ETA ${vehicle.estimatedArrival}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(160),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Details',
                        outline: true,
                        height: 44,
                        onPressed: onViewDetails,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Select Vehicle',
                        height: 44,
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
    );
  }
}

class _VehicleInfoHeader extends StatelessWidget {
  const _VehicleInfoHeader({required this.vehicle});

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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                vehicle.model,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withAlpha(170),
                ),
              ),
              const SizedBox(height: 8),
              StatusChip(label: vehicle.vehicleType),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.schedule_rounded, size: 16, color: scheme.primary),
            const SizedBox(height: 4),
            Text(
              vehicle.routeDuration,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.onSurface.withAlpha(200),
          ),
        ),
      ],
    );
  }
}

class _ComfortRow extends StatelessWidget {
  const _ComfortRow({required this.vehicle});

  final VehicleDetailData vehicle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniChip(
          icon: vehicle.hasAirConditioning
              ? Icons.ac_unit_rounded
              : Icons.ac_unit_outlined,
          label: vehicle.hasAirConditioning ? 'A/C' : 'No A/C',
          active: vehicle.hasAirConditioning,
        ),
        _MiniChip(icon: Icons.chair_rounded, label: vehicle.seatType),
        _MiniChip(
          icon: Icons.airline_seat_recline_extra_rounded,
          label: vehicle.hasRecliningSeats ? 'Reclining' : 'Fixed seats',
          active: vehicle.hasRecliningSeats,
        ),
        _MiniChip(
          icon: Icons.straighten_rounded,
          label: 'Leg room · ${vehicle.legRoomLabel}',
        ),
        _MiniChip(
          icon: Icons.verified_rounded,
          label: vehicle.vehicleCondition,
          active: vehicle.vehicleCondition == 'Excellent',
        ),
      ],
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({required this.vehicle});

  final VehicleDetailData vehicle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        AppAvatar(initials: vehicle.driverInitials, radius: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.driverName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star_rounded, size: 14, color: scheme.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    vehicle.driverRating.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    ' · ${vehicle.completedTrips} trips · ${vehicle.yearsExperience} yrs',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? scheme.primary.withAlpha(36)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? scheme.primary.withAlpha(100)
              : scheme.outline.withAlpha(80),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PricingChip extends StatelessWidget {
  const _PricingChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondary.withAlpha(28),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
