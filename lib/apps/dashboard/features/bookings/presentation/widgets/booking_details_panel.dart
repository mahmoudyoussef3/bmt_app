import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import 'booking_next_action_banner.dart';
import 'booking_reassign_dialog.dart';
import 'booking_review_intents.dart' as intents;
import 'booking_status_chips.dart';

/// Right-hand (or bottom-sheet) inspector showing a booking's real customer,
/// trip, payment, receipt and lifecycle data joined from the database.
///
/// The review actions are docked to the bottom of the panel rather than sitting
/// in the scrolling body: they are why the panel is open, and on a short window
/// they used to scroll out of reach behind the customer and trip sections.
class BookingDetailsPanel extends StatelessWidget {
  const BookingDetailsPanel({
    super.key,
    required this.booking,
    required this.clientBookingsCount,
    this.isProcessing = false,
  });

  final OperationBooking booking;
  final int clientBookingsCount;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();
    final hasActions = booking.awaitingReview || booking.canBeReassigned;

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
                BookingNextActionBanner(booking: booking),
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
                      ? _ReceiptPreview(url: booking.receiptUrl!)
                      : const _NoReceiptNote(),
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
          if (hasActions) ...[
            const Divider(height: 1),
            _ActionBar(
              booking: booking,
              cubit: cubit,
              isProcessing: isProcessing,
            ),
          ],
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
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
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
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _PhoneLine(
                      bookingNumber: booking.bookingNumber,
                      phone: booking.phone,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                tooltip: 'إغلاق',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xSmall,
                  runSpacing: AppSpacing.xSmall,
                  children: [
                    BookingStateChip.booking(booking.status),
                    BookingStateChip.payment(booking.paymentStatus),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              // The fare is the number every review decision turns on, so it
              // sits in the header instead of three sections down.
              Text(
                booking.amountLabel,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Booking number + phone, with the phone copyable — support agents call the
/// client straight from this panel and were retyping the number by hand.
class _PhoneLine extends StatelessWidget {
  const _PhoneLine({required this.bookingNumber, required this.phone});

  final String bookingNumber;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Row(
      children: [
        Flexible(
          child: Text(
            [
              if (bookingNumber.isNotEmpty) bookingNumber,
              if (phone.isNotEmpty) phone,
            ].join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (phone.isNotEmpty)
          IconButton(
            tooltip: 'نسخ رقم الهاتف',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.copy_rounded, size: 14),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: phone));
              if (context.mounted) {
                AppSnackbar.success(context, 'تم نسخ رقم الهاتف');
              }
            },
          ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.booking,
    required this.cubit,
    required this.isProcessing,
  });

  final OperationBooking booking;
  final BookingsCubit cubit;
  final bool isProcessing;

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
    final scheme = Theme.of(context).colorScheme;
    final approved = paymentStatusStyle(PaymentStatus.approved);
    final rejected = paymentStatusStyle(PaymentStatus.rejected);
    final busy = isProcessing;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      color: scheme.surfaceContainerHighest.withAlpha(60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (busy) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: AppSpacing.small),
          ],
          if (booking.awaitingReview) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => intents.approveBooking(context, cubit, booking),
                    style: FilledButton.styleFrom(
                      backgroundColor: approved.onContainer,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('قبول الدفع'),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => intents.rejectBooking(context, cubit, booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: rejected.onContainer,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('رفض'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
          ],
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              if (booking.awaitingReview)
                TextButton.icon(
                  onPressed: busy
                      ? null
                      : () => intents.requestReupload(context, cubit, booking),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('طلب إعادة رفع'),
                ),
              if (booking.canBeReassigned)
                TextButton.icon(
                  onPressed: busy ? null : () => _reassign(context),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('نقل إلى رحلة أخرى'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The receipt is the evidence a payment review is decided on, so the panel
/// shows it inline instead of hiding it behind a button.
class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => _ReceiptDialog(url: url),
          ),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          child: Container(
            height: 150,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(90),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              border: Border.all(color: scheme.outline.withAlpha(90)),
            ),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  'تعذر تحميل صورة الإيصال',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _ReceiptDialog(url: url),
            ),
            icon: const Icon(Icons.zoom_in_rounded, size: 18),
            label: const Text('تكبير الإيصال'),
          ),
        ),
      ],
    );
  }
}

class _NoReceiptNote extends StatelessWidget {
  const _NoReceiptNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          Icons.image_not_supported_outlined,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            'لم يرفع العميل إيصالاً بعد.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
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
            Flexible(
              child: InteractiveViewer(
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

/// Lifecycle history drawn as a rail: dots and a connector make the order of
/// events readable, where the old flat list of bold lines did not.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});

  final List<BookingTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.xSmall),
              Text(
                'سجل العمليات',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          if (events.isEmpty)
            Text(
              'لا يوجد سجل لهذا الحجز.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          for (final (index, event) in events.indexed)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: index == events.length - 1
                              ? scheme.primary
                              : scheme.outline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (index != events.length - 1)
                        Expanded(
                          child: Container(width: 2, color: scheme.outline),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: index == events.length - 1
                            ? 0
                            : AppSpacing.medium,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.action,
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _formatTime(event.timestamp),
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          if (event.note != null)
                            Text(
                              event.note!,
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
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
