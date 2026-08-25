import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_dialog_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/forms/forms.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_input_formatters.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_validators.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/pending_fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_documents_inline_section.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/core/theme/spacing.dart';

/// Create/edit a driver: one page, four bands, no wizard.
///
/// Built on the console's shared form kit so it validates, counts and recovers
/// the same way the vehicle, trip and route forms do. Three behaviours are the
/// point of it:
///
/// * **Nothing is discovered at save time.** Required fields are marked before
///   the operator commits, uniqueness is checked against the drivers already
///   loaded in the workspace rather than by waiting for the database to
///   refuse, and a failed submit lists every outstanding field as a button
///   that scrolls to it.
/// * **The whole form is fillable from the keyboard.** Every text field hands
///   focus to the next one.
/// * **Unsaved work is hard to lose.** Dirty state is a comparison against the
///   values the form opened with, not a flag that latches on the first
///   keystroke — typing a character and deleting it again leaves the dialog
///   closeable without a prompt.
class FleetDriverFormView extends StatefulWidget {
  final FleetDriver? driver;
  final FleetWorkspace workspace;
  final VoidCallback onBack;

  /// Persists the driver. Returns `null` on success (the dialog is closed by
  /// the caller) or an error message to show inline so the user can fix the
  /// data and retry without losing their input.
  final Future<String?> Function(
    FleetDriver driver,
    List<PendingFleetDocument> docs,
  )
  onSave;

  const FleetDriverFormView({
    super.key,
    this.driver,
    required this.workspace,
    required this.onBack,
    required this.onSave,
  });

  @override
  State<FleetDriverFormView> createState() => _FleetDriverFormViewState();
}

class _FleetDriverFormViewState extends State<FleetDriverFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController nationalId;
  late final TextEditingController license;
  late final TextEditingController expiry;
  late final TextEditingController address;
  late final TextEditingController emergency;
  late final TextEditingController employeeCode;
  late final TextEditingController hireDate;
  late final TextEditingController notes;
  String? selectedVehicleId;

  final _nameFocus = FocusNode();
  final _nationalIdFocus = FocusNode();
  final _employeeCodeFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emergencyFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _licenseFocus = FocusNode();
  final _expiryFocus = FocusNode();
  final _hireDateFocus = FocusNode();
  final _notesFocus = FocusNode();

  final _nameKey = GlobalKey();
  final _nationalIdKey = GlobalKey();
  final _employeeCodeKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _emergencyKey = GlobalKey();
  final _addressKey = GlobalKey();
  final _licenseKey = GlobalKey();
  final _expiryKey = GlobalKey();
  final _hireDateKey = GlobalKey();

  late final DashboardFormController _form;
  late final String _openingSignature;

  List<PendingFleetDocument> _pendingDocs = const [];
  String _globalError = '';
  bool _showIssues = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    name = TextEditingController(text: d?.fullName ?? '');
    phone = TextEditingController(text: d?.phone ?? '');
    nationalId = TextEditingController(text: d?.nationalId ?? '');
    license = TextEditingController(text: d?.licenseNumber ?? '');
    expiry = TextEditingController(text: d?.licenseExpiryDate ?? '');
    address = TextEditingController(text: d?.address ?? '');
    emergency = TextEditingController(text: d?.emergencyPhone ?? '');
    employeeCode = TextEditingController(text: d?.employeeCode ?? '');
    hireDate = TextEditingController(text: d?.hireDate ?? '');
    notes = TextEditingController(text: d?.notes ?? '');
    selectedVehicleId = d?.currentVehicleId.isNotEmpty == true
        ? d!.currentVehicleId
        : null;

    _form = DashboardFormController([
      DashboardFormFieldSpec(
        id: 'name',
        label: 'الاسم الكامل',
        section: _personal,
        anchorKey: _nameKey,
        focusNode: _nameFocus,
        validate: () => _validateName(name.text),
      ),
      DashboardFormFieldSpec(
        id: 'nationalId',
        label: 'الرقم القومي',
        section: _personal,
        anchorKey: _nationalIdKey,
        focusNode: _nationalIdFocus,
        validate: () => _validateNationalId(nationalId.text),
      ),
      DashboardFormFieldSpec(
        id: 'employeeCode',
        label: 'كود الموظف',
        section: _personal,
        anchorKey: _employeeCodeKey,
        focusNode: _employeeCodeFocus,
        validate: () => _validateEmployeeCode(employeeCode.text),
      ),
      DashboardFormFieldSpec(
        id: 'phone',
        label: 'رقم الهاتف',
        section: _contact,
        anchorKey: _phoneKey,
        focusNode: _phoneFocus,
        validate: () => _validatePhone(phone.text),
      ),
      DashboardFormFieldSpec(
        id: 'emergency',
        label: 'رقم الطوارئ',
        section: _contact,
        anchorKey: _emergencyKey,
        focusNode: _emergencyFocus,
        validate: () => _validateEmergency(emergency.text),
      ),
      DashboardFormFieldSpec(
        id: 'address',
        label: 'العنوان السكني',
        section: _contact,
        anchorKey: _addressKey,
        focusNode: _addressFocus,
        validate: () => _validateAddress(address.text),
      ),
      DashboardFormFieldSpec(
        id: 'license',
        label: 'رقم رخصة القيادة',
        section: _licence,
        anchorKey: _licenseKey,
        focusNode: _licenseFocus,
        validate: () => _validateLicense(license.text),
      ),
      DashboardFormFieldSpec(
        id: 'expiry',
        label: 'انتهاء صلاحية الرخصة',
        section: _licence,
        anchorKey: _expiryKey,
        focusNode: _expiryFocus,
        validate: () => _validateExpiry(expiry.text),
      ),
      DashboardFormFieldSpec(
        id: 'hireDate',
        label: 'تاريخ التعيين',
        section: _licence,
        anchorKey: _hireDateKey,
        focusNode: _hireDateFocus,
        validate: () => _validateHireDate(hireDate.text),
      ),
    ]);

    _openingSignature = _signature;
  }

  static const _personal = 'البيانات الشخصية';
  static const _contact = 'بيانات الاتصال';
  static const _licence = 'الرخصة والتعيين';

  @override
  void dispose() {
    for (final c in [
      name,
      phone,
      nationalId,
      license,
      expiry,
      address,
      emergency,
      employeeCode,
      hireDate,
      notes,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus,
      _nationalIdFocus,
      _employeeCodeFocus,
      _phoneFocus,
      _emergencyFocus,
      _addressFocus,
      _licenseFocus,
      _expiryFocus,
      _hireDateFocus,
      _notesFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------- validation
  //
  // Every rule lives here once and is read from two places: the field's own
  // `validator` (for the inline error) and its [DashboardFormFieldSpec] (for
  // the summary and the completion counter). One definition, so the three can
  // never disagree about whether a field is acceptable.

  String? _validateName(String value) => FleetValidators.validateName(value);

  String? _validateNationalId(String value) {
    final base = FleetValidators.validateNationalId(value);
    if (base != null) return base;
    return _duplicate(
      value,
      (driver) => driver.nationalId,
      'هذا الرقم القومي مسجّل بالفعل لسائق آخر في المكتب',
    );
  }

  String? _validateEmployeeCode(String value) {
    final base = FleetValidators.validateEmployeeCode(value);
    if (base != null) return base;
    return _duplicate(
      value,
      (driver) => driver.employeeCode,
      'كود الموظف مستخدم بالفعل — اختر كوداً آخر',
    );
  }

  String? _validatePhone(String value) {
    final base = FleetValidators.validatePhone(value, 'رقم الهاتف');
    if (base != null) return base;
    return _duplicate(
      value,
      (driver) => driver.phone,
      'رقم الهاتف مسجّل بالفعل لسائق آخر',
    );
  }

  String? _validateEmergency(String value) {
    final base = FleetValidators.validatePhone(value, 'رقم هاتف الطوارئ');
    if (base != null) return base;
    if (phone.text.trim() == value.trim()) {
      return 'رقم الطوارئ لا يمكن أن يكون نفس الرقم الأساسي';
    }
    return null;
  }

  String? _validateAddress(String value) =>
      value.trim().isEmpty ? 'العنوان السكني مطلوب' : null;

  String? _validateLicense(String value) {
    final base = FleetValidators.validateLicenseNumber(value);
    if (base != null) return base;
    return _duplicate(
      value,
      (driver) => driver.licenseNumber,
      'رقم الرخصة مسجّل بالفعل لسائق آخر',
    );
  }

  /// An expired licence is refused outright rather than warned about: a driver
  /// whose licence has run out cannot legally be dispatched, and letting the
  /// record be saved as-is is what produces a fleet that looks compliant and
  /// is not.
  String? _validateExpiry(String value) {
    final base = FleetValidators.validateDate(value, 'تاريخ انتهاء الرخصة');
    if (base != null) return base;
    final date = DateTime.parse(value.trim());
    final today = DateTime.now();
    if (date.isBefore(DateTime(today.year, today.month, today.day))) {
      return 'الرخصة منتهية — لا يمكن تشغيل سائق برخصة منتهية';
    }
    return null;
  }

  String? _validateHireDate(String value) {
    final base = FleetValidators.validateDate(value, 'تاريخ التعيين');
    if (base != null) return base;
    final date = DateTime.parse(value.trim());
    if (date.isAfter(DateTime.now())) {
      return 'تاريخ التعيين لا يمكن أن يكون في المستقبل';
    }
    return null;
  }

  /// Uniqueness checked against the drivers already in the workspace.
  ///
  /// The database has the final word — this only spares the operator a round
  /// trip and an opaque constraint error for a clash the app can already see.
  String? _duplicate(
    String value,
    String Function(FleetDriver) field,
    String message,
  ) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    final clashes = widget.workspace.drivers.any(
      (driver) =>
          driver.id != widget.driver?.id &&
          field(driver).trim().toLowerCase() == trimmed,
    );
    return clashes ? message : null;
  }

  /// How close a licence is to running out, said in the field itself so it is
  /// visible while the date is being chosen rather than only in the fleet's
  /// expiry report weeks later.
  String? _expiryNotice() {
    final date = DateTime.tryParse(expiry.text.trim());
    if (date == null) return null;
    final days = date.difference(DateTime.now()).inDays;
    if (days < 0) return null;
    if (days <= 30) return 'تنبيه: تنتهي خلال $days يوماً — جدّدها قريباً';
    if (days <= 90) return 'تنتهي خلال $days يوماً';
    return null;
  }

  // ------------------------------------------------------------- dirty state

  /// Every value the form can change, flattened. Compared against the same
  /// string taken when the dialog opened, so "has changes" means the data
  /// actually differs — not that a key was pressed.
  String get _signature => [
    name.text,
    phone.text,
    nationalId.text,
    license.text,
    expiry.text,
    address.text,
    emergency.text,
    employeeCode.text,
    hireDate.text,
    notes.text,
    selectedVehicleId ?? '',
  ].join('|');

  bool get _hasChanges =>
      _signature != _openingSignature || _pendingDocs.isNotEmpty;

  List<FleetVehicle> _availableVehicles() {
    return widget.workspace.vehicles.where((v) {
      if (v.status != FleetVehicleStatus.active) return false;
      final hasExpiredDocs = widget.workspace.documents.any(
        (d) => d.ownerId == v.id && d.status == FleetDocumentStatus.expired,
      );
      if (hasExpiredDocs) return false;
      final isAssignedToOther = widget.workspace.assignments.any(
        (a) =>
            a.vehicleId == v.id &&
            a.status == FleetAssignmentStatus.active &&
            a.driverId != widget.driver?.id,
      );
      return !isAssignedToOther;
    }).toList();
  }

  int _sectionFilled(String section) => _form.fields
      .where((f) => f.section == section && f.validate() == null)
      .length;

  int _sectionTotal(String section) =>
      _form.fields.where((f) => f.section == section).length;

  // ----------------------------------------------------------------- actions

  Future<void> _handleBack() async {
    if (_saving) return;
    if (!_hasChanges) {
      widget.onBack();
      return;
    }
    final discard = await confirmDiscardChanges(context);
    if (discard && mounted) widget.onBack();
  }

  Future<void> _onSave() async {
    if (_saving) return;
    setState(() => _globalError = '');

    final inlineValid = _formKey.currentState!.validate();
    if (!inlineValid || !_form.isValid) {
      setState(() => _showIssues = true);
      await _form.jumpToFirstIssue();
      return;
    }

    final existing = widget.driver;
    final driver = FleetDriver(
      id: existing?.id ?? '',
      employeeCode: employeeCode.text.trim(),
      fullName: name.text.trim(),
      phone: phone.text.trim(),
      emergencyPhone: emergency.text.trim(),
      address: address.text.trim(),
      nationalId: nationalId.text.trim(),
      profileImageUrl: existing?.profileImageUrl ?? '',
      licenseNumber: license.text.trim(),
      licenseExpiryDate: expiry.text.trim(),
      hireDate: hireDate.text.trim(),
      notes: notes.text.trim(),
      status: existing?.status ?? FleetDriverStatus.active,
      currentVehicleId: selectedVehicleId ?? '',
      tripHistory: existing?.tripHistory ?? const [],
      vehicleHistory: existing?.vehicleHistory ?? const [],
      documents: existing?.documents ?? const [],
      completedTripsCount: existing?.completedTripsCount ?? 0,
      cancelledTripsCount: existing?.cancelledTripsCount ?? 0,
      rating: existing?.rating ?? 0,
      ratingCount: existing?.ratingCount ?? 0,
    );

    setState(() => _saving = true);
    final error = await widget.onSave(driver, _pendingDocs);

    if (!mounted) return;
    setState(() {
      _saving = false;
      if (error != null) {
        _globalError = error;
        _showIssues = true;
      }
    });
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.driver != null;
    final vehicles = _availableVehicles();
    final issues = _showIssues ? _form.issues : const <DashboardFormIssue>[];

    return PopScope(
      canPop: !_hasChanges && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            children: [
              DashboardDialogHeader(
                icon: isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                title: isEdit
                    ? 'تعديل السائق: ${widget.driver!.name}'
                    : 'إضافة سائق جديد',
                description: isEdit
                    ? 'عدّل بيانات السائق ومستنداته، ثم احفظ.'
                    : 'الحقول المعلّمة بـ * مطلوبة لتشغيل السائق على الرحلات.',
                onClose: _saving ? null : _handleBack,
              ),
              const DashboardDialogDivider(),
              Expanded(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  // Rebuilds on every keystroke so the section badges and the
                  // completion track answer while the operator types, not only
                  // once they try to save.
                  onChanged: () => setState(() {}),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (issues.isNotEmpty || _globalError.isNotEmpty) ...[
                          DashboardFormIssuesBanner(
                            issues: issues,
                            message: _globalError,
                            onJumpTo: _form.jumpTo,
                          ),
                          const SizedBox(height: AppSpacing.large),
                        ],
                        _personalSection(),
                        const SizedBox(height: AppSpacing.large),
                        _contactSection(),
                        const SizedBox(height: AppSpacing.large),
                        _licenceSection(vehicles),
                        const SizedBox(height: AppSpacing.large),
                        FleetDocumentsInlineSection(
                          isDriver: true,
                          existingDocuments:
                              widget.driver?.documents ?? const [],
                          onChanged: (docs) =>
                              setState(() => _pendingDocs = docs),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: FleetFormActionsBar(
                  saving: _saving,
                  onCancel: _handleBack,
                  onSave: _onSave,
                  saveLabel: isEdit ? 'حفظ التعديلات' : 'حفظ السائق',
                  requiredFilled: _form.requiredFilled,
                  requiredTotal: _form.requiredTotal,
                  hint: _actionHint(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Names the next thing to do, rather than repeating "review your data".
  String _actionHint() {
    final outstanding = _form.issues;
    if (outstanding.isEmpty) {
      return 'كل البيانات المطلوبة مكتملة — يمكنك الحفظ.';
    }
    if (outstanding.length == 1) {
      return 'متبقٍ: ${outstanding.first.label}';
    }
    return 'متبقٍ ${outstanding.length} حقول، أولها: ${outstanding.first.label}';
  }

  Widget _personalSection() {
    return DashboardFormSection(
      icon: Icons.person_outline_rounded,
      title: _personal,
      subtitle: 'هوية السائق كما ستظهر في التشغيل وملفات الموظفين.',
      filled: _sectionFilled(_personal),
      total: _sectionTotal(_personal),
      child: DashboardFieldGrid(
        children: [
          DashboardFormField(
            key: _nameKey,
            controller: name,
            focusNode: _nameFocus,
            nextFocus: _nationalIdFocus,
            autofocus: widget.driver == null,
            label: 'الاسم الكامل',
            icon: Icons.person_outline_rounded,
            hint: 'مثال: محمد أحمد إبراهيم',
            helper: 'ثنائي على الأقل، كما هو مكتوب في الرقم القومي.',
            validator: (v) => _validateName(v ?? ''),
          ),
          DashboardFormField(
            key: _nationalIdKey,
            controller: nationalId,
            focusNode: _nationalIdFocus,
            nextFocus: _employeeCodeFocus,
            label: 'الرقم القومي',
            icon: Icons.badge_outlined,
            hint: 'مثال: 29001011234567',
            helper: '14 رقماً. يمنع تسجيل السائق نفسه مرتين.',
            keyboardType: TextInputType.number,
            inputFormatters: FleetInputFormatters.nationalId,
            validator: (v) => _validateNationalId(v ?? ''),
          ),
          DashboardFormField(
            key: _employeeCodeKey,
            controller: employeeCode,
            focusNode: _employeeCodeFocus,
            nextFocus: _phoneFocus,
            label: 'كود الموظف',
            icon: Icons.vpn_key_outlined,
            hint: 'مثال: EMP-101',
            helper: 'معرّف داخلي فريد داخل المكتب، 3 رموز فأكثر.',
            textCapitalization: TextCapitalization.characters,
            validator: (v) => _validateEmployeeCode(v ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _contactSection() {
    return DashboardFormSection(
      icon: Icons.contact_phone_outlined,
      title: 'بيانات الاتصال والعنوان',
      subtitle: 'كيف تصل إلى السائق أثناء الرحلة وعند الطوارئ.',
      filled: _sectionFilled(_contact),
      total: _sectionTotal(_contact),
      child: DashboardFieldGrid(
        children: [
          DashboardFormField(
            key: _phoneKey,
            controller: phone,
            focusNode: _phoneFocus,
            nextFocus: _emergencyFocus,
            label: 'رقم الهاتف',
            icon: Icons.phone_android_rounded,
            hint: 'مثال: 01012345678',
            helper: '11 رقماً يبدأ بـ 010 أو 011 أو 012 أو 015.',
            keyboardType: TextInputType.phone,
            inputFormatters: FleetInputFormatters.egyptianPhone,
            validator: (v) => _validatePhone(v ?? ''),
          ),
          DashboardFormField(
            key: _emergencyKey,
            controller: emergency,
            focusNode: _emergencyFocus,
            nextFocus: _addressFocus,
            label: 'رقم الطوارئ',
            icon: Icons.contact_phone_outlined,
            hint: 'مثال: 01112345678',
            helper: 'رقم بديل يختلف عن الأساسي، للتواصل عند تعذّر الوصول.',
            keyboardType: TextInputType.phone,
            inputFormatters: FleetInputFormatters.egyptianPhone,
            validator: (v) => _validateEmergency(v ?? ''),
          ),
          DashboardFormField(
            key: _addressKey,
            controller: address,
            focusNode: _addressFocus,
            nextFocus: _licenseFocus,
            label: 'العنوان السكني',
            icon: Icons.home_outlined,
            hint: 'مثال: القليوبية، بنها، شارع الجمهورية',
            helper: 'يُستخدم في ملف الموظف والتحقق من بياناته.',
            validator: (v) => _validateAddress(v ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _licenceSection(List<FleetVehicle> vehicles) {
    return DashboardFormSection(
      icon: Icons.card_membership_rounded,
      title: _licence,
      subtitle: 'صلاحية القيادة، تاريخ الالتحاق، والمركبة المخصصة.',
      filled: _sectionFilled(_licence),
      total: _sectionTotal(_licence),
      child: Column(
        children: [
          DashboardFieldGrid(
            children: [
              DashboardFormField(
                key: _licenseKey,
                controller: license,
                focusNode: _licenseFocus,
                nextFocus: _notesFocus,
                label: 'رقم رخصة القيادة',
                icon: Icons.card_membership_rounded,
                helper: 'كما هو مدوّن في الرخصة، 4 رموز فأكثر.',
                validator: (v) => _validateLicense(v ?? ''),
              ),
              DashboardDateFormField(
                key: _expiryKey,
                controller: expiry,
                focusNode: _expiryFocus,
                label: 'انتهاء صلاحية الرخصة',
                helper: _expiryNotice(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                validator: (v) => _validateExpiry(v ?? ''),
                onPicked: (value) => setState(() => expiry.text = value),
              ),
              DashboardDateFormField(
                key: _hireDateKey,
                controller: hireDate,
                focusNode: _hireDateFocus,
                label: 'تاريخ التعيين',
                firstDate: DateTime.now().subtract(
                  const Duration(days: 365 * 40),
                ),
                lastDate: DateTime.now(),
                validator: (v) => _validateHireDate(v ?? ''),
                onPicked: (value) => setState(() => hireDate.text = value),
              ),
              DashboardDropdownFormField<String>(
                value: selectedVehicleId,
                label: 'المركبة المخصصة',
                icon: Icons.directions_car_rounded,
                isRequired: false,
                helper: vehicles.isEmpty
                    ? 'لا توجد مركبات متاحة للتخصيص حالياً.'
                    : 'اختياري الآن — يمكن ربط السائق بمركبة لاحقاً.',
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('بدون مركبة'),
                  ),
                  ...vehicles.map(
                    (v) => DropdownMenuItem<String>(
                      value: v.id,
                      child: Text(
                        '${v.vehicleCode} • ${v.plateNumber}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => selectedVehicleId = val),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          DashboardFormField(
            controller: notes,
            focusNode: _notesFocus,
            label: 'ملاحظات',
            icon: Icons.notes_rounded,
            isRequired: false,
            maxLines: 3,
            hint: 'أي ملاحظة تشغيلية عن هذا السائق',
            helper: 'داخلية — لا تظهر للعميل.',
          ),
        ],
      ),
    );
  }
}
