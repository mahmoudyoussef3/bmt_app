import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_trip.dart';
import 'trip_status_badge.dart';

class TripDetailsPanel extends StatelessWidget {
  final OperationTrip trip;
  final VoidCallback onClose;
  final void Function(OperationTripStatus status) onStatusChanged;
  final void Function(TripSeat seat, TripSeatState state) onSeatStateChanged;

  const TripDetailsPanel({
    required this.trip,
    required this.onClose,
    required this.onStatusChanged,
    required this.onSeatStateChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.route_outlined, size: 42),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.route,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text('${trip.date} • ${trip.departure} - ${trip.arrival}'),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text('${trip.driver} • ${trip.vehicle}'),
                    const SizedBox(height: AppSpacing.small),
                    TripStatusBadge(status: trip.status),
                  ],
                ),
              ),
              Wrap(
                spacing: AppSpacing.small,
                children: [
                  PopupMenuButton<OperationTripStatus>(
                    tooltip: 'تحديث الحالة',
                    onSelected: onStatusChanged,
                    itemBuilder: (context) => OperationTripStatus.values
                        .map(
                          (status) => PopupMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    child: const Icon(Icons.more_vert),
                  ),
                  AppButton(
                    label: 'إغلاق',
                    height: 40,
                    outline: true,
                    onPressed: onClose,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        _TripCompositionSection(trip: trip),
        const SizedBox(height: AppSpacing.medium),
        _SeatMapSection(trip: trip, onSeatStateChanged: onSeatStateChanged),
        const SizedBox(height: AppSpacing.medium),
        _TimelineSection(events: trip.events),
        const SizedBox(height: AppSpacing.medium),
        _PassengersSection(passengers: trip.passengers),
        const SizedBox(height: AppSpacing.medium),
        _PaymentsSection(payments: trip.payments),
        const SizedBox(height: AppSpacing.medium),
        _EventsSection(events: trip.events),
        const SizedBox(height: AppSpacing.medium),
        _NotesSection(notes: trip.notes),
      ],
    );
  }
}

class _TripCompositionSection extends StatelessWidget {
  final OperationTrip trip;

  const _TripCompositionSection({required this.trip});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('المسار', trip.route, Icons.alt_route_outlined),
      ('المركبة', trip.vehicle, Icons.directions_bus_outlined),
      ('السائق', trip.driver, Icons.badge_outlined),
      ('التوقيت', '${trip.date} • ${trip.departure}', Icons.schedule_outlined),
    ];

    return AppCard(
      child: Wrap(
        spacing: AppSpacing.medium,
        runSpacing: AppSpacing.medium,
        children: items.map((item) {
          return SizedBox(
            width: 190,
            child: Row(
              children: [
                Icon(item.$3),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xSmall),
                      Text(
                        item.$2,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SeatMapSection extends StatelessWidget {
  final OperationTrip trip;
  final void Function(TripSeat seat, TripSeatState state) onSeatStateChanged;

  const _SeatMapSection({required this.trip, required this.onSeatStateChanged});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'إدارة المقاعد',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TripStatusBadge(status: trip.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'اختر أي مقعد لتغيير حالته من خلال خدمة العملاء.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          _SeatLegend(trip: trip),
          const SizedBox(height: AppSpacing.large),
          _VehicleSeatMap(
            seats: trip.seats,
            onSeatStateChanged: onSeatStateChanged,
          ),
        ],
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  final OperationTrip trip;

  const _SeatLegend({required this.trip});

  @override
  Widget build(BuildContext context) {
    final items = [
      (TripSeatState.available, trip.availableSeats),
      (TripSeatState.reserved, trip.reservedSeats),
      (TripSeatState.confirmed, trip.occupiedSeats),
      (TripSeatState.blocked, trip.blockedSeats),
    ];

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: items.map((item) {
        return _SeatStateChip(state: item.$1, count: item.$2);
      }).toList(),
    );
  }
}

class _SeatStateChip extends StatelessWidget {
  final TripSeatState state;
  final int count;

  const _SeatStateChip({required this.state, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = _seatColors(context, state);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_seat_outlined, size: 16, color: colors.foreground),
            const SizedBox(width: AppSpacing.xSmall),
            Text(
              '${state.label}: $count',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: colors.foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleSeatMap extends StatelessWidget {
  final List<TripSeat> seats;
  final void Function(TripSeat seat, TripSeatState state) onSeatStateChanged;

  const _VehicleSeatMap({
    required this.seats,
    required this.onSeatStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rows = seats.map((seat) => seat.row).fold(0, (max, row) {
      return row > max ? row : max;
    });

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                    vertical: AppSpacing.small,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.airline_seat_recline_normal_outlined),
                      SizedBox(width: AppSpacing.xSmall),
                      Text('مقدمة المركبة'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            ...List.generate(rows + 1, (row) {
              final rowSeats = seats.where((seat) => seat.row == row).toList()
                ..sort(
                  (first, second) => first.column.compareTo(second.column),
                );
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.small),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: rowSeats.indexed.map((entry) {
                    final (index, seat) = entry;
                    return Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: index == 2 ? AppSpacing.large : AppSpacing.small,
                      ),
                      child: _SeatTile(
                        seat: seat,
                        onSeatStateChanged: onSeatStateChanged,
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  final TripSeat seat;
  final void Function(TripSeat seat, TripSeatState state) onSeatStateChanged;

  const _SeatTile({required this.seat, required this.onSeatStateChanged});

  @override
  Widget build(BuildContext context) {
    final colors = _seatColors(context, seat.state);

    return PopupMenuButton<TripSeatState>(
      tooltip: 'إدارة المقعد ${seat.label}',
      onSelected: (state) => onSeatStateChanged(seat, state),
      itemBuilder: (context) => TripSeatState.values
          .map((state) => PopupMenuItem(value: state, child: Text(state.label)))
          .toList(),
      child: SizedBox(
        width: 58,
        height: 64,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background,
            border: Border.all(color: colors.border, width: 1.5),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xSmall),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_seat_outlined,
                  size: 18,
                  color: colors.foreground,
                ),
                const SizedBox(height: 2),
                Text(
                  seat.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  seat.state.label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final List<TripEvent> events;

  const _TimelineSection({required this.events});

  @override
  Widget build(BuildContext context) {
    final requiredEvents = [
      'Created',
      'Assigned Driver',
      'Started',
      'Arrived',
      'Completed',
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          ...requiredEvents.map((title) {
            final event = events.firstWhere(
              (item) => item.title == title,
              orElse: () => TripEvent(
                title: title,
                time: 'غير محدد',
                description: 'لم يتم تسجيل الحدث بعد.',
                done: false,
              ),
            );
            return _TimelineRow(event: event);
          }),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TripEvent event;

  const _TimelineRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: event.done
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            child: Icon(
              event.done ? Icons.check : Icons.more_horiz,
              size: 15,
              color: event.done
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text('${event.time} • ${event.description}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassengersSection extends StatelessWidget {
  final List<TripPassenger> passengers;

  const _PassengersSection({required this.passengers});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Passengers', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          if (passengers.isEmpty)
            const Text('لا يوجد ركاب لهذه الرحلة.')
          else
            ...passengers.map(
              (passenger) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(passenger.name),
                subtitle: Text('${passenger.pickup} • مقعد ${passenger.seat}'),
                trailing: Text(passenger.status),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentsSection extends StatelessWidget {
  final List<TripPayment> payments;

  const _PaymentsSection({required this.payments});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payments', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          if (payments.isEmpty)
            const Text('لا توجد مدفوعات مرتبطة.')
          else
            ...payments.map(
              (payment) => ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text(payment.passengerName),
                subtitle: Text('${payment.method} • ${payment.status}'),
                trailing: Text(payment.amount),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventsSection extends StatelessWidget {
  final List<TripEvent> events;

  const _EventsSection({required this.events});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Events', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          ...events.map(
            (event) => ListTile(
              leading: const Icon(Icons.history_outlined),
              title: Text(event.title),
              subtitle: Text(event.description),
              trailing: Text(event.time),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  final List<String> notes;

  const _NotesSection({required this.notes});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          if (notes.isEmpty)
            const Text('لا توجد ملاحظات.')
          else
            ...notes.map(
              (note) => ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(note),
              ),
            ),
        ],
      ),
    );
  }
}

_SeatPalette _seatColors(BuildContext context, TripSeatState state) {
  final scheme = Theme.of(context).colorScheme;
  return switch (state) {
    TripSeatState.available => _SeatPalette(
      background: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
      border: scheme.primary,
    ),
    TripSeatState.reserved => _SeatPalette(
      background: scheme.tertiaryContainer,
      foreground: scheme.onTertiaryContainer,
      border: scheme.tertiary,
    ),
    TripSeatState.confirmed => _SeatPalette(
      background: scheme.secondaryContainer,
      foreground: scheme.onSecondaryContainer,
      border: scheme.secondary,
    ),
    TripSeatState.blocked => _SeatPalette(
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
      border: scheme.error,
    ),
  };
}

class _SeatPalette {
  final Color background;
  final Color foreground;
  final Color border;

  const _SeatPalette({
    required this.background,
    required this.foreground,
    required this.border,
  });
}
