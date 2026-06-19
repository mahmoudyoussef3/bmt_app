import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/driver_operations.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/widgets/fleet_document_manager.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FleetBreadcrumbs(
            currentLabel: 'ملف السائق: ${driver.name}',
            onBack: onBack,
          ),
          const SizedBox(height: AppSpacing.medium),
          _DriverProfileHero(
            driver: driver,
            snapshot: snapshot,
            vehicleLabel: vehicle,
            onEdit: onEdit,
          ),
          const SizedBox(height: AppSpacing.medium),
          _ReadinessPanel(
            driver: driver,
            snapshot: snapshot,
            vehicleLabel: vehicle,
          ),
          const SizedBox(height: AppSpacing.medium),
          _PerformanceMetricsCard(driver: driver),
          const SizedBox(height: AppSpacing.medium),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 980;
              final info = _DriverInfoCard(driver: driver, vehicle: vehicle);
              final documents = FleetDocumentManager(
                ownerId: driver.id,
                isDriver: true,
                documents: driver.documents,
              );
              final history = Column(
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
              );

              if (!isDesktop) {
                return Column(
                  children: [
                    info,
                    const SizedBox(height: AppSpacing.medium),
                    documents,
                    const SizedBox(height: AppSpacing.medium),
                    history,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        info,
                        const SizedBox(height: AppSpacing.medium),
                        documents,
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(flex: 4, child: history),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DriverProfileHero extends StatelessWidget {
  const _DriverProfileHero({
    required this.driver,
    required this.snapshot,
    required this.vehicleLabel,
    required this.onEdit,
  });

  final FleetDriver driver;
  final DriverOperationsSnapshot snapshot;
  final String vehicleLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final healthColor = switch (snapshot.health) {
      DriverHealthLevel.healthy => scheme.primary,
      DriverHealthLevel.warning => scheme.tertiary,
      DriverHealthLevel.critical => scheme.error,
    };

    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          color: scheme.primary.withAlpha(12),
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: scheme.primary.withAlpha(28)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final identity = Row(
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: FleetAvatar(
                    label: driver.imageLabel,
                    profileImageUrl: driver.profileImageUrl,
                  ),
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
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: AppSpacing.small,
                        runSpacing: AppSpacing.xSmall,
                        children: [
                          StatusChip(label: driver.status.label),
                          StatusChip(
                            label: snapshot.health.label,
                            color: healthColor.withAlpha(24),
                            textColor: healthColor,
                          ),
                          StatusChip(label: snapshot.status.label),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            final action = FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('تعديل بيانات السائق'),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact) ...[
                  identity,
                  const SizedBox(height: AppSpacing.medium),
                  action,
                ] else
                  Row(
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: AppSpacing.medium),
                      action,
                    ],
                  ),
                const SizedBox(height: AppSpacing.medium),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    _HeroFact(
                      icon: Icons.badge_outlined,
                      label: 'كود الموظف',
                      value: driver.employeeCode,
                    ),
                    _HeroFact(
                      icon: Icons.phone_android_rounded,
                      label: 'الهاتف',
                      value: driver.phone,
                    ),
                    _HeroFact(
                      icon: Icons.directions_bus_outlined,
                      label: 'المركبة الحالية',
                      value: vehicleLabel.isEmpty ? 'بدون مركبة' : vehicleLabel,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 170, maxWidth: 260),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(170),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: scheme.primary, size: 18),
          const SizedBox(width: AppSpacing.small),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value.isEmpty ? 'غير محدد' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverInfoCard extends StatelessWidget {
  const _DriverInfoCard({required this.driver, required this.vehicle});

  final FleetDriver driver;
  final String vehicle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FleetSectionTitle(
            icon: Icons.account_box_outlined,
            title: 'البيانات الأساسية والمهنية',
            subtitle: 'معلومات التواصل والرخصة والتعيين التشغيلي للسائق.',
          ),
          const SizedBox(height: AppSpacing.medium),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 620;
              final width = twoColumns
                  ? (constraints.maxWidth - AppSpacing.small) / 2
                  : constraints.maxWidth;
              final details = [
                _DetailTile(
                  icon: Icons.person_outline_rounded,
                  label: 'الاسم الكامل',
                  value: driver.fullName,
                ),
                _DetailTile(
                  icon: Icons.badge_outlined,
                  label: 'كود الموظف',
                  value: driver.employeeCode,
                ),
                _DetailTile(
                  icon: Icons.credit_card_outlined,
                  label: 'الرقم القومي',
                  value: driver.nationalId,
                ),
                _DetailTile(
                  icon: Icons.phone_android_rounded,
                  label: 'رقم الهاتف الأساسي',
                  value: driver.phone,
                ),
                _DetailTile(
                  icon: Icons.contact_phone_outlined,
                  label: 'رقم هاتف الطوارئ',
                  value: driver.emergencyPhone,
                ),
                _DetailTile(
                  icon: Icons.work_outline_rounded,
                  label: 'تاريخ التعيين',
                  value: driver.hireDate,
                ),
                _DetailTile(
                  icon: Icons.assignment_ind_outlined,
                  label: 'رقم رخصة القيادة',
                  value: driver.licenseNumber,
                ),
                _DetailTile(
                  icon: Icons.event_available_outlined,
                  label: 'تاريخ انتهاء الرخصة',
                  value: driver.licenseExpiryDate,
                  valueColor: driver.isLicenseExpired
                      ? Theme.of(context).colorScheme.error
                      : driver.isLicenseExpiringSoon
                      ? Theme.of(context).colorScheme.tertiary
                      : null,
                ),
                _DetailTile(
                  icon: Icons.directions_bus_outlined,
                  label: 'المركبة الحالية',
                  value: vehicle.isEmpty ? 'بدون مركبة حالياً' : vehicle,
                ),
                _DetailTile(
                  icon: Icons.verified_outlined,
                  label: 'حالة الحساب',
                  value: driver.status.label,
                ),
                _DetailTile(
                  icon: Icons.home_outlined,
                  label: 'العنوان الكامل',
                  value: driver.address,
                  wide: true,
                ),
              ];

              return Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: details
                    .map(
                      (detail) => SizedBox(
                        width: detail.wide ? constraints.maxWidth : width,
                        child: detail,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (driver.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.medium),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(55),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withAlpha(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ملاحظات الإدارة',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(driver.notes),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary, size: 19),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'غير محدد' : value,
                  maxLines: wide ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w900,
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

class _ReadinessPanel extends StatelessWidget {
  const _ReadinessPanel({
    required this.driver,
    required this.snapshot,
    required this.vehicleLabel,
  });

  final FleetDriver driver;
  final DriverOperationsSnapshot snapshot;
  final String vehicleLabel;

  static (Color bg, Color fg) _healthColors(DriverHealthLevel health) =>
      switch (health) {
        DriverHealthLevel.healthy => (
          AppStatusColors.successContainer,
          AppStatusColors.onSuccessContainer,
        ),
        DriverHealthLevel.warning => (
          AppStatusColors.warningContainer,
          AppStatusColors.onWarningContainer,
        ),
        DriverHealthLevel.critical => (
          AppStatusColors.errorContainer,
          AppStatusColors.onErrorContainer,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (healthBg, healthFg) = _healthColors(snapshot.health);

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
              color: snapshot.canAssign ? scheme.primary : healthFg,
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
              color: healthFg,
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
                                color: healthFg,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    label: snapshot.health.label,
                    color: healthBg,
                    textColor: healthFg,
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
                          color: healthBg,
                          textColor: healthFg,
                        ),
                      )
                      .toList(),
                ),
              ],
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
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
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
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
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
            }),
        ],
      ),
    );
  }
}

class _PerformanceMetricsCard extends StatelessWidget {
  const _PerformanceMetricsCard({required this.driver});
  final FleetDriver driver;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tripCount = driver.tripHistory.length;
    final violationCount = driver.violations.length;
    final licenseExpired = driver.isLicenseExpired;
    final licenseWarn = driver.isLicenseExpiringSoon;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مؤشرات الأداء',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.medium),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final width = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - AppSpacing.small * 2) / 3;
              final items = [
                _PerfMetric(
                  label: 'إجمالي الرحلات',
                  value: '$tripCount',
                  icon: Icons.map_outlined,
                  color: scheme.primary,
                ),
                _PerfMetric(
                  label: 'المخالفات',
                  value: '$violationCount',
                  icon: Icons.gpp_bad_outlined,
                  color: violationCount > 0 ? scheme.error : scheme.primary,
                ),
                _PerfMetric(
                  label: 'الرخصة',
                  value: licenseExpired
                      ? 'منتهية'
                      : licenseWarn
                      ? 'تنتهي قريباً'
                      : 'سارية',
                  icon: Icons.badge_outlined,
                  color: licenseExpired
                      ? scheme.error
                      : licenseWarn
                      ? scheme.tertiary
                      : scheme.primary,
                ),
              ];
              return Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: items
                    .map((item) => SizedBox(width: width, child: item))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PerfMetric extends StatelessWidget {
  const _PerfMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
