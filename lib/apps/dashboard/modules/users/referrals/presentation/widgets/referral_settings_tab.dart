import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/referral_reward_config.dart';
import 'referral_format.dart';

class ReferralSettingsTab extends StatefulWidget {
  const ReferralSettingsTab({
    super.key,
    required this.config,
    required this.isSaving,
    required this.onSave,
  });

  final ReferralRewardConfig config;
  final bool isSaving;
  final ValueChanged<ReferralRewardConfig> onSave;

  @override
  State<ReferralSettingsTab> createState() => _ReferralSettingsTabState();
}

class _ReferralSettingsTabState extends State<ReferralSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late bool _enabled;
  late String _rewardType;
  late final TextEditingController _referrerCtrl;
  late final TextEditingController _referredCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _couponCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.config;
    _enabled = c.enabled;
    _rewardType = c.rewardType;
    _referrerCtrl = TextEditingController(text: _trim(c.rewardValue));
    _referredCtrl = TextEditingController(text: _trim(c.referredValue));
    _currencyCtrl = TextEditingController(text: c.currency);
    _couponCtrl = TextEditingController(text: c.couponCode ?? '');
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _referrerCtrl.dispose();
    _referredCtrl.dispose();
    _currencyCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _onToggle(bool value) async {
    if (!value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تعطيل برنامج الإحالات'),
          content: const Text(
            'سيتوقف منح مكافآت الإحالة للمستخدمين الجدد حتى يتم تفعيل البرنامج '
            'مرة أخرى. هل أنت متأكد؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تعطيل'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _enabled = value);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSave(
      ReferralRewardConfig(
        enabled: _enabled,
        rewardType: _rewardType,
        rewardValue: double.tryParse(_referrerCtrl.text.trim()) ?? 0,
        referredValue: double.tryParse(_referredCtrl.text.trim()) ?? 0,
        currency: _currencyCtrl.text.trim().isEmpty
            ? 'EGP'
            : _currencyCtrl.text.trim(),
        couponCode:
            _rewardType == 'coupon' && _couponCtrl.text.trim().isNotEmpty
            ? _couponCtrl.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.large),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _enabled,
                  onChanged: _onToggle,
                  title: const Text('تفعيل برنامج الإحالات'),
                  subtitle: Text(
                    _enabled
                        ? 'البرنامج مُفعّل ويتم منح المكافآت تلقائياً.'
                        : 'البرنامج مُعطّل ولن يتم منح أي مكافآت.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (widget.config.updatedAt != null) ...[
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    'آخر تحديث: ${referralArDate(widget.config.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات المكافأة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                DropdownButtonFormField<String>(
                  initialValue: _rewardType,
                  decoration: const InputDecoration(
                    labelText: 'نوع المكافأة',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final type in ReferralRewardConfig.rewardTypes)
                      DropdownMenuItem(
                        value: type,
                        child: Text(referralRewardTypeLabel(type)),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _rewardType = value ?? _rewardType),
                ),
                const SizedBox(height: AppSpacing.medium),
                _NumberField(
                  controller: _referrerCtrl,
                  label: 'قيمة مكافأة المُحيل',
                  helper: 'تُمنح للمُحيل بعد إتمام المدعو لأول طلب مدفوع.',
                ),
                const SizedBox(height: AppSpacing.medium),
                _NumberField(
                  controller: _referredCtrl,
                  label: 'قيمة مكافأة المدعو',
                  helper: 'تُمنح للمستخدم المدعو بعد إتمام أول طلب مدفوع.',
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _currencyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العملة',
                    helperText: 'تُستخدم لمكافآت المحفظة والكوبون.',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_rewardType == 'coupon') ...[
                  const SizedBox(height: AppSpacing.medium),
                  TextFormField(
                    controller: _couponCtrl,
                    decoration: const InputDecoration(
                      labelText: 'كود الكوبون',
                      helperText: 'كود الخصم الذي يُمنح عند اختيار نوع كوبون.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          FilledButton.icon(
            onPressed: widget.isSaving ? null : _save,
            icon: widget.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(widget.isSaving ? 'جارٍ الحفظ...' : 'حفظ الإعدادات'),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.helper,
  });

  final TextEditingController controller;
  final String label;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final parsed = double.tryParse((value ?? '').trim());
        if (parsed == null) return 'أدخل رقماً صحيحاً';
        if (parsed < 0) return 'القيمة يجب أن تكون موجبة';
        return null;
      },
    );
  }
}
