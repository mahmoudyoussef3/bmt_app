import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/driver.dart';
import 'driver_avatar.dart';
import 'driver_status_badge.dart';

class DriverDetailsView extends StatelessWidget {
  final Driver driver;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(DriverStatus status) onStatusChanged;

  const DriverDetailsView({
    required this.driver,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.large),
        children: [
          _ProfileHeader(
            driver: driver,
            onBack: onBack,
            onEdit: onEdit,
            onDelete: onDelete,
            onStatusChanged: onStatusChanged,
          ),
          const SizedBox(height: AppSpacing.large),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'البيانات الشخصية'),
                    Tab(text: 'المستندات'),
                    Tab(text: 'بيانات التشغيل'),
                    Tab(text: 'التقييمات'),
                    Tab(text: 'الشكاوى'),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                SizedBox(
                  height: 560,
                  child: TabBarView(
                    children: [
                      _PersonalSection(driver: driver),
                      _DocumentsSection(driver: driver),
                      _OperationsSection(driver: driver),
                      _ReviewsSection(driver: driver),
                      _ComplaintsSection(driver: driver),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Driver driver;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(DriverStatus status) onStatusChanged;

  const _ProfileHeader({
    required this.driver,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canActivate = driver.status == DriverStatus.suspended;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DriverAvatar(driver: driver, radius: 42),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text('${driver.phone} • ${driver.currentRoute}'),
                const SizedBox(height: AppSpacing.small),
                DriverStatusBadge(status: driver.status),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              AppButton(
                label: 'رجوع',
                height: 40,
                outline: true,
                onPressed: onBack,
              ),
              AppButton(label: 'تعديل', height: 40, onPressed: onEdit),
              AppButton(
                label: canActivate ? 'تفعيل' : 'إيقاف',
                height: 40,
                outline: true,
                onPressed: () => onStatusChanged(
                  canActivate ? DriverStatus.active : DriverStatus.suspended,
                ),
              ),
              AppButton(
                label: 'حذف',
                height: 40,
                outline: true,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonalSection extends StatelessWidget {
  final Driver driver;

  const _PersonalSection({required this.driver});

  @override
  Widget build(BuildContext context) {
    final fields = [
      ('الاسم', driver.name),
      ('الهاتف', driver.phone),
      ('البريد', driver.email),
      ('العنوان', driver.address),
      ('الرقم القومي', driver.nationalId),
      ('تاريخ التعيين', driver.assignedAt),
      ('رقم الرخصة', driver.licenseNumber),
      ('انتهاء الرخصة', driver.licenseExpiry),
    ];

    return _FieldWrap(fields: fields);
  }
}

class _DocumentsSection extends StatelessWidget {
  final Driver driver;

  const _DocumentsSection({required this.driver});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: driver.documents
              .map(
                (document) => SizedBox(
                  width: 260,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description_outlined, size: 34),
                        const SizedBox(height: AppSpacing.medium),
                        Text(
                          document.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(document.number),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(document.status),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(document.updatedAt),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _OperationsSection extends StatelessWidget {
  final Driver driver;

  const _OperationsSection({required this.driver});

  @override
  Widget build(BuildContext context) {
    final fields = [
      ('المركبة الحالية', driver.currentVehicle),
      ('المسار الحالي', driver.currentRoute),
      ('عدد الرحلات اليوم', '${driver.todayTrips}'),
      ('عدد الرحلات الشهرية', '${driver.monthlyTrips}'),
      ('إجمالي الركاب', '${driver.totalPassengers}'),
      ('إجمالي الرحلات', '${driver.totalTrips}'),
      ('التقييم', driver.rating.toStringAsFixed(1)),
      ('الحالة', driver.status.label),
    ];

    return _FieldWrap(fields: fields);
  }
}

class _ReviewsSection extends StatelessWidget {
  final Driver driver;

  const _ReviewsSection({required this.driver});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: driver.reviews.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final review = driver.reviews[index];
        return ListTile(
          leading: const Icon(Icons.star_outline),
          title: Text(review.passengerName),
          subtitle: Text(review.comment),
          trailing: Text(review.rating.toStringAsFixed(1)),
        );
      },
    );
  }
}

class _ComplaintsSection extends StatelessWidget {
  final Driver driver;

  const _ComplaintsSection({required this.driver});

  @override
  Widget build(BuildContext context) {
    if (driver.complaints.isEmpty) {
      return const Center(child: Text('لا توجد شكاوى مرتبطة بهذا السائق.'));
    }

    return ListView.separated(
      itemCount: driver.complaints.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final complaint = driver.complaints[index];
        return ListTile(
          leading: const Icon(Icons.report_outlined),
          title: Text('${complaint.id} - ${complaint.passengerName}'),
          subtitle: Text(complaint.summary),
          trailing: Text(complaint.status),
        );
      },
    );
  }
}

class _FieldWrap extends StatelessWidget {
  final List<(String, String)> fields;

  const _FieldWrap({required this.fields});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: fields
              .map(
                (field) => SizedBox(
                  width: 240,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.$1,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(
                          field.$2,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
