import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import '../cubit/wallet_cubit.dart';
import 'wallet_format.dart';

/// Files a refund against ONE named booking.
///
/// The booking picker is not a convenience — it is the control. A refund with no
/// booking behind it has no cumulative cap to check against, no payment to
/// reconcile with, and no answer to "which journey was this?". That is why §8.1
/// rejects a standalone adjustments page and why this dialog refuses to open on
/// a customer with no refundable booking.
///
/// What the operator sees, and only what the server would accept: each booking
/// carries the remaining refundable amount computed by `refund_capacity`, so the
/// maximum offered here is the maximum that exists.
class WalletRefundDialog extends StatefulWidget {
  const WalletRefundDialog({
    super.key,
    required this.cubit,
    required this.customer,
    required this.canSettleImmediately,
  });

  final WalletCubit cubit;
  final WalletCustomer customer;

  /// True for the owner, whose refund is born approved and settles in the same
  /// call; false for a support agent, whose refund is born pending (§9).
  final bool canSettleImmediately;

  @override
  State<WalletRefundDialog> createState() => _WalletRefundDialogState();
}

class _WalletRefundDialogState extends State<WalletRefundDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final String _requestKey = const Uuid().v4();

  late Future<List<RefundableBooking>> _bookingsFuture;
  RefundableBooking? _booking;
  String _category = WalletCategories.refund.first.code;
  RefundSettlement _settlement = RefundSettlement.wallet;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    _bookingsFuture = widget.cubit
        .refundableBookings(widget.customer.id)
        .then((bookings) {
          if (mounted && bookings.isNotEmpty) {
            setState(() {
              _booking = bookings.first;
              _amountController.text = bookings.first.refundableAmount
                  .toStringAsFixed(2);
            });
          }
          return bookings;
        });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.assignment_return_rounded),
      title: Text('استرداد — ${widget.customer.displayName}'),
      content: SizedBox(
        width: 520,
        child: FutureBuilder<List<RefundableBooking>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _ErrorLine(
                message: snapshot.error.toString().replaceAll('Exception: ', ''),
              );
            }
            final bookings = snapshot.data ?? const <RefundableBooking>[];
            if (bookings.isEmpty || _booking == null) {
              return const _EmptyBookings();
            }
            return SingleChildScrollView(child: _buildForm(context, bookings));
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _submitting || _booking == null ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(
            widget.canSettleImmediately ? 'تنفيذ الاسترداد' : 'إرسال الطلب',
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, List<RefundableBooking> bookings) {
    final text = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _booking!.bookingId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'الحجز',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
            items: [
              for (final booking in bookings)
                DropdownMenuItem(
                  value: booking.bookingId,
                  child: Text(
                    '${booking.label} · ${booking.route ?? 'بدون مسار'} · '
                    'متاح ${WalletFormat.money(booking.refundableAmount)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              final next = bookings.firstWhere((b) => b.bookingId == value);
              setState(() {
                _booking = next;
                _amountController.text = next.refundableAmount.toStringAsFixed(2);
              });
            },
          ),
          const SizedBox(height: AppSpacing.medium),
          _BookingSummary(booking: _booking!),
          const SizedBox(height: AppSpacing.medium),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: 'المبلغ (ج.م)',
              helperText:
                  'المتبقي القابل للرد ${WalletFormat.money(_booking!.refundableAmount)} — '
                  'يمكن الرد جزئيًا أكثر من مرة',
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
            validator: (value) {
              final amount = double.tryParse((value ?? '').trim());
              if (amount == null || amount <= 0) return 'أدخل مبلغًا أكبر من صفر';
              if (amount > _booking!.refundableAmount) {
                return 'المبلغ أكبر من المتبقي على هذا الحجز';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.medium),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'سبب الاسترداد',
              prefixIcon: Icon(Icons.sell_outlined),
            ),
            items: [
              for (final category in WalletCategories.refund)
                DropdownMenuItem(
                  value: category.code,
                  child: Text(category.label),
                ),
            ],
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: AppSpacing.medium),
          DropdownButtonFormField<RefundSettlement>(
            initialValue: _settlement,
            decoration: const InputDecoration(
              labelText: 'طريقة التسوية',
              helperText:
                  'الرد إلى المحفظة هو الوحيد الذي يسجّل حركة في سجل المحفظة',
              prefixIcon: Icon(Icons.account_balance_rounded),
            ),
            items: [
              for (final method in RefundSettlement.values)
                DropdownMenuItem(value: method, child: Text(method.label)),
            ],
            onChanged: (value) =>
                setState(() => _settlement = value ?? _settlement),
          ),
          const SizedBox(height: AppSpacing.medium),
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'ملاحظة السبب (إلزامي)',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
            maxLength: 160,
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'السبب مطلوب' : null,
          ),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'تفاصيل إضافية (اختياري)',
              prefixIcon: Icon(Icons.sticky_note_2_outlined),
            ),
            maxLines: 2,
          ),
          if (!widget.canSettleImmediately) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              'سيُرسل الطلب إلى المالك للاعتماد، وسيظهر في قائمة طلبات الاسترداد.',
              style: text.labelSmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.medium),
            _ErrorLine(message: _error!),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final failure = await widget.cubit.createRefund(
      booking: _booking!,
      amount: double.parse(_amountController.text.trim()),
      category: _category,
      reason: _reasonController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      settlement: _settlement,
      requestKey: _requestKey,
    );

    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = failure;
    });
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({required this.booking});

  final RefundableBooking booking;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.route ?? 'حجز بدون مسار',
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: 4,
            children: [
              if (booking.tripDate != null)
                Text(
                  'تاريخ الرحلة ${WalletFormat.date(booking.tripDate!)}',
                  style: text.labelSmall,
                ),
              if (booking.seat != null)
                Text('المقعد ${booking.seat}', style: text.labelSmall),
              Text(
                'المدفوع ${WalletFormat.money(booking.paidAmount)}',
                style: text.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: DashboardColors.faintInk(context),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'لا توجد حجوزات قابلة للرد لهذا العميل',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'كل حجوزات هذا العميل إمّا غير مدفوعة أو تم ردّها بالكامل.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withAlpha(120),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
