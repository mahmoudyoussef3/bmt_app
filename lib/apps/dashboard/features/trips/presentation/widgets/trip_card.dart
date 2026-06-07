import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_trip.dart';
import 'trip_status_badge.dart';

class TripCard extends StatelessWidget {
  final OperationTrip trip;
  final VoidCallback onTap;

  const TripCard({required this.trip, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Draggable<OperationTrip>(
      data: trip,
      feedback: SizedBox(
        width: 280,
        child: Opacity(opacity: 0.92, child: _TripCardContent(trip: trip)),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _TripCardContent(trip: trip),
      ),
      child: AppCard(
        onTap: onTap,
        child: _TripCardBody(trip: trip),
      ),
    );
  }
}

class _TripCardContent extends StatelessWidget {
  final OperationTrip trip;

  const _TripCardContent({required this.trip});

  @override
  Widget build(BuildContext context) {
    return AppCard(child: _TripCardBody(trip: trip));
  }
}

class _TripCardBody extends StatelessWidget {
  final OperationTrip trip;

  const _TripCardBody({required this.trip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                trip.route,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TripStatusBadge(status: trip.status),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        _Fact(icon: Icons.person_outline, text: trip.driver),
        _Fact(icon: Icons.directions_bus_outlined, text: trip.vehicle),
        _Fact(
          icon: Icons.groups_outlined,
          text: '${trip.passengersCount} ركاب',
        ),
        const Divider(),
        Row(
          children: [
            Expanded(
              child: Text(
                'المغادرة ${trip.departure}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Text(
              'الوصول ${trip.arrival}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xSmall),
          Expanded(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
