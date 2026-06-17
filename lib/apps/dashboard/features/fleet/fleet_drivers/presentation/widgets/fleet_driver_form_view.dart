import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_input_formatters.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_validators.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

class FleetDriverFormView extends StatefulWidget {
  final FleetDriver? driver;
  final FleetWorkspace workspace;
  final VoidCallback onBack;
  final ValueChanged<FleetDriver> onSave;
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

  int _currentStep = 0;
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
    selectedVehicleId = d?.currentVehicleId.isNotEmpty == true
        ? d!.currentVehicleId
        : null;
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
    name.dispose();
    phone.dispose();
    nationalId.dispose();
    license.dispose();
    expiry.dispose();
    address.dispose();
    emergency.dispose();
    employeeCode.dispose();
    hireDate.dispose();
    notes.dispose();
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.driver != null;

    final steps = [
      'البيانات الشخصية',
      'بيانات الاتصال والعنوان',
      'الرخصة وصلاحية العمل',
      'مراجعة وحفظ البيانات',
    ];

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
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                final stepIndicators = List.generate(steps.length, (index) {
                  final active = index == _currentStep;
                  final done = index < _currentStep;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                              : done
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (done)
                              Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: scheme.onPrimaryContainer,
                              )
                            else
                              Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: active
                                      ? scheme.onPrimary
                                      : scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            const SizedBox(width: 6),
                            Text(
                              steps[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: active
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: active
                                    ? scheme.onPrimary
                                    : done
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < steps.length - 1 && !isCompact)
                        Container(
                          width: 30,
                          height: 2,
                          color: done ? scheme.primary : scheme.outlineVariant,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                    ],
                  );
                });

                return isCompact
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: stepIndicators
                              .map(
                                (w) => Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: w,
                                ),
                              )
                              .toList(),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: stepIndicators,
                      );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: _buildStepContent(),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_currentStep > 0) ...[
                OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('السابق'),
                ),
                const SizedBox(width: AppSpacing.medium),
              ],
              FilledButton.icon(
                onPressed: widget.saving ? null : _onNext,
                icon: widget.saving && _currentStep == steps.length - 1
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox.shrink(),
                label: Text(
                  _currentStep == steps.length - 1
                      ? 'تأكيد وحفظ السائق'
                      : 'التالي',
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 720;
        final colCount = isDesktop ? 2 : 1;

        switch (_currentStep) {
          case 0:
            return _responsiveGrid(colCount, [
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
            ]);
          case 1:
            return _responsiveGrid(colCount, [
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
                    return 'رقم هاتف الطوارئ لا يمكن أن يكون هو نفسه رقم الهاتف الأساسي';
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
            ]);
          case 2:
            final availableVehicles = _getAvailableVehicles();
            return _responsiveGrid(colCount, [
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
                  ...availableVehicles.map(
                    (v) => DropdownMenuItem<String>(
                      value: v.id,
                      child: Text('${v.vehicleCode} (${v.plateNumber})'),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    selectedVehicleId = val;
                  });
                },
              ),
              _textFormField(
                controller: notes,
                label: 'ملاحظات إضافية عن السائق',
                icon: Icons.notes_rounded,
                maxLines: 2,
              ),
            ]);
          case 3:
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'يرجى مراجعة البيانات بعناية قبل التأكيد:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                _reviewRow('الاسم الكامل', name.text),
                _reviewRow('الرقم القومي', nationalId.text),
                _reviewRow('كود الموظف', employeeCode.text),
                _reviewRow('رقم الهاتف', phone.text),
                _reviewRow('هاتف الطوارئ', emergency.text),
                _reviewRow('العنوان', address.text),
                _reviewRow('رقم الرخصة', license.text),
                _reviewRow('انتهاء الرخصة', expiry.text),
                _reviewRow('تاريخ التعيين', hireDate.text),
                _reviewRow(
                  'المركبة المعينة',
                  selectedVehicleId != null
                      ? (widget.workspace.vehicles
                                .cast<FleetVehicle?>()
                                .firstWhere(
                                  (v) => v?.id == selectedVehicleId,
                                  orElse: () => null,
                                )
                                ?.vehicleCode ??
                            'غير معروف')
                      : 'غير معين',
                ),
                if (notes.text.isNotEmpty) _reviewRow('الملاحظات', notes.text),
              ],
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _responsiveGrid(int columns, List<Widget> children) {
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
    final initialDate = parsedInitial != null &&
            parsedInitial.isAfter(effectiveFirstDate)
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

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppStatusColors.onNeutralContainer,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onNext() {
    setState(() => _globalError = '');
    if (_currentStep < 3) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      } else {
        setState(
          () => _globalError = 'يرجى تصحيح الأخطاء في الحقول المميزة بالأحمر',
        );
      }
    } else {
      if (_formKey.currentState!.validate()) {
        final existing = widget.driver;
        final finalDriver = FleetDriver(
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
        widget.onSave(finalDriver);
      } else {
        setState(() => _globalError = 'يرجى مراجعة وتصحيح الحقول أولاً');
      }
    }
  }
}
