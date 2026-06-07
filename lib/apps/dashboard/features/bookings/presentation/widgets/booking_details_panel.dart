import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/operation_booking.dart';

class BookingDetailsPanel extends StatelessWidget {
  final OperationBooking booking;
  final VoidCallback onClose;
  final void Function(BookingStatus status) onStatus;

  const BookingDetailsPanel({
    required this.booking,
    required this.onClose,
    required this.onStatus,
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
              const CircleAvatar(radius: 28, child: Icon(Icons.person_outline)),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.passengerName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(booking.phone),
                    const SizedBox(height: AppSpacing.small),
                    StatusChip(label: booking.status.label),
                  ],
                ),
              ),
              PopupMenuButton<BookingStatus>(
                tooltip: 'تحديث الحالة',
                onSelected: onStatus,
                itemBuilder: (context) => BookingStatus.values
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
        ),
        const SizedBox(height: AppSpacing.medium),
        _Section(
          title: 'Customer Profile',
          rows: [
            ('الاسم', booking.customerProfile.name),
            ('الهاتف', booking.customerProfile.phone),
            ('البريد', booking.customerProfile.email),
            ('عدد الرحلات', booking.customerProfile.tripsCount),
            ('حالة الحساب', booking.customerProfile.accountStatus),
          ],
        ),
        _Section(
          title: 'Trip Details',
          rows: [
            ('المسار', booking.tripDetails.route),
            ('التاريخ', booking.tripDetails.date),
            ('الوقت', booking.tripDetails.time),
            ('المركبة', booking.tripDetails.vehicle),
            ('السائق', booking.tripDetails.driver),
            ('الرحلة المسندة', booking.assignedTrip),
          ],
        ),
        _Section(
          title: 'Payment Details',
          rows: [
            ('المبلغ', booking.paymentDetails.amount),
            ('الطريقة', booking.paymentDetails.method.label),
            ('الحالة', booking.paymentDetails.status),
            ('المرجع', booking.paymentDetails.reference),
          ],
        ),
        _ListSection(title: 'Attachments', items: booking.attachments),
        _ListSection(title: 'Notes', items: booking.notes),
        _ListSection(title: 'History', items: booking.history),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;

  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.medium),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
                child: Row(
                  children: [
                    SizedBox(width: 110, child: Text(row.$1)),
                    Expanded(child: Text(row.$2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ListSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.medium),
            if (items.isEmpty)
              const Text('لا توجد عناصر.')
            else
              ...items.map(
                (item) => ListTile(
                  leading: const Icon(Icons.circle_outlined, size: 16),
                  title: Text(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
