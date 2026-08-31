import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/forms/forms.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/validation/contact_validation.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/office_profile.dart';
import 'office_marketplace_preview.dart';

/// Lets the screen above the form reach into it: jump to a field the
/// completeness checklist names, and ask whether anything is unsaved before it
/// throws the form away on a refresh.
///
/// The alternative — hoisting every controller into the screen so the checklist
/// and the fields share one state object — would put ten controllers and a
/// dirty signature in a widget whose job is composition. This is two callbacks,
/// wired once in [State.initState] and cleared with the form.
class OfficeProfileFormHandle {
  /// Scrolls the named field into view and focuses it. Null while no form is
  /// mounted (the read-only view builds none).
  Future<void> Function(String fieldId)? jumpTo;

  /// Whether the operator has edits that a reload would discard.
  bool Function()? isDirty;

  bool get hasUnsavedChanges => isDirty?.call() ?? false;
}

/// The editable half of the office record — everything a client sees on the
/// office's marketplace card.
///
/// Built on the console's shared form kit ([DashboardFormSection],
/// [DashboardFormField], [DashboardFormController]) so it validates, counts and
/// recovers the way the fleet, trip and route forms do. Three bands, in the
/// order the marketplace card is read: **الهوية** (who you are), **التواصل**
/// (how to reach you), **التغطية** (where you drive).
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
    this.handle,
  });

  final OfficeProfile profile;
  final bool isSaving;
  final bool isUploadingLogo;
  final bool canEdit;
  final ValueChanged<OfficeProfileEdit> onSave;

  /// Uploads the picked bytes and resolves to the stored public URL, or null if
  /// the upload failed (the cubit surfaces the reason as a snack bar).
  final Future<String?> Function(Uint8List bytes, String fileName) onUploadLogo;

  /// Wired by the screen so the overview's checklist can jump into the form and
  /// «تحديث» can ask before discarding edits.
  final OfficeProfileFormHandle? handle;

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

  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _logoFocus = FocusNode();
  final _areaFocus = FocusNode();

  final _nameKey = GlobalKey();
  final _descriptionKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _logoKey = GlobalKey();
  final _areasKey = GlobalKey();

  late final DashboardFormController _form;
  late final String _openingSignature;

  late List<String> _serviceAreas;

  /// The URL field is folded away by default. Uploading is the path that keeps
  /// the image inside the platform's own bucket; the field stays for offices
  /// onboarded before that bucket existed, which is a minority case and should
  /// not be the first thing the eye lands on.
  bool _showLogoUrlField = false;

  /// The area input replaces the «إضافة منطقة» chip while it is open, so the
  /// band is a row of chips at rest rather than a form with a permanently empty
  /// box at the end of it.
  bool _addingArea = false;

  bool _showIssues = false;

  /// Picker/upload failures that belong beside the logo field rather than in a
  /// snack bar — "this file is too big" is about the control the operator just
  /// used, and stays visible while they pick another.
  String? _logoError;

  static const _identity = 'الهوية';
  static const _contact = 'التواصل';
  static const _coverage = 'التغطية';

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
    _showLogoUrlField = (p.logoUrl ?? '').trim().isNotEmpty && !_isPlatformLogo;

    _form = DashboardFormController([
      DashboardFormFieldSpec(
        id: 'name',
        label: 'اسم المكتب',
        section: _identity,
        anchorKey: _nameKey,
        focusNode: _nameFocus,
        validate: () => _validateName(_nameCtrl.text),
      ),
      DashboardFormFieldSpec(
        id: 'description',
        label: 'وصف المكتب',
        section: _identity,
        anchorKey: _descriptionKey,
        focusNode: _descriptionFocus,
        isRequired: false,
        validate: () => _validateDescription(_descriptionCtrl.text),
      ),
      DashboardFormFieldSpec(
        id: 'logo',
        label: 'شعار المكتب',
        section: _identity,
        anchorKey: _logoKey,
        focusNode: _logoFocus,
        isRequired: false,
        validate: () => _validateLogoUrl(_logoCtrl.text),
      ),
      DashboardFormFieldSpec(
        id: 'phone',
        label: 'رقم التواصل',
        section: _contact,
        anchorKey: _phoneKey,
        focusNode: _phoneFocus,
        isRequired: false,
        validate: () => _validatePhone(_phoneCtrl.text),
      ),
      DashboardFormFieldSpec(
        id: 'email',
        label: 'البريد الإلكتروني',
        section: _contact,
        anchorKey: _emailKey,
        focusNode: _emailFocus,
        isRequired: false,
        validate: () => _validateEmail(_emailCtrl.text),
      ),
      DashboardFormFieldSpec(
        id: 'areas',
        label: 'مناطق الخدمة',
        section: _coverage,
        anchorKey: _areasKey,
        focusNode: _areaFocus,
        isRequired: false,
        validate: () => null,
      ),
    ]);

    _openingSignature = _signature;
    widget.handle
      ?..jumpTo = _form.jumpTo
      ..isDirty = () => _hasChanges;
  }

  @override
  void dispose() {
    final handle = widget.handle;
    if (handle != null) {
      handle.jumpTo = null;
      handle.isDirty = null;
    }
    for (final c in [
      _nameCtrl,
      _descriptionCtrl,
      _logoCtrl,
      _phoneCtrl,
      _emailCtrl,
      _areaCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus,
      _descriptionFocus,
      _phoneFocus,
      _emailFocus,
      _logoFocus,
      _areaFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------- validation
  //
  // Every rule lives here once and is read from two places: the field's own
  // `validator` (for the inline error) and its [DashboardFormFieldSpec] (for
  // the issues banner and the jump target). One definition, so the two can
  // never disagree about whether a field is acceptable.

  String? _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'اسم المكتب مطلوب';
    if (trimmed.length < 3) return 'الاسم قصير جداً';
    return null;
  }

  /// Length only. A blank description never blocks a save — it costs the office
  /// a complete card, which the checklist says plainly, and refusing to store
  /// the phone number an operator just corrected because the description is
  /// still empty would be the wrong trade.
  String? _validateDescription(String value) =>
      value.trim().length > 500 ? 'الوصف أطول من 500 حرف' : null;

  /// Mirrors the rule the platform's own onboarding form applies to this exact
  /// column (7–20 characters): two forms writing `offices.phone` that disagree
  /// about what a number is produce rows neither of them would accept.
  String? _validatePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length < 7 || trimmed.length > 20) {
      return 'رقم هاتف غير صالح';
    }
    return null;
  }

  String? _validateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return ContactValidation.isValidEmail(trimmed)
        ? null
        : 'بريد إلكتروني غير صالح';
  }

  String? _validateLogoUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    final isHttp =
        uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return isHttp ? null : 'أدخل رابطاً صحيحاً يبدأ بـ https';
  }

  // ------------------------------------------------------------- dirty state

  /// Every value the form can change, flattened. Compared against the same
  /// string taken when the form opened, so "has changes" means the data
  /// actually differs — not that a key was pressed.
  String get _signature => [
    _nameCtrl.text.trim(),
    _descriptionCtrl.text.trim(),
    _logoCtrl.text.trim(),
    _phoneCtrl.text.trim(),
    _emailCtrl.text.trim(),
    _serviceAreas.join('،'),
  ].join('|');

  bool get _hasChanges => _signature != _openingSignature;

  bool get _isPlatformLogo => _logoCtrl.text.trim().contains('/office-logos/');

  // ------------------------------------------------------- card completeness
  //
  // Separate from validation on purpose. The form asks "may this be stored?";
  // the badges ask "is the marketplace card finished?" — and the answer to the
  // second is never allowed to block the first.

  bool get _hasDescription => _descriptionCtrl.text.trim().isNotEmpty;
  bool get _hasLogo => _logoCtrl.text.trim().isNotEmpty;
  bool get _hasPhone => _phoneCtrl.text.trim().isNotEmpty;

  int _cardFilled(String section) => switch (section) {
    _identity => [
      _validateName(_nameCtrl.text) == null,
      _hasDescription,
      _hasLogo,
    ].where((filled) => filled).length,
    _contact => _hasPhone ? 1 : 0,
    _ => _serviceAreas.isNotEmpty ? 1 : 0,
  };

  int _cardTotal(String section) => section == _identity ? 3 : 1;

  // ----------------------------------------------------------------- actions

  void _addArea() {
    final value = _areaCtrl.text.trim();
    if (value.isEmpty) {
      setState(() => _addingArea = false);
      return;
    }

    final exists = _serviceAreas.any(
      (area) => area.toLowerCase() == value.toLowerCase(),
    );
    setState(() {
      if (!exists) _serviceAreas.add(value);
      _areaCtrl.clear();
    });
    // Areas are added in runs — a governorate, then the districts inside it —
    // so the field keeps focus for the next one instead of closing each time.
    _areaFocus.requestFocus();
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

      setState(() {
        _logoCtrl.text = url;
        _showLogoUrlField = false;
      });
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
    final inlineValid = _formKey.currentState?.validate() ?? false;
    if (!inlineValid || !_form.isValid) {
      setState(() => _showIssues = true);
      _form.jumpToFirstIssue();
      return;
    }
    setState(() => _showIssues = false);
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

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    // Two different reasons a field cannot be typed into, drawn differently on
    // purpose: a support agent is *reading* the office's data and needs it at
    // full contrast, while a form mid-save is genuinely inert and greys out.
    final enabled = !widget.isSaving;
    final issues = _showIssues ? _form.issues : const <DashboardFormIssue>[];

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      // Rebuilds on every keystroke so the band badges, the live card preview
      // and the unsaved marker answer while the operator types.
      onChanged: () => setState(() {}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.canEdit) ...[
            const _ReadOnlyNotice(),
            const SizedBox(height: AppSpacing.medium),
          ],
          if (issues.isNotEmpty) ...[
            DashboardFormIssuesBanner(issues: issues, onJumpTo: _form.jumpTo),
            const SizedBox(height: AppSpacing.medium),
          ],
          _identitySection(enabled),
          const SizedBox(height: AppSpacing.medium),
          _contactSection(enabled),
          const SizedBox(height: AppSpacing.medium),
          _coverageSection(enabled && widget.canEdit),
          if (widget.canEdit) ...[
            const SizedBox(height: AppSpacing.medium),
            _SaveBar(
              isSaving: widget.isSaving,
              hasChanges: _hasChanges,
              hint: _saveHint(),
              onSave: _save,
            ),
          ],
        ],
      ),
    );
  }

  /// Names the next thing to do rather than repeating "review your data".
  String _saveHint() {
    if (!_hasChanges) {
      return 'التغييرات تُحفظ فوراً وتظهر لكل من يزور صفحة مكتبك في تطبيق العملاء.';
    }
    final missing = [
      if (!_hasDescription) 'الوصف',
      if (!_hasLogo) 'الشعار',
      if (!_hasPhone) 'رقم التواصل',
      if (_serviceAreas.isEmpty) 'مناطق الخدمة',
    ];
    if (missing.isEmpty) {
      return 'لديك تعديلات غير محفوظة — اضغط حفظ لتظهر للعملاء.';
    }
    return 'لديك تعديلات غير محفوظة. ما زال ينقص البطاقة: ${missing.join('، ')}.';
  }

  Widget _identitySection(bool enabled) {
    return DashboardFormSection(
      icon: Icons.storefront_outlined,
      title: _identity,
      subtitle: 'الاسم والوصف والشعار — أول ما يراه العميل في دليل المكاتب.',
      filled: _cardFilled(_identity),
      total: _cardTotal(_identity),
      trailing: _SlugChip(slug: widget.profile.slug),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardFormField(
            key: _nameKey,
            controller: _nameCtrl,
            focusNode: _nameFocus,
            nextFocus: _descriptionFocus,
            enabled: enabled,
            readOnly: !widget.canEdit,
            label: 'اسم المكتب',
            icon: Icons.badge_outlined,
            hint: 'مثال: مكتب القاهرة للنقل',
            helper: widget.profile.slug.trim().isEmpty
                ? 'الاسم التجاري الذي يراه العملاء.'
                : 'الاسم التجاري الذي يراه العملاء. المعرّف العام '
                      '(${widget.profile.slug}) ثابت ولا يمكن تغييره.',
            validator: (v) => _validateName(v ?? ''),
          ),
          const SizedBox(height: AppSpacing.medium),
          DashboardFormField(
            key: _descriptionKey,
            controller: _descriptionCtrl,
            focusNode: _descriptionFocus,
            enabled: enabled,
            readOnly: !widget.canEdit,
            isRequired: false,
            maxLines: 4,
            maxLength: 500,
            label: 'وصف المكتب',
            hint: 'مثال: خدمة نقل يومي مكيّف بين بنها والقاهرة بمواعيد ثابتة.',
            helper:
                'نبذة قصيرة عن خدماتك — تظهر في صفحة المكتب داخل تطبيق العملاء.',
            validator: (v) => _validateDescription(v ?? ''),
          ),
          const SizedBox(height: AppSpacing.small),
          _LogoField(
            fieldKey: _logoKey,
            controller: _logoCtrl,
            focusNode: _logoFocus,
            enabled: enabled && widget.canEdit && !widget.isUploadingLogo,
            readOnly: !widget.canEdit,
            isUploading: widget.isUploadingLogo,
            errorText: _logoError,
            showUrlField: _showLogoUrlField,
            onToggleUrlField: () =>
                setState(() => _showLogoUrlField = !_showLogoUrlField),
            onChanged: () => setState(() {}),
            onPick: _pickLogo,
            onClear: () => setState(() {
              _logoCtrl.clear();
              _logoError = null;
            }),
            validator: (v) => _validateLogoUrl(v ?? ''),
          ),
          const SizedBox(height: AppSpacing.medium),
          OfficeMarketplacePreview(
            name: _nameCtrl.text,
            description: _descriptionCtrl.text,
            logoUrl: _logoCtrl.text,
            serviceAreas: _serviceAreas,
            rating: widget.profile.rating,
            ratingsCount: widget.profile.ratingsCount,
            isListed: widget.profile.isListed,
          ),
        ],
      ),
    );
  }

  Widget _contactSection(bool enabled) {
    return DashboardFormSection(
      icon: Icons.contact_phone_outlined,
      title: _contact,
      subtitle: 'كيف يصل إليك العميل خارج التطبيق.',
      filled: _cardFilled(_contact),
      total: _cardTotal(_contact),
      child: DashboardFieldGrid(
        children: [
          DashboardFormField(
            key: _phoneKey,
            controller: _phoneCtrl,
            focusNode: _phoneFocus,
            nextFocus: _emailFocus,
            enabled: enabled,
            readOnly: !widget.canEdit,
            isRequired: false,
            label: 'رقم التواصل',
            icon: Icons.phone_in_talk_outlined,
            hint: 'مثال: 01012345678',
            helper: 'يظهر للعملاء للتواصل مع المكتب.',
            keyboardType: TextInputType.phone,
            validator: (v) => _validatePhone(v ?? ''),
          ),
          DashboardFormField(
            key: _emailKey,
            controller: _emailCtrl,
            focusNode: _emailFocus,
            enabled: enabled,
            readOnly: !widget.canEdit,
            isRequired: false,
            label: 'البريد الإلكتروني',
            icon: Icons.alternate_email_rounded,
            hint: 'مثال: info@office.com',
            helper: 'اختياري — للمراسلات الرسمية، ولا يظهر في بطاقة السوق.',
            keyboardType: TextInputType.emailAddress,
            validator: (v) => _validateEmail(v ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _coverageSection(bool enabled) {
    return DashboardFormSection(
      icon: Icons.map_outlined,
      title: _coverage,
      subtitle: 'المحافظات والمناطق التي يخدمها المكتب — بها يجدك العملاء.',
      filled: _cardFilled(_coverage),
      total: _cardTotal(_coverage),
      child: _ServiceAreasEditor(
        anchorKey: _areasKey,
        areas: _serviceAreas,
        controller: _areaCtrl,
        focusNode: _areaFocus,
        enabled: enabled,
        isAdding: _addingArea,
        onStartAdding: () {
          setState(() => _addingArea = true);
          _areaFocus.requestFocus();
        },
        onStopAdding: () => setState(() {
          _addingArea = false;
          _areaCtrl.clear();
        }),
        onAdd: _addArea,
        onRemove: (area) => setState(() => _serviceAreas.remove(area)),
      ),
    );
  }
}

/// The office's public identifier, shown where the name is edited so it is
/// obvious the two are different things — and that only one of them moves.
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
          border: Border.all(color: DashboardColors.border(context)),
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
    final tone = context.status(AppStatusTone.neutral);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 20, color: tone.ink),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'العرض فقط — تعديل بيانات المكتب متاح لحساب المالك.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tone.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// The docked save row: what the button is about to do on one side, the button
/// on the other, and an unmistakable marker while anything is unsaved.
///
/// The module has no route of its own — a sidebar click tears it down without
/// asking — so "you have unsaved changes" has to be visible *while* editing
/// rather than only in a prompt on the way out.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isSaving,
    required this.hasChanges,
    required this.hint,
    required this.onSave,
  });

  final bool isSaving;
  final bool hasChanges;
  final String hint;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tone = context.status(AppStatusTone.warning);

    final status = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasChanges && !isSaving) ...[
          Container(
            padding: AppSpacing.chip,
            decoration: BoxDecoration(
              color: tone.tint,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              border: Border.all(color: tone.ink.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_note_rounded, size: 15, color: tone.ink),
                const SizedBox(width: 4),
                Text(
                  'تغييرات غير محفوظة',
                  style: text.labelSmall?.copyWith(
                    color: tone.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xSmall),
        ],
        Text(
          isSaving ? 'جارٍ حفظ بيانات المكتب...' : hint,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    final save = FilledButton.icon(
      onPressed: isSaving ? null : onSave,
      icon: isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_rounded),
      label: Text(isSaving ? 'جارٍ الحفظ...' : 'حفظ بيانات المكتب'),
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          if (constraints.maxWidth >= 520 * scale) {
            return Row(
              children: [
                Expanded(child: status),
                const SizedBox(width: AppSpacing.medium),
                save,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              status,
              const SizedBox(height: AppSpacing.small),
              save,
            ],
          );
        },
      ),
    );
  }
}

/// The office logo: upload a file, or — folded away — paste a link.
///
/// Uploading is the primary path: it puts the image in the platform's own
/// `office-logos` bucket, so the marketplace card cannot go blank because some
/// third-party host expired. The URL field stays because offices onboarded
/// before the bucket existed already hold external links, and because it is
/// where an uploaded file's resulting URL lands: one value, two ways to fill it.
///
/// The preview renders whatever the field currently holds, so a broken link is
/// visible before saving rather than after a client reports an empty card.
class _LogoField extends StatelessWidget {
  const _LogoField({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.readOnly,
    required this.isUploading,
    required this.errorText,
    required this.showUrlField,
    required this.onToggleUrlField,
    required this.onChanged,
    required this.onPick,
    required this.onClear,
    required this.validator,
  });

  final GlobalKey fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool readOnly;
  final bool isUploading;
  final String? errorText;
  final bool showUrlField;
  final VoidCallback onToggleUrlField;
  final VoidCallback onChanged;
  final Future<void> Function() onPick;
  final VoidCallback onClear;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final url = controller.text.trim();

    return Column(
      key: fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'شعار المكتب',
          style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.small),
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
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.error,
                          ),
                        ),
                      if (enabled)
                        TextButton.icon(
                          onPressed: onToggleUrlField,
                          icon: Icon(
                            showUrlField
                                ? Icons.expand_less_rounded
                                : Icons.link_rounded,
                            size: 18,
                          ),
                          label: Text(
                            showUrlField ? 'إخفاء الرابط' : 'استخدام رابط',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    'PNG أو JPG أو WEBP بحد أقصى 2 ميجابايت. '
                    'الصورة تُحفظ مع بيانات المكتب عند الضغط على حفظ.',
                    style: text.bodySmall?.copyWith(
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
            style: text.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
        if (showUrlField) ...[
          const SizedBox(height: AppSpacing.medium),
          DashboardFormField(
            controller: controller,
            focusNode: focusNode,
            // A reader still gets the URL at full contrast; only an owner
            // mid-save has it greyed out.
            enabled: readOnly || enabled,
            readOnly: readOnly,
            isRequired: false,
            label: 'رابط شعار المكتب',
            icon: Icons.link_rounded,
            helper:
                'يُملأ تلقائياً بعد الرفع، أو الصق رابطاً مباشراً يبدأ بـ https.',
            keyboardType: TextInputType.url,
            onChanged: (_) => onChanged(),
            validator: validator,
          ),
        ],
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

    return Container(
      width: 84,
      height: 84,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: isUploading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : url.isEmpty
          ? Icon(
              Icons.storefront_outlined,
              color: scheme.onSurfaceVariant,
              size: 28,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.broken_image_outlined, color: scheme.error),
            ),
    );
  }
}

/// Service areas as a row of removable chips, with the input appearing only
/// while something is being added.
///
/// A permanently open text box at the end of the row reads as an unfinished
/// field; the dashed «إضافة منطقة» chip reads as what it is — one more item in
/// a list the operator is building.
class _ServiceAreasEditor extends StatelessWidget {
  const _ServiceAreasEditor({
    required this.anchorKey,
    required this.areas,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isAdding,
    required this.onStartAdding,
    required this.onStopAdding,
    required this.onAdd,
    required this.onRemove,
  });

  final GlobalKey anchorKey;
  final List<String> areas;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isAdding;
  final VoidCallback onStartAdding;
  final VoidCallback onStopAdding;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      key: anchorKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (areas.isEmpty && !isAdding)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.small),
            child: Text(
              'لم تُضف أي مناطق بعد — بدونها لا يجدك العميل عند البحث بالمنطقة، '
              'ولا يمكن نشر المكتب في السوق.',
              style: text.bodySmall?.copyWith(
                color: context.status(AppStatusTone.warning).ink,
              ),
            ),
          ),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final area in areas)
              InputChip(
                label: Text(area),
                onDeleted: enabled ? () => onRemove(area) : null,
                deleteIcon: const Icon(Icons.close_rounded, size: 18),
              ),
            if (enabled && !isAdding)
              _AddAreaChip(onTap: onStartAdding)
            else if (enabled)
              SizedBox(
                width: 240,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onAdd(),
                  onTapOutside: (_) {
                    if (controller.text.trim().isEmpty) onStopAdding();
                  },
                  decoration: InputDecoration(
                    hintText: 'مثال: القاهرة',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'إضافة',
                      onPressed: onAdd,
                      icon: const Icon(Icons.check_rounded, size: 20),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (areas.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          Text(
            '${areas.length} منطقة خدمة',
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _AddAreaChip extends StatelessWidget {
  const _AddAreaChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          border: Border.all(
            color: scheme.primary.withAlpha(110),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              'إضافة منطقة',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
