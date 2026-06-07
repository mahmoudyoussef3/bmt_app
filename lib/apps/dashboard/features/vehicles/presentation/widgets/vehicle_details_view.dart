import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/vehicle.dart';
import 'vehicle_status_badge.dart';

class VehicleDetailsView extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final void Function(VehicleStatus status) onStatusChanged;
  final ValueChanged<String> onRenewDocument;

  const VehicleDetailsView({
    required this.vehicle,
    required this.onBack,
    required this.onEdit,
    required this.onStatusChanged,
    required this.onRenewDocument,
    super.key,
  });

  @override
  State<VehicleDetailsView> createState() => _VehicleDetailsViewState();
}

class _VehicleDetailsViewState extends State<VehicleDetailsView> {
  int _section = 0;

  static const _sections = [
    'البيانات العامة',
    'المستندات',
    'الصيانة',
    'الرحلات',
    'السائقين السابقين',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        AppCard(
          child: Row(
            children: [
              Container(
                width: 96,
                height: 80,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
                child: const Icon(Icons.directions_bus_outlined, size: 42),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vehicle.plateNumber,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text('${widget.vehicle.type} • ${widget.vehicle.model}'),
                    const SizedBox(height: AppSpacing.small),
                    VehicleStatusBadge(status: widget.vehicle.status),
                  ],
                ),
              ),
              Wrap(
                spacing: AppSpacing.small,
                children: [
                  AppButton(
                    label: 'رجوع',
                    height: 40,
                    outline: true,
                    onPressed: widget.onBack,
                  ),
                  AppButton(
                    label: 'تعديل',
                    height: 40,
                    onPressed: widget.onEdit,
                  ),
                  PopupMenuButton<VehicleStatus>(
                    tooltip: 'تحديث الحالة',
                    onSelected: widget.onStatusChanged,
                    itemBuilder: (context) => VehicleStatus.values
                        .map(
                          (status) => PopupMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            final navigation = _SideNavigation(
              sections: _sections,
              selectedIndex: _section,
              onSelected: (index) => setState(() => _section = index),
            );
            final content = _SectionContent(
              vehicle: widget.vehicle,
              section: _section,
              onRenewDocument: widget.onRenewDocument,
            );

            if (compact) {
              return Column(
                children: [
                  navigation,
                  const SizedBox(height: AppSpacing.medium),
                  content,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 260, child: navigation),
                const SizedBox(width: AppSpacing.medium),
                Expanded(child: content),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SideNavigation extends StatelessWidget {
  final List<String> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SideNavigation({
    required this.sections,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sections.indexed.map((entry) {
          final (index, section) = entry;
          final selected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
            child: Material(
              color: selected ? scheme.primaryContainer : scheme.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.small),
                  child: Text(
                    section,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionContent extends StatelessWidget {
  final Vehicle vehicle;
  final int section;
  final ValueChanged<String> onRenewDocument;

  const _SectionContent({
    required this.vehicle,
    required this.section,
    required this.onRenewDocument,
  });

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      0 => _GeneralSection(vehicle: vehicle),
      1 => _DocumentsSection(
        vehicle: vehicle,
        onRenewDocument: onRenewDocument,
      ),
      2 => _MaintenanceSection(vehicle: vehicle),
      3 => _TripsSection(vehicle: vehicle),
      _ => _PreviousDriversSection(vehicle: vehicle),
    };
  }
}

class _GeneralSection extends StatelessWidget {
  final Vehicle vehicle;

  const _GeneralSection({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final fields = [
      ('رقم اللوحة', vehicle.plateNumber),
      ('النوع', vehicle.type),
      ('الموديل', vehicle.model),
      ('السعة', '${vehicle.capacity} مقعد'),
      ('الحالة', vehicle.status.label),
      ('السائق الحالي', vehicle.currentDriver),
      ('المسار الحالي', vehicle.currentRoute),
      ('الرخصة', vehicle.licenseExpiry),
      ('التأمين', vehicle.insuranceExpiry),
      ('الفحص الفني', vehicle.inspectionExpiry),
    ];

    return _FieldWrap(title: 'البيانات العامة', fields: fields);
  }
}

class _DocumentsSection extends StatelessWidget {
  final Vehicle vehicle;
  final ValueChanged<String> onRenewDocument;

  const _DocumentsSection({
    required this.vehicle,
    required this.onRenewDocument,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المستندات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.medium,
            children: vehicle.documents
                .map(
                  (document) => SizedBox(
                    width: 260,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 110,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusSmall,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: scheme.onSurfaceVariant,
                                size: 42,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            document.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xSmall),
                          Text(document.previewLabel),
                          const SizedBox(height: AppSpacing.xSmall),
                          Text('ينتهي: ${document.expirationDate}'),
                          const SizedBox(height: AppSpacing.medium),
                          AppButton(
                            label: 'تجديد',
                            height: 40,
                            outline: !document.expired,
                            onPressed: () => onRenewDocument(document.title),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceSection extends StatelessWidget {
  final Vehicle vehicle;

  const _MaintenanceSection({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('جدول الصيانة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          if (vehicle.maintenance.isEmpty)
            const Text('لا توجد صيانات مسجلة لهذه المركبة.')
          else
            ...vehicle.maintenance.indexed.map((entry) {
              final (index, item) = entry;
              return _TimelineItem(
                maintenance: item,
                last: index == vehicle.maintenance.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final VehicleMaintenance maintenance;
  final bool last;

  const _TimelineItem({required this.maintenance, required this.last});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                Icons.build_outlined,
                size: 15,
                color: scheme.onPrimaryContainer,
              ),
            ),
            if (!last)
              Container(
                width: 2,
                height: 54,
                color: scheme.outline.withAlpha(120),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  maintenance.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text('${maintenance.date} • ${maintenance.status}'),
                const SizedBox(height: AppSpacing.xSmall),
                Text(maintenance.notes),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TripsSection extends StatelessWidget {
  final Vehicle vehicle;

  const _TripsSection({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الرحلات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          if (vehicle.trips.isEmpty)
            const Text('لا توجد رحلات حالية مرتبطة بهذه المركبة.')
          else
            ...vehicle.trips.map(
              (trip) => ListTile(
                leading: const Icon(Icons.route_outlined),
                title: Text('رحلة ${trip.tripNumber}'),
                subtitle: Text('${trip.route} • ${trip.driver}'),
                trailing: Text(trip.status),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviousDriversSection extends StatelessWidget {
  final Vehicle vehicle;

  const _PreviousDriversSection({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'السائقين السابقين',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.medium),
          if (vehicle.previousDrivers.isEmpty)
            const Text('لم يتم إسناد سائقين سابقين لهذه المركبة.')
          else
            ...vehicle.previousDrivers.map(
              (driver) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(driver),
                subtitle: const Text('إسناد سابق ضمن بيانات وهمية'),
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldWrap extends StatelessWidget {
  final String title;
  final List<(String, String)> fields;

  const _FieldWrap({required this.title, required this.fields});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
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
      ),
    );
  }
}
