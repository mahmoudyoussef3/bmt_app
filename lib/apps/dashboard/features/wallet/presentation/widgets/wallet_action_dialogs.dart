import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import '../cubit/wallet_cubit.dart';
import 'wallet_format.dart';

/// The module's shorter write surfaces: reversal, freeze/unfreeze, a refund
/// decision, and the cancelled-trip batch.
///
/// Each is a small form with one shared shape — a reason that cannot be blank, a
/// request key generated once on open, and a submit that stays open on refusal
/// so the operator can read why. The reason is mandatory everywhere for the same
/// reason it is mandatory on the ledger: these rows are read months later by
/// someone who was not in the room.

class WalletReverseDialog extends StatefulWidget {
  const WalletReverseDialog({
    super.key,
    required this.cubit,
    required this.entry,
  });

  final WalletCubit cubit;
  final WalletTransaction entry;

  @override
  State<WalletReverseDialog> createState() => _WalletReverseDialogState();
}

class _WalletReverseDialogState extends State<WalletReverseDialog> {
  final _reasonController = TextEditingController();
  final String _requestKey = const Uuid().v4();
  String _category = WalletCategories.reversal.first.code;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return AlertDialog(
      icon: const Icon(Icons.undo_rounded),
      title: const Text('عكس عملية'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Callout(
                
                message:
                    'سيتم تسجيل حركة معاكسة بقيمة ${WalletFormat.signed(-entry.amount)} '
                    'وتُعلَّم العملية الأصلية كمعكوسة. لا يُحذف أي سجل.',
              ),
              const SizedBox(height: AppSpacing.medium),
              _KeyValue(label: 'العملية', value: '#${entry.seq} — ${entry.kind.label}'),
              _KeyValue(label: 'القيمة', value: WalletFormat.signed(entry.amount)),
              _KeyValue(label: 'السبب الأصلي', value: entry.reason),
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'سبب العكس',
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
                items: [
                  for (final category in WalletCategories.reversal)
                    DropdownMenuItem(
                      value: category.code,
                      child: Text(category.label),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _category = value ?? _category),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل السبب (إلزامي)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLength: 160,
              ),
              if (_error != null) _ErrorLine(message: _error!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: const Text('تنفيذ العكس'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      setState(() => _error = 'سبب العكس مطلوب.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final failure = await widget.cubit.reverseEntry(
      transaction: widget.entry,
      reason: _reasonController.text.trim(),
      category: _category,
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

class WalletFreezeDialog extends StatefulWidget {
  const WalletFreezeDialog({
    super.key,
    required this.cubit,
    required this.customer,
    required this.wallet,
  });

  final WalletCubit cubit;
  final WalletCustomer customer;
  final Wallet wallet;

  @override
  State<WalletFreezeDialog> createState() => _WalletFreezeDialogState();
}

class _WalletFreezeDialogState extends State<WalletFreezeDialog> {
  final _reasonController = TextEditingController();
  bool _submitting = false;
  String? _error;

  bool get _freezing => !widget.wallet.isFrozen;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(_freezing ? Icons.ac_unit_rounded : Icons.lock_open_rounded),
      title: Text(_freezing ? 'تجميد المحفظة' : 'إلغاء تجميد المحفظة'),
      content: SizedBox(
        width: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Callout(
              message: _freezing
                  
                  ? 'التجميد يمنع الخصم من محفظة ${widget.customer.displayName} فقط. '
                        'الإضافات والمرتجعات تظل ممكنة — يجب أن تبقى قادرًا على رد أموال العميل.'
                  : 'سيعود الخصم من محفظة ${widget.customer.displayName} متاحًا.',
            ),
            if (widget.wallet.isFrozen &&
                widget.wallet.frozenReason != null) ...[
              const SizedBox(height: AppSpacing.medium),
              _KeyValue(
                label: 'سبب التجميد',
                value: widget.wallet.frozenReason!,
              ),
            ],
            const SizedBox(height: AppSpacing.medium),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'السبب (إلزامي)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLength: 160,
            ),
            if (_error != null) _ErrorLine(message: _error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_freezing ? 'تجميد' : 'إلغاء التجميد'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      setState(() => _error = 'السبب مطلوب.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final failure = await widget.cubit.setWalletStatus(
      clientId: widget.customer.id,
      status: _freezing ? WalletStatus.frozen : WalletStatus.active,
      reason: _reasonController.text.trim(),
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

/// Approve (with an editable amount and a destination) or reject (with a
/// reason). The approval path is where the agent → owner pipeline closes.
class RefundDecisionDialog extends StatefulWidget {
  const RefundDecisionDialog({
    super.key,
    required this.cubit,
    required this.refund,
    required this.approve,
  });

  final WalletCubit cubit;
  final RefundRequest refund;
  final bool approve;

  @override
  State<RefundDecisionDialog> createState() => _RefundDecisionDialogState();
}

class _RefundDecisionDialogState extends State<RefundDecisionDialog> {
  late final TextEditingController _amountController = TextEditingController(
    text: widget.refund.amount.toStringAsFixed(2),
  );
  final _reasonController = TextEditingController();
  final String _requestKey = const Uuid().v4();
  RefundSettlement _settlement = RefundSettlement.wallet;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    if (widget.refund.clientId == null) _settlement = RefundSettlement.cash;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refund = widget.refund;
    final methods = refund.clientId == null
        ? RefundSettlement.values
              .where((m) => m != RefundSettlement.wallet)
              .toList()
        : RefundSettlement.values;

    return AlertDialog(
      icon: Icon(
        widget.approve ? Icons.check_circle_outline_rounded : Icons.block_rounded,
      ),
      title: Text(widget.approve ? 'اعتماد الاسترداد' : 'رفض طلب الاسترداد'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _KeyValue(
                label: 'العميل',
                value: refund.clientName ?? 'حجز بدون حساب عميل',
              ),
              if (refund.bookingNumber != null)
                _KeyValue(label: 'الحجز', value: '#${refund.bookingNumber}'),
              _KeyValue(
                label: 'المطلوب',
                value: WalletFormat.money(refund.amount),
              ),
              _KeyValue(label: 'السبب', value: refund.reason),
              if (refund.requestedByName != null)
                _KeyValue(label: 'مقدّم الطلب', value: refund.requestedByName!),
              const SizedBox(height: AppSpacing.medium),
              if (widget.approve) ...[
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المعتمد (ج.م)',
                    helperText: 'يمكن اعتماد مبلغ أقل من المطلوب',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                DropdownButtonFormField<RefundSettlement>(
                  initialValue: _settlement,
                  decoration: const InputDecoration(
                    labelText: 'طريقة التسوية',
                    prefixIcon: Icon(Icons.account_balance_rounded),
                  ),
                  items: [
                    for (final method in methods)
                      DropdownMenuItem(value: method, child: Text(method.label)),
                  ],
                  onChanged: (value) =>
                      setState(() => _settlement = value ?? _settlement),
                ),
              ] else
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'سبب الرفض (إلزامي)',
                    helperText: 'يُرسل للعميل مع إشعار الرفض',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLength: 160,
                ),
              if (_error != null) _ErrorLine(message: _error!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(widget.approve ? 'اعتماد وتنفيذ' : 'رفض'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final failure = await widget.cubit.decideRefund(
      refund: widget.refund,
      approve: widget.approve,
      approvedAmount: widget.approve
          ? double.tryParse(_amountController.text.trim())
          : null,
      settlement: _settlement,
      reason: widget.approve ? null : _reasonController.text.trim(),
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

/// Refunding a 14-seat cancelled bus one customer at a time is not a product.
/// This picks a cancelled trip that still owes money and refunds every seat on
/// it in one transaction, under one batch key.
class TripBatchRefundDialog extends StatefulWidget {
  const TripBatchRefundDialog({super.key, required this.cubit});

  final WalletCubit cubit;

  @override
  State<TripBatchRefundDialog> createState() => _TripBatchRefundDialogState();
}

class _TripBatchRefundDialogState extends State<TripBatchRefundDialog> {
  late Future<List<CancelledTripRefundTarget>> _tripsFuture;
  final _reasonController = TextEditingController(text: 'إلغاء الرحلة');
  final String _requestKey = const Uuid().v4();
  CancelledTripRefundTarget? _trip;
  RefundSettlement _settlement = RefundSettlement.wallet;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    _tripsFuture = widget.cubit.cancelledTrips().then((trips) {
      if (mounted && trips.isNotEmpty) {
        setState(() => _trip = trips.first);
      }
      return trips;
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.event_busy_rounded),
      title: const Text('استرداد جماعي لرحلة ملغاة'),
      content: SizedBox(
        width: 520,
        child: FutureBuilder<List<CancelledTripRefundTarget>>(
          future: _tripsFuture,
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
            final trips = snapshot.data ?? const <CancelledTripRefundTarget>[];
            if (trips.isEmpty || _trip == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
                child: Text(
                  'لا توجد رحلات ملغاة عليها مبالغ مستحقة الرد.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            _trip ??= trips.first;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _trip!.tripId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'الرحلة',
                      prefixIcon: Icon(Icons.departure_board_outlined),
                    ),
                    items: [
                      for (final trip in trips)
                        DropdownMenuItem(
                          value: trip.tripId,
                          child: Text(
                            '${trip.routeName ?? 'بدون مسار'} · '
                            '${trip.tripDate == null ? '' : WalletFormat.date(trip.tripDate!)} · '
                            '${trip.pendingBookings} حجز',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(
                      () => _trip = trips.firstWhere((t) => t.tripId == value),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _Callout(
                    message:
                        'سيتم رد ${WalletFormat.money(_trip!.refundableAmount)} '
                        'على ${_trip!.pendingBookings} حجز في عملية واحدة. '
                        'الحجوزات بدون حساب عميل تُسوّى نقدًا تلقائيًا.',
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  DropdownButtonFormField<RefundSettlement>(
                    initialValue: _settlement,
                    decoration: const InputDecoration(
                      labelText: 'طريقة التسوية',
                      prefixIcon: Icon(Icons.account_balance_rounded),
                    ),
                    items: [
                      for (final method in RefundSettlement.values)
                        DropdownMenuItem(
                          value: method,
                          child: Text(method.label),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _settlement = value ?? _settlement),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'السبب (إلزامي)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    maxLength: 160,
                  ),
                  if (_error != null) _ErrorLine(message: _error!),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submitting || _trip == null ? null : _submit,
          child: const Text('تنفيذ الاسترداد الجماعي'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      setState(() => _error = 'السبب مطلوب.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final failure = await widget.cubit.refundTripBatch(
      trip: _trip!,
      reason: _reasonController.text.trim(),
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

class _Callout extends StatelessWidget {
  const _Callout({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.primary.withAlpha(70)),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
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
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.medium),
      child: Container(
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
      ),
    );
  }
}
