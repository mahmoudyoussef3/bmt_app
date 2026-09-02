import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_pager.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_results_header.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_format.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/driver_operations.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

class FleetDriversCardList extends StatelessWidget {
  final List<FleetDriver> drivers;
  final FleetWorkspace workspace;
  final ValueChanged<FleetDriver> onViewDetails;
  final ValueChanged<FleetDriver> onEdit;
  final ValueChanged<FleetDriver> onDelete;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const FleetDriversCardList({
    super.key,
    required this.drivers,
    required this.workspace,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  FleetVehicle? _vehicleOf(String vehicleId) {
    if (vehicleId.isEmpty) return null;
    return workspace.vehicles.where((v) => v.id == vehicleId).firstOrNull;
  }

  /// The same success/warning/error tones the drivers *table* paints
  /// readiness in — the two layouts are the same list at two widths, and a
  /// driver who is green in one and blue in the other reads as two records.
  Color _healthColor(BuildContext context, DriverHealthLevel health) =>
      context.status(switch (health) {
        DriverHealthLevel.healthy => AppStatusTone.success,
        DriverHealthLevel.warning => AppStatusTone.warning,
        DriverHealthLevel.critical => AppStatusTone.error,
      }).ink;

  @override
  Widget build(BuildContext context) {
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, drivers.length);
    final paged = start >= drivers.length
        ? <FleetDriver>[]
        : drivers.sublist(start, end);

    if (paged.isEmpty) {
      return const DashboardEmptyState(
        icon: DashboardIcons.captains,
        title: 'لا يوجد سائقون مطابقون',
        message:
            'لا يطابق أي سائق البحث أو الفلاتر الحالية. وسّع الفلاتر، أو أضف '
            'سائقاً جديداً إلى الأسطول.',
      );
    }

    final pages = (drivers.length / pageSize).ceil().clamp(1, 9999);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // The console's one card-grid rule, so الأسطول breaks to two and
            // three columns at the same widths as every other list module.
            const gap = AppSpacing.medium;
            final columns = dashboardCardColumnsFor(constraints.maxWidth);
            final cardWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: paged.map((driver) {
                final snapshot = DriverOperations.snapshot(driver, workspace);
                final healthColor = _healthColor(context, snapshot.health);

                return SizedBox(
                  width: cardWidth,
                  child: _DriverListCard(
                    driver: driver,
                    snapshot: snapshot,
                    healthColor: healthColor,
                    vehicle: _vehicleOf(driver.currentVehicleId),
                    onViewDetails: () => onViewDetails(driver),
                    onEdit: () => onEdit(driver),
                    onDelete: () => onDelete(driver),
                  ),
                );
              }).toList(),
            );
          },
        ),
        DashboardPagerBar(
          totalLabel: 'الإجمالي ${FleetFormat.count(drivers.length)} سائق',
          currentPage: page,
          pages: pages,
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }
}

/// One driver, one glance. Earlier this repeated the same readiness signal in
/// four places (a health chip, an operational-status strip, an alert banner,
/// and a "قرار التشغيل" line) stacked with a full mini data-sheet in between —
/// which is why the list felt endless to scroll. This keeps exactly one
/// status pill, one assignment fact, one reason (only when something needs
/// attention), and the two contact facts an operator actually scans a list
/// for.
class _DriverListCard extends StatelessWidget {
  const _DriverListCard({
    required this.driver,
    required this.snapshot,
    required this.healthColor,
    required this.vehicle,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final FleetDriver driver;
  final DriverOperationsSnapshot snapshot;
  final Color healthColor;
  final FleetVehicle? vehicle;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      onTap: onViewDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FleetAvatar(
                label: driver.imageLabel,
                profileImageUrl: driver.profileImageUrl,
                ringColor: healthColor,
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driver.employeeCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              DashboardStatusChip(
                label: snapshot.status.label,
                color: healthColor.withAlpha(24),
                textColor: healthColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          _VehicleLine(vehicle: vehicle, onAssign: onEdit),
          if (snapshot.requiresAttention) ...[
            const SizedBox(height: AppSpacing.small),
            _ReasonLine(reason: snapshot.primaryReason, color: healthColor),
          ],
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Icon(
                Icons.phone_android_rounded,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                driver.phone.isEmpty ? 'بدون رقم' : driver.phone,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Icon(
                Icons.event_available_outlined,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              // Never the raw `2027-09-25`: a hyphenated ISO date inside an
              // RTL line renders its parts in the opposite order, so the card
              // was showing "25-09-2027" for a licence expiring in 2027.
              Flexible(
                child: Text(
                  driver.isLicenseExpired || driver.isLicenseExpiringSoon
                      ? 'الرخصة ${FleetFormat.dateText(driver.licenseExpiry)}'
                            ' • ${FleetFormat.remainingShort(driver.licenseExpiry)}'
                      : 'الرخصة ${FleetFormat.dateText(driver.licenseExpiry)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: driver.isLicenseExpired
                        ? context.status(AppStatusTone.error).ink
                        : driver.isLicenseExpiringSoon
                        ? context.status(AppStatusTone.warning).ink
                        : scheme.onSurfaceVariant,
                    fontWeight:
                        driver.isLicenseExpired || driver.isLicenseExpiringSoon
                        ? FontWeight.w800
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FleetRowActionButton(
                tooltip: 'تعديل',
                icon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
              FleetRowActionButton(
                tooltip: 'حذف',
                icon: Icons.delete_outline_rounded,
                onPressed: onDelete,
                color: scheme.error,
              ),
              const SizedBox(width: AppSpacing.xSmall),
              FilledButton.tonalIcon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('فتح الملف'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The single line that answers "which bus, if any". A driver with no
/// vehicle can't be scheduled — see
/// 20260731090000_driver_vehicle_authority — so that state keeps its call to
/// action; an assigned driver just gets a quiet one-line fact instead of a
/// second tinted banner competing with the reason line above it.
class _VehicleLine extends StatelessWidget {
  const _VehicleLine({required this.vehicle, required this.onAssign});

  final FleetVehicle? vehicle;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final assigned = vehicle;
    if (assigned == null) {
      final warning = context.status(AppStatusTone.warning);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: warning.tint,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: warning.ink),
            const SizedBox(width: AppSpacing.xSmall),
            Expanded(
              child: Text(
                'بدون مركبة مخصصة',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: warning.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: onAssign,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
                foregroundColor: warning.ink,
              ),
              child: const Text('تعيين سيارة'),
            ),
          ],
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final type = FleetFormat.vehicleType(assigned.type);
    return Row(
      children: [
        Icon(Icons.directions_bus_rounded, size: 16, color: scheme.primary),
        const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            [
              assigned.vehicleNumber,
              if (type.isNotEmpty) type,
              '${FleetFormat.count(assigned.capacity)} مقعد',
            ].join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReasonLine extends StatelessWidget {
  const _ReasonLine({required this.reason, required this.color});

  final String reason;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 15, color: color),
        const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            reason,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
