import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import 'booking_next_action_banner.dart';
import 'booking_reassign_dialog.dart';
import 'booking_review_intents.dart' as intents;

/// Right-hand (or bottom-sheet) inspector showing a booking's real customer,
/// trip, payment, receipt and lifecycle data joined from the database.
class BookingDetailsPanel extends StatelessWidget {
  const BookingDetailsPanel({
    super.key,
    required this.booking,
    required this.clientBookingsCount,
  });

  final OperationBooking booking;
  final int clientBookingsCount;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _Header(booking: booking, onClose: cubit.closePanel),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.medium),
              children: [
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    StatusChip(label: 'الحجز: ${booking.status.label}'),
                    StatusChip(
                      label: 'الدفع: ${booking.paymentStatus.label}',
                      color: AppStatusColors.onWarningContainer,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                BookingNextActionBanner(booking: booking),
                if (booking.awaitingReview) ...[
                  const SizedBox(height: AppSpacing.medium),
                  _ReviewButtons(booking: booking, cubit: cubit),
                ],
                if (booking.canBeReassigned) ...[
                  const SizedBox(height: AppSpacing.small),
                  _ReassignButton(booking: booking, cubit: cubit),
                ],
                const SizedBox(height: AppSpacing.medium),
                _Section(
                  title: 'بيانات العميل',
                  icon: Icons.person_rounded,
                  rows: [
                    ('الاسم', booking.passengerName),
                    ('الهاتف', booking.phone),
                    ('معرّف العميل', _shortId(booking.clientId)),
                    ('إجمالي حجوزاته', '$clientBookingsCount'),
                  ],
                ),
                _Section(
                  title: 'تفاصيل الرحلة',
                  icon: Icons.route_rounded,
                  rows: [
                    ('المسار', booking.tripDetails.route),
                    ('التاريخ', booking.tripDetails.date),
                    ('الوقت', booking.tripDetails.time),
                    ('المقعد', booking.seat),
                    ('المركبة', booking.tripDetails.vehicle),
                    ('السائق', booking.tripDetails.driver),
                  ],
                ),
                _Section(
                  title: 'بيانات الدفع',
                  icon: Icons.payments_rounded,
                  rows: [
                    ('المبلغ', booking.amountLabel),
                    ('الطريقة', booking.paymentMethod.label),
                    ('حالة الدفع', booking.paymentStatus.label),
                    if (booking.packageName.isNotEmpty)
                      ('الباقة', booking.packageName),
                  ],
                  trailing: booking.hasReceipt
                      ? _ReceiptButton(url: booking.receiptUrl!)
                      : null,
                ),
                if (booking.rejectionReason != null)
                  _Section(
                    title: 'سبب الرفض',
                    icon: Icons.warning_rounded,
                    rows: [('السبب', booking.rejectionReason!)],
                  ),
                if (booking.notes.isNotEmpty)
                  _ListSection(title: 'ملاحظات', items: booking.notes),
                _Timeline(events: booking.timeline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _shortId(String id) =>
      id.isEmpty ? '—' : id.substring(0, id.length < 8 ? id.length : 8);
}

class _Header extends StatelessWidget {
  const _Header({required this.booking, required this.onClose});

  final OperationBooking booking;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: scheme.primary.withAlpha(20),
            child: Icon(Icons.person_outline, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.passengerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${booking.bookingNumber} • ${booking.phone}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }
}

class _ReviewButtons extends StatelessWidget {
  const _ReviewButtons({required this.booking, required this.cubit});

  final OperationBooking booking;
  final BookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xSmall,
      runSpacing: AppSpacing.xSmall,
      children: [
        FilledButton.icon(
          onPressed: () => intents.approveBooking(context, cubit, booking),
          icon: const Icon(Icons.check_rounded),
          label: const Text('قبول الدفع'),
        ),
        OutlinedButton.icon(
          onPressed: () => intents.rejectBooking(context, cubit, booking),
          icon: const Icon(Icons.close_rounded),
          label: const Text('رفض'),
        ),
        OutlinedButton.icon(
          onPressed: () => intents.requestReupload(context, cubit, booking),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة رفع'),
        ),
      ],
    );
  }
}

/// Moves the passenger to another trip — the recovery path when a trip is
/// cancelled, delayed, or the customer asks to travel on a different date.
class _ReassignButton extends StatelessWidget {
  const _ReassignButton({required this.booking, required this.cubit});

  final OperationBooking booking;
  final BookingsCubit cubit;

  Future<void> _reassign(BuildContext context) async {
    final tripId = await BookingReassignDialog.show(
      context,
      passengerName: booking.passengerName,
      currentTrip: '${booking.tripDetails.route} · ${booking.tripDetails.date}',
      loadTargets: cubit.loadReassignmentTargets,
    );
    if (tripId == null) return;
    await cubit.reassignBooking(booking.id, tripId);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        onPressed: () => _reassign(context),
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text('نقل إلى رحلة أخرى'),
      ),
    );
  }
}

class _ReceiptButton extends StatelessWidget {
  const _ReceiptButton({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _ReceiptDialog(url: url),
        ),
        icon: const Icon(Icons.receipt_long_rounded, size: 18),
        label: const Text('عرض الإيصال'),
      ),
    );
  }
}

class _ReceiptDialog extends StatelessWidget {
  const _ReceiptDialog({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(AppSpacing.large),
                  child: Text('تعذر تحميل صورة الإيصال.'),
                ),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Padding(
                        padding: EdgeInsets.all(AppSpacing.large),
                        child: CircularProgressIndicator(),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.rows,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<(String, String)> rows;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpacing.xSmall),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            ...rows.map((row) => _DetailRow(label: row.$1, value: row.$2)),
            if (trailing != null) ...[
              const SizedBox(height: AppSpacing.small),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.small),
            ...items.map(
              (item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.circle_outlined, size: 14),
                title: Text(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});

  final List<BookingTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سجل العمليات',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.medium),
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.action,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _formatTime(event.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (event.note != null)
                    Text(
                      event.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(time.day)}/${two(time.month)} ${two(time.hour)}:${two(time.minute)}';
  }
}
