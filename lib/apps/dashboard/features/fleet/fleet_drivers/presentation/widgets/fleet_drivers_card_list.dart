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
    final textTheme = Theme.of(context).textTheme;
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
                final vehicle = _vehicleName(driver.currentVehicleId);
                final snapshot = DriverOperations.snapshot(driver, workspace);
                final healthColor = _healthColor(context, snapshot.health);

                return SizedBox(
                  width: cardWidth,
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    onTap: () => onViewDetails(driver),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.medium),
                          child: Row(
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  StatusChip(
                                    label: snapshot.health.label,
                                    color: healthColor.withAlpha(24),
                                    textColor: healthColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                          ),
                          child: _DriverOperationalStrip(
                            status: snapshot.status.label,
                            reason: snapshot.primaryReason,
                            color: healthColor,
                          ),
                        ),
                        if (driver.isLicenseExpired) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.medium,
                              AppSpacing.small,
                              AppSpacing.medium,
                              0,
                            ),
                            child: const _DriverAlertBanner(
                              icon: Icons.warning_rounded,
                              label: 'الرخصة منتهية',
                              severity: _DriverAlertSeverity.critical,
                            ),
                          ),
                        ] else if (driver.isLicenseExpiringSoon) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.medium,
                              AppSpacing.small,
                              AppSpacing.medium,
                              0,
                            ),
                            child: const _DriverAlertBanner(
                              icon: Icons.schedule_rounded,
                              label: 'الرخصة تنتهي قريباً',
                              severity: _DriverAlertSeverity.warning,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.small),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                          ),
                          child: _DriverMetaGrid(
                            items: [
                              _DriverMetaItem(
                                icon: Icons.phone_android_rounded,
                                label: 'الهاتف',
                                value: driver.phone,
                              ),
                              _DriverMetaItem(
                                icon: Icons.badge_outlined,
                                label: 'الرقم القومي',
                                value: driver.nationalId,
                              ),
                              _DriverMetaItem(
                                icon: Icons.directions_bus_outlined,
                                label: 'المركبة',
                                value: vehicle.isEmpty ? 'بدون مركبة' : vehicle,
                              ),
                              _DriverMetaItem(
                                icon: Icons.calendar_today_rounded,
                                label: 'انتهاء الرخصة',
                                value: driver.licenseExpiry,
                                valueColor: healthColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                          ),
                          child: _DriverDecisionLine(
                            value: snapshot.canAssign
                                ? 'جاهز للتعيين'
                                : 'راجع المخاطر',
                            color: snapshot.canAssign
                                ? scheme.primary
                                : healthColor,
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
                                  onPressed: () => onViewDetails(driver),
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  label: const Text('فتح ملف السائق'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => onEdit(driver),
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
                                  onPressed: () => onDelete(driver),
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
          total: drivers.length,
          currentPage: page,
          pages: pages,
          onPageChanged: onPageChanged,
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

class _DriverOperationalStrip extends StatelessWidget {
  const _DriverOperationalStrip({
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

enum _DriverAlertSeverity { warning, critical }

class _DriverAlertBanner extends StatelessWidget {
  const _DriverAlertBanner({
    required this.icon,
    required this.label,
    required this.severity,
  });

  final IconData icon;
  final String label;
  final _DriverAlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    final isCritical = severity == _DriverAlertSeverity.critical;
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

class _DriverMetaGrid extends StatelessWidget {
  const _DriverMetaGrid({required this.items});

  final List<_DriverMetaItem> items;

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
                child: _DriverMetaTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _DriverMetaItem {
  const _DriverMetaItem({
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

class _DriverMetaTile extends StatelessWidget {
  const _DriverMetaTile({required this.item});

  final _DriverMetaItem item;

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

class _DriverDecisionLine extends StatelessWidget {
  const _DriverDecisionLine({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.assignment_turned_in_outlined, size: 18, color: color),
        const SizedBox(width: AppSpacing.small),
        Text(
          'قرار التشغيل',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
