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
  final ValueChanged<FleetVehicle> onDelete;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const FleetVehiclesCardList({
    super.key,
    required this.vehicles,
    required this.workspace,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
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

    final pages = (vehicles.length / pageSize).ceil().clamp(1, 9999);

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
              children: paged.map((vehicle) {
                final driverName = _driverName(vehicle.currentDriverId);
                final documentColor = vehicle.hasExpiredDocument
                    ? AppStatusColors.onErrorContainer
                    : vehicle.hasDocumentExpiringSoon
                    ? AppStatusColors.onWarningContainer
                    : scheme.primary;

                return SizedBox(
                  width: cardWidth,
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    onTap: () => onViewDetails(vehicle),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.medium),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${vehicle.brand} ${vehicle.model} ${vehicle.modelYear}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.small),
                              StatusChip(label: vehicle.status.label),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                          ),
                          child: _VehicleOperationalStrip(
                            status: driverName.isEmpty
                                ? 'غير معين'
                                : 'معين لسائق',
                            reason: driverName.isEmpty
                                ? 'جاهزة لاختيار سائق'
                                : driverName,
                            color: driverName.isEmpty
                                ? scheme.tertiary
                                : scheme.primary,
                          ),
                        ),
                        if (vehicle.hasExpiredDocument) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.medium,
                              AppSpacing.small,
                              AppSpacing.medium,
                              0,
                            ),
                            child: const _VehicleAlertBanner(
                              icon: Icons.warning_rounded,
                              label: 'يوجد مستند منتهي',
                              severity: _VehicleAlertSeverity.critical,
                            ),
                          ),
                        ] else if (vehicle.hasDocumentExpiringSoon) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.medium,
                              AppSpacing.small,
                              AppSpacing.medium,
                              0,
                            ),
                            child: const _VehicleAlertBanner(
                              icon: Icons.schedule_rounded,
                              label: 'مستند يقترب من الانتهاء',
                              severity: _VehicleAlertSeverity.warning,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.small),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                          ),
                          child: _VehicleMetaGrid(
                            items: [
                              _VehicleMetaItem(
                                icon: Icons.confirmation_number_outlined,
                                label: 'اللوحة',
                                value: vehicle.plateNumber,
                              ),
                              _VehicleMetaItem(
                                icon: Icons.event_seat_outlined,
                                label: 'السعة',
                                value: '${vehicle.capacity} مقعد',
                              ),
                              _VehicleMetaItem(
                                icon: Icons.calendar_today_rounded,
                                label: 'الرخصة',
                                value: vehicle.licenseExpiry,
                                valueColor: documentColor,
                              ),
                              _VehicleMetaItem(
                                icon: Icons.verified_user_outlined,
                                label: 'التأمين',
                                value: vehicle.insuranceExpiry,
                                valueColor: documentColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withAlpha(38),
                            border: Border(
                              top: BorderSide(color: scheme.outlineVariant),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.medium),
                            child: Wrap(
                              spacing: AppSpacing.small,
                              runSpacing: AppSpacing.small,
                              alignment: WrapAlignment.end,
                              children: [
                                FilledButton.icon(
                                  onPressed: () => onViewDetails(vehicle),
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  label: const Text('فتح ملف المركبة'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => onEdit(vehicle),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('تعديل'),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: scheme.error,
                                  ),
                                  onPressed: () => onDelete(vehicle),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('حذف'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        _FleetCardsPagination(
          total: vehicles.length,
          currentPage: page,
          pages: pages,
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }
}

class _VehicleOperationalStrip extends StatelessWidget {
  const _VehicleOperationalStrip({
    required this.status,
    required this.reason,
    required this.color,
  });

  final String status;
  final String reason;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            status,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              reason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _VehicleAlertSeverity { warning, critical }

class _VehicleAlertBanner extends StatelessWidget {
  const _VehicleAlertBanner({
    required this.icon,
    required this.label,
    required this.severity,
  });

  final IconData icon;
  final String label;
  final _VehicleAlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    final isCritical = severity == _VehicleAlertSeverity.critical;
    final bg = isCritical
        ? AppStatusColors.errorContainer
        : AppStatusColors.warningContainer;
    final fg = isCritical
        ? AppStatusColors.onErrorContainer
        : AppStatusColors.onWarningContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleMetaGrid extends StatelessWidget {
  const _VehicleMetaGrid({required this.items});

  final List<_VehicleMetaItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 560
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.small) / 2;
        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _VehicleMetaTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _VehicleMetaItem {
  const _VehicleMetaItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
}

class _VehicleMetaTile extends StatelessWidget {
  const _VehicleMetaTile({required this.item});

  final _VehicleMetaItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 17, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: item.valueColor ?? scheme.onSurface,
                    fontWeight: FontWeight.w800,
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
        borderRadius: BorderRadius.circular(16),
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
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: 'التالي',
            onPressed: currentPage >= pages - 1
                ? null
                : () => onPageChanged(currentPage + 1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
