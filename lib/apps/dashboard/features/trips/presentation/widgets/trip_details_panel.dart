import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_trip.dart';
import 'trip_status_badge.dart';

class TripDetailsPanel extends StatelessWidget {
  final OperationTrip trip;
  final VoidCallback onClose;
  final void Function(OperationTripStatus status) onStatusChanged;

  const TripDetailsPanel({
    required this.trip,
    required this.onClose,
    required this.onStatusChanged,
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
