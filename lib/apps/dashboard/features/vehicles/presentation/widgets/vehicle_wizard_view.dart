import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/vehicle.dart';

class VehicleWizardView extends StatefulWidget {
  final Vehicle? vehicle;
  final ValueChanged<Vehicle> onSubmit;
  final VoidCallback onCancel;

  const VehicleWizardView({
    required this.onSubmit,
    required this.onCancel,
    this.vehicle,
    super.key,
  });

  @override
  State<VehicleWizardView> createState() => _VehicleWizardViewState();
}

class _VehicleWizardViewState extends State<VehicleWizardView> {
  int _step = 0;

  late final TextEditingController _plate;
  late final TextEditingController _type;
  late final TextEditingController _model;
  late final TextEditingController _capacity;
  late final TextEditingController _license;
  late final TextEditingController _insurance;
  late final TextEditingController _inspection;
  late final TextEditingController _driver;
  late final TextEditingController _route;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    _plate = TextEditingController(text: vehicle?.plateNumber ?? '');
    _type = TextEditingController(text: vehicle?.type ?? '');
    _model = TextEditingController(text: vehicle?.model ?? '');
    _capacity = TextEditingController(text: vehicle?.capacity.toString() ?? '');
    _license = TextEditingController(text: vehicle?.licenseExpiry ?? '');
    _insurance = TextEditingController(text: vehicle?.insuranceExpiry ?? '');
    _inspection = TextEditingController(text: vehicle?.inspectionExpiry ?? '');
    _driver = TextEditingController(text: vehicle?.currentDriver ?? '');
    _route = TextEditingController(text: vehicle?.currentRoute ?? '');
  }

  @override
  void dispose() {
    _plate.dispose();
    _type.dispose();
    _model.dispose();
    _capacity.dispose();
    _license.dispose();
    _insurance.dispose();
    _inspection.dispose();
    _driver.dispose();
    _route.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.vehicle == null ? 'إضافة مركبة' : 'تعديل المركبة';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xSmall),
                  const Text('تدفق إدارة أصول لإضافة مركبة وتجهيزها للتشغيل.'),
                ],
              ),
            ),
            AppButton(
              label: 'إلغاء',
              height: 40,
              outline: true,
              onPressed: widget.onCancel,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        AppCard(
          child: Stepper(
            currentStep: _step,
            onStepTapped: (step) => setState(() => _step = step),
            onStepContinue: _step == 3
                ? () => widget.onSubmit(_buildVehicle())
                : () => setState(() => _step += 1),
            onStepCancel: _step == 0
                ? widget.onCancel
                : () => setState(() => _step -= 1),
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.medium),
                child: Wrap(
                  spacing: AppSpacing.small,
                  children: [
                    AppButton(
                      label: _step == 3 ? 'حفظ المركبة' : 'التالي',
                      height: 40,
                      onPressed: details.onStepContinue ?? () {},
                    ),
                    AppButton(
                      label: _step == 0 ? 'إلغاء' : 'السابق',
                      height: 40,
                      outline: true,
                      onPressed: details.onStepCancel ?? () {},
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('بيانات المركبة'),
                isActive: _step >= 0,
                content: _VehicleDataStep(
                  plate: _plate,
                  type: _type,
                  model: _model,
                  capacity: _capacity,
                ),
              ),
              Step(
                title: const Text('المستندات'),
                isActive: _step >= 1,
                content: _DocumentsStep(
                  license: _license,
                  insurance: _insurance,
                  inspection: _inspection,
                ),
              ),
              Step(
                title: const Text('التعيين'),
                isActive: _step >= 2,
                content: _AssignmentStep(driver: _driver, route: _route),
              ),
              Step(
                title: const Text('المراجعة'),
                isActive: _step >= 3,
                content: _ReviewStep(
                  plate: _plate,
                  type: _type,
                  model: _model,
                  capacity: _capacity,
                  driver: _driver,
                  route: _route,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Vehicle _buildVehicle() {
    final existing = widget.vehicle;
    final parsedCapacity = int.tryParse(_capacity.text.trim()) ?? 0;
    final plate = _plate.text.trim().isEmpty
        ? 'لوحة جديدة'
        : _plate.text.trim();

    return Vehicle(
      id: existing?.id ?? '',
      plateNumber: plate,
      type: _type.text.trim().isEmpty ? 'ميني باص' : _type.text.trim(),
      model: _model.text.trim().isEmpty ? 'موديل غير محدد' : _model.text.trim(),
      capacity: parsedCapacity == 0 ? 12 : parsedCapacity,
      status: existing?.status ?? VehicleStatus.pendingAssignment,
      currentDriver: _driver.text.trim().isEmpty
          ? 'بانتظار التعيين'
          : _driver.text.trim(),
      currentRoute: _route.text.trim().isEmpty
          ? 'بانتظار التعيين'
          : _route.text.trim(),
      licenseExpiry: _license.text.trim().isEmpty
          ? 'غير محدد'
          : _license.text.trim(),
      insuranceExpiry: _insurance.text.trim().isEmpty
          ? 'غير محدد'
          : _insurance.text.trim(),
      inspectionExpiry: _inspection.text.trim().isEmpty
          ? 'غير محدد'
          : _inspection.text.trim(),
      imageLabel: existing?.imageLabel ?? 'مركبة جديدة',
      documents: existing?.documents ?? _defaultDocuments,
      maintenance: existing?.maintenance ?? const [],
      trips: existing?.trips ?? const [],
      previousDrivers: existing?.previousDrivers ?? const [],
      notes: existing?.notes ?? const ['تمت الإضافة من نموذج تجريبي.'],
    );
  }
}

class _VehicleDataStep extends StatelessWidget {
  final TextEditingController plate;
  final TextEditingController type;
  final TextEditingController model;
  final TextEditingController capacity;

  const _VehicleDataStep({
    required this.plate,
    required this.type,
    required this.model,
    required this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldWrap(
      fields: [
        ('رقم اللوحة', plate),
        ('النوع', type),
        ('الموديل', model),
        ('السعة', capacity),
      ],
    );
  }
}

class _DocumentsStep extends StatelessWidget {
  final TextEditingController license;
  final TextEditingController insurance;
  final TextEditingController inspection;

  const _DocumentsStep({
    required this.license,
    required this.insurance,
    required this.inspection,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldWrap(
      fields: [
        ('انتهاء الرخصة', license),
        ('انتهاء التأمين', insurance),
        ('انتهاء الفحص الفني', inspection),
      ],
    );
  }
}

class _AssignmentStep extends StatelessWidget {
  final TextEditingController driver;
  final TextEditingController route;

  const _AssignmentStep({required this.driver, required this.route});

  @override
  Widget build(BuildContext context) {
    return _FieldWrap(
      fields: [('السائق الحالي', driver), ('المسار الحالي', route)],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final TextEditingController plate;
  final TextEditingController type;
  final TextEditingController model;
  final TextEditingController capacity;
  final TextEditingController driver;
  final TextEditingController route;

  const _ReviewStep({
    required this.plate,
    required this.type,
    required this.model,
    required this.capacity,
    required this.driver,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('رقم اللوحة', plate.text),
      ('النوع', type.text),
      ('الموديل', model.text),
      ('السعة', capacity.text),
      ('السائق', driver.text),
      ('المسار', route.text),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: Text('${row.$1}: ${row.$2.isEmpty ? 'غير محدد' : row.$2}'),
            ),
          )
          .toList(),
    );
  }
}

class _FieldWrap extends StatelessWidget {
  final List<(String, TextEditingController)> fields;

  const _FieldWrap({required this.fields});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.medium,
      children: fields
          .map(
            (field) => SizedBox(
              width: 300,
              child: TextField(
                controller: field.$2,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(labelText: field.$1),
              ),
            ),
          )
          .toList(),
    );
  }
}

const _defaultDocuments = [
  VehicleDocument(
    title: 'رخصة المركبة',
    number: 'غير محدد',
    expirationDate: 'غير محدد',
    previewLabel: 'صورة الرخصة',
    expired: false,
  ),
  VehicleDocument(
    title: 'التأمين',
    number: 'غير محدد',
    expirationDate: 'غير محدد',
    previewLabel: 'وثيقة التأمين',
    expired: false,
  ),
  VehicleDocument(
    title: 'الفحص الفني',
    number: 'غير محدد',
    expirationDate: 'غير محدد',
    previewLabel: 'تقرير الفحص',
    expired: false,
  ),
];
