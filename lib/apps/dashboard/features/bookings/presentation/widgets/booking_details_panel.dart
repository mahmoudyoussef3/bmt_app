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
                    Row(
                      children: [
                        StatusChip(label: booking.status.label),
                        const SizedBox(width: AppSpacing.small),
                        StatusChip(
                          label: booking.priority.label,
                          color: _priorityColor(
                            booking.priority,
                            Theme.of(context).colorScheme,
                          ),
                        ),
                      ],
                    ),
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
          title: 'بيانات العميل',
          rows: [
            ('الاسم', booking.customerProfile.name),
            ('الهاتف', booking.customerProfile.phone),
            ('البريد', booking.customerProfile.email),
            ('عدد الرحلات', booking.customerProfile.tripsCount),
            ('حالة الحساب', booking.customerProfile.accountStatus),
          ],
        ),
        _Section(
          title: 'تفاصيل الرحلة',
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
          title: 'بيانات الدفع',
          rows: [
            ('المبلغ', booking.paymentDetails.amount),
            ('الطريقة', booking.paymentDetails.method.label),
            ('الحالة', booking.paymentDetails.status),
            ('المرجع', booking.paymentDetails.reference),
            if (booking.paymentDetails.receiptReference != null)
              ('رقم الإيصال', booking.paymentDetails.receiptReference!),
          ],
        ),
        if (booking.rejectionReason != null)
          _Section(
            title: 'سبب الرفض',
            rows: [('السبب', booking.rejectionReason!)],
          ),
        if (booking.reviewerName != null)
          _Section(
            title: 'المراجع',
            rows: [('اسم المراجع', booking.reviewerName!)],
          ),
        _ListSection(title: 'المرفقات', items: booking.attachments),
        _ListSection(title: 'ملاحظات', items: booking.notes),
        _TimelineSection(events: booking.timeline),
      ],
    );
  }

  Color _priorityColor(BookingPriority priority, ColorScheme scheme) {
    return switch (priority) {
      BookingPriority.normal => scheme.primary.withAlpha(24),
      BookingPriority.urgent => Colors.orange.withAlpha(30),
      BookingPriority.vip => Colors.amber.withAlpha(30),
    };
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

class _TimelineSection extends StatelessWidget {
  final List<BookingTimelineEvent> events;

  const _TimelineSection({required this.events});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سجل العمليات',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.medium),
            if (events.isEmpty)
              const Text('لا يوجد سجل.')
            else
              ...events.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.small),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primary,
                            ),
                          ),
                          if (event != events.last)
                            Container(
                              width: 2,
                              height: 32,
                              color: scheme.outline.withAlpha(60),
                            ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.action,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${event.actor} • ${_formatTime(event.timestamp)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            if (event.note != null)
                              Text(
                                event.note!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: scheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
