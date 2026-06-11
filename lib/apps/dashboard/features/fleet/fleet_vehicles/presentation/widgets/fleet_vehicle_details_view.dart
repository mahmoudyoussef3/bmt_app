import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_common.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_seat_layout_visualizer.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/widgets/fleet_document_manager.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

class FleetVehicleDetailsView extends StatelessWidget {
  final FleetVehicle vehicle;
  final FleetWorkspace workspace;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const FleetVehicleDetailsView({
    super.key,
    required this.vehicle,
    required this.workspace,
    required this.onBack,
    required this.onEdit,
  });

  String _driverName(String driverId) {
    if (driverId.isEmpty) return '';
    final match = workspace.drivers.where((d) => d.id == driverId);
    if (match.isEmpty) return '';
    return match.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vehicleDocs = workspace.documents.where((d) => d.ownerId == vehicle.id).toList();
    final driverName = _driverName(vehicle.currentDriverId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FleetBreadcrumbs(
          currentLabel: 'تفاصيل المركبة: ${vehicle.vehicleNumber}',
          onBack: onBack,
        ),
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            final headerWidgets = [
              Container(
                width: 56,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  border: Border.all(color: scheme.outline.withAlpha(90)),
                ),
                child: Icon(Icons.directions_bus_rounded, color: scheme.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model} (${vehicle.vehicleNumber})',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text('رقم اللوحة: ${vehicle.plateNumber} | السعة الركابية: ${vehicle.capacity} مقعد'),
                  ],
                ),
              ),
              if (isCompact) const SizedBox(height: AppSpacing.medium),
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('تعديل البيانات'),
              ),
            ];

            return isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: headerWidgets[0],
                      ),
                      const SizedBox(height: AppSpacing.small),
                      (headerWidgets[2] as Expanded).child,
                      const SizedBox(height: AppSpacing.medium),
                      headerWidgets.last,
                    ],
                  )
                : Row(
                    children: headerWidgets,
                  );
          },
        ),
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _infoCard(context, vehicle, driverName),
                        const SizedBox(height: AppSpacing.medium),
                        FleetSeatLayoutVisualizer(seatConfig: vehicle.seatConfiguration),
                        const SizedBox(height: AppSpacing.medium),
                        FleetDocumentManager(
                          ownerId: vehicle.id,
                          isDriver: false,
                          documents: vehicleDocs,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.large),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _HistoryTimeline(
                          title: 'سجل السائقين السابقين',
                          items: vehicle.previousDrivers,
                          icon: Icons.people_outline_rounded,
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        _HistoryTimeline(
                          title: 'سجل الرحلات',
                          items: vehicle.tripHistory,
                          icon: Icons.map_outlined,
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        _HistoryTimeline(
                          title: 'سجل النشاط التشغيلي',
                          items: vehicle.timeline,
                          icon: Icons.timeline_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _infoCard(context, vehicle, driverName),
                  const SizedBox(height: AppSpacing.medium),
                  FleetSeatLayoutVisualizer(seatConfig: vehicle.seatConfiguration),
                  const SizedBox(height: AppSpacing.medium),
                  FleetDocumentManager(
                    ownerId: vehicle.id,
                    isDriver: false,
                    documents: vehicleDocs,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(
                    title: 'سجل السائقين السابقين',
                    items: vehicle.previousDrivers,
                    icon: Icons.people_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(
                    title: 'سجل الرحلات',
                    items: vehicle.tripHistory,
                    icon: Icons.map_outlined,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(
                    title: 'سجل النشاط التشغيلي',
                    items: vehicle.timeline,
                    icon: Icons.timeline_rounded,
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _infoCard(BuildContext context, FleetVehicle vehicle, String driverName) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المعلومات الأساسية والتشغيلية',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.medium),
          _detailRow('كود المركبة', vehicle.vehicleCode),
          _detailRow('رقم اللوحة المرورية', vehicle.plateNumber),
          _detailRow('نوع المركبة', vehicle.vehicleType),
          _detailRow('الماركة', vehicle.brand),
          _detailRow('طراز الموديل', vehicle.model),
          _detailRow('سنة الصنع', '${vehicle.manufactureYear}'),
          _detailRow('لون المركبة', vehicle.color),
          _detailRow('السعة الركابية', '${vehicle.capacity} مقعد'),
          _detailRow('نوع تخطيط المقاعد', vehicle.seatLayoutType),
          _detailRow('السائق الحالي', driverName.isEmpty ? 'بدون سائق حالياً' : driverName),
          _detailRow('حالة المركبة', vehicle.status.label),
          _detailRow('انتهاء الرخصة', vehicle.licenseExpiry),
          _detailRow('انتهاء التأمين', vehicle.insuranceExpiry),
          _detailRow('انتهاء الفحص الفني', vehicle.inspectionExpiry),
          if (vehicle.notes.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.small),
            Text(
              'ملاحظات التشغيل والصيانة:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Text(vehicle.notes, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  final String title;
  final List<FleetHistoryItem> items;
  final IconData icon;
  final Color? color;

  const _HistoryTimeline({
    required this.title,
    required this.items,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = color ?? scheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: AppSpacing.small),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          if (items.isEmpty)
            const Text('لا توجد سجلات حالياً.')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconColor,
                          ),
                        ),
                        if (index < items.length - 1)
                          Container(
                            width: 2,
                            height: 40,
                            color: scheme.outlineVariant,
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${item.date} - ${item.description}',
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                          ),
                          const SizedBox(height: AppSpacing.small),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
