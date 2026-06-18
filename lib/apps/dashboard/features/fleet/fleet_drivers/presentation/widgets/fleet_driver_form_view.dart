import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/pending_fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_documents_inline_section.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_input_formatters.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_validators.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// Single comprehensive driver create/edit form with inline per-field
/// validation and an embedded documents section (no multi-step wizard).
class FleetDriverFormView extends StatefulWidget {
  final FleetDriver? driver;
  final FleetWorkspace workspace;
  final VoidCallback onBack;
  final void Function(FleetDriver driver, List<PendingFleetDocument> docs) onSave;
  final bool saving;

  const FleetDriverFormView({
    super.key,
    this.driver,
    required this.workspace,
    required this.onBack,
    required this.onSave,
    this.saving = false,
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

  List<PendingFleetDocument> _pendingDocs = const [];
  String _globalError = '';
  bool _hasChanges = false;

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
    selectedVehicleId =
        d?.currentVehicleId.isNotEmpty == true ? d!.currentVehicleId : null;
  }

  List<FleetVehicle> _getAvailableVehicles() {
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
    super.dispose();
  }

  Future<void> _handleBack() async {
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
    if (confirmed == true) widget.onBack();
  }

  void _onSave() {
    setState(() => _globalError = '');
    if (!_formKey.currentState!.validate()) {
      setState(
        () => _globalError = 'يرجى تصحيح الأخطاء في الحقول المميزة بالأحمر',
      );
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
      violations: existing?.violations ?? const [],
      documents: existing?.documents ?? const [],
      activityTimeline: existing?.activityTimeline ?? const [],
    );
    widget.onSave(driver, _pendingDocs);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.driver != null;
    final vehicles = _getAvailableVehicles();

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: () {
          if (!_hasChanges) setState(() => _hasChanges = true);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FleetBreadcrumbs(
              currentLabel: isEdit
                  ? 'تعديل السائق: ${widget.driver!.name}'
                  : 'إضافة سائق جديد',
              onBack: _handleBack,
            ),
            const SizedBox(height: AppSpacing.large),
            _section(
              icon: Icons.person_outline_rounded,
              title: 'البيانات الشخصية',
              subtitle: 'الاسم والهوية وكود الموظف.',
              child: _responsiveGrid([
                _textFormField(
                  controller: name,
                  label: 'الاسم الكامل للسائق ثنائياً أو أكثر',
                  icon: Icons.person_outline_rounded,
                  validator: FleetValidators.validateName,
                ),
                _textFormField(
                  controller: nationalId,
                  label: 'الرقم القومي (14 رقماً مصرياً)',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: FleetInputFormatters.nationalId,
                  validator: FleetValidators.validateNationalId,
                ),
                _textFormField(
                  controller: employeeCode,
                  label: 'كود الموظف (EMP-XXX)',
                  icon: Icons.vpn_key_outlined,
                  validator: FleetValidators.validateEmployeeCode,
                ),
              ]),
            ),
            _section(
              icon: Icons.contact_phone_outlined,
              title: 'بيانات الاتصال والعنوان',
              subtitle: 'أرقام التواصل والعنوان السكني.',
              child: _responsiveGrid([
                _textFormField(
                  controller: phone,
                  label: 'رقم الهاتف الأساسي',
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  inputFormatters: FleetInputFormatters.egyptianPhone,
                  validator: (v) =>
                      FleetValidators.validatePhone(v ?? '', 'رقم الهاتف'),
                ),
                _textFormField(
                  controller: emergency,
                  label: 'رقم هاتف الطوارئ البديل',
                  icon: Icons.contact_phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: FleetInputFormatters.egyptianPhone,
                  validator: (v) {
                    final err = FleetValidators.validatePhone(
                      v ?? '',
                      'رقم هاتف الطوارئ',
                    );
                    if (err == null &&
                        phone.text.trim() == emergency.text.trim()) {
                      return 'رقم هاتف الطوارئ لا يمكن أن يكون نفس الرقم الأساسي';
                    }
                    return err;
                  },
                ),
                _textFormField(
                  controller: address,
                  label: 'العنوان السكني التفصيلي',
                  icon: Icons.home_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'العنوان السكني مطلوب'
                      : null,
                ),
              ]),
            ),
            _section(
              icon: Icons.card_membership_rounded,
              title: 'الرخصة وصلاحية العمل',
              subtitle: 'بيانات الرخصة والتعيين والمركبة.',
              child: _responsiveGrid([
                _textFormField(
                  controller: license,
                  label: 'رقم رخصة القيادة',
                  icon: Icons.card_membership_rounded,
                  validator: FleetValidators.validateLicenseNumber,
                ),
                _dateFormField(
                  controller: expiry,
                  label: 'تاريخ انتهاء صلاحية الرخصة (YYYY-MM-DD)',
                  firstDate: DateTime.now(),
                  validator: (v) => FleetValidators.validateDate(
                    v ?? '',
                    'تاريخ انتهاء الرخصة',
                  ),
                ),
                _dateFormField(
                  controller: hireDate,
                  label: 'تاريخ تعيين الموظف بالشركة (YYYY-MM-DD)',
                  validator: (v) =>
                      FleetValidators.validateDate(v ?? '', 'تاريخ التعيين'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedVehicleId,
                  decoration: const InputDecoration(
                    labelText: 'المركبة المعينة (اختياري)',
                    prefixIcon: Icon(Icons.directions_car_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('غير معين (بدون مركبة)'),
                    ),
                    ...vehicles.map(
                      (v) => DropdownMenuItem<String>(
                        value: v.id,
                        child: Text('${v.vehicleCode} (${v.plateNumber})'),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => selectedVehicleId = val),
                ),
                _textFormField(
                  controller: notes,
                  label: 'ملاحظات إضافية عن السائق',
                  icon: Icons.notes_rounded,
                  maxLines: 2,
                ),
              ]),
            ),
            FleetDocumentsInlineSection(
              isDriver: true,
              existingDocuments: widget.driver?.documents ?? const [],
              onChanged: (docs) => _pendingDocs = docs,
            ),
            const SizedBox(height: AppSpacing.large),
            if (_globalError.isNotEmpty) ...[
              Text(
                _globalError,
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
            ],
            FleetFormActionsBar(
              saving: widget.saving,
              onCancel: _handleBack,
              onSave: _onSave,
              saveLabel: isEdit ? 'حفظ التعديلات' : 'حفظ السائق',
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.large),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FleetSectionTitle(icon: icon, title: title, subtitle: subtitle),
            const SizedBox(height: AppSpacing.medium),
            child,
          ],
        ),
      ),
    );
  }

  Widget _responsiveGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        if (columns == 1) {
          return Column(
            children: children
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: c,
                  ),
                )
                .toList(),
          );
        }
        final itemWidth =
            (constraints.maxWidth - AppSpacing.medium) / columns;
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
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _dateFormField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    DateTime? firstDate,
  }) {
    final effectiveFirstDate =
        firstDate ?? DateTime.now().subtract(const Duration(days: 3650));
    final parsedInitial = DateTime.tryParse(controller.text);
    final initialDate =
        parsedInitial != null && parsedInitial.isAfter(effectiveFirstDate)
        ? parsedInitial
        : DateTime.now().add(const Duration(days: 365));
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_rounded),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: effectiveFirstDate,
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (date != null) {
          setState(() {
            controller.text = date.toIso8601String().substring(0, 10);
          });
        }
      },
    );
  }
}
