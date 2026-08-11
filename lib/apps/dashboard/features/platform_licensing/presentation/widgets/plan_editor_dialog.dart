import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../domain/entities/licensing_catalog.dart';

/// The plan's commercial identity: everything a plan is *sold* on — its name,
/// price, trial and marketplace visibility — as opposed to the feature values
/// the builder screen edits.
///
/// It exists because the plan builder edited feature values and nothing else:
/// price, trial and visibility were readable in the list and editable nowhere,
/// so every commercial change to a plan meant an SQL console.
///
/// Returns the payload for `platform_save_plan`, deliberately **without** a
/// `features` key — that RPC replaces the feature map wholesale whenever the
/// payload carries one, and this dialog knows nothing about features.
Future<Map<String, dynamic>?> showPlanEditorDialog(
  BuildContext context, {
  LicensingPlan? plan,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => _PlanEditorDialog(plan: plan),
  );
}

/// A clone's new identity. Asked for properly rather than through the reason
/// prompt, which labelled the key field "السبب" and told the operator it would
/// appear in the audit log.
Future<({String key, String name})?> showClonePlanDialog(
  BuildContext context, {
  required LicensingPlan plan,
}) {
  return showDialog<({String key, String name})>(
    context: context,
    builder: (context) => _ClonePlanDialog(plan: plan),
  );
}

class _PlanEditorDialog extends StatefulWidget {
  const _PlanEditorDialog({this.plan});

  final LicensingPlan? plan;

  @override
  State<_PlanEditorDialog> createState() => _PlanEditorDialogState();
}

class _PlanEditorDialogState extends State<_PlanEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _key = TextEditingController(text: widget.plan?.key ?? '');
  late final _nameAr = TextEditingController(text: widget.plan?.nameAr ?? '');
  late final _nameEn = TextEditingController(text: widget.plan?.nameEn ?? '');
  late final _tagline = TextEditingController(
    text: widget.plan?.taglineAr ?? '',
  );
  late final _priceMonthly = TextEditingController(
    text: _money(widget.plan?.priceMonthly),
  );
  late final _priceYearly = TextEditingController(
    text: _money(widget.plan?.priceYearly),
  );
  late final _trialDays = TextEditingController(
    text: '${widget.plan?.trialDays ?? 0}',
  );
  final _reason = TextEditingController();

  late bool _isPublic = widget.plan?.isPublic ?? false;
  late String _status = switch (widget.plan?.status) {
    'active' => 'active',
    _ => 'draft',
  };

  bool get _isNew => widget.plan == null;

  static String _money(num? value) {
    if (value == null) return '';
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
  }

  @override
  void dispose() {
    _key.dispose();
    _nameAr.dispose();
    _nameEn.dispose();
    _tagline.dispose();
    _priceMonthly.dispose();
    _priceYearly.dispose();
    _trialDays.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(_isNew ? 'باقة جديدة' : 'بيانات الباقة'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  
                  'هذه بيانات البيع فقط: الاسم والسعر والعرض. ميزات الباقة '
                  'تُحرَّر من لوحة الميزات ولا يمسّها الحفظ هنا.',
                  style: text.bodySmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                _Section(label: 'الهوية'),
                TextFormField(
                  controller: _key,
                  enabled: _isNew,
                  decoration: InputDecoration(
                    labelText: 'المفتاح',
                    hintText: 'starter',
                    border: const OutlineInputBorder(),
                    helperText: _isNew
                        ? 'حروف إنجليزية صغيرة وأرقام وشرطات، ولا يمكن تغييره بعد الإنشاء.'
                        : 'المفتاح ثابت: الكود والتقارير تشير إليه.',
                  ),
                  validator: (v) {
                    if (!_isNew) return null;
                    final value = (v ?? '').trim();
                    if (!RegExp(r'^[a-z0-9-]{3,}$').hasMatch(value)) {
                      return 'حروف إنجليزية صغيرة وأرقام وشرطات، ٣ أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _nameAr,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالعربية',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'اكتب اسم الباقة' : null,
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _nameEn,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالإنجليزية',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _tagline,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'وصف مختصر',
                    hintText: 'لمن هذه الباقة، في سطر واحد',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                _Section(label: 'التسعير'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceMonthly,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'السعر الشهري',
                          suffixText: 'ج.م',
                          border: OutlineInputBorder(),
                          
                          helperText: 'اتركه فارغًا لسعر تفاوضي',
                          helperMaxLines: 2,
                        ),
                        validator: _validatePrice,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: TextFormField(
                        controller: _priceYearly,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'السعر السنوي',
                          suffixText: 'ج.م',
                          border: OutlineInputBorder(),
                          helperText: 'اختياري',
                          helperMaxLines: 2,
                        ),
                        validator: _validatePrice,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _trialDays,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'أيام التجربة',
                    border: OutlineInputBorder(),
                    helperText: 'صفر يعني بلا فترة تجريبية',
                  ),
                  validator: (v) {
                    final parsed = int.tryParse((v ?? '').trim());
                    if (parsed == null || parsed < 0 || parsed > 365) {
                      return 'رقم بين ٠ و٣٦٥';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.large),
                _Section(label: 'العرض'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                  title: const Text('معروضة للمكاتب'),
                  subtitle: Text(
                    _isPublic
                        ? 'تظهر ضمن الباقات المتاحة للاشتراك.'
                        : 'لا تظهر لأحد، وتُمنح بالتعيين من وحدة التحكم فقط.',
                    style: text.bodySmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'draft', label: Text('مسودة')),
                    ButtonSegment(value: 'active', label: Text('نشطة')),
                  ],
                  selected: {_status},
                  onSelectionChanged: (s) => setState(() => _status = s.first),
                ),
                if (widget.plan?.isArchived == true)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xSmall),
                    child: Text(
                      'الباقة مؤرشفة الآن — اختيار «نشطة» يعيدها إلى التعيين.',
                      style: text.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.large),
                TextFormField(
                  controller: _reason,
                  maxLines: 2,
                  
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة للسجل (اختيارية)',
                    hintText: 'ما الذي تغيّر، ولماذا',
                    border: OutlineInputBorder(),
                  ),
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
        FilledButton(onPressed: _submit, child: Text(_isNew ? 'إنشاء' : 'حفظ')),
      ],
    );
  }

  String? _validatePrice(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    final parsed = num.tryParse(raw);
    if (parsed == null || parsed < 0) return 'رقم صحيح أو اتركه فارغًا';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop({
      if (!_isNew) 'id': widget.plan!.id,
      'key': _isNew ? _key.text.trim() : widget.plan!.key,
      'name_ar': _nameAr.text.trim(),
      'name_en': _nameEn.text.trim(),
      'tagline_ar': _tagline.text.trim(),
      'status': _status,
      'is_public': _isPublic,
      
      'price_monthly': _priceMonthly.text.trim(),
      'price_yearly': _priceYearly.text.trim(),
      'trial_days': int.tryParse(_trialDays.text.trim()) ?? 0,
      'reason': _reason.text.trim().isEmpty
          ? (_isNew ? 'إنشاء باقة من وحدة التحكم' : 'تعديل بيانات بيع الباقة')
          : _reason.text.trim(),
    });
  }
}

class _ClonePlanDialog extends StatefulWidget {
  const _ClonePlanDialog({required this.plan});

  final LicensingPlan plan;

  @override
  State<_ClonePlanDialog> createState() => _ClonePlanDialogState();
}

class _ClonePlanDialogState extends State<_ClonePlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _key = TextEditingController();
  late final _name = TextEditingController(
    text: 'نسخة من ${widget.plan.nameAr}',
  );

  @override
  void dispose() {
    _key.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('نسخ الباقة'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تُنشأ النسخة بكل قيم «${widget.plan.nameAr}» كمسودة غير '
                'معروضة، ولا يتأثر أي مكتب حتى تُعيَّن له.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextFormField(
                controller: _key,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'مفتاح النسخة',
                  hintText: 'starter-2027',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    RegExp(r'^[a-z0-9-]{3,}$').hasMatch((v ?? '').trim())
                    ? null
                    : 'حروف إنجليزية صغيرة وأرقام وشرطات، ٣ أحرف على الأقل',
              ),
              const SizedBox(height: AppSpacing.medium),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'اسم النسخة',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'اكتب اسمًا للنسخة' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(
              context,
            ).pop((key: _key.text.trim(), name: _name.text.trim()));
          },
          child: const Text('إنشاء النسخة'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
