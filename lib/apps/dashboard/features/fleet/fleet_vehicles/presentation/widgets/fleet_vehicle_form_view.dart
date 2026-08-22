import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/pending_fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_documents_inline_section.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_input_formatters.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_validators.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_upload_helpers.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/vehicle_seat_configuration.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_seat_layout_visualizer.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_dialog_header.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/theme/tokens.dart';

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

  VehicleType vehicleType = VehicleType.coaster;
  String seatLayoutType = 'standard';
  String? selectedDriverId;

  List<String> _existingImageUrls = [];
  final List<PlatformFile> _newPickedFiles = [];
  final List<List<int>> _newPickedBytes = [];
  List<PendingFleetDocument> _pendingDocs = const [];

  String _globalError = '';
  bool _saving = false;
  bool _hasChanges = false;

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

  @override
  void dispose() {
    code.dispose();
    plate.dispose();
    model.dispose();
    year.dispose();
    seats.dispose();
    brand.dispose();
    color.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (_saving) return;
    if (!_hasChanges) {
      widget.onBack();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تخلٍّ عن التغييرات؟'),
        content: const Text('لديك تغييرات غير محفوظة. هل تريد الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('متابعة التعديل'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج بدون حفظ'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicle != null;
    final scheme = Theme.of(context).colorScheme;

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
                onClose: _saving ? null : _handleBack,
              ),
              const DashboardDialogDivider(),
              Expanded(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: () {
                    if (!_hasChanges) setState(() => _hasChanges = true);
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.large),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isDesktop = constraints.maxWidth >= 980;

                            if (isDesktop) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _VehicleMainInfoCard(
                                      child: _buildMainFields(columns: 2),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.large),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      children: [
                                        _VehicleImagePickerCard(
                                          existingUrls: _existingImageUrls,
                                          newFiles: _newPickedFiles,
                                          newBytes: _newPickedBytes,
                                          onPick: _pickVehicleImages,
                                          onRemoveExisting:
                                              _removeExistingImage,
                                          onRemoveNew: _removeNewImage,
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.medium,
                                        ),
                                        _VehicleDriverCard(
                                          selectedDriverId: selectedDriverId,
                                          drivers: _getAvailableDrivers(),
                                          onChanged: (val) {
                                            setState(
                                              () => selectedDriverId = val,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                _VehicleImagePickerCard(
                                  existingUrls: _existingImageUrls,
                                  newFiles: _newPickedFiles,
                                  newBytes: _newPickedBytes,
                                  onPick: _pickVehicleImages,
                                  onRemoveExisting: _removeExistingImage,
                                  onRemoveNew: _removeNewImage,
                                ),
                                const SizedBox(height: AppSpacing.medium),
                                _VehicleMainInfoCard(
                                  child: _buildMainFields(columns: 1),
                                ),
                                const SizedBox(height: AppSpacing.medium),
                                _VehicleDriverCard(
                                  selectedDriverId: selectedDriverId,
                                  drivers: _getAvailableDrivers(),
                                  onChanged: (val) =>
                                      setState(() => selectedDriverId = val),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.large),

                        FleetSeatLayoutVisualizer(
                          seatConfig: _previewSeatConfiguration(),
                          vehicleType: vehicleType,
                        ),
                        const SizedBox(height: AppSpacing.large),
                        FleetDocumentsInlineSection(
                          isDriver: false,
                          existingDocuments: _vehicleDocuments(),
                          onChanged: (docs) => _pendingDocs = docs,
                        ),
                        if (_globalError.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.medium),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.medium),
                            decoration: BoxDecoration(
                              color: scheme.error.withAlpha(18),
                              borderRadius: BorderRadius.circular(
                                AppTokens.radius,
                              ),
                              border: Border.all(
                                color: scheme.error.withAlpha(55),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: scheme.error,
                                ),
                                const SizedBox(width: AppSpacing.small),
                                Expanded(
                                  child: Text(
                                    _globalError,
                                    style: TextStyle(
                                      color: scheme.error,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainFields({required int columns}) {
    final hasFixedCapacity =
        VehicleSeatConfigurator.fixedCapacityFor(vehicleType) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _responsiveGrid(columns, [
          _textFormField(
            controller: code,
            label: 'كود المركبة الداخلي',
            hint: 'مثال: BUS-201',
            icon: Icons.directions_bus_rounded,
            validator: FleetValidators.validateVehicleCode,
          ),
          _textFormField(
            controller: plate,
            label: 'رقم اللوحة المرورية',
            hint: 'مثال: ٣٣٠٠ ق ل',
            icon: Icons.confirmation_number_outlined,
            validator: FleetValidators.validatePlateNumber,
          ),
          _textFormField(
            controller: brand,
            label: 'الماركة',
            hint: 'Toyota / Mercedes',
            icon: Icons.branding_watermark_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'اسم الماركة مطلوب' : null,
          ),
          _textFormField(
            controller: model,
            label: 'الموديل',
            hint: 'Coaster / Sprinter / Hiace',
            icon: Icons.model_training_rounded,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'اسم طراز الموديل مطلوب'
                : null,
          ),
          _textFormField(
            controller: year,
            label: 'سنة الصنع',
            hint: 'مثال: 2024',
            icon: Icons.calendar_today_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: FleetInputFormatters.year,
            validator: FleetValidators.validateManufactureYear,
          ),
          _textFormField(
            controller: seats,
            label: 'السعة الركابية',
            hint: 'عدد المقاعد الفعلي',
            icon: Icons.event_seat_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: FleetInputFormatters.capacity,
            validator: FleetValidators.validateCapacity,
            readOnly: hasFixedCapacity,
            helper: hasFixedCapacity
                ? 'محددة تلقائياً من نوع المركبة (${VehicleSeatConfigurator.typeLabels[vehicleType]}).'
                : null,
          ),
          _textFormField(
            controller: color,
            label: 'لون المركبة',
            hint: 'أبيض / فضي / رمادي',
            icon: Icons.color_lens_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'لون الهيكل مطلوب' : null,
          ),
          DropdownButtonFormField<VehicleType>(
            initialValue: vehicleType,
            decoration: const InputDecoration(
              labelText: 'نوع المركبة',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
              helperText: 'يحدد النوع سعة المركبة وتخطيط مقاعدها تلقائياً.',
            ),
            items: [
              for (final entry in VehicleSeatConfigurator.typeLabels.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: _onVehicleTypeChanged,
          ),
          DropdownButtonFormField<String>(
            initialValue: seatLayoutType,
            decoration: const InputDecoration(
              labelText: 'تخطيط المقاعد',
              prefixIcon: Icon(Icons.grid_view_rounded),
              border: OutlineInputBorder(),
              helperText: 'كل مقاعد الركاب قياسية. لا توجد فئات VIP.',
            ),
            items: const [
              DropdownMenuItem(
                value: 'standard',
                child: Text('Standard - قياسي'),
              ),
            ],
            onChanged: (v) => setState(() => seatLayoutType = v ?? 'standard'),
          ),
        ]),
        const SizedBox(height: AppSpacing.medium),
        _textFormField(
          controller: notes,
          label: 'ملاحظات التشغيل والصيانة',
          hint: 'أي ملاحظات داخلية لخدمة العملاء أو التشغيل',
          icon: Icons.edit_note_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _responsiveGrid(int columns, List<Widget> children) {
    if (columns == 1) {
      return Column(
        children: children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                child: child,
              ),
            )
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - AppSpacing.medium * (columns - 1)) /
            columns;

        return Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _textFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    String? helper,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: readOnly,
      ),
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
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

      for (final file in result.files) {
        final bytes = await FleetUploadHelpers.readPickedFileBytes(file);
        if (bytes == null || bytes.isEmpty) {
          continue;
        }
        if (bytes.length > 5 * 1024 * 1024) {
          setState(
            () => _globalError =
                'بعض الصور تتجاوز الحجم الأقصى 5MB وسجلنا بعضها الآخر.',
          );
          continue;
        }
        validFiles.add(file);
        validBytes.add(bytes);
      }

      setState(() {
        _newPickedFiles.addAll(validFiles);
        _newPickedBytes.addAll(validBytes);
        if (validFiles.isNotEmpty) _hasChanges = true;
      });
    } catch (e) {
      setState(() => _globalError = 'تعذر اختيار الصور: $e');
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
      _hasChanges = true;
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newPickedFiles.removeAt(index);
      _newPickedBytes.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<void> _onSave() async {
    setState(() => _globalError = '');

    if (!_formKey.currentState!.validate()) {
      setState(() => _globalError = 'يرجى تصحيح الأخطاء في الحقول أولاً');
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
        setState(() => _globalError = error);
      }
    } catch (e) {
      setState(() => _globalError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _VehicleMainInfoCard extends StatelessWidget {
  const _VehicleMainInfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FleetSectionTitle(
            icon: Icons.fact_check_outlined,
            title: 'بيانات المركبة',
            subtitle: 'المعلومات التي تظهر في لوحة التشغيل والتعيينات.',
          ),
          const SizedBox(height: AppSpacing.large),
          child,
        ],
      ),
    );
  }
}

class _VehicleImagePickerCard extends StatelessWidget {
  const _VehicleImagePickerCard({
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

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FleetSectionTitle(
            icon: Icons.image_rounded,
            title: 'صور المركبة',
            subtitle:
                'ارفع صورة أو أكثر للمركبة. الصورة الأولى ستعتبر الصورة الأساسية.',
          ),
          const SizedBox(height: AppSpacing.medium),
          if (totalImages == 0)
            GestureDetector(
              onTap: onPick,
              child: Container(
                constraints: const BoxConstraints(minHeight: 140),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.medium,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                  border: Border.all(
                    color: scheme.outline.withAlpha(80),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اضغط لاختيار صور المركبة',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PNG / JPG / WEBP بحد أقصى 5MB للواحدة',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                ...List.generate(existingUrls.length, (index) {
                  final url = existingUrls[index];
                  return _ImageThumbnail(
                    isFirst: index == 0,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.broken_image_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    onRemove: () => onRemoveExisting(index),
                  );
                }),
                ...List.generate(newFiles.length, (index) {
                  final bytes = newBytes[index];
                  final isFirst = existingUrls.isEmpty && index == 0;
                  return _ImageThumbnail(
                    isFirst: isFirst,
                    child: Image.memory(
                      Uint8List.fromList(bytes),
                      fit: BoxFit.cover,
                    ),
                    onRemove: () => onRemoveNew(index),
                  );
                }),
                GestureDetector(
                  onTap: onPick,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withAlpha(50),
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                      border: Border.all(
                        color: scheme.outline.withAlpha(90),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: scheme.primary,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
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
              child: const Text(
                'الأساسية',
                style: TextStyle(
                  color: Colors.white,
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

class _VehicleDriverCard extends StatelessWidget {
  const _VehicleDriverCard({
    required this.selectedDriverId,
    required this.drivers,
    required this.onChanged,
  });

  final String? selectedDriverId;
  final List<FleetDriver> drivers;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FleetSectionTitle(
            icon: Icons.person_rounded,
            title: 'السائق المعين',
            subtitle:
                'مطلوب. لا يمكن إنشاء مركبة بدون سائق. يمكن تغييره لاحقاً.',
          ),
          const SizedBox(height: AppSpacing.medium),
          DropdownButtonFormField<String>(
            initialValue: selectedDriverId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'السائق *',
              prefixIcon: Icon(Icons.person_rounded),
              border: OutlineInputBorder(),
            ),
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
            onChanged: onChanged,
          ),
          if (drivers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: Text(
                'لا يوجد سائقون متاحون. أضف سائقاً نشطاً أولاً.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
