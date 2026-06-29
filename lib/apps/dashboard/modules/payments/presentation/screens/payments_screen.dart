import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../cubit/payments_cubit.dart';
import '../cubit/payments_state.dart';
import '../widgets/payment_card.dart';
import '../widgets/payment_details_panel.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentsCubit, PaymentsState>(
      builder: (context, state) {
        return switch (state) {
          PaymentsLoading() => const Center(child: CircularProgressIndicator()),
          PaymentsError(:final message) => Center(child: Text(message)),
          PaymentsLoaded() => _PaymentsLoadedView(state: state),
        };
      },
    );
  }
}

class _PaymentsLoadedView extends StatelessWidget {
  final PaymentsLoaded state;

  const _PaymentsLoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedPayment;
    final cubit = context.read<PaymentsCubit>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        if (compact) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.large),
            children: [
              _Header(
                total: state.payments.length,
                pending: state.pendingCount,
                needsReview: state.needsReviewCount,
              ),
              const SizedBox(height: AppSpacing.medium),
              _PaymentsInbox(state: state, onSelect: cubit.selectPayment),
              if (selected != null) ...[
                const SizedBox(height: AppSpacing.medium),
                PaymentDetailsPanel(
                  payment: selected,
                  receiptZoom: state.receiptZoom,
                  onZoomChanged: cubit.setReceiptZoom,
                  onStatus: (status) => cubit.updateStatus(selected, status),
                  onAddNote: (note) => cubit.addNote(selected, note),
                ),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 420,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.large),
                children: [
                  _Header(
                    total: state.payments.length,
                    pending: state.pendingCount,
                    needsReview: state.needsReviewCount,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _PaymentsInbox(state: state, onSelect: cubit.selectPayment),
                ],
              ),
            ),
            Expanded(
              child: selected == null
                  ? const Center(child: Text('لا توجد مدفوعات للمراجعة.'))
                  : PaymentDetailsPanel(
                      payment: selected,
                      receiptZoom: state.receiptZoom,
                      onZoomChanged: cubit.setReceiptZoom,
                      onStatus: (status) =>
                          cubit.updateStatus(selected, status),
                      onAddNote: (note) => cubit.addNote(selected, note),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int total;
  final int pending;
  final int needsReview;

  const _Header({
    required this.total,
    required this.pending,
    required this.needsReview,
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
              const Icon(Icons.account_balance_outlined, size: 38),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Text(
                  'مراجعة المدفوعات',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'صندوق مراجعة مالي لفحص الإيصالات وتأكيد العمليات قبل تفعيل الخدمة.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              _Metric(label: 'كل العمليات', value: '$total'),
              _Metric(label: 'بانتظار المراجعة', value: '$pending'),
              _Metric(label: 'محتاج مراجعة', value: '$needsReview'),
            ],
          ),
        ],
      ),
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
    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xSmall,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PaymentsInbox extends StatelessWidget {
  final PaymentsLoaded state;
  final void Function(String paymentId) onSelect;

  const _PaymentsInbox({required this.state, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('صندوق العمليات', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.small),
        ...state.payments.map(
          (payment) => PaymentCard(
            payment: payment,
            selected: payment.id == state.selectedPaymentId,
            onTap: () => onSelect(payment.id),
          ),
        ),
      ],
    );
  }
}
