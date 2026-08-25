import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_dialog_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/forms/forms.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_seat_layout_visualizer.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_input_formatters.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_upload_helpers.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_validators.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/vehicle_seat_configuration.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/pending_fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_documents_inline_section.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';

/// Create/edit a vehicle.
///
/// The sibling of [FleetDriverFormView] and built on the same form kit, with
/// one thing that is particular to a bus: **the cabin is drawn while it is
/// being described.** Type and capacity sit directly above a live seat map
/// rendered from the exact configuration that will be persisted, so a wrong
/// vehicle type is caught by looking at it rather than by a rider later
/// finding a seat that does not exist.
///
/// Codes and plates are checked for collision against the vehicles already in
/// the workspace before submitting — the database enforces uniqueness, but
/// discovering it from a constraint error after uploading four photos is not
/// an acceptable way to be told.
class FleetVehicleFormView extends StatefulWidget {
  final FleetVehicle? vehicle;
  final FleetWorkspace workspace;
  final VoidCallback onBack;

  /// Persists the vehicle. Returns `null` on success (the dialog is closed by
  /// the caller) or an error message to show inline so the user can fix the
  /// data and retry without losing their input.
  final Future<String?> Function(
    FleetVehicle vehicle,
    List<PendingFleetDocument> docs,
  )
  onSave;

  /// Uploads a picked file to Supabase Storage and returns its public URL, or
  /// `null` on failure. Passed in so the form stays decoupled from the cubit
  /// provider scope (the dialog is mounted above that scope in the tree).
  final Future<String?> Function(String bucket, String path, List<int> bytes)
  onUploadFile;

  const FleetVehicleFormView({
    super.key,
    this.vehicle,
    required this.workspace,
    required this.onBack,
    required this.onSave,
    required this.onUploadFile,
  });

  @override
  State<FleetVehicleFormView> createState() => _FleetVehicleFormViewState();
}

class _FleetVehicleFormViewState extends State<FleetVehicleFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController code;
  late final TextEditingController plate;
  late final TextEditingController model;
  late final TextEditingController year;
  late final TextEditingController seats;
  late final TextEditingController brand;
  late final TextEditingController color;
  late final TextEditingController notes;

  final _codeFocus = FocusNode();
  final _plateFocus = FocusNode();
  final _brandFocus = FocusNode();
  final _modelFocus = FocusNode();
  final _yearFocus = FocusNode();
  final _seatsFocus = FocusNode();
  final _colorFocus = FocusNode();
  final _notesFocus = FocusNode();

  final _codeKey = GlobalKey();
  final _plateKey = GlobalKey();
  final _brandKey = GlobalKey();
  final _modelKey = GlobalKey();
  final _yearKey = GlobalKey();
  final _seatsKey = GlobalKey();
  final _colorKey = GlobalKey();
  final _driverKey = GlobalKey();

  late final DashboardFormController _form;
  late final String _openingSignature;

  VehicleType vehicleType = VehicleType.coaster;
  String seatLayoutType = 'standard';
  String? selectedDriverId;

  List<String> _existingImageUrls = [];
  final List<PlatformFile> _newPickedFiles = [];
  final List<List<int>> _newPickedBytes = [];
  List<PendingFleetDocument> _pendingDocs = const [];

  String _globalError = '';
  bool _showIssues = false;
  bool _saving = false;

  static const _identity = 'بيانات المركبة';
  static const _cabin = 'النوع والسعة';
  static const _driverSection = 'السائق المعين';

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    code = TextEditingController(text: v?.vehicleCode ?? '');
    plate = TextEditingController(text: v?.plateNumber ?? '');
    model = TextEditingController(text: v?.model ?? '');
    year = TextEditingController(text: v == null ? '' : '${v.manufactureYear}');
    seats = TextEditingController(text: v == null ? '' : '${v.capacity}');
    if (v != null) vehicleType = VehicleTypeParser.fromDatabase(v.vehicleType);
    _applyTypeCapacity();
    brand = TextEditingController(text: v?.brand ?? '');
    color = TextEditingController(text: v?.color ?? '');
    notes = TextEditingController(text: v?.notes ?? '');
    if (v != null && v.imageUrl.isNotEmpty) {
      _existingImageUrls = v.imageUrl
          .split(',')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList();
    } else {
      _existingImageUrls = [];
    }

    if (v != null) {
      seatLayoutType = 'standard';
    }

    selectedDriverId = v?.currentDriverId.isNotEmpty == true
        ? v!.currentDriverId
        : null;

    _form = DashboardFormController([
      DashboardFormFieldSpec(
        id: 'code',
        label: 'كود المركبة',
        section: _identity,
        anchorKey: _codeKey,
        focusNode: _codeFocus,
        validate: () => _validateCode(code.text),
      ),
      DashboardFormFieldSpec(
        id: 'plate',
        label: 'رقم اللوحة',
        section: _identity,
        anchorKey: _plateKey,
        focusNode: _plateFocus,
        validate: () => _validatePlate(plate.text),
      ),
      DashboardFormFieldSpec(
        id: 'brand',
        label: 'الماركة',
        section: _identity,
        anchorKey: _brandKey,
        focusNode: _brandFocus,
        validate: () => brand.text.trim().isEmpty ? 'اسم الماركة مطلوب' : null,
      ),
      DashboardFormFieldSpec(
        id: 'model',
        label: 'الموديل',
        section: _identity,
        anchorKey: _modelKey,
        focusNode: _modelFocus,
        validate: () =>
            model.text.trim().isEmpty ? 'اسم طراز الموديل مطلوب' : null,
      ),
      DashboardFormFieldSpec(
        id: 'year',
        label: 'سنة الصنع',
        section: _identity,
        anchorKey: _yearKey,
        focusNode: _yearFocus,
        validate: () => FleetValidators.validateManufactureYear(year.text),
      ),
      DashboardFormFieldSpec(
        id: 'color',
        label: 'لون المركبة',
        section: _identity,
        anchorKey: _colorKey,
        focusNode: _colorFocus,
        validate: () => color.text.trim().isEmpty ? 'لون الهيكل مطلوب' : null,
      ),
      DashboardFormFieldSpec(
        id: 'seats',
        label: 'السعة الركابية',
        section: _cabin,
        anchorKey: _seatsKey,
        focusNode: _seatsFocus,
        validate: () => FleetValidators.validateCapacity(seats.text),
      ),
      DashboardFormFieldSpec(
        id: 'driver',
        label: 'السائق',
        section: _driverSection,
        anchorKey: _driverKey,
        validate: () => (selectedDriverId == null || selectedDriverId!.isEmpty)
            ? 'يجب تعيين سائق للمركبة'
            : null,
      ),
    ]);

    _openingSignature = _signature;
  }

  @override
  void dispose() {
    for (final c in [code, plate, model, year, seats, brand, color, notes]) {
      c.dispose();
    }
    for (final f in [
      _codeFocus,
      _plateFocus,
      _brandFocus,
      _modelFocus,
      _yearFocus,
      _seatsFocus,
      _colorFocus,
      _notesFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------- validation

  String? _validateCode(String value) {
    final base = FleetValidators.validateVehicleCode(value);
    if (base != null) return base;
    return _duplicate(
      value,
      (v) => v.vehicleCode,
      'كود المركبة مستخدم بالفعل — اختر كوداً آخر',
    );
  }

  String? _validatePlate(String value) {
    final base = FleetValidators.validatePlateNumber(value);
    if (base != null) return base;
    return _duplicate(
      value,
      (v) => v.plateNumber,
      'رقم اللوحة مسجّل بالفعل لمركبة أخرى',
    );
  }

  /// Uniqueness against the vehicles already loaded, so a collision is shown
  /// on the field that caused it instead of arriving as a database error after
  /// the photo uploads have already run.
  String? _duplicate(
    String value,
    String Function(FleetVehicle) field,
    String message,
  ) {
    final trimmed = FleetValidators.normalizeDigits(
      value.trim(),
    ).replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (trimmed.isEmpty) return null;
    final clashes = widget.workspace.vehicles.any((vehicle) {
      if (vehicle.id == widget.vehicle?.id) return false;
      final other = FleetValidators.normalizeDigits(
        field(vehicle).trim(),
      ).replaceAll(RegExp(r'\s+'), '').toLowerCase();
      return other.isNotEmpty && other == trimmed;
    });
    return clashes ? message : null;
  }

  /// A type with a predefined cabin (Hiace, Coaster) owns its capacity, so the
  /// seats field mirrors the blueprint instead of accepting a number that would
  /// disagree with the seat map the Client App draws.
  void _applyTypeCapacity() {
    final fixed = VehicleSeatConfigurator.fixedCapacityFor(vehicleType);
    if (fixed != null) seats.text = '$fixed';
  }

  void _onVehicleTypeChanged(VehicleType? value) {
    if (value == null || value == vehicleType) return;
    setState(() {
      vehicleType = value;
      _applyTypeCapacity();
    });
  }

  /// The configuration that will be saved for the current form state, used both
  /// for the live preview and by [_onSave] — one function, so the preview can
  /// never show a layout different from the one persisted.
  SeatConfiguration _previewSeatConfiguration() {
    final entered = int.tryParse(seats.text.trim()) ?? 0;
    if (entered <= 0) return SeatConfiguration.empty();
    return VehicleSeatConfigurator.resolve(
      type: vehicleType,
      capacity: VehicleSeatConfigurator.capacityFor(vehicleType, entered),
      existing: widget.vehicle?.seatConfiguration,
      existingType: widget.vehicle == null
          ? null
          : VehicleTypeParser.fromDatabase(widget.vehicle!.vehicleType),
    );
  }

  List<FleetDriver> _getAvailableDrivers() {
    return widget.workspace.drivers.where((d) {
      if (d.status != FleetDriverStatus.active) return false;

      final hasExpiredDocs = d.documents.any(
        (doc) => doc.status == FleetDocumentStatus.expired,
      );
      if (hasExpiredDocs) return false;

      final isAssignedToOther = widget.workspace.assignments.any(
        (a) =>
            a.driverId == d.id &&
            a.status == FleetAssignmentStatus.active &&
            a.vehicleId != widget.vehicle?.id,
      );

      return !isAssignedToOther;
    }).toList();
  }

  List<FleetDocument> _vehicleDocuments() {
    final id = widget.vehicle?.id;
    if (id == null || id.isEmpty) return const [];
    return widget.workspace.documents.where((d) => d.ownerId == id).toList();
  }

  // ------------------------------------------------------------- dirty state

  String get _signature => [
    code.text,
    plate.text,
    model.text,
    year.text,
    seats.text,
    brand.text,
    color.text,
    notes.text,
    vehicleType.name,
    seatLayoutType,
    selectedDriverId ?? '',
    _existingImageUrls.join(','),
  ].join('|');

  bool get _hasChanges =>
      _signature != _openingSignature ||
      _newPickedFiles.isNotEmpty ||
      _pendingDocs.isNotEmpty;

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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicle != null;
    final issues = _showIssues ? _form.issues : const <DashboardFormIssue>[];

    return PopScope(
      canPop: !_hasChanges && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              DashboardDialogHeader(
                icon: isEdit
                    ? Icons.edit_rounded
                    : Icons.directions_bus_rounded,
                title: isEdit
                    ? 'تعديل المركبة: ${widget.vehicle!.vehicleNumber}'
                    : 'إضافة مركبة جديدة',
                description: isEdit
                    ? 'عدّل بيانات المركبة وصورها ومستنداتها، ثم احفظ.'
                    : 'الحقول المعلّمة بـ * مطلوبة قبل تشغيل المركبة على الرحلات.',
                onClose: _saving ? null : _handleBack,
              ),
              const DashboardDialogDivider(),
              Expanded(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isDesktop = constraints.maxWidth >= 940;
                            final sideRail = Column(
                              children: [
                                _driverCard(),
                                const SizedBox(height: AppSpacing.large),
                                _imagesCard(),
                              ],
                            );

                            if (isDesktop) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _identityCard(columns: 2),
                                  ),
                                  const SizedBox(width: AppSpacing.large),
                                  Expanded(flex: 3, child: sideRail),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                _identityCard(columns: 1),
                                const SizedBox(height: AppSpacing.large),
                                sideRail,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.large),
                        _cabinCard(),
                        const SizedBox(height: AppSpacing.large),
                        FleetDocumentsInlineSection(
                          isDriver: false,
                          existingDocuments: _vehicleDocuments(),
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
                  saveLabel: isEdit ? 'حفظ التعديلات' : 'إضافة المركبة',
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

  String _actionHint() {
    final outstanding = _form.issues;
    if (outstanding.isEmpty) {
      final photos = _existingImageUrls.length + _newPickedFiles.length;
      return photos == 0
          ? 'جاهزة للحفظ — يمكنك إضافة صور لاحقاً.'
          : 'جاهزة للحفظ مع $photos صورة.';
    }
    if (outstanding.length == 1) return 'متبقٍ: ${outstanding.first.label}';
    return 'متبقٍ ${outstanding.length} حقول، أولها: ${outstanding.first.label}';
  }

  Widget _identityCard({required int columns}) {
    return DashboardFormSection(
      icon: Icons.fact_check_outlined,
      title: _identity,
      subtitle: 'ما يظهر في لوحة التشغيل، التعيينات، وتذكرة الراكب.',
      filled: _sectionFilled(_identity),
      total: _sectionTotal(_identity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardFieldGrid(
            columns: columns,
            breakpoint: columns == 1 ? double.infinity : 420,
            children: [
              DashboardFormField(
                key: _codeKey,
                controller: code,
                focusNode: _codeFocus,
                nextFocus: _plateFocus,
                autofocus: widget.vehicle == null,
                label: 'كود المركبة',
                icon: Icons.directions_bus_rounded,
                hint: 'مثال: BUS-201',
                helper: 'معرّف داخلي فريد داخل المكتب.',
                textCapitalization: TextCapitalization.characters,
                validator: (v) => _validateCode(v ?? ''),
              ),
              DashboardFormField(
                key: _plateKey,
                controller: plate,
                focusNode: _plateFocus,
                nextFocus: _brandFocus,
                label: 'رقم اللوحة',
                icon: Icons.confirmation_number_outlined,
                hint: 'مثال: ٣٣٠٠ ق ل',
                helper: 'أرقام وحروف كما هي على اللوحة، بأي من الخطين.',
                validator: (v) => _validatePlate(v ?? ''),
              ),
              DashboardFormField(
                key: _brandKey,
                controller: brand,
                focusNode: _brandFocus,
                nextFocus: _modelFocus,
                label: 'الماركة',
                icon: Icons.branding_watermark_outlined,
                hint: 'مثال: Toyota / Mercedes',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'اسم الماركة مطلوب'
                    : null,
              ),
              DashboardFormField(
                key: _modelKey,
                controller: model,
                focusNode: _modelFocus,
                nextFocus: _yearFocus,
                label: 'الموديل',
                icon: Icons.model_training_rounded,
                hint: 'مثال: Coaster / Sprinter / Hiace',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'اسم طراز الموديل مطلوب'
                    : null,
              ),
              DashboardFormField(
                key: _yearKey,
                controller: year,
                focusNode: _yearFocus,
                nextFocus: _colorFocus,
                label: 'سنة الصنع',
                icon: Icons.calendar_today_rounded,
                hint: 'مثال: 2024',
                helper: 'بين 1990 و${DateTime.now().year + 1}.',
                keyboardType: TextInputType.number,
                inputFormatters: FleetInputFormatters.year,
                validator: FleetValidators.validateManufactureYear,
              ),
              DashboardFormField(
                key: _colorKey,
                controller: color,
                focusNode: _colorFocus,
                nextFocus: _notesFocus,
                label: 'لون المركبة',
                icon: Icons.color_lens_outlined,
                hint: 'مثال: أبيض / فضي / رمادي',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'لون الهيكل مطلوب' : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          DashboardFormField(
            controller: notes,
            focusNode: _notesFocus,
            label: 'ملاحظات التشغيل والصيانة',
            icon: Icons.edit_note_rounded,
            isRequired: false,
            maxLines: 3,
            hint: 'أي ملاحظات داخلية لخدمة العملاء أو التشغيل',
            helper: 'داخلية — لا تظهر للعميل.',
          ),
        ],
      ),
    );
  }

  /// Type, capacity and the cabin they produce, in one band.
  ///
  /// The seat map is not decoration: it is the same [SeatConfiguration] the
  /// save writes, drawn as soon as there is a capacity to draw. Putting it
  /// under the two fields that determine it is what makes a wrong vehicle type
  /// self-evident.
  Widget _cabinCard() {
    final hasFixedCapacity =
        VehicleSeatConfigurator.fixedCapacityFor(vehicleType) != null;

    return DashboardFormSection(
      icon: Icons.event_seat_rounded,
      title: _cabin,
      subtitle: 'يحدد النوع تخطيط المقاعد الذي يراه الراكب عند الحجز.',
      filled: _sectionFilled(_cabin),
      total: _sectionTotal(_cabin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardFieldGrid(
            columns: 3,
            breakpoint: 720,
            children: [
              DashboardDropdownFormField<VehicleType>(
                value: vehicleType,
                label: 'نوع المركبة',
                icon: Icons.category_outlined,
                helper: 'يحدد السعة وتخطيط المقاعد تلقائياً.',
                items: [
                  for (final entry
                      in VehicleSeatConfigurator.typeLabels.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: _onVehicleTypeChanged,
              ),
              DashboardFormField(
                key: _seatsKey,
                controller: seats,
                focusNode: _seatsFocus,
                label: 'السعة الركابية',
                icon: Icons.event_seat_rounded,
                hint: 'عدد المقاعد الفعلي',
                keyboardType: TextInputType.number,
                inputFormatters: FleetInputFormatters.capacity,
                validator: FleetValidators.validateCapacity,
                readOnly: hasFixedCapacity,
                helper: hasFixedCapacity
                    ? 'محددة تلقائياً من نوع المركبة (${VehicleSeatConfigurator.typeLabels[vehicleType]}).'
                    : 'بين 2 و100 مقعد.',
              ),
              DashboardDropdownFormField<String>(
                value: seatLayoutType,
                label: 'تخطيط المقاعد',
                icon: Icons.grid_view_rounded,
                helper: 'كل مقاعد الركاب قياسية. لا توجد فئات VIP.',
                items: const [
                  DropdownMenuItem(
                    value: 'standard',
                    child: Text('Standard - قياسي'),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => seatLayoutType = v ?? 'standard'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          FleetSeatLayoutVisualizer(
            seatConfig: _previewSeatConfiguration(),
            vehicleType: vehicleType,
          ),
        ],
      ),
    );
  }

  Widget _driverCard() {
    final drivers = _getAvailableDrivers();
    return DashboardFormSection(
      icon: Icons.person_rounded,
      title: _driverSection,
      subtitle: 'لا يمكن تشغيل مركبة بدون سائق. يمكن تغييره لاحقاً.',
      filled: _sectionFilled(_driverSection),
      total: _sectionTotal(_driverSection),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardDropdownFormField<String>(
            key: _driverKey,
            value: selectedDriverId,
            label: 'السائق',
            icon: Icons.person_rounded,
            helper: drivers.isEmpty
                ? null
                : 'يظهر هنا السائقون النشطون غير المرتبطين بمركبة أخرى.',
            items: drivers
                .map(
                  (d) => DropdownMenuItem<String>(
                    value: d.id,
                    child: Text(
                      '${d.name} (${d.employeeCode})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'يجب تعيين سائق للمركبة' : null,
            onChanged: (val) => setState(() => selectedDriverId = val),
          ),
          if (drivers.isEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              'لا يوجد سائقون متاحون. أضف سائقاً نشطاً أولاً من تبويب السائقين.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _imagesCard() {
    final total = _existingImageUrls.length + _newPickedFiles.length;
    return DashboardFormSection(
      icon: Icons.image_rounded,
      title: 'صور المركبة',
      subtitle: total == 0
          ? 'الصورة الأولى هي التي يراها الراكب في التطبيق.'
          : '$total صورة — الأولى هي الأساسية.',
      optional: true,
      child: _VehicleImagePicker(
        existingUrls: _existingImageUrls,
        newFiles: _newPickedFiles,
        newBytes: _newPickedBytes,
        onPick: _pickVehicleImages,
        onRemoveExisting: _removeExistingImage,
        onRemoveNew: _removeNewImage,
      ),
    );
  }

  Future<void> _pickVehicleImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return;

      final List<PlatformFile> validFiles = [];
      final List<List<int>> validBytes = [];
      var oversized = 0;

      for (final file in result.files) {
        final bytes = await FleetUploadHelpers.readPickedFileBytes(file);
        if (bytes == null || bytes.isEmpty) {
          continue;
        }
        if (bytes.length > 5 * 1024 * 1024) {
          oversized += 1;
          continue;
        }
        validFiles.add(file);
        validBytes.add(bytes);
      }

      if (!mounted) return;
      setState(() {
        _newPickedFiles.addAll(validFiles);
        _newPickedBytes.addAll(validBytes);
        if (oversized > 0) {
          _globalError =
              'تم تجاهل $oversized صورة تتجاوز الحد الأقصى 5 ميجابايت.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _globalError = 'تعذر اختيار الصور: $e');
    }
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() {
      _newPickedFiles.removeAt(index);
      _newPickedBytes.removeAt(index);
    });
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

    setState(() => _saving = true);

    try {
      final seatsValue = VehicleSeatConfigurator.capacityFor(
        vehicleType,
        int.parse(seats.text.trim()),
      );
      final yearValue = int.parse(year.text.trim());
      final existing = widget.vehicle;
      final List<String> finalUrls = [..._existingImageUrls];

      for (int i = 0; i < _newPickedFiles.length; i++) {
        final file = _newPickedFiles[i];
        final bytes = _newPickedBytes[i];

        final fileName = FleetUploadHelpers.safeStorageFileName(file.name);
        final path =
            'vehicles/${existing?.id.isNotEmpty == true ? existing!.id : 'new'}/${DateTime.now().millisecondsSinceEpoch}_${i}_$fileName';

        final url = await widget.onUploadFile('vehicle-images', path, bytes);

        if (url == null || url.isEmpty) {
          throw Exception('فشل رفع إحدى صور المركبة إلى Supabase Storage.');
        }
        finalUrls.add(url);
      }

      final seatConfig = VehicleSeatConfigurator.resolve(
        type: vehicleType,
        capacity: seatsValue,
        existing: existing?.seatConfiguration,
        existingType: existing == null
            ? null
            : VehicleTypeParser.fromDatabase(existing.vehicleType),
      );

      final finalVehicle = FleetVehicle(
        id: existing?.id ?? '',
        vehicleCode: code.text.trim(),
        plateNumber: plate.text.trim(),
        vehicleType: vehicleType.dbValue,
        brand: brand.text.trim(),
        model: model.text.trim(),
        manufactureYear: yearValue,
        color: color.text.trim(),
        capacity: seatsValue,
        seatLayoutType: seatLayoutType,
        imageUrl: finalUrls.join(','),
        notes: notes.text.trim(),
        status: existing?.status ?? FleetVehicleStatus.active,
        currentDriverId: selectedDriverId ?? '',
        seatConfiguration: seatConfig,
        licenseExpiry: existing?.licenseExpiry ?? '',
        insuranceExpiry: existing?.insuranceExpiry ?? '',
        inspectionExpiry: existing?.inspectionExpiry ?? '',
        images: finalUrls.map((url) => FleetVehicleImage(url: url)).toList(),
        previousDrivers: existing?.previousDrivers ?? const [],
        tripHistory: existing?.tripHistory ?? const [],
        completedTripsCount: existing?.completedTripsCount ?? 0,
        cancelledTripsCount: existing?.cancelledTripsCount ?? 0,
        rating: existing?.rating ?? 0,
        ratingCount: existing?.ratingCount ?? 0,
      );

      final error = await widget.onSave(finalVehicle, _pendingDocs);

      if (mounted && error != null) {
        setState(() {
          _globalError = error;
          _showIssues = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _globalError = e.toString().replaceAll('Exception: ', '');
          _showIssues = true;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// The photo tray: a drop-zone while empty, a thumbnail strip once it is not.
///
/// The first image is badged rather than merely being first, because "first"
/// is not visible information once the strip wraps onto a second row — and the
/// first image is the one the Client App shows as the bus.
class _VehicleImagePicker extends StatelessWidget {
  const _VehicleImagePicker({
    required this.existingUrls,
    required this.newFiles,
    required this.newBytes,
    required this.onPick,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  final List<String> existingUrls;
  final List<PlatformFile> newFiles;
  final List<List<int>> newBytes;
  final VoidCallback onPick;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalImages = existingUrls.length + newFiles.length;

    if (totalImages == 0) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        child: Container(
          constraints: const BoxConstraints(minHeight: 140),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(color: scheme.outline.withAlpha(80)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 44,
                color: scheme.primary,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'اضغط لاختيار صور المركبة',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'PNG / JPG / WEBP بحد أقصى 5 ميجابايت للصورة',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        ...List.generate(existingUrls.length, (index) {
          final url = existingUrls[index];
          return _ImageThumbnail(
            isFirst: index == 0,
            onRemove: () => onRemoveExisting(index),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.broken_image_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
          );
        }),
        ...List.generate(newFiles.length, (index) {
          final bytes = newBytes[index];
          final isFirst = existingUrls.isEmpty && index == 0;
          return _ImageThumbnail(
            isFirst: isFirst,
            onRemove: () => onRemoveNew(index),
            child: Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover),
          );
        }),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(50),
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: scheme.outline.withAlpha(90)),
            ),
            child: Icon(
              Icons.add_a_photo_outlined,
              color: scheme.primary,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.child,
    required this.onRemove,
    this.isFirst = false,
  });

  final Widget child;
  final VoidCallback onRemove;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(
              color: isFirst ? scheme.primary : scheme.outline.withAlpha(60),
              width: isFirst ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            child: child,
          ),
        ),
        if (isFirst)
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primary.withAlpha(200),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
              alignment: Alignment.center,
              child: Text(
                'الأساسية',
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
