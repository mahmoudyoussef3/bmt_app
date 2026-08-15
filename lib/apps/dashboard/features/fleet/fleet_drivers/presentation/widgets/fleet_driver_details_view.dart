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
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

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
          _DriverHeroCard(
            driver: driver,
            snapshot: snapshot,
            vehicleLabel: vehicle,
            onEdit: onEdit,
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

/// Identity + a single, unambiguous readiness signal.
///
/// The old layout spread status across three separate chips (account status,
/// health, operational status) plus a second card repeating health and
/// status again next to three bordered metric tiles. Those three vocabularies
/// always agreed in practice — `driver.status` folds straight into
/// [DriverOperationsSnapshot.status] — so showing all of them just made the
/// operator re-read the same fact three times. This card says it once: one
/// pill (operational status, tinted by health) with the reason right next to
/// it, and any *additional* issues beyond that reason as small trailing tags.
class _DriverHeroCard extends StatelessWidget {
  const _DriverHeroCard({
    required this.driver,
    required this.snapshot,
    required this.vehicleLabel,
    required this.onEdit,
  });

  final FleetDriver driver;
  final DriverOperationsSnapshot snapshot;
  final String vehicleLabel;
  final VoidCallback onEdit;

  static AppStatusTone _healthTone(DriverHealthLevel health) =>
      switch (health) {
        DriverHealthLevel.healthy => AppStatusTone.success,
        DriverHealthLevel.warning => AppStatusTone.warning,
        DriverHealthLevel.critical => AppStatusTone.error,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = context.status(_healthTone(snapshot.health));
    final extraIssues = snapshot.attentionReasons.skip(1).toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                height: 64,
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
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(
                          label: snapshot.status.label,
                          color: status.tint,
                          textColor: status.ink,
                        ),
                        Text(
                          snapshot.primaryReason,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: status.ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
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
              Divider(height: 1, color: scheme.outlineVariant.withAlpha(120)),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.large,
                runSpacing: AppSpacing.small,
                children: [
                  _InlineFact(
                    icon: Icons.badge_outlined,
                    label: 'كود الموظف',
                    value: driver.employeeCode,
                  ),
                  _InlineFact(
                    icon: Icons.phone_android_rounded,
                    label: 'الهاتف',
                    value: driver.phone,
                  ),
                  _InlineFact(
                    icon: Icons.directions_bus_outlined,
                    label: 'المركبة الحالية',
                    value: vehicleLabel.isEmpty
                        ? 'بدون مركبة'
                        : vehicleLabel,
                    valueColor: vehicleLabel.isEmpty
                        ? context.status(AppStatusTone.warning).ink
                        : null,
                  ),
                ],
              ),
              if (extraIssues.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.medium),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: extraIssues
                      .map(
                        (reason) => StatusChip(
                          label: reason,
                          color: status.tint,
                          textColor: status.ink,
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

class _InlineFact extends StatelessWidget {
  const _InlineFact({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '$label  ',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(
          value.isEmpty ? 'غير محدد' : value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
          const SizedBox(height: AppSpacing.small),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 620;
              final width = twoColumns
                  ? (constraints.maxWidth - AppSpacing.medium) / 2
                  : constraints.maxWidth;
              final fields = [
                _InfoField(
                  icon: Icons.person_outline_rounded,
                  label: 'الاسم الكامل',
                  value: driver.fullName,
                ),
                _InfoField(
                  icon: Icons.badge_outlined,
                  label: 'كود الموظف',
                  value: driver.employeeCode,
                ),
                _InfoField(
                  icon: Icons.credit_card_outlined,
                  label: 'الرقم القومي',
                  value: driver.nationalId,
                ),
                _InfoField(
                  icon: Icons.phone_android_rounded,
                  label: 'رقم الهاتف الأساسي',
                  value: driver.phone,
                ),
                _InfoField(
                  icon: Icons.contact_phone_outlined,
                  label: 'رقم هاتف الطوارئ',
                  value: driver.emergencyPhone,
                ),
                _InfoField(
                  icon: Icons.work_outline_rounded,
                  label: 'تاريخ التعيين',
                  value: driver.hireDate,
                ),
                _InfoField(
                  icon: Icons.assignment_ind_outlined,
                  label: 'رقم رخصة القيادة',
                  value: driver.licenseNumber,
                ),
                _InfoField(
                  icon: Icons.event_available_outlined,
                  label: 'تاريخ انتهاء الرخصة',
                  value: driver.licenseExpiryDate,
                  valueColor: driver.isLicenseExpired
                      ? Theme.of(context).colorScheme.error
                      : driver.isLicenseExpiringSoon
                      ? Theme.of(context).colorScheme.tertiary
                      : null,
                ),
                _InfoField(
                  icon: Icons.directions_bus_outlined,
                  label: 'المركبة الحالية',
                  value: vehicle.isEmpty ? 'بدون مركبة حالياً' : vehicle,
                ),
                _InfoField(
                  icon: Icons.verified_outlined,
                  label: 'حالة الحساب',
                  value: driver.status.label,
                ),
                _InfoField(
                  icon: Icons.home_outlined,
                  label: 'العنوان الكامل',
                  value: driver.address,
                  wide: true,
                ),
              ];

              return Wrap(
                children: fields
                    .map(
                      (field) => SizedBox(
                        width: field.wide ? constraints.maxWidth : width,
                        child: field,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (driver.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
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

/// A single labelled fact rendered as a plain row with a hairline underneath,
/// instead of its own bordered/tinted box. A data sheet with a dozen facts
/// reads as a form when each row is this light — a dozen individually boxed
/// tiles reads as a wall of cards.
class _InfoField extends StatelessWidget {
  const _InfoField({
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      margin: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withAlpha(90)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.onSurfaceVariant, size: 18),
          const SizedBox(width: AppSpacing.small),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'غير محدد' : value,
                  maxLines: wide ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor,
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

/// Trip/violation/license counts as one stat bar instead of three separately
/// tinted boxes — the numbers carry the meaning, the colour just flags the
/// ones worth a second look.
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

    final items = [
      _StatItem(
        label: 'إجمالي الرحلات',
        value: '$tripCount',
        icon: Icons.map_outlined,
        color: scheme.primary,
      ),
      _StatItem(
        label: 'المخالفات',
        value: '$violationCount',
        icon: Icons.gpp_bad_outlined,
        color: violationCount > 0 ? scheme.error : scheme.primary,
      ),
      _StatItem(
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
              final compact = constraints.maxWidth < 480;
              if (compact) {
                return Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      items[i],
                      if (i < items.length - 1)
                        const SizedBox(height: AppSpacing.small),
                    ],
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      Expanded(child: items[i]),
                      if (i < items.length - 1)
                        VerticalDivider(
                          width: AppSpacing.large,
                          thickness: 1,
                          color: scheme.outlineVariant.withAlpha(110),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
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
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.small),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
