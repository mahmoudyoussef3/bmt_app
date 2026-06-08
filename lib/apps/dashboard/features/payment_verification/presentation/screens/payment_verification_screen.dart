import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/booking_payment_verification.dart';
import '../cubit/payment_verification_cubit.dart';
import '../cubit/payment_verification_state.dart';

class PaymentVerificationScreen extends StatelessWidget {
  const PaymentVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentVerificationCubit, PaymentVerificationState>(
      builder: (context, state) {
        return switch (state) {
          PaymentVerificationLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PaymentVerificationError(:final message) => Center(
            child: Text(message),
          ),
          PaymentVerificationLoaded() => _VerificationLoadedView(state: state),
        };
      },
    );
  }
}

class _VerificationLoadedView extends StatelessWidget {
  final PaymentVerificationLoaded state;

  const _VerificationLoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentVerificationCubit>();
    final selected = state.selectedItem;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1080;
        final queue = _VerificationQueue(state: state, onSelect: cubit.select);
        final review = selected == null
            ? const Center(child: Text('لا توجد إيصالات للمراجعة.'))
            : _ReviewScreen(
                item: selected,
                zoom: state.receiptZoom,
                onZoomChanged: cubit.setReceiptZoom,
                onApprove: (note) => cubit.approve(selected, note),
                onReject: (note) => cubit.reject(selected, note),
                onRequestReview: (note) => cubit.requestReview(selected, note),
                onAddNote: (note) => cubit.addNote(selected, note),
              );

        if (compact) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.large),
            children: [
              queue,
              const SizedBox(height: AppSpacing.large),
              review,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 430,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.large),
                children: [queue],
              ),
            ),
            Expanded(child: review),
          ],
        );
      },
    );
  }
}

class _VerificationQueue extends StatelessWidget {
  final PaymentVerificationLoaded state;
  final ValueChanged<String> onSelect;

  const _VerificationQueue({required this.state, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.fact_check_outlined, size: 38),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Text(
                      'Verification Queue',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'مراجعة إيصالات الحجز قبل تثبيت المقاعد نهائياً.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  _Metric(label: 'بانتظار', value: '${state.pendingCount}'),
                  _Metric(label: 'مراجعة', value: '${state.reviewCount}'),
                  _Metric(label: 'مقبولة', value: '${state.approvedCount}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        ...state.items.map(
          (item) => _QueueCard(
            item: item,
            selected: item.id == state.selectedId,
            onTap: () => onSelect(item.id),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final BookingPaymentVerification item;
  final bool selected;
  final VoidCallback onTap;

  const _QueueCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline.withAlpha(0),
              width: selected ? 2 : 0,
            ),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          child: Padding(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.customer.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    StatusChip(label: item.status.label),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                Text('${item.trip.route} • ${item.trip.time}'),
                const SizedBox(height: AppSpacing.xSmall),
                Text('مقعد ${item.selectedSeat} • ${item.amount}'),
                const SizedBox(height: AppSpacing.xSmall),
                Text(item.seatState.label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewScreen extends StatefulWidget {
  final BookingPaymentVerification item;
  final double zoom;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;
  final ValueChanged<String> onRequestReview;
  final ValueChanged<String> onAddNote;

  const _ReviewScreen({
    required this.item,
    required this.zoom,
    required this.onZoomChanged,
    required this.onApprove,
    required this.onReject,
    required this.onRequestReview,
    required this.onAddNote,
  });

  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> {
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _ReviewHeader(item: item),
        const SizedBox(height: AppSpacing.medium),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 980;
            final receipt = _ReceiptPreview(
              item: item,
              zoom: widget.zoom,
              onZoomChanged: widget.onZoomChanged,
            );
            final details = _ReviewDetails(
              item: item,
              notes: _notes,
              onApprove: () => _submit(widget.onApprove),
              onReject: () => _submit(widget.onReject),
              onRequestReview: () => _submit(widget.onRequestReview),
              onAddNote: () => _submit(widget.onAddNote),
            );

            if (compact) {
              return Column(
                children: [
                  receipt,
                  const SizedBox(height: AppSpacing.medium),
                  details,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: receipt),
                const SizedBox(width: AppSpacing.medium),
                Expanded(flex: 2, child: details),
              ],
            );
          },
        ),
      ],
    );
  }

  void _submit(ValueChanged<String> action) {
    action(_notes.text);
    _notes.clear();
  }
}

class _ReviewHeader extends StatelessWidget {
  final BookingPaymentVerification item;

  const _ReviewHeader({required this.item});

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
                  item.customer.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  '${item.amount} • ${item.method.label} • ${item.bookingId}',
                ),
              ],
            ),
          ),
          StatusChip(label: item.seatState.label),
        ],
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  final BookingPaymentVerification item;
  final double zoom;
  final ValueChanged<double> onZoomChanged;

  const _ReceiptPreview({
    required this.item,
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
                'Receipt Preview',
                style: Theme.of(context).textTheme.titleLarge,
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
          Slider(value: zoom, min: 0.8, max: 2.2, onChanged: onZoomChanged),
          const SizedBox(height: AppSpacing.medium),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: Container(
              height: 520,
              width: double.infinity,
              color: scheme.surfaceContainerHighest,
              child: Center(
                child: Transform.scale(
                  scale: zoom,
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(AppSpacing.large),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.shadow.withAlpha(35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.image_outlined, size: 52),
                        const SizedBox(height: AppSpacing.medium),
                        Text(
                          item.receiptTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(item.referenceNumber, textAlign: TextAlign.center),
                        const Divider(height: AppSpacing.large),
                        _ReceiptLine(label: 'المبلغ', value: item.amount),
                        _ReceiptLine(
                          label: 'الطريقة',
                          value: item.method.label,
                        ),
                        _ReceiptLine(label: 'الحجز', value: item.bookingId),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          item.receiptMeta,
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

class _ReceiptLine extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _ReviewDetails extends StatelessWidget {
  final BookingPaymentVerification item;
  final TextEditingController notes;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRequestReview;
  final VoidCallback onAddNote;

  const _ReviewDetails({
    required this.item,
    required this.notes,
    required this.onApprove,
    required this.onReject,
    required this.onRequestReview,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking & Seat', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          _InfoRow(label: 'العميل', value: item.customer.name),
          _InfoRow(label: 'الهاتف', value: item.customer.phone),
          _InfoRow(label: 'الحساب', value: item.customer.profileStatus),
          _InfoRow(label: 'الرحلة', value: item.trip.tripId),
          _InfoRow(label: 'المسار', value: item.trip.route),
          _InfoRow(
            label: 'الموعد',
            value: '${item.trip.date} • ${item.trip.time}',
          ),
          _InfoRow(label: 'المركبة', value: item.trip.vehicle),
          _InfoRow(label: 'السائق', value: item.trip.driver),
          _InfoRow(label: 'المقعد', value: item.selectedSeat),
          _InfoRow(label: 'حالة المقعد', value: item.seatState.label),
          const SizedBox(height: AppSpacing.medium),
          TextField(
            controller: notes,
            minLines: 3,
            maxLines: 4,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'Verification notes',
              hintText: 'اكتب سبب القرار أو ملاحظة للمتابعة',
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              AppButton(label: 'Approve', height: 42, onPressed: onApprove),
              AppButton(
                label: 'Reject',
                height: 42,
                outline: true,
                onPressed: onReject,
              ),
              AppButton(
                label: 'Request review',
                height: 42,
                outline: true,
                onPressed: onRequestReview,
              ),
              AppButton(
                label: 'Add note',
                height: 42,
                outline: true,
                onPressed: onAddNote,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Text('Notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.small),
          if (item.notes.isEmpty)
            const Text('لا توجد ملاحظات.')
          else
            ...item.notes.map((note) => _NoteRow(note: note)),
          const SizedBox(height: AppSpacing.medium),
          Text('Workflow', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.small),
          ...item.history.map((history) => _HistoryRow(item: history)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final String note;

  const _NoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_outlined, size: 18),
          const SizedBox(width: AppSpacing.small),
          Expanded(child: Text(note)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final VerificationHistoryItem item;

  const _HistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 7, backgroundColor: scheme.primary),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xSmall),
                Text('${item.time} • ${item.description}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
