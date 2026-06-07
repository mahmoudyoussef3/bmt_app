import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_trip.dart';
import 'trip_card.dart';

class TripsKanbanBoard extends StatelessWidget {
  final List<OperationTrip> trips;
  final ValueChanged<OperationTrip> onTripSelected;
  final void Function(OperationTrip trip, OperationTripStatus status)
  onTripMoved;

  const TripsKanbanBoard({
    required this.trips,
    required this.onTripSelected,
    required this.onTripMoved,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: OperationTripStatus.values.map((status) {
          final columnTrips = trips
              .where((trip) => trip.status == status)
              .toList();
          return SizedBox(
            width: 310,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.medium),
              child: _KanbanColumn(
                status: status,
                trips: columnTrips,
                onTripSelected: onTripSelected,
                onTripMoved: onTripMoved,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final OperationTripStatus status;
  final List<OperationTrip> trips;
  final ValueChanged<OperationTrip> onTripSelected;
  final void Function(OperationTrip trip, OperationTripStatus status)
  onTripMoved;

  const _KanbanColumn({
    required this.status,
    required this.trips,
    required this.onTripSelected,
    required this.onTripMoved,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DragTarget<OperationTrip>(
      onAcceptWithDetails: (details) => onTripMoved(details.data, status),
      builder: (context, candidates, rejects) {
        final hovering = candidates.isNotEmpty;
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: hovering ? scheme.primaryContainer.withAlpha(70) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          status.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text('${trips.length}'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  if (trips.isEmpty)
                    SizedBox(
                      height: 110,
                      child: Center(
                        child: Text(
                          'اسحب رحلة هنا',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )
                  else
                    ...trips.map(
                      (trip) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.medium,
                        ),
                        child: TripCard(
                          trip: trip,
                          onTap: () => onTripSelected(trip),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
