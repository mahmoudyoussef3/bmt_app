import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/validation/contact_validation.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/office_profile.dart';

/// The editable half of the office record — everything a client sees on the
/// office's marketplace card.
///
/// Only the fields in [OfficeProfileEdit] appear here. `slug`, `status`,
/// `rating` and `join_code` are shown elsewhere or not at all, deliberately:
/// the update policy would let an admin write them, so keeping them out of the
/// form is what keeps them platform-owned in practice.
class OfficeIdentityForm extends StatefulWidget {
  const OfficeIdentityForm({
    super.key,
    required this.profile,
    required this.isSaving,
    required this.canEdit,
    required this.onSave,
  });

  final OfficeProfile profile;
  final bool isSaving;
  final bool canEdit;
  final ValueChanged<OfficeProfileEdit> onSave;

  @override
  State<OfficeIdentityForm> createState() => _OfficeIdentityFormState();
}

class _OfficeIdentityFormState extends State<OfficeIdentityForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _logoCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  final _areaCtrl = TextEditingController();
  late List<String> _serviceAreas;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.name);
    _descriptionCtrl = TextEditingController(text: p.description);
    _logoCtrl = TextEditingController(text: p.logoUrl ?? '');
    _phoneCtrl = TextEditingController(text: p.phone ?? '');
    _emailCtrl = TextEditingController(text: p.email ?? '');
    _serviceAreas = [...p.serviceAreas];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _logoCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  void _addArea() {
    final value = _areaCtrl.text.trim();
    if (value.isEmpty) return;
    // Case-insensitive: "الجيزة" and "الجيزه" are the operator's problem, but
    // the same string twice is ours.
    final exists = _serviceAreas.any(
      (area) => area.toLowerCase() == value.toLowerCase(),
    );
    setState(() {
      if (!exists) _serviceAreas.add(value);
      _areaCtrl.clear();
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSave(
      OfficeProfileEdit(
        name: _nameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        serviceAreas: _serviceAreas,
        logoUrl: _logoCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.canEdit && !widget.isSaving;

    return Form(
      key: _formKey,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.badge_outlined, color: scheme.primary),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    'بيانات المكتب',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _SlugChip(slug: widget.profile.slug),
              ],
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              'هذه البيانات تظهر للعملاء في دليل المكاتب وعلى بطاقات الرحلات.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (!widget.canEdit) ...[
              const SizedBox(height: AppSpacing.medium),
              const _ReadOnlyNotice(),
            ],
            const SizedBox(height: AppSpacing.large),
            TextFormField(
              controller: _nameCtrl,
              enabled: enabled,
              decoration: const InputDecoration(
                labelText: 'اسم المكتب',
                helperText: 'الاسم التجاري الذي يراه العملاء.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final trimmed = (value ?? '').trim();
                if (trimmed.isEmpty) return 'اسم المكتب مطلوب';
                if (trimmed.length < 3) return 'الاسم قصير جداً';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _descriptionCtrl,
              enabled: enabled,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'وصف المكتب',
                helperText:
                    'نبذة قصيرة عن خدماتك — تظهر في صفحة المكتب داخل تطبيق العملاء.',
                helperMaxLines: 2,
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            _LogoField(
              controller: _logoCtrl,
              enabled: enabled,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _phoneCtrl,
              enabled: enabled,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم التواصل',
                helperText: 'رقم يظهر للعملاء للتواصل مع المكتب.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _emailCtrl,
              enabled: enabled,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                helperText: 'اختياري — للمراسلات الرسمية.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final trimmed = (value ?? '').trim();
                if (trimmed.isEmpty) return null;
                return ContactValidation.isValidEmail(trimmed)
                    ? null
                    : 'بريد إلكتروني غير صالح';
              },
            ),
            const SizedBox(height: AppSpacing.large),
            _ServiceAreasEditor(
              areas: _serviceAreas,
              controller: _areaCtrl,
              enabled: enabled,
              onAdd: _addArea,
              onRemove: (area) => setState(() => _serviceAreas.remove(area)),
            ),
            if (widget.canEdit) ...[
              const SizedBox(height: AppSpacing.large),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  onPressed: widget.isSaving ? null : _save,
                  icon: widget.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    widget.isSaving ? 'جارٍ الحفظ...' : 'حفظ بيانات المكتب',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlugChip extends StatelessWidget {
  const _SlugChip({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    if (slug.trim().isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'المعرّف العام للمكتب — ثابت ولا يمكن تغييره.',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xSmall,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(color: scheme.outline.withAlpha(60)),
        ),
        child: Text(
          slug,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'العرض فقط — تعديل بيانات المكتب متاح لحساب المالك.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo URL plus a live preview.
///
/// A URL field rather than an upload: the client renders office logos with a
/// plain `Image.network`, and there is no provisioned public bucket for office
/// branding the way `documents` exists for fleet paperwork. The preview is what
/// makes a URL field usable — a broken link is visible before saving, not after
/// a client reports a blank card.
class _LogoField extends StatelessWidget {
  const _LogoField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final url = controller.text.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LogoPreview(url: url),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.url,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'رابط شعار المكتب',
              helperText: 'رابط مباشر لصورة الشعار (PNG أو JPG).',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final trimmed = (value ?? '').trim();
              if (trimmed.isEmpty) return null;
              final uri = Uri.tryParse(trimmed);
              final isHttp =
                  uri != null &&
                  uri.hasScheme &&
                  (uri.scheme == 'http' || uri.scheme == 'https') &&
                  uri.host.isNotEmpty;
              return isHttp ? null : 'أدخل رابطاً صحيحاً يبدأ بـ https';
            },
          ),
        ),
      ],
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Icon(
      Icons.storefront_outlined,
      color: scheme.onSurfaceVariant,
    );

    return Container(
      width: 72,
      height: 72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(60)),
      ),
      child: url.isEmpty
          ? placeholder
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.broken_image_outlined, color: scheme.error),
            ),
    );
  }
}

class _ServiceAreasEditor extends StatelessWidget {
  const _ServiceAreasEditor({
    required this.areas,
    required this.controller,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> areas;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مناطق الخدمة',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          'المحافظات أو المناطق التي يخدمها المكتب — تساعد العملاء على إيجادك.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (enabled)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onAdd(),
                  decoration: const InputDecoration(
                    labelText: 'أضف منطقة',
                    hintText: 'مثال: القاهرة',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة'),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.medium),
        if (areas.isEmpty)
          Text(
            'لم تُضف أي مناطق بعد.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              for (final area in areas)
                InputChip(
                  label: Text(area),
                  onDeleted: enabled ? () => onRemove(area) : null,
                  deleteIcon: const Icon(Icons.close_rounded, size: 18),
                ),
            ],
          ),
      ],
    );
  }
}
