import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import '../cubit/wallet_cubit.dart';
import 'wallet_format.dart';

/// Cashback, manual credit and manual debit — one dialog, three configurations.
///
/// ## The controls, and why each is here (§11)
///
/// * **A mandatory category and a mandatory free-text reason.** Every entry in
///   this ledger is read later by someone asking "why". A category makes that
///   answer groupable; the free text makes it human.
/// * **The office's own cap, shown.** A limit the operator cannot see is a limit
///   they discover by being refused.
/// * **Double confirmation on a debit only.** A debit takes money away from a
///   customer who is not in the room, so the second screen restates it in words:
///   who, how much, and what the balance becomes.
/// * **Step-up above the policy threshold** — re-type the amount. Offered where
///   maker–checker is possible rather than mandated where it is not (§9).
/// * **One request key per dialog open.** A double tap, a retried request or a
///   flaky connection returns the original transaction instead of posting a
///   second one.
class WalletAmountDialog extends StatefulWidget {
  const WalletAmountDialog({
    super.key,
    required this.cubit,
    required this.kind,
    required this.customer,
    required this.wallet,
    required this.policy,
  });

  final WalletCubit cubit;
  final WalletKind kind;
  final WalletCustomer customer;
  final Wallet wallet;
  final WalletPolicy policy;

  @override
  State<WalletAmountDialog> createState() => _WalletAmountDialogState();
}

class _WalletAmountDialogState extends State<WalletAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _stepUpController = TextEditingController();

  /// Generated once, on open — not per submit. That is what makes it an
  /// idempotency key rather than a fresh id for every attempt.
  final String _requestKey = const Uuid().v4();

  late String _category = WalletCategories.forKind(widget.kind).first.code;
  bool _confirming = false;
  bool _submitting = false;
  String? _error;

  bool get _isDebit => widget.kind == WalletKind.manualDebit;

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  double get _cap => widget.policy.capFor(credit: !_isDebit);

  bool get _needsStepUp => widget.policy.needsStepUp(_amount);

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _stepUpController.dispose();
    super.dispose();
  }

  String get _title => switch (widget.kind) {
    WalletKind.cashback => 'منح كاش باك',
    WalletKind.manualCredit => 'إضافة رصيد',
    _ => 'خصم من الرصيد',
  };

  IconData get _icon => switch (widget.kind) {
    WalletKind.cashback => Icons.card_giftcard_rounded,
    WalletKind.manualCredit => Icons.add_card_rounded,
    _ => Icons.remove_circle_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(_icon),
      title: Text('$_title — ${widget.customer.displayName}'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: _confirming ? _buildConfirmation(context) : _buildForm(context),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => _confirming
                    ? setState(() => _confirming = false)
                    : Navigator.of(context).pop(),
          child: Text(_confirming ? 'رجوع' : 'إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _onPrimary,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_confirming ? Icons.check_rounded : Icons.arrow_back_rounded),
          label: Text(_confirming ? 'تأكيد التنفيذ' : 'متابعة'),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _BalanceLine(wallet: widget.wallet),
          const SizedBox(height: AppSpacing.medium),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Western digits only: an Arabic-Indic numeral typed into a money
            // field parses as null and silently becomes zero.
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: 'المبلغ (ج.م)',
              helperText:
                  'الحد الأقصى للعملية الواحدة ${WalletFormat.money(_cap)}',
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
            onChanged: (_) => setState(() {}),
            validator: _validateAmount,
          ),
          const SizedBox(height: AppSpacing.medium),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'التصنيف',
              prefixIcon: Icon(Icons.sell_outlined),
            ),
            items: [
              for (final category in WalletCategories.forKind(widget.kind))
                DropdownMenuItem(
                  value: category.code,
                  child: Text(category.label),
                ),
            ],
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: AppSpacing.medium),
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'السبب (إلزامي)',
              helperText: 'يظهر في سجل المحفظة ولا يمكن تعديله بعد التنفيذ',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
            maxLength: 160,
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'السبب مطلوب لكل حركة على المحفظة'
                : null,
          ),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'ملاحظات (اختياري)',
              prefixIcon: Icon(Icons.sticky_note_2_outlined),
            ),
            maxLines: 2,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.medium),
            _ErrorLine(message: _error!),
          ],
          const SizedBox(height: AppSpacing.small),
          Text(
            'ستصل للعميل رسالة بالتغيير، وتُسجَّل العملية باسمك في السجل.',
            style: text.labelSmall?.copyWith(
              color: DashboardColors.faintInk(context),
            ),
          ),
        ],
      ),
    );
  }

  /// The debit's second screen. It restates the operation in a sentence rather
  /// than re-showing the form, because "50.00" in a field and "سيتم خصم 50.00
  /// ج.م من رصيد أحمد" are not read with the same attention.
  Widget _buildConfirmation(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final resulting = _isDebit
        ? widget.wallet.balance - _amount
        : widget.wallet.balance + _amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: (_isDebit ? scheme.error : scheme.primary).withAlpha(20),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            border: Border.all(
              color: (_isDebit ? scheme.error : scheme.primary).withAlpha(90),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isDebit
                    ? 'سيتم خصم ${WalletFormat.money(_amount)} من رصيد ${widget.customer.displayName}.'
                    : 'سيتم إضافة ${WalletFormat.money(_amount)} إلى رصيد ${widget.customer.displayName}.',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'الرصيد بعد العملية: ${WalletFormat.money(resulting)}',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'لا يمكن التراجع عن هذه العملية إلا بعملية عكسية مسجّلة في السجل.',
                style: text.bodySmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        _SummaryRow(
          label: 'التصنيف',
          value: WalletCategories.labelOf(_category),
        ),
        _SummaryRow(label: 'السبب', value: _reasonController.text.trim()),
        if (_needsStepUp) ...[
          const SizedBox(height: AppSpacing.medium),
          TextField(
            controller: _stepUpController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'أعد كتابة المبلغ للتأكيد',
              helperText: 'مطلوب للمبالغ التي تتجاوز حد المراجعة الثانية',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.medium),
          _ErrorLine(message: _error!),
        ],
      ],
    );
  }

  String? _validateAmount(String? value) {
    final amount = double.tryParse((value ?? '').trim());
    if (amount == null || amount <= 0) return 'أدخل مبلغًا أكبر من صفر';
    if (amount > _cap) {
      return 'المبلغ يتجاوز الحد المسموح (${WalletFormat.money(_cap)})';
    }
    if (_isDebit && amount > widget.wallet.availableBalance) {
      return 'الرصيد المتاح ${WalletFormat.money(widget.wallet.availableBalance)} فقط';
    }
    return null;
  }

  Future<void> _onPrimary() async {
    if (!_confirming) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      // Credits go straight through unless the office asked for step-up; a debit
      // always gets the second screen.
      if (_isDebit || _needsStepUp) {
        setState(() {
          _confirming = true;
          _error = null;
        });
        return;
      }
      await _submit();
      return;
    }

    if (_needsStepUp) {
      final retyped = double.tryParse(_stepUpController.text.trim());
      if (retyped == null || (retyped - _amount).abs() > 0.001) {
        setState(() => _error = 'المبلغ المُعاد كتابته لا يطابق المبلغ الأصلي.');
        return;
      }
    }
    await _submit();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final failure = await widget.cubit.adjust(
      kind: widget.kind,
      clientId: widget.customer.id,
      amount: _amount,
      category: _category,
      reason: _reasonController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      requestKey: _requestKey,
    );

    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    // Stay open on a refusal: the operator needs to read why, and usually to fix
    // one field rather than start over.
    setState(() {
      _submitting = false;
      _error = failure;
    });
  }
}

class _BalanceLine extends StatelessWidget {
  const _BalanceLine({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 18,
            color: DashboardColors.mutedInk(context),
          ),
          const SizedBox(width: AppSpacing.small),
          Text('الرصيد الحالي', style: text.bodySmall),
          const Spacer(),
          Text(
            WalletFormat.money(wallet.availableBalance),
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

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
            width: 88,
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
