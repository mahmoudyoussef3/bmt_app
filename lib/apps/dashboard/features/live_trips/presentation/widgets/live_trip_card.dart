import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';

import '../../domain/entities/live_trip.dart';

class LiveTripCard extends StatelessWidget {
  final LiveTrip trip;
  final bool selected;
  final VoidCallback onTap;

  const LiveTripCard({
    required this.trip,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline.withAlpha(0),
            width: selected ? 2 : 0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.route,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (trip.alerts.isNotEmpty)
                    Badge(
                      label: Text('${trip.alerts.length}'),
                      child: const Icon(Icons.warning_amber_outlined),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              _Fact(icon: Icons.person_outline, label: trip.driver),
              _Fact(icon: Icons.directions_bus_outlined, label: trip.vehicle),
              _Fact(
                icon: Icons.groups_outlined,
                label: '${trip.passengersCount} ركاب',
              ),
              const SizedBox(height: AppSpacing.medium),
              AppProgressBar(progress: trip.progress / 100),
              const SizedBox(height: AppSpacing.xSmall),
              Row(
                children: [
                  Text('التقدم ${trip.progress}%'),
                  const Spacer(),
                  Text('ETA ${trip.eta}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Fact({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xSmall),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
