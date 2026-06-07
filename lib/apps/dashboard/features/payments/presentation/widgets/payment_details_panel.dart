import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/finance_payment.dart';
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
              child: Center(
                child: Transform.scale(
                  scale: zoom,
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(AppSpacing.large),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.image_outlined, size: 46),
                        const SizedBox(height: AppSpacing.medium),
                        Text(
                          payment.receiptLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          payment.referenceNumber,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Divider(height: AppSpacing.large),
                        Text(
                          payment.receiptMeta,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
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
        ],
      ),
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
          Text('سجل الإجراءات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.medium),
          ...items.map(
            (item) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(radius: 7, backgroundColor: scheme.primary),
                    Container(
                      width: 2,
                      height: 54,
                      color: scheme.outlineVariant,
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Text(
                              item.time,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(item.description),
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
}
