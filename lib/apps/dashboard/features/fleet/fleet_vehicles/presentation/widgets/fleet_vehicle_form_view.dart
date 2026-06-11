import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_driver.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_validators.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

class FleetVehicleFormView extends StatefulWidget {
  final FleetVehicle? vehicle;
  final FleetWorkspace workspace;
  final VoidCallback onBack;
  final ValueChanged<FleetVehicle> onSave;

  const FleetVehicleFormView({
    super.key,
    this.vehicle,
    required this.workspace,
    required this.onBack,
    required this.onSave,
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

  String vehicleType = 'Coaster';
  String seatLayoutType = 'standard';
  String? selectedDriverId;

  PlatformFile? _pickedVehicleImage;
  List<int>? _pickedVehicleImageBytes;
  String _vehicleImageUrl = '';

  String _globalError = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    code = TextEditingController(text: v?.vehicleCode ?? '');
    plate = TextEditingController(text: v?.plateNumber ?? '');
    model = TextEditingController(text: v?.model ?? '');
    year = TextEditingController(text: v == null ? '' : '${v.manufactureYear}');
    seats = TextEditingController(text: v == null ? '' : '${v.capacity}');
    brand = TextEditingController(text: v?.brand ?? '');
    color = TextEditingController(text: v?.color ?? '');
    notes = TextEditingController(text: v?.notes ?? '');
    _vehicleImageUrl = v?.imageUrl ?? '';

    if (v != null) {
      vehicleType = v.vehicleType.isEmpty ? 'Coaster' : v.vehicleType;
      seatLayoutType = v.seatLayoutType.isEmpty ? 'standard' : v.seatLayoutType;
    }

    selectedDriverId = v?.currentDriverId.isNotEmpty == true ? v!.currentDriverId : null;
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

  Future<List<int>?> _readPickedFileBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;
    if (!kIsWeb && file.path != null) {
      return io.File(file.path!).readAsBytes();
    }
    return null;
  }

  String _safeStorageFileName(String input) {
    final extension = input.contains('.') ? '.${input.split('.').last}' : '';
    final nameWithoutExtension =
        input.contains('.') ? input.substring(0, input.lastIndexOf('.')) : input;

    final safeName = nameWithoutExtension
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return '${safeName.isEmpty ? 'file' : safeName}$extension';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicle != null;
    final scheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FleetBreadcrumbs(
            currentLabel: isEdit ? 'تعديل المركبة: ${widget.vehicle!.vehicleNumber}' : 'إضافة مركبة جديدة',
            onBack: widget.onBack,
          ),
          const SizedBox(height: AppSpacing.large),
          FleetFormHeroCard(
            icon: Icons.directions_bus_filled_rounded,
            title: isEdit ? 'تعديل بيانات المركبة' : 'إضافة مركبة جديدة',
            subtitle: 'أدخل بيانات المركبة والصورة والسائق المرتبط بها. الصورة ترفع إلى Supabase Storage قبل الحفظ.',
          ),
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
                            imageUrl: _vehicleImageUrl,
                            pickedFile: _pickedVehicleImage,
                            pickedBytes: _pickedVehicleImageBytes,
                            onPick: _pickVehicleImage,
                            onRemove: _removeVehicleImage,
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          _VehicleDriverCard(
                            selectedDriverId: selectedDriverId,
                            drivers: _getAvailableDrivers(),
                            onChanged: (val) {
                              setState(() => selectedDriverId = val);
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
                    imageUrl: _vehicleImageUrl,
                    pickedFile: _pickedVehicleImage,
                    pickedBytes: _pickedVehicleImageBytes,
                    onPick: _pickVehicleImage,
                    onRemove: _removeVehicleImage,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _VehicleMainInfoCard(child: _buildMainFields(columns: 1)),
                  const SizedBox(height: AppSpacing.medium),
                  _VehicleDriverCard(
                    selectedDriverId: selectedDriverId,
                    drivers: _getAvailableDrivers(),
                    onChanged: (val) => setState(() => selectedDriverId = val),
                  ),
                ],
              );
            },
          ),
          if (_globalError.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.medium),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: scheme.error.withAlpha(18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.error.withAlpha(55)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: scheme.error),
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
          const SizedBox(height: AppSpacing.large),
          FleetFormActionsBar(
            saving: _saving,
            onCancel: widget.onBack,
            onSave: _onSave,
            saveLabel: isEdit ? 'حفظ التعديلات' : 'إضافة المركبة',
          ),
        ],
      ),
    );
  }

  Widget _buildMainFields({required int columns}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _responsiveGrid(
          columns,
          [
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
              validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم الماركة مطلوب' : null,
            ),
            _textFormField(
              controller: model,
              label: 'الموديل',
              hint: 'Coaster / Sprinter / Hiace',
              icon: Icons.model_training_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم طراز الموديل مطلوب' : null,
            ),
            _textFormField(
              controller: year,
              label: 'سنة الصنع',
              hint: 'مثال: 2024',
              icon: Icons.calendar_today_rounded,
              keyboardType: TextInputType.number,
              validator: FleetValidators.validateManufactureYear,
            ),
            _textFormField(
              controller: seats,
              label: 'السعة الركابية',
              hint: 'عدد المقاعد الفعلي',
              icon: Icons.event_seat_rounded,
              keyboardType: TextInputType.number,
              validator: FleetValidators.validateCapacity,
            ),
            _textFormField(
              controller: color,
              label: 'لون المركبة',
              hint: 'أبيض / فضي / رمادي',
              icon: Icons.color_lens_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'لون الهيكل مطلوب' : null,
            ),
            DropdownButtonFormField<String>(
              value: vehicleType,
              decoration: const InputDecoration(
                labelText: 'نوع المركبة',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Coaster', child: Text('Coaster - ميني باص')),
                DropdownMenuItem(value: 'Sprinter', child: Text('Sprinter - سبرنتر')),
                DropdownMenuItem(value: 'Hiace', child: Text('Hiace - هايس')),
                DropdownMenuItem(value: 'H1', child: Text('H1 - فان')),
                DropdownMenuItem(value: 'Other', child: Text('نوع آخر')),
              ],
              onChanged: (v) => setState(() => vehicleType = v ?? 'Coaster'),
            ),
            DropdownButtonFormField<String>(
              value: seatLayoutType,
              decoration: const InputDecoration(
                labelText: 'تخطيط المقاعد',
                prefixIcon: Icon(Icons.grid_view_rounded),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'standard', child: Text('Standard - قياسي')),
                DropdownMenuItem(value: 'VIP', child: Text('VIP - مميز')),
              ],
              onChanged: (v) => setState(() => seatLayoutType = v ?? 'standard'),
            ),
          ],
        ),
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
        final itemWidth = (constraints.maxWidth - AppSpacing.medium * (columns - 1)) / columns;

        return Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Future<void> _pickVehicleImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = await _readPickedFileBytes(file);

      if (bytes == null || bytes.isEmpty) {
        setState(() => _globalError = 'تعذر قراءة صورة المركبة. جرّب صورة أخرى.');
        return;
      }

      if (bytes.length > 5 * 1024 * 1024) {
        setState(() => _globalError = 'حجم الصورة كبير. الحد الأقصى 5MB.');
        return;
      }

      setState(() {
        _pickedVehicleImage = file;
        _pickedVehicleImageBytes = bytes;
        _globalError = '';
      });
    } catch (e) {
      setState(() => _globalError = 'تعذر اختيار صورة المركبة: $e');
    }
  }

  void _removeVehicleImage() {
    setState(() {
      _pickedVehicleImage = null;
      _pickedVehicleImageBytes = null;
      _vehicleImageUrl = '';
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
      final seatsValue = int.parse(seats.text.trim());
      final yearValue = int.parse(year.text.trim());
      final existing = widget.vehicle;
      var finalImageUrl = _vehicleImageUrl;

      if (_pickedVehicleImage != null && _pickedVehicleImageBytes != null) {
        final fileName = _safeStorageFileName(_pickedVehicleImage!.name);
        final path =
            'vehicles/${existing?.id.isNotEmpty == true ? existing!.id : 'new'}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        final url = await context.read<FleetVehiclesCubit>().uploadVehicleFile(
              'vehicle-images',
              path,
              _pickedVehicleImageBytes!,
            );

        if (url == null || url.isEmpty) {
          throw Exception('تم الحفظ بدون صورة؟ لا، فشل رفع صورة المركبة إلى Supabase Storage.');
        }
        finalImageUrl = url;
      }

      final seatConfig = existing != null && existing.capacity == seatsValue
          ? existing.seatConfiguration
          : SeatConfiguration.generateDefault(seatsValue);

      final finalVehicle = FleetVehicle(
        id: existing?.id ?? '',
        vehicleCode: code.text.trim(),
        plateNumber: plate.text.trim(),
        vehicleType: vehicleType,
        brand: brand.text.trim(),
        model: model.text.trim(),
        manufactureYear: yearValue,
        color: color.text.trim(),
        capacity: seatsValue,
        seatLayoutType: seatLayoutType,
        imageUrl: finalImageUrl,
        notes: notes.text.trim(),
        status: existing?.status ?? FleetVehicleStatus.active,
        currentDriverId: selectedDriverId ?? '',
        seatConfiguration: seatConfig,
        licenseExpiry: existing?.licenseExpiry ?? '',
        insuranceExpiry: existing?.insuranceExpiry ?? '',
        inspectionExpiry: existing?.inspectionExpiry ?? '',
        images: existing?.images ?? const [],
        previousDrivers: existing?.previousDrivers ?? const [],
        tripHistory: existing?.tripHistory ?? const [],
        timeline: existing?.timeline ?? const [],
      );

      widget.onSave(finalVehicle);
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
    required this.imageUrl,
    required this.pickedFile,
    required this.pickedBytes,
    required this.onPick,
    required this.onRemove,
  });

  final String imageUrl;
  final PlatformFile? pickedFile;
  final List<int>? pickedBytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = (pickedBytes != null && pickedBytes!.isNotEmpty) || imageUrl.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FleetSectionTitle(
            icon: Icons.image_rounded,
            title: 'صورة المركبة',
            subtitle: 'ارفع صورة واضحة للمركبة لتظهر في الكروت والتفاصيل.',
          ),
          const SizedBox(height: AppSpacing.medium),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 190,
              width: double.infinity,
              color: scheme.surfaceContainerHighest,
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (pickedBytes != null && pickedBytes!.isNotEmpty)
                          Image.memory(
                            Uint8List.fromList(pickedBytes!),
                            fit: BoxFit.cover,
                          )
                        else
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 44,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        PositionedDirectional(
                          top: 10,
                          end: 10,
                          child: IconButton.filledTonal(
                            tooltip: 'إزالة الصورة',
                            onPressed: onRemove,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bus_filled_outlined,
                          size: 56,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لا توجد صورة للمركبة',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PNG / JPG / WEBP بحد أقصى 5MB',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          if (pickedFile != null)
            Text(
              pickedFile!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          const SizedBox(height: AppSpacing.small),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(hasImage ? 'تغيير الصورة' : 'اختيار صورة المركبة'),
            ),
          ),
        ],
      ),
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
            subtitle: 'اختياري. لا يظهر إلا السائقين المتاحين والنشطين.',
          ),
          const SizedBox(height: AppSpacing.medium),
          DropdownButtonFormField<String>(
            value: selectedDriverId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'السائق',
              prefixIcon: Icon(Icons.person_rounded),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('بدون سائق الآن'),
              ),
              ...drivers.map(
                (d) => DropdownMenuItem<String>(
                  value: d.id,
                  child: Text(
                    '${d.name} (${d.employeeCode})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
