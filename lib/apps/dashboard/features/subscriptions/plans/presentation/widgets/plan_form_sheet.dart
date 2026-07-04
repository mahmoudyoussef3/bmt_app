import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import '../../domain/entities/subscription_plan.dart';

/// Create / edit form for a subscription plan. Returns the edited plan via
/// [showPlanForm]; null when cancelled.
Future<SubscriptionPlan?> showPlanForm(
  BuildContext context, {
  SubscriptionPlan? existing,
}) {
  return showDialog<SubscriptionPlan>(
    context: context,
    builder: (_) => _PlanFormDialog(existing: existing),
  );
}

class _PlanFormDialog extends StatefulWidget {
  final SubscriptionPlan? existing;
  const _PlanFormDialog({this.existing});

  @override
  State<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<_PlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _packageType;
  late final TextEditingController _price;
  late final TextEditingController _days;
  late final TextEditingController _trips;
  late PlanStatus _status;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _subtitle = TextEditingController(text: e?.subtitle ?? '');
    _packageType = TextEditingController(text: e?.packageType ?? '');
    _price = TextEditingController(text: e?.price.toStringAsFixed(0) ?? '');
    _days = TextEditingController(text: (e?.days ?? 30).toString());
    _trips = TextEditingController(text: (e?.tripsCount ?? 0).toString());
    _status = e?.status ?? PlanStatus.active;
  }

  @override
  void dispose() {
    for (final c in [_title, _subtitle, _packageType, _price, _days, _trips]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'باقة جديدة' : 'تعديل الباقة'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_title, 'اسم الباقة بالعربية', required: true),
                _field(_subtitle, 'اسم الباقة بالإنجليزية', required: true),
                _field(
                  _packageType,
                  'رمز نوع الباقة (مثال: work_week)',
                  required: true,
                ),
                _field(_price, 'السعر (ج.م)', number: true, required: true),
                Row(
                  children: [
                    Expanded(child: _field(_days, 'المدة (يوم)', number: true)),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: _field(_trips, 'عدد الرحلات', number: true),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                DropdownButtonFormField<PlanStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'الحالة',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final s in PlanStatus.values)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? _status),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool number = false,
    bool required = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: TextFormField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null
            : null,
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final plan = SubscriptionPlan(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      subtitle: _subtitle.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? 0,
      days: int.tryParse(_days.text.trim()) ?? 30,
      tripsCount: int.tryParse(_trips.text.trim()) ?? 0,
      discountPercent: 0,
      savingsAmount: widget.existing?.savingsAmount ?? 0,
      description: '',
      status: _status,
      packageType: _packageType.text.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9_]+'),
        '_',
      ),
    );
    Navigator.of(context).pop(plan);
  }
}
