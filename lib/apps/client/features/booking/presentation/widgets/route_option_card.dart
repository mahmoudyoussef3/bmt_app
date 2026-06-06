import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';

class RouteOptionCard extends StatelessWidget {
  const RouteOptionCard({
    super.key,
    required this.route,
    required this.onTap,
    this.selected = false,
  });

  final RouteOptionData route;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (route.isFastest) ...[
                const AppBadge(text: 'Fastest'),
                const SizedBox(width: 8),
              ],
              if (selected) ...[
                AppBadge(text: 'Selected'),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              Text(
                route.startingPrice,
                style: AppTextThemes.priceEmphasis(
                  scheme,
                ).copyWith(fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _EndpointRow(
            icon: Icons.trip_origin_rounded,
            color: scheme.secondary,
            label: 'Pickup Point',
            value: route.pickup,
          ),
          const SizedBox(height: 8),
          _EndpointRow(
            icon: Icons.location_on_rounded,
            color: scheme.tertiary,
            label: 'Destination',
            value: route.destination,
          ),
          const SizedBox(height: 14),
          const AppSeparator(),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetaChip(icon: Icons.schedule_rounded, label: route.duration),
              const SizedBox(width: 12),
              _MetaChip(
                icon: Icons.event_seat_rounded,
                label: '${route.availableSeats} seats',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EndpointRow extends StatelessWidget {
  const _EndpointRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
