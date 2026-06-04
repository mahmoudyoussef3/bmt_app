import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/home_mock_data.dart';

/// Stands alone as a premium top-level card for trip overview/booking search.
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
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outline.withAlpha(50),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onViewTrip,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Category label & Status
                Row(
                  children: [
                    Text(
                      'UPCOMING RIDE',
                      style: AppTypography.caption(scheme).copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 11,
                        color: scheme.primary,
                      ),
                    ),
                    const Spacer(),
                    StatusChip(label: trip.statusLabel),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Visual Timeline
                _TripTimeline(
                  scheme: scheme,
                  pickup: trip.pickup,
                  destination: trip.destination,
                  schedule: trip.schedule,
                ),
                
                // Driver Details (if assigned)
                if (trip.driverLine != null) ...[
                  const SizedBox(height: 16),
                  Divider(height: 1, color: scheme.outline.withAlpha(55)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: scheme.primary.withAlpha(20),
                        child: Icon(
                          Icons.person_rounded,
                          color: scheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ahmed Captain',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trip.driverLine!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: scheme.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: scheme.primary,
                            size: 18,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                
                // Action Buttons
                Row(
                  children: [
                    if (onTrackTrip != null) ...[
                      Expanded(
                        child: AppButton(
                          label: 'Track Ride',
                          onPressed: onTrackTrip!,
                          height: 46,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: AppButton(
                        label: 'Details',
                        onPressed: onViewTrip,
                        outline: true,
                          height: 46,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripTimeline extends StatelessWidget {
  const _TripTimeline({
    required this.scheme,
    required this.pickup,
    required this.destination,
    required this.schedule,
  });

  final ColorScheme scheme;
  final String pickup;
  final String destination;
  final String schedule;

  @override
  Widget build(BuildContext context) {
    // Extract a mock departure time if available, else default
    final timeStr = schedule.contains('Departs') 
        ? schedule.split('Departs').last.trim() 
        : '8:40 AM';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Times
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 2),
            Text(
              timeStr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
            ),
            const SizedBox(height: 32),
            Text(
              'Est. +45m',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(120),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        
        // Center Column: Visual Dots & Timeline Line
        Column(
          children: [
            const SizedBox(height: 5),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: scheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.secondary.withAlpha(120), width: 2),
              ),
            ),
            Container(
              width: 2,
              height: 34,
              color: scheme.outline.withAlpha(85),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: scheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.error.withAlpha(120), width: 2),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        
        // Right Column: Location labels
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickup,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Pickup Station',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(130),
                      fontSize: 11.5,
                    ),
              ),
              const SizedBox(height: 14),
              Text(
                destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Drop-off Destination',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(130),
                      fontSize: 11.5,
                    ),
              ),
            ],
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
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outline.withAlpha(50),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Where would you like to go?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                    letterSpacing: -0.2,
                  ),
            ),
            const SizedBox(height: 12),
            
            // Mock Search Bar Input Field
            InkWell(
              onTap: onBookTrip,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withAlpha(130),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.outline.withAlpha(45),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: scheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Enter destination...',
                        style: TextStyle(
                          color: scheme.onSurface.withAlpha(120),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.my_location_rounded,
                      color: scheme.onSurface.withAlpha(130),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            
            // Quick Shortcuts / Destinations
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 15,
                  color: scheme.onSurface.withAlpha(110),
                ),
                const SizedBox(width: 6),
                Text(
                  'Quick Commutes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(120),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildShortcutChip(
                  context,
                  icon: Icons.work_outline_rounded,
                  label: 'Smart Village',
                ),
                _buildShortcutChip(
                  context,
                  icon: Icons.train_outlined,
                  label: 'Banha Station',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: onBookTrip,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.primary.withAlpha(12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: scheme.primary.withAlpha(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
