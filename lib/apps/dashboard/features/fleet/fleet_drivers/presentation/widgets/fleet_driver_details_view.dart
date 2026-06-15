import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/driver_operations.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/widgets/fleet_document_manager.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

class FleetDriverDetailsView extends StatelessWidget {
  final FleetDriver driver;
  final FleetWorkspace workspace;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const FleetDriverDetailsView({
    super.key,
    required this.driver,
    required this.workspace,
    required this.onBack,
    required this.onEdit,
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
    final vehicle = _vehicleName(driver.currentVehicleId);
    final snapshot = DriverOperations.snapshot(driver, workspace);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FleetBreadcrumbs(
          currentLabel: 'تفاصيل السائق: ${driver.name}',
          onBack: onBack,
        ),
        const SizedBox(height: AppSpacing.large),
        _ReadinessPanel(
          driver: driver,
          snapshot: snapshot,
          vehicleLabel: vehicle,
          onEdit: onEdit,
        ),
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            final headerWidgets = [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(
                  driver.imageLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'كود الموظف: ${driver.employeeCode} | الرقم القومي: ${driver.nationalId}',
                    ),
                  ],
                ),
              ),
              if (isCompact) const SizedBox(height: AppSpacing.medium),
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('تعديل بيانات السائق'),
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
                : Row(children: headerWidgets);
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
                        _infoCard(context, driver, vehicle),
                        const SizedBox(height: AppSpacing.medium),
                        FleetDocumentManager(
                          ownerId: driver.id,
                          isDriver: true,
                          documents: driver.documents,
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
                          title: 'سجل الرحلات',
                          items: driver.tripHistory,
                          icon: Icons.map_outlined,
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        _HistoryTimeline(
                          title: 'سجل المخالفات',
                          items: driver.violations,
                          icon: Icons.gpp_bad_outlined,
                          color: scheme.error,
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        _HistoryTimeline(
                          title: 'سجل النشاط',
                          items: driver.activityTimeline,
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
                  _infoCard(context, driver, vehicle),
                  const SizedBox(height: AppSpacing.medium),
                  FleetDocumentManager(
                    ownerId: driver.id,
                    isDriver: true,
                    documents: driver.documents,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(
                    title: 'سجل الرحلات',
                    items: driver.tripHistory,
                    icon: Icons.map_outlined,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(
                    title: 'سجل المخالفات',
                    items: driver.violations,
                    icon: Icons.gpp_bad_outlined,
                    color: scheme.error,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(
                    title: 'سجل النشاط',
                    items: driver.activityTimeline,
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

  Widget _infoCard(BuildContext context, FleetDriver driver, String vehicle) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المعلومات الأساسية والمهنية',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.medium),
          _detailRow('الاسم الكامل', driver.fullName),
          _detailRow('كود الموظف', driver.employeeCode),
          _detailRow('الرقم القومي', driver.nationalId),
          _detailRow('العنوان الكامل', driver.address),
          _detailRow('رقم الهاتف الأساسي', driver.phone),
          _detailRow('رقم هاتف الطوارئ', driver.emergencyPhone),
          _detailRow('تاريخ التعيين', driver.hireDate),
          _detailRow('رقم رخصة القيادة', driver.licenseNumber),
          _detailRow('تاريخ انتهاء الرخصة', driver.licenseExpiryDate),
          _detailRow(
            'المركبة الحالية',
            vehicle.isEmpty ? 'بدون مركبة حالياً' : vehicle,
          ),
          _detailRow('حالة الحساب', driver.status.label),
          if (driver.notes.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.small),
            Text(
              'ملاحظات الإدارة:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              driver.notes,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
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
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessPanel extends StatelessWidget {
  const _ReadinessPanel({
    required this.driver,
    required this.snapshot,
    required this.vehicleLabel,
    required this.onEdit,
  });

  final FleetDriver driver;
  final DriverOperationsSnapshot snapshot;
  final String vehicleLabel;
  final VoidCallback onEdit;

  Color _healthColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (snapshot.health) {
      DriverHealthLevel.healthy => scheme.primary,
      DriverHealthLevel.warning => scheme.tertiary,
      DriverHealthLevel.critical => scheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final healthColor = _healthColor(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final verdict = snapshot.canAssign
              ? 'يمكن تعيين هذا السائق الآن'
              : 'لا تعين هذا السائق قبل معالجة التنبيهات';

          final summary = [
            _ReadinessMetric(
              icon: Icons.verified_user_outlined,
              label: 'قرار التشغيل',
              value: verdict,
              color: snapshot.canAssign ? scheme.primary : healthColor,
            ),
            _ReadinessMetric(
              icon: Icons.directions_bus_filled_outlined,
              label: 'المركبة',
              value: vehicleLabel.isEmpty ? 'بدون مركبة' : vehicleLabel,
              color: vehicleLabel.isEmpty ? scheme.tertiary : scheme.primary,
            ),
            _ReadinessMetric(
              icon: Icons.badge_outlined,
              label: 'الرخصة',
              value: driver.licenseExpiryDate,
              color: healthColor,
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جاهزية السائق للتشغيل',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snapshot.primaryReason,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: healthColor,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    label: snapshot.health.label,
                    color: healthColor.withAlpha(24),
                    textColor: healthColor,
                  ),
                  const SizedBox(width: AppSpacing.small),
                  StatusChip(label: snapshot.status.label),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: summary
                    .map(
                      (metric) => SizedBox(
                        width: compact
                            ? constraints.maxWidth
                            : (constraints.maxWidth - AppSpacing.small * 2) / 3,
                        child: metric,
                      ),
                    )
                    .toList(),
              ),
              if (snapshot.attentionReasons.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.medium),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: snapshot.attentionReasons
                      .map(
                        (reason) => StatusChip(
                          label: reason,
                          color: healthColor.withAlpha(18),
                          textColor: healthColor,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.medium),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('تعديل بيانات الجاهزية'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReadinessMetric extends StatelessWidget {
  const _ReadinessMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'غير محدد' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${item.date} - ${item.description}',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
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
