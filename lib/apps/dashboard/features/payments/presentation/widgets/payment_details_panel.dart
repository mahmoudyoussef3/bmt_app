import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/finance_payment.dart';
import '../cubit/payments_cubit.dart';
import '../cubit/payments_state.dart';
import 'payment_note_dialog.dart';

class PaymentDetailsPanel extends StatelessWidget {
  final FinancePayment payment;
  final double receiptZoom;
  final ValueChanged<double> onZoomChanged;
  final void Function(PaymentReviewStatus status) onStatus;
  final void Function(String note) onAddNote;

  const PaymentDetailsPanel({
    required this.payment,
    required this.receiptZoom,
    required this.onZoomChanged,
    required this.onStatus,
    required this.onAddNote,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _Header(payment: payment),
        const SizedBox(height: AppSpacing.medium),
        _ReceiptPreview(
          payment: payment,
          zoom: receiptZoom,
          onZoomChanged: onZoomChanged,
        ),
        const SizedBox(height: AppSpacing.medium),
        _ActionBar(payment: payment, onStatus: onStatus, onAddNote: onAddNote),
        const SizedBox(height: AppSpacing.medium),
        _Information(payment: payment),
        const SizedBox(height: AppSpacing.medium),
        _Notes(notes: payment.notes),
        const SizedBox(height: AppSpacing.medium),
        _HistoryTimeline(items: payment.history),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final FinancePayment payment;

  const _Header({required this.payment});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            child: const Icon(Icons.receipt_long_outlined),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.userName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  '${payment.amount} · ${payment.method.label} · ${payment.paidAt}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(label: payment.status.label),
        ],
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  final FinancePayment payment;
  final double zoom;
  final ValueChanged<double> onZoomChanged;

  const _ReceiptPreview({
    required this.payment,
    required this.zoom,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'معاينة الإيصال',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'تصغير',
                onPressed: () => onZoomChanged(zoom - 0.1),
                icon: const Icon(Icons.zoom_out),
              ),
              Text('${(zoom * 100).round()}%'),
              IconButton(
                tooltip: 'تكبير',
                onPressed: () => onZoomChanged(zoom + 0.1),
                icon: const Icon(Icons.zoom_in),
              ),
            ],
          ),
          Slider(value: zoom, min: 0.8, max: 1.8, onChanged: onZoomChanged),
          const SizedBox(height: AppSpacing.small),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 330,
              width: double.infinity,
              color: scheme.surfaceContainerHighest,
              child: payment.receiptUrl != null &&
                      payment.receiptUrl!.isNotEmpty
                  ? InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Transform.scale(
                        scale: zoom,
                        child: Image.network(
                          payment.receiptUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (_, e, s) => Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 46,
                                  color: scheme.error,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'تعذر تحميل الإيصال',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: scheme.error),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 46,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            payment.receiptLabel,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            'لم يتم رفع إيصال بعد',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final FinancePayment payment;
  final void Function(PaymentReviewStatus status) onStatus;
  final void Function(String note) onAddNote;

  const _ActionBar({
    required this.payment,
    required this.onStatus,
    required this.onAddNote,
  });

  void _showReassignDialog(BuildContext context) {
    final cubit = context.read<PaymentsCubit>();
    cubit.loadAvailableTrips();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: _ReassignDialog(bookingId: payment.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        children: [
          AppButton(
            label: 'قبول',
            height: 42,
            onPressed: () => onStatus(PaymentReviewStatus.accepted),
          ),
          AppButton(
            label: 'رفض',
            height: 42,
            outline: true,
            onPressed: () => onStatus(PaymentReviewStatus.rejected),
          ),
          AppButton(
            label: 'طلب مراجعة',
            height: 42,
            outline: true,
            onPressed: () => onStatus(PaymentReviewStatus.needsReview),
          ),
          AppButton(
            label: 'إضافة ملاحظة',
            height: 42,
            outline: true,
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => PaymentNoteDialog(onSubmit: onAddNote),
              );
            },
          ),
          AppButton(
            label: 'تحويل الحجز',
            height: 42,
            outline: true,
            onPressed: () => _showReassignDialog(context),
          ),
        ],
      ),
    );
  }
}

class _ReassignDialog extends StatefulWidget {
  const _ReassignDialog({required this.bookingId});
  final String bookingId;

  @override
  State<_ReassignDialog> createState() => _ReassignDialogState();
}

class _ReassignDialogState extends State<_ReassignDialog> {
  String? _selectedTripId;

  String _tripLabel(Map<String, dynamic> t) {
    final route = (t['operation_routes'] as Map<String, dynamic>?)?['name'] ?? '';
    final date = t['trip_date'] as String? ?? '';
    final time = t['departure_time'] as String? ?? '';
    return '$route · $date · $time';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentsCubit, PaymentsState>(
      builder: (context, state) {
        final trips = state is PaymentsLoaded ? state.availableTrips : <Map<String, dynamic>>[];
        final error = state is PaymentsLoaded ? state.reassignError : null;

        return AlertDialog(
          title: const Text('تحويل الحجز إلى رحلة أخرى'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trips.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedTripId),
                    decoration: const InputDecoration(
                      labelText: 'اختر الرحلة الجديدة',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedTripId,
                    items: trips.map((t) {
                      final id = t['id'] as String;
                      return DropdownMenuItem(value: id, child: Text(_tripLabel(t), style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedTripId = v),
                  ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
            FilledButton(
              onPressed: _selectedTripId == null ? null : () async {
                final success = await context.read<PaymentsCubit>().reassignBooking(widget.bookingId, _selectedTripId!);
                if (success && context.mounted) Navigator.of(context).pop();
              },
              child: const Text('تحويل'),
            ),
          ],
        );
      },
    );
  }
}

class _Information extends StatelessWidget {
  final FinancePayment payment;

  const _Information({required this.payment});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات الدفعة',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.medium),
          _InfoRow(label: 'المستخدم', value: payment.user),
          _InfoRow(label: 'الرحلة', value: payment.trip),
          _InfoRow(label: 'الباقة', value: payment.packageName),
          _InfoRow(label: 'المبلغ', value: payment.amount),
          _InfoRow(label: 'رقم المرجع', value: payment.referenceNumber),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Notes extends StatelessWidget {
  final List<String> notes;

  const _Notes({required this.notes});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الملاحظات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.medium),
          if (notes.isEmpty)
            const Text('لا توجد ملاحظات.')
          else
            ...notes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.small),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sticky_note_2_outlined, size: 18),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(child: Text(note)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  final List<PaymentHistoryItem> items;

  const _HistoryTimeline({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 18),
              const SizedBox(width: 6),
              Text('سجل الإجراءات', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${items.length} إجراء', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          if (items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 36, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text('لا توجد إجراءات مسجلة', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              final item = entry.value;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(radius: 7, backgroundColor: scheme.primary),
                      if (!isLast)
                        Container(width: 2, height: 54, color: scheme.outlineVariant),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(item.title, style: Theme.of(context).textTheme.titleSmall)),
                              Text(item.time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                            ],
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xSmall),
                            Text(item.description, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}
