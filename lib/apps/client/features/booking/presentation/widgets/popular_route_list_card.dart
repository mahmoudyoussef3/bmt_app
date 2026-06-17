import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
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
    return Material(
      color: ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ClientColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.route_rounded, color: ClientColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.routeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.headingSmall(context),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${route.dailyTrips} available ${route.dailyTrips == 1 ? 'trip' : 'trips'}',
                          style: ClientTypography.labelMedium(context).copyWith(
                            color: route.dailyTrips > 0
                                ? ClientColors.primary
                                : ClientColors.textTertiaryFor(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'From',
                        style: ClientTypography.labelSmall(context).copyWith(
                          color: ClientColors.textTertiaryFor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route.startingPrice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClientTypography.priceMedium(context).copyWith(
                          fontSize: 17,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RouteLine(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Endpoint(label: 'Start', value: route.pickup),
                        const SizedBox(height: 14),
                        _Endpoint(label: 'Destination', value: route.destination),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FactChip(icon: Icons.straighten_rounded, label: route.distance),
                  _FactChip(icon: Icons.schedule_rounded, label: route.averageDuration),
                  _FactChip(
                    icon: Icons.directions_bus_rounded,
                    label: '${route.dailyTrips} trips',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tap to view route options',
                      style: ClientTypography.labelMedium(context).copyWith(
                        color: ClientColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ClientColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: ClientColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.textTertiaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? 'Not set' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(context),
        ),
      ],
    );
  }
}

class _RouteLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 72,
      child: Column(
        children: [
          _Dot(color: ClientColors.primary),
          Expanded(
            child: Center(
              child: Container(
                width: 2,
                color: ClientColors.borderFor(context),
              ),
            ),
          ),
          _Dot(color: ClientColors.journeyAmber),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: ClientColors.primary),
          const SizedBox(width: 6),
          Text(
            label.isEmpty ? 'Not set' : label,
            style: ClientTypography.labelMedium(context).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
