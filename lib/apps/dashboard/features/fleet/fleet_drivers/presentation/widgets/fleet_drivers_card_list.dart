import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/driver_operations.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
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
            final columns = constraints.maxWidth >= 1180 ? 2 : 1;
            final gap = AppSpacing.medium;
            final cardWidth = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - gap) / 2;

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
        const SizedBox(height: AppSpacing.medium),
        _FleetCardsPagination(
          total: drivers.length,
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
              StatusChip(
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
              Text(
                'الرخصة ${driver.licenseExpiry}',
                style: textTheme.bodySmall?.copyWith(
                  color: driver.isLicenseExpired
                      ? scheme.error
                      : driver.isLicenseExpiringSoon
                      ? scheme.tertiary
                      : scheme.onSurfaceVariant,
                  fontWeight:
                      driver.isLicenseExpired || driver.isLicenseExpiringSoon
                      ? FontWeight.w800
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'تعديل',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: scheme.error,
                ),
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
    return Row(
      children: [
        Icon(Icons.directions_bus_rounded, size: 16, color: scheme.primary),
        const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            '${assigned.vehicleNumber} • ${assigned.type} • ${assigned.capacity} مقعد',
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

class _FleetCardsPagination extends StatelessWidget {
  const _FleetCardsPagination({
    required this.total,
    required this.currentPage,
    required this.pages,
    required this.onPageChanged,
  });

  final int total;
  final int currentPage;
  final int pages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(36),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outlineVariant.withAlpha(80)),
      ),
      child: Row(
        children: [
          Text('الإجمالي $total'),
          const Spacer(),
          Text('صفحة ${currentPage + 1} من $pages'),
          const SizedBox(width: AppSpacing.small),
          IconButton(
            tooltip: 'السابق',
            onPressed: currentPage == 0
                ? null
                : () => onPageChanged(currentPage - 1),
            icon: const Icon(DashboardIcons.paginationPrevious),
          ),
          IconButton(
            tooltip: 'التالي',
            onPressed: currentPage >= pages - 1
                ? null
                : () => onPageChanged(currentPage + 1),
            icon: const Icon(DashboardIcons.paginationNext),
          ),
        ],
      ),
    );
  }
}
