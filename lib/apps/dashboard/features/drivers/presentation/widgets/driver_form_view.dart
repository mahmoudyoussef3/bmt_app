import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/driver.dart';

class DriverFormView extends StatefulWidget {
  final Driver? driver;
  final ValueChanged<Driver> onSubmit;
  final VoidCallback onCancel;

  const DriverFormView({
    required this.onSubmit,
    required this.onCancel,
    this.driver,
    super.key,
  });

  @override
  State<DriverFormView> createState() => _DriverFormViewState();
}

class _DriverFormViewState extends State<DriverFormView> {
  int _step = 0;

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _nationalId;
  late final TextEditingController _licenseNumber;
  late final TextEditingController _licenseExpiry;
  late final TextEditingController _vehicle;
  late final TextEditingController _route;

  @override
  void initState() {
    super.initState();
    final driver = widget.driver;
    _name = TextEditingController(text: driver?.name ?? '');
    _phone = TextEditingController(text: driver?.phone ?? '');
    _email = TextEditingController(text: driver?.email ?? '');
    _address = TextEditingController(text: driver?.address ?? '');
    _nationalId = TextEditingController(text: driver?.nationalId ?? '');
    _licenseNumber = TextEditingController(text: driver?.licenseNumber ?? '');
    _licenseExpiry = TextEditingController(text: driver?.licenseExpiry ?? '');
    _vehicle = TextEditingController(text: driver?.currentVehicle ?? '');
    _route = TextEditingController(text: driver?.currentRoute ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _nationalId.dispose();
    _licenseNumber.dispose();
    _licenseExpiry.dispose();
    _vehicle.dispose();
    _route.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.driver == null ? 'إضافة سائق' : 'تعديل السائق';

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
                  const Text(
                    'نموذج متعدد الخطوات لإدخال بيانات السائق ومراجعتها.',
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'إلغاء',
              outline: true,
              height: 40,
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
                ? () => widget.onSubmit(_buildDriver())
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
                      label: _step == 3 ? 'حفظ السائق' : 'التالي',
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
                title: const Text('البيانات الشخصية'),
                isActive: _step >= 0,
                content: _PersonalForm(
                  name: _name,
                  phone: _phone,
                  email: _email,
                  address: _address,
                  nationalId: _nationalId,
                ),
              ),
              Step(
                title: const Text('بيانات الرخصة'),
                isActive: _step >= 1,
                content: _LicenseForm(
                  licenseNumber: _licenseNumber,
                  licenseExpiry: _licenseExpiry,
                  vehicle: _vehicle,
                  route: _route,
                ),
              ),
              const Step(
                title: Text('المستندات'),
                isActive: true,
                content: _DocumentsForm(),
              ),
              Step(
                title: const Text('تأكيد البيانات'),
                isActive: _step >= 3,
                content: _ConfirmForm(
                  name: _name,
                  phone: _phone,
                  nationalId: _nationalId,
                  licenseNumber: _licenseNumber,
                  vehicle: _vehicle,
                  route: _route,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Driver _buildDriver() {
    final existing = widget.driver;
    final name = _name.text.trim().isEmpty ? 'سائق جديد' : _name.text.trim();
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first)
        .join(' ');

    return Driver(
      id: existing?.id ?? '',
      name: name,
      phone: _phone.text.trim().isEmpty ? '٠١٠٠٠٠٠٠٠٠٠' : _phone.text.trim(),
      nationalId: _nationalId.text.trim().isEmpty
          ? 'غير محدد'
          : _nationalId.text.trim(),
      email: _email.text.trim().isEmpty
          ? 'driver@bmt.local'
          : _email.text.trim(),
      address: _address.text.trim().isEmpty ? 'غير محدد' : _address.text.trim(),
      avatarInitials: initials.isEmpty ? 'س ج' : initials,
      currentVehicle: _vehicle.text.trim().isEmpty
          ? 'غير مسند'
          : _vehicle.text.trim(),
      currentRoute: _route.text.trim().isEmpty
          ? 'غير مسند'
          : _route.text.trim(),
      totalTrips: existing?.totalTrips ?? 0,
      todayTrips: existing?.todayTrips ?? 0,
      monthlyTrips: existing?.monthlyTrips ?? 0,
      totalPassengers: existing?.totalPassengers ?? 0,
      rating: existing?.rating ?? 0,
      status: existing?.status ?? DriverStatus.pendingDocuments,
      assignedAt: existing?.assignedAt ?? 'اليوم',
      licenseNumber: _licenseNumber.text.trim().isEmpty
          ? 'غير محدد'
          : _licenseNumber.text.trim(),
      licenseExpiry: _licenseExpiry.text.trim().isEmpty
          ? 'غير محدد'
          : _licenseExpiry.text.trim(),
      documents: existing?.documents ?? _defaultDocuments,
      reviews: existing?.reviews ?? const [],
      complaints: existing?.complaints ?? const [],
      notes: existing?.notes ?? const ['تمت الإضافة من نموذج تجريبي.'],
    );
  }
}

class _PersonalForm extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController address;
  final TextEditingController nationalId;

  const _PersonalForm({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.nationalId,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldGrid(
      fields: [
        ('الاسم', name),
        ('رقم الهاتف', phone),
        ('البريد', email),
        ('العنوان', address),
        ('الرقم القومي', nationalId),
      ],
    );
  }
}

class _LicenseForm extends StatelessWidget {
  final TextEditingController licenseNumber;
  final TextEditingController licenseExpiry;
  final TextEditingController vehicle;
  final TextEditingController route;

  const _LicenseForm({
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.vehicle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldGrid(
      fields: [
        ('رقم الرخصة', licenseNumber),
        ('تاريخ انتهاء الرخصة', licenseExpiry),
        ('المركبة الحالية', vehicle),
        ('المسار الحالي', route),
      ],
    );
  }
}

class _DocumentsForm extends StatelessWidget {
  const _DocumentsForm();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.medium,
      children: _defaultDocuments
          .map(
            (document) => SizedBox(
              width: 220,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.upload_file_outlined),
                    const SizedBox(height: AppSpacing.small),
                    Text(document.title),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(document.status),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ConfirmForm extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController nationalId;
  final TextEditingController licenseNumber;
  final TextEditingController vehicle;
  final TextEditingController route;

  const _ConfirmForm({
    required this.name,
    required this.phone,
    required this.nationalId,
    required this.licenseNumber,
    required this.vehicle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final fields = [
      ('الاسم', name.text),
      ('الهاتف', phone.text),
      ('الرقم القومي', nationalId.text),
      ('الرخصة', licenseNumber.text),
      ('المركبة', vehicle.text),
      ('المسار', route.text),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields
          .map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: Text(
                '${field.$1}: ${field.$2.isEmpty ? 'غير محدد' : field.$2}',
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  final List<(String, TextEditingController)> fields;

  const _FieldGrid({required this.fields});

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
  DriverDocument(
    title: 'رخصة القيادة',
    number: 'غير محدد',
    status: 'بانتظار الرفع',
    updatedAt: 'لم يتم الرفع',
  ),
  DriverDocument(
    title: 'بطاقة الرقم القومي',
    number: 'غير محدد',
    status: 'بانتظار الرفع',
    updatedAt: 'لم يتم الرفع',
  ),
  DriverDocument(
    title: 'فيش جنائي',
    number: 'غير محدد',
    status: 'بانتظار الرفع',
    updatedAt: 'لم يتم الرفع',
  ),
  DriverDocument(
    title: 'عقد العمل',
    number: 'غير محدد',
    status: 'بانتظار الرفع',
    updatedAt: 'لم يتم الرفع',
  ),
];
