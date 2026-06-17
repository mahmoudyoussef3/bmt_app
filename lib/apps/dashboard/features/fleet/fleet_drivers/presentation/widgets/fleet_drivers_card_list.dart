import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/driver_operations.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/core/theme/colors.dart';
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

  Color _healthColor(BuildContext context, DriverHealthLevel health) {
    final scheme = Theme.of(context).colorScheme;
    return switch (health) {
      DriverHealthLevel.healthy => scheme.primary,
      DriverHealthLevel.warning => scheme.tertiary,
      DriverHealthLevel.critical => scheme.error,
    };
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
            final snapshot = DriverOperations.snapshot(driver, workspace);
            final healthColor = _healthColor(context, snapshot.health);

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
                      StatusChip(
                        label: snapshot.health.label,
                        color: healthColor.withAlpha(24),
                        textColor: healthColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    children: [
                      Expanded(child: StatusChip(label: snapshot.status.label)),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Text(
                          snapshot.primaryReason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: healthColor,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (driver.isLicenseExpired) ...[
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
                          Text('الرخصة منتهية', style: TextStyle(color: AppStatusColors.onErrorContainer, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ] else if (driver.isLicenseExpiringSoon) ...[
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
                          Text('الرخصة تنتهي قريباً', style: TextStyle(color: AppStatusColors.onWarningContainer, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
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
                    valueColor: healthColor,
                  ),
                  FleetMetaRow(
                    icon: Icons.assignment_late_outlined,
                    label: 'قرار التشغيل',
                    value: snapshot.canAssign ? 'جاهز للتعيين' : 'راجع المخاطر',
                    valueColor: snapshot.canAssign
                        ? scheme.primary
                        : healthColor,
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
