import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/office_onboarding.dart';

/// The onboarding form: the office's marketplace identity, and its first
/// dashboard administrator.
///
/// Two sections because they are two different creations that happen to be one
/// transaction — an office row and a login account. Keeping them visually
/// separate is what stops the office's public contact email being mistaken for
/// the administrator's login, which is the one confusion this screen can cause:
/// the login is a *name*, and the address behind it is synthetic and never typed
/// by anyone.
class OfficeOnboardingForm extends StatefulWidget {
  const OfficeOnboardingForm({
    super.key,
    required this.isSubmitting,
    required this.fieldErrors,
    required this.onSubmit,
    this.embedded = false,
  });

  /// Renders the fields alone — no card, no collapsible header, always open —
  /// so a dialog can host them.
  ///
  /// The form used to sit permanently between the platform overview and the
  /// office filters, folded, as a third of the screen's chrome for an action
  /// taken a handful of times a year. Every other creation in this console is a
  /// dialog; this one now is too.
  final bool embedded;

  final bool isSubmitting;

  /// Server- or use-case-side validation errors, keyed as
  /// [OfficeOnboardingRequest.validate] keys them.
  final Map<String, String> fieldErrors;

  final ValueChanged<OfficeOnboardingRequest> onSubmit;

  @override
  State<OfficeOnboardingForm> createState() => _OfficeOnboardingFormState();
}

class _OfficeOnboardingFormState extends State<OfficeOnboardingForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final List<String> _serviceAreas = [];
  bool _expanded = false;
  bool _generatePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descriptionCtrl.dispose();
    _logoCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _areaCtrl.dispose();
    _usernameCtrl.dispose();
    _adminNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _addArea() {
    final value = _areaCtrl.text.trim();
    if (value.isEmpty) return;
    final exists = _serviceAreas.any(
      (area) => area.toLowerCase() == value.toLowerCase(),
    );
    setState(() {
      if (!exists) _serviceAreas.add(value);
      _areaCtrl.clear();
    });
  }

  OfficeOnboardingRequest _buildRequest() => OfficeOnboardingRequest(
    name: _nameCtrl.text,
    slug: _slugCtrl.text,
    description: _descriptionCtrl.text,
    logoUrl: _logoCtrl.text,
    phone: _phoneCtrl.text,
    email: _emailCtrl.text,
    serviceAreas: _serviceAreas,
    adminUsername: _usernameCtrl.text,
    adminFullName: _adminNameCtrl.text,
    adminPassword: _generatePassword ? '' : _passwordCtrl.text,
  );

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_buildRequest());
  }

  /// Prefers the local rule, falls back to whatever the server rejected the
  /// field for. The two agree by construction; when they disagree the server is
  /// the one that matters.
  String? _errorFor(String field, String? Function() local) {
    return local() ?? widget.fieldErrors[field];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = !widget.isSubmitting;

    if (widget.embedded) return _fields(context, enabled: enabled);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
              child: Row(
                children: [
                  Icon(Icons.add_business_outlined, color: scheme.primary),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إضافة مكتب جديد',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'يُنشأ المكتب مباشرة مع حساب مسؤوله الأول، ولا يظهر '
                          'للعملاء حتى تعرضه في السوق.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.large),
            _fields(context, enabled: enabled),
          ],
        ],
      ),
    );
  }

  Widget _fields(BuildContext context, {required bool enabled}) {
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(
            icon: Icons.storefront_outlined,
            label: 'هوية المكتب في السوق',
          ),
          const SizedBox(height: AppSpacing.medium),
          TextFormField(
            controller: _nameCtrl,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'اسم المكتب *',
              helperText: 'الاسم التجاري الذي يراه العملاء.',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _errorFor('name', () {
              final trimmed = (value ?? '').trim();
              if (trimmed.length < 3) return 'اسم المكتب مطلوب';
              return null;
            }),
          ),
          const SizedBox(height: AppSpacing.medium),
          TextFormField(
            controller: _slugCtrl,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'المعرّف المختصر (slug)',
              helperText:
                  'حروف إنجليزية صغيرة وأرقام وشرطات. اتركه فارغاً '
                  'ليُولَّد تلقائياً — لا يمكن تغييره لاحقاً.',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
            ),
            validator: (value) => _errorFor('slug', () {
              final trimmed = (value ?? '').trim().toLowerCase();
              if (trimmed.isEmpty) return null;
              final request = OfficeOnboardingRequest(
                name: 'placeholder',
                adminUsername: 'placeholder',
                slug: trimmed,
              );
              return request.validate()['slug'];
            }),
          ),
          const SizedBox(height: AppSpacing.medium),
          TextFormField(
            controller: _descriptionCtrl,
            enabled: enabled,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'وصف المكتب',
              helperText: 'مطلوب قبل عرض المكتب في السوق، ويمكن إضافته لاحقاً.',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          TextFormField(
            controller: _logoCtrl,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'رابط الشعار',
              helperText: 'رابط https مباشر لصورة الشعار.',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _errorFor('logoUrl', () {
              final trimmed = (value ?? '').trim();
              if (trimmed.isEmpty) return null;
              if (!trimmed.toLowerCase().startsWith('https://')) {
                return 'يجب أن يبدأ الرابط بـ https://';
              }
              return null;
            }),
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _phoneCtrl,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم التواصل',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => widget.fieldErrors['phone'],
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: TextFormField(
                  controller: _emailCtrl,
                  enabled: enabled,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني للمكتب',
                    helperText: 'للمراسلات — ليس بيانات دخول.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => widget.fieldErrors['email'],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _ServiceAreasField(
            controller: _areaCtrl,
            areas: _serviceAreas,
            enabled: enabled,
            onAdd: _addArea,
            onRemove: (area) => setState(() => _serviceAreas.remove(area)),
          ),
          const SizedBox(height: AppSpacing.large),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.large),
          _SectionLabel(
            icon: Icons.person_add_alt_1_outlined,
            label: 'مسؤول المكتب الأول',
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'يسجّل الدخول باسم المستخدم وكلمة المرور من نفس شاشة الدخول '
            'الحالية. لا يوجد بريد إلكتروني يُكتب.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          TextFormField(
            controller: _usernameCtrl,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'اسم الدخول *',
              helperText: 'حروف إنجليزية صغيرة وأرقام و . _ - فقط.',
              border: OutlineInputBorder(),
            ),
            validator: (value) => _errorFor('adminUsername', () {
              final request = OfficeOnboardingRequest(
                name: 'placeholder',
                adminUsername: (value ?? '').trim().toLowerCase(),
              );
              return request.validate()['adminUsername'];
            }),
          ),
          const SizedBox(height: AppSpacing.medium),
          TextFormField(
            controller: _adminNameCtrl,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'اسم المسؤول',
              helperText: 'يظهر داخل لوحة تحكم المكتب.',
              border: OutlineInputBorder(),
            ),
            validator: (value) => widget.fieldErrors['adminFullName'],
          ),
          const SizedBox(height: AppSpacing.medium),
          SwitchListTile(
            value: _generatePassword,
            onChanged: enabled
                ? (value) => setState(() => _generatePassword = value)
                : null,
            contentPadding: EdgeInsets.zero,
            title: const Text('توليد كلمة مرور مؤقتة'),
            subtitle: const Text(
              'تُعرض مرة واحدة بعد الإنشاء ولا يمكن استرجاعها.',
            ),
          ),
          if (!_generatePassword) ...[
            const SizedBox(height: AppSpacing.small),
            TextFormField(
              controller: _passwordCtrl,
              enabled: enabled,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور *',
                helperText: '10 أحرف على الأقل.',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _errorFor('adminPassword', () {
                if ((value ?? '').length < 10) {
                  return 'كلمة المرور 10 أحرف على الأقل';
                }
                return null;
              }),
            ),
          ],
          const SizedBox(height: AppSpacing.large),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: enabled ? _submit : null,
              icon: widget.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                widget.isSubmitting ? 'جارٍ الإنشاء…' : 'إنشاء المكتب',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: AppSpacing.xSmall),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ServiceAreasField extends StatelessWidget {
  const _ServiceAreasField({
    required this.controller,
    required this.areas,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController controller;
  final List<String> areas;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                onFieldSubmitted: (_) => onAdd(),
                decoration: const InputDecoration(
                  labelText: 'مناطق الخدمة',
                  helperText:
                      'المحافظات أو المدن التي يخدمها المكتب — مطلوبة قبل '
                      'العرض في السوق.',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            IconButton.filledTonal(
              onPressed: enabled ? onAdd : null,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'إضافة منطقة',
            ),
          ],
        ),
        if (areas.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.xSmall,
            runSpacing: AppSpacing.xSmall,
            children: [
              for (final area in areas)
                InputChip(
                  label: Text(area),
                  onDeleted: enabled ? () => onRemove(area) : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
