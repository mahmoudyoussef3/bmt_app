import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

class FleetDriversCardList extends StatelessWidget {
  final List<FleetDriver> drivers;
  final FleetWorkspace workspace;
  final ValueChanged<FleetDriver> onViewDetails;
  final ValueChanged<FleetDriver> onEdit;
  final int page;
  final int pageSize;

  const FleetDriversCardList({
    super.key,
    required this.drivers,
    required this.workspace,
    required this.onViewDetails,
    required this.onEdit,
    required this.page,
    required this.pageSize,
  });

  String _vehicleName(String vehicleId) {
    if (vehicleId.isEmpty) return '';
    final match = workspace.vehicles.where((v) => v.id == vehicleId);
    if (match.isEmpty) return '';
    return match.first.vehicleNumber;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, drivers.length);
    final paged = start >= drivers.length
        ? <FleetDriver>[]
        : drivers.sublist(start, end);

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
            final driver = paged[index];
            final vehicle = _vehicleName(driver.currentVehicleId);
            final documentExpired = driver.documents.any(
              (d) => d.status == FleetDocumentStatus.expired,
            );
            final documentExpiring = driver.documents.any(
              (d) => d.status == FleetDocumentStatus.expiringSoon,
            );

            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FleetAvatar(
                        label: driver.imageLabel,
                        profileImageUrl: driver.profileImageUrl,
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              driver.employeeCode,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(label: driver.status.label),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.small),
                  FleetMetaRow(
                    icon: Icons.phone_android_rounded,
                    label: 'الهاتف',
                    value: driver.phone,
                  ),
                  FleetMetaRow(
                    icon: Icons.badge_outlined,
                    label: 'الرقم القومي',
                    value: driver.nationalId,
                  ),
                  FleetMetaRow(
                    icon: Icons.directions_bus_outlined,
                    label: 'المركبة',
                    value: vehicle.isEmpty ? 'بدون مركبة' : vehicle,
                  ),
                  FleetMetaRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'انتهاء الرخصة',
                    value: driver.licenseExpiry,
                    valueColor: documentExpired
                        ? scheme.error
                        : documentExpiring
                        ? scheme.tertiary
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => onViewDetails(driver),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('عرض'),
                      ),
                      TextButton.icon(
                        onPressed: () => onEdit(driver),
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
