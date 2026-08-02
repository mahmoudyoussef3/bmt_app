import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    required this.isUploadingLogo,
    required this.canEdit,
    required this.onSave,
    required this.onUploadLogo,
  });

  final OfficeProfile profile;
  final bool isSaving;
  final bool isUploadingLogo;
  final bool canEdit;
  final ValueChanged<OfficeProfileEdit> onSave;

  /// Uploads the picked bytes and resolves to the stored public URL, or null if
  /// the upload failed (the cubit surfaces the reason as a snack bar).
  final Future<String?> Function(Uint8List bytes, String fileName) onUploadLogo;

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

  /// Picker/upload failures that belong beside the logo field rather than in a
  /// snack bar — "this file is too big" is about the control the operator just
  /// used, and stays visible while they pick another.
  String? _logoError;

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

  /// Max upload size, mirroring `office-logos`'s `file_size_limit`. Checked here
  /// so an oversized file is refused before it is sent, with a message that says
  /// what the limit is — the bucket's own rejection does not.
  static const _maxLogoBytes = 2 * 1024 * 1024;

  Future<void> _pickLogo() async {
    setState(() => _logoError = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
        allowMultiple: false,
        // On web there is no path to read from, so the bytes have to come back
        // with the pick itself.
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = await _readBytes(file);
      if (bytes == null || bytes.isEmpty) {
        setState(() => _logoError = 'تعذر قراءة الملف. جرّب صورة أخرى.');
        return;
      }
      if (bytes.length > _maxLogoBytes) {
        setState(() => _logoError = 'حجم الصورة كبير. الحد الأقصى 2 ميجابايت.');
        return;
      }

      final url = await widget.onUploadLogo(bytes, file.name);
      if (!mounted || url == null) return;

      // Straight into the same controller the URL field edits, so an uploaded
      // logo and a pasted link are the same value from here on — and both are
      // only persisted by the save button below.
      setState(() => _logoCtrl.text = url);
    } catch (error) {
      if (!mounted) return;
      setState(() => _logoError = 'تعذر رفع الصورة: $error');
    }
  }

  Future<Uint8List?> _readBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;
    if (!kIsWeb && file.path != null) {
      return io.File(file.path!).readAsBytes();
    }
    return null;
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
              enabled: enabled && !widget.isUploadingLogo,
              isUploading: widget.isUploadingLogo,
              errorText: _logoError,
              onChanged: () => setState(() {}),
              onPick: _pickLogo,
              onClear: () => setState(() {
                _logoCtrl.clear();
                _logoError = null;
              }),
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

/// The office logo: upload a file, or paste a link.
///
/// Uploading is the primary path — it puts the image in the platform's own
/// `office-logos` bucket, so the marketplace card cannot go blank because some
/// third-party host expired. The URL field stays because offices onboarded
/// before the bucket existed already hold external links, and because it is
/// where an uploaded file's resulting URL lands: one value, two ways to fill it.
///
/// The preview renders whatever the field currently holds, so a broken link is
/// visible before saving rather than after a client reports an empty card.
class _LogoField extends StatelessWidget {
  const _LogoField({
    required this.controller,
    required this.enabled,
    required this.isUploading,
    required this.errorText,
    required this.onChanged,
    required this.onPick,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isUploading;
  final String? errorText;
  final VoidCallback onChanged;
  final Future<void> Function() onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LogoPreview(url: url, isUploading: isUploading),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.small,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: enabled ? onPick : null,
                        icon: isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_rounded),
                        label: Text(
                          isUploading
                              ? 'جارٍ الرفع...'
                              : url.isEmpty
                              ? 'رفع صورة الشعار'
                              : 'تغيير الصورة',
                        ),
                      ),
                      if (url.isNotEmpty && enabled)
                        TextButton.icon(
                          onPressed: onClear,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('إزالة'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    'PNG أو JPG أو WEBP بحد أقصى 2 ميجابايت. '
                    'الصورة تُحفظ مع بيانات المكتب عند الضغط على حفظ.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.small),
          Text(
            errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
        const SizedBox(height: AppSpacing.medium),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.url,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: 'رابط شعار المكتب',
            helperText: 'يُملأ تلقائياً بعد الرفع، أو الصق رابطاً مباشراً.',
            helperMaxLines: 2,
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
      ],
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.url, this.isUploading = false});

  final String url;
  final bool isUploading;

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
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(60)),
      ),
      child: isUploading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : url.isEmpty
          ? placeholder
          : Image.network(
              url,
              fit: BoxFit.cover,
              // Rendered from the stored public URL rather than the picked
              // bytes: if this shows the logo, the upload is genuinely readable
              // by the same anonymous request the client app will make.
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
