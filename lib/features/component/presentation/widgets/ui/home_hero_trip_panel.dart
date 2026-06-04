import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/home_mock_data.dart';

/// Current-trip summary or book-a-trip prompt inside the home hero.
class HomeHeroTripPanel extends StatelessWidget {
  const HomeHeroTripPanel({
    super.key,
    required this.scheme,
    required this.trip,
    required this.onBookTrip,
    required this.onViewTrip,
    this.onTrackTrip,
  });

  final ColorScheme scheme;
  final HomeCurrentTripData? trip;
  final VoidCallback onBookTrip;
  final VoidCallback onViewTrip;
  final VoidCallback? onTrackTrip;

  @override
  Widget build(BuildContext context) {
    if (trip == null) {
      return _NoTripPanel(scheme: scheme, onBookTrip: onBookTrip);
    }
    return _ActiveTripPanel(
      scheme: scheme,
      trip: trip!,
      onViewTrip: onViewTrip,
      onTrackTrip: onTrackTrip,
    );
  }
}

class _ActiveTripPanel extends StatelessWidget {
  const _ActiveTripPanel({
    required this.scheme,
    required this.trip,
    required this.onViewTrip,
    this.onTrackTrip,
  });

  final ColorScheme scheme;
  final HomeCurrentTripData trip;
  final VoidCallback onViewTrip;
  final VoidCallback? onTrackTrip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surface.withAlpha(238),
      borderRadius: BorderRadius.circular(AppLayout.radiusLg),
      child: InkWell(
        onTap: onViewTrip,
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppLayout.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Current trip',
                    style: AppTypography.caption(
                      scheme,
                    ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3),
                  ),
                  const Spacer(),
                  StatusChip(label: trip.statusLabel),
                ],
              ),
              const SizedBox(height: AppLayout.spaceMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RouteDots(scheme: scheme),
                  const SizedBox(width: AppLayout.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.routeLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: AppLayout.spaceXs),
                        Text(
                          trip.schedule,
                          style: AppTypography.caption(
                            scheme,
                          ).copyWith(color: scheme.onSurface.withAlpha(175)),
                        ),
                        if (trip.driverLine != null) ...[
                          const SizedBox(height: AppLayout.spaceXs),
                          Text(
                            trip.driverLine!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.secondary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.spaceMd),
              Row(
                children: [
                  if (onTrackTrip != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onTrackTrip,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppLayout.spaceSm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppLayout.radiusMd,
                            ),
                          ),
                        ),
                        child: const Text('Track'),
                      ),
                    ),
                  if (onTrackTrip != null)
                    const SizedBox(width: AppLayout.spaceSm),
                  Expanded(
                    child: TextButton(
                      onPressed: onViewTrip,
                      child: const Text('Trip details'),
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

class _RouteDots extends StatelessWidget {
  const _RouteDots({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: scheme.secondary,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 2,
          height: 28,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: scheme.outline.withAlpha(90),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: scheme.error,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _NoTripPanel extends StatelessWidget {
  const _NoTripPanel({required this.scheme, required this.onBookTrip});

  final ColorScheme scheme;
  final VoidCallback onBookTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.spaceLg,
        vertical: AppLayout.spaceXl,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(235),
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
        border: Border.all(
          color: scheme.outline.withAlpha(50),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withAlpha(22),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withAlpha(40),
                ),
                child: Icon(
                  Icons.directions_bus_filled_rounded,
                  size: 32,
                  color: scheme.primary,
                ),
              ),
              Positioned(
                right: 4,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outline.withAlpha(80)),
                  ),
                  child: Icon(
                    Icons.add_road_rounded,
                    size: 16,
                    color: scheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.spaceMd),
          Text(
            'No trip scheduled',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppLayout.spaceXs),
          Text(
            'Search routes and book your next commute when you are ready.',
            textAlign: TextAlign.center,
            style: AppTypography.caption(
              scheme,
            ).copyWith(color: scheme.onSurface.withAlpha(165), height: 1.4),
          ),
          const SizedBox(height: AppLayout.spaceLg),
          AppButton(label: 'Find a trip', height: 46, onPressed: onBookTrip),
        ],
      ),
    );
  }
}
