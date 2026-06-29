import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/domain/entities/booking_option.dart';

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
    final hasTrips = route.dailyTrips > 0;
    final pricePending =
        route.startingPrice.trim().toLowerCase() == 'price pending';

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
            boxShadow: [
              BoxShadow(
                color: ClientColors.shadowFor(context).withAlpha(14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
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
                      color: hasTrips
                          ? ClientColors.primaryContainerFor(context)
                          : ClientColors.surfaceMutedFor(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.route_rounded,
                      color: hasTrips
                          ? ClientColors.primaryFor(context)
                          : ClientColors.textTertiaryFor(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.routeName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.headingSmall(context),
                        ),
                        const SizedBox(height: 6),
                        _AvailabilityBadge(
                          label: hasTrips
                              ? '${route.dailyTrips} ${route.dailyTrips == 1 ? 'trip' : 'trips'} today'
                              : 'No trips today',
                          active: hasTrips,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _PriceBlock(
                    price: route.startingPrice,
                    pending: pricePending,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ClientColors.surfaceSubtleFor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ClientColors.borderFor(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RouteLine(active: hasTrips),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Endpoint(label: 'From', value: route.pickup),
                          const SizedBox(height: 12),
                          _Endpoint(label: 'To', value: route.destination),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FactChip(
                    icon: Icons.straighten_rounded,
                    label: route.distance,
                  ),
                  _FactChip(
                    icon: Icons.schedule_rounded,
                    label: route.averageDuration,
                  ),
                  _FactChip(
                    icon: Icons.directions_bus_rounded,
                    label: hasTrips ? 'Seats available' : 'Check later',
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasTrips
                          ? 'Choose trip time and vehicle'
                          : 'View route details',
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
                      color: hasTrips
                          ? ClientColors.primary
                          : ClientColors.surfaceMutedFor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: hasTrips
                          ? Colors.white
                          : ClientColors.textSecondaryFor(context),
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

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final background = active
        ? ClientColors.journeyGreenLight
        : ClientColors.journeySlateLight;
    final foreground = active
        ? ClientColors.onJourneyGreen
        : ClientColors.onJourneySlate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.info_rounded,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelMedium(
                context,
              ).copyWith(color: foreground, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.price, required this.pending});

  final String price;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            pending ? 'Price' : 'From',
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textTertiaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            price,
            maxLines: pending ? 2 : 1,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: pending
                ? ClientTypography.labelLarge(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  )
                : ClientTypography.priceMedium(
                    context,
                  ).copyWith(fontSize: 18, height: 1.05),
          ),
        ],
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
  const _RouteLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 72,
      child: Column(
        children: [
          _Dot(
            color: active
                ? ClientColors.primaryFor(context)
                : ClientColors.textTertiaryFor(context),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 2,
                color: ClientColors.borderFor(context),
              ),
            ),
          ),
          _Dot(color: active ? ClientColors.journeyAmber : ClientColors.border),
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
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
