import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

class FleetVehiclesCardList extends StatelessWidget {
  final List<FleetVehicle> vehicles;
  final FleetWorkspace workspace;
  final ValueChanged<FleetVehicle> onViewDetails;
  final ValueChanged<FleetVehicle> onEdit;
  final int page;
  final int pageSize;

  const FleetVehiclesCardList({
    super.key,
    required this.vehicles,
    required this.workspace,
    required this.onViewDetails,
    required this.onEdit,
    required this.page,
    required this.pageSize,
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
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, vehicles.length);
    final paged = start >= vehicles.length
        ? <FleetVehicle>[]
        : vehicles.sublist(start, end);

    if (paged.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.large),
          child: Text('لا توجد بيانات مطابقة'),
        ),
      );
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paged.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.small),
          itemBuilder: (context, index) {
            final vehicle = paged[index];
            final driverName = _driverName(vehicle.currentDriverId);

            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FleetVehicleThumb(
                        label: vehicle.imageLabel,
                        imageUrl: vehicle.imageUrl,
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.vehicleNumber,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${vehicle.brand} ${vehicle.model} | ${vehicle.plateNumber}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(label: vehicle.status.label),
                    ],
                  ),
                  if (vehicle.hasExpiredDocument) ...[
                    const SizedBox(height: AppSpacing.small),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppStatusColors.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppStatusColors.onErrorContainer),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_rounded, color: AppStatusColors.onErrorContainer, size: 16),
                          const SizedBox(width: 6),
                          Text('وثيقة منتهية', style: TextStyle(color: AppStatusColors.onErrorContainer, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ] else if (vehicle.hasDocumentExpiringSoon) ...[
                    const SizedBox(height: AppSpacing.small),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppStatusColors.warningContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppStatusColors.onWarningContainer),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_rounded, color: AppStatusColors.onWarningContainer, size: 16),
                          const SizedBox(width: 6),
                          Text('وثيقة تنتهي قريباً', style: TextStyle(color: AppStatusColors.onWarningContainer, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.medium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.small),
                  FleetMetaRow(
                    icon: Icons.person_outline_rounded,
                    label: 'السائق الحالي',
                    value: driverName.isEmpty ? 'بدون سائق' : driverName,
                  ),
                  FleetMetaRow(
                    icon: Icons.event_seat_outlined,
                    label: 'السعة الركابية',
                    value: '${vehicle.capacity} مقعد',
                  ),
                  FleetMetaRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'رخصة المركبة',
                    value: vehicle.licenseExpiry,
                  ),
                  FleetMetaRow(
                    icon: Icons.verified_user_outlined,
                    label: 'التأمين',
                    value: vehicle.insuranceExpiry,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => onViewDetails(vehicle),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('عرض'),
                      ),
                      TextButton.icon(
                        onPressed: () => onEdit(vehicle),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('تعديل'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
