import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';

class PopularRouteListCard extends StatelessWidget {
  const PopularRouteListCard({
    super.key,
    required this.route,
    required this.onTap,
  });

  final PopularRouteListData route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.alt_route_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.routeName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${route.pickup} → ${route.destination}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                route.startingPrice,
                style: AppTextThemes.priceEmphasis(
                  scheme,
                ).copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(
                icon: Icons.repeat_rounded,
                label: '${route.dailyTrips} daily trips',
              ),
              const SizedBox(width: 16),
              _Stat(
                icon: Icons.av_timer_rounded,
                label: 'Avg ${route.averageDuration}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
