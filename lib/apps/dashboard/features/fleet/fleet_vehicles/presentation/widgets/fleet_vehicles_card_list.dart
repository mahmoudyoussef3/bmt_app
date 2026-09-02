import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_pager.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_results_header.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_format.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// المركبات on a narrow console — the same rows as [FleetVehiclesTable],
/// stacked.
///
/// Rebuilt to mirror the drivers card one tab over, fact for fact: header
/// (picture, code, spec, live status) → the pairing line → the one thing that
/// needs attention, if anything does → the two facts an operator scans for →
/// actions. It used to be a mini data sheet — a four-tile meta grid, a tinted
/// operational strip, an alert banner and three full-width buttons per card —
/// which made a nine-vehicle fleet several screens tall and buried the one
/// status signal among four competing tinted blocks.
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
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, vehicles.length);
    final paged = start >= vehicles.length
        ? <FleetVehicle>[]
        : vehicles.sublist(start, end);

    if (paged.isEmpty) {
      return const DashboardEmptyState(
        icon: DashboardIcons.vehicle,
        title: 'لا توجد مركبات مطابقة',
        message:
            'لا تطابق أي مركبة البحث أو الفلاتر الحالية. وسّع الفلاتر، أو أضف '
            'مركبة جديدة إلى الأسطول.',
      );
    }

    final pages = (vehicles.length / pageSize).ceil().clamp(1, 9999);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = AppSpacing.medium;
            final columns = dashboardCardColumnsFor(constraints.maxWidth);
            final cardWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final vehicle in paged)
                  SizedBox(
                    width: cardWidth,
                    child: _VehicleListCard(
                      vehicle: vehicle,
                      operational: workspace.operationalStatusOf(vehicle),
                      driverName: _driverName(vehicle.currentDriverId),
                      onViewDetails: () => onViewDetails(vehicle),
                      onEdit: () => onEdit(vehicle),
                      onDelete: () => onDelete(vehicle),
                    ),
                  ),
              ],
            );
          },
        ),
        DashboardPagerBar(
          totalLabel: 'الإجمالي ${FleetFormat.count(vehicles.length)} مركبة',
          currentPage: page,
          pages: pages,
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }
}

class _VehicleListCard extends StatelessWidget {
  const _VehicleListCard({
    required this.vehicle,
    required this.operational,
    required this.driverName,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final FleetVehicle vehicle;
  final FleetOperationalStatus operational;
  final String driverName;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static AppStatusTone _recordTone(FleetVehicleStatus status) =>
      switch (status) {
        FleetVehicleStatus.active => AppStatusTone.info,
        FleetVehicleStatus.maintenance => AppStatusTone.warning,
        FleetVehicleStatus.suspended => AppStatusTone.error,
        FleetVehicleStatus.archived => AppStatusTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final spec = [
      vehicle.brand,
      vehicle.model,
      if (vehicle.modelYear > 0) '${vehicle.modelYear}',
    ].where((part) => part.trim().isNotEmpty).join(' ');

    final attention = vehicle.hasExpiredDocument
        ? 'يوجد مستند منتهي — راجع ملف المركبة'
        : vehicle.hasDocumentExpiringSoon
        ? 'مستند يقترب من الانتهاء'
        : null;
    final attentionTone = vehicle.hasExpiredDocument
        ? AppStatusTone.error
        : AppStatusTone.warning;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      onTap: onViewDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spec.isEmpty ? 'بدون بيانات طراز' : spec,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: DashboardColors.mutedInk(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              // One status pill, not two stacked: the record state only earns
              // its own line when it disagrees with what the bus is doing.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FleetOperationalChip(status: operational, duty: null),
                  // Only when the live reading and the record disagree — an
                  // in-flight trip outranks the record, so this is the one
                  // case the chip above does not already say.
                  if (operational == FleetOperationalStatus.onTrip &&
                      vehicle.status != FleetVehicleStatus.active) ...[
                    const SizedBox(height: AppSpacing.xSmall),
                    DashboardStatusChip(
                      label: 'السجل: ${vehicle.status.label}',
                      color: context.status(_recordTone(vehicle.status)).tint,
                      textColor: context
                          .status(_recordTone(vehicle.status))
                          .ink,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          _DriverLine(driverName: driverName, onAssign: onEdit),
          if (attention != null) ...[
            const SizedBox(height: AppSpacing.small),
            _AttentionLine(
              reason: attention,
              color: context.status(attentionTone).ink,
            ),
          ],
          const SizedBox(height: AppSpacing.small),
          _FactsLine(vehicle: vehicle),
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
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.xSmall),
              FilledButton.tonalIcon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('فتح ملف المركبة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Which driver, if any" — the vehicle-side mirror of the drivers card's
/// vehicle line. An unassigned bus cannot be scheduled, so that state keeps a
/// call to action; an assigned one is a quiet one-line fact.
class _DriverLine extends StatelessWidget {
  const _DriverLine({required this.driverName, required this.onAssign});

  final String driverName;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    if (driverName.isEmpty) {
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
                'بدون سائق مخصص',
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
              child: const Text('تعيين سائق'),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Icon(
          DashboardIcons.captains,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            driverName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DashboardColors.ink(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AttentionLine extends StatelessWidget {
  const _AttentionLine({required this.reason, required this.color});

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

/// The plate, the capacity and the paperwork verdict — the three facts a
/// dispatcher matches a booking against, on one line.
class _FactsLine extends StatelessWidget {
  const _FactsLine({required this.vehicle});

  final FleetVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: DashboardColors.mutedInk(context));

    return Row(
      children: [
        Icon(
          Icons.confirmation_number_outlined,
          size: 15,
          color: DashboardColors.mutedInk(context),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            vehicle.plateNumber.isEmpty ? 'بدون لوحة' : vehicle.plateNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Icon(
          Icons.event_seat_outlined,
          size: 15,
          color: DashboardColors.mutedInk(context),
        ),
        const SizedBox(width: 4),
        Text('${FleetFormat.count(vehicle.capacity)} مقعد', style: style),
        const Spacer(),
        FleetDocumentsHealthCell(
          documents: [
            FleetDatedDocument(label: 'رخصة', date: vehicle.licenseExpiry),
            FleetDatedDocument(label: 'تأمين', date: vehicle.insuranceExpiry),
            FleetDatedDocument(label: 'فحص', date: vehicle.inspectionExpiry),
          ],
        ),
      ],
    );
  }
}
