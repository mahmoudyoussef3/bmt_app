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
  final ScrollController? scrollController;

  const FleetDriverDetailsView({
    super.key,
    required this.driver,
    required this.workspace,
    required this.onBack,
    required this.onEdit,
    this.scrollController,
  });

  String _vehicleName(String vehicleId) {
    if (vehicleId.isEmpty) return '';
    final match = workspace.vehicles.where((v) => v.id == vehicleId);
    if (match.isEmpty) return '';
    return match.first.vehicleNumber;
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _vehicleName(driver.currentVehicleId);
    final snapshot = DriverOperations.snapshot(driver, workspace);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.xLarge),
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
                    title: 'سجل الرحلات (آخر 12 شهر)',
                    items: driver.tripHistory,
                    icon: Icons.map_outlined,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(
                    title: 'سجل المركبات المعينة سابقاً',
                    items: driver.vehicleHistory,
                    icon: Icons.directions_bus_filled_outlined,
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withAlpha(38),
            scheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(
          color: scheme.primary.withAlpha(51),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary.withAlpha(76), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withAlpha(51),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: FleetAvatar(
                    label: driver.imageLabel,
                    profileImageUrl: driver.profileImageUrl,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.large),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      driver.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(
                          label: snapshot.status.label,
                          color: status.tint,
                          textColor: status.ink,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: status.tint.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: status.tint.withAlpha(76)),
                          ),
                          child: Text(
                            snapshot.primaryReason,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: status.ink,
                                  fontWeight: FontWeight.bold,
                                ),
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
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radius),
              ),
            ),
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: const Text('تعديل البيانات', style: TextStyle(fontWeight: FontWeight.bold)),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                identity,
                const SizedBox(height: AppSpacing.large),
                action,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: AppSpacing.large),
                    action,
                  ],
                ),
              const SizedBox(height: AppSpacing.xLarge),
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: scheme.surface.withAlpha(127),
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  border: Border.all(color: scheme.outlineVariant.withAlpha(76)),
                ),
                child: Wrap(
                  spacing: AppSpacing.xLarge,
                  runSpacing: AppSpacing.medium,
                  children: [
                    _InlineFact(
                      icon: Icons.badge_rounded,
                      label: 'كود الموظف',
                      value: driver.employeeCode,
                    ),
                    _InlineFact(
                      icon: Icons.phone_rounded,
                      label: 'الهاتف',
                      value: driver.phone,
                    ),
                    _InlineFact(
                      icon: Icons.directions_bus_rounded,
                      label: 'المركبة الحالية',
                      value: vehicleLabel.isEmpty ? 'بدون مركبة' : vehicleLabel,
                      valueColor: vehicleLabel.isEmpty ? context.status(AppStatusTone.warning).ink : scheme.primary,
                    ),
                  ],
                ),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (valueColor ?? scheme.primary).withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: valueColor ?? scheme.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value.isEmpty ? 'غير محدد' : value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: valueColor ?? scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
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
    final scheme = Theme.of(context).colorScheme;
    
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FleetSectionTitle(
            icon: Icons.account_box_rounded,
            title: 'البيانات الأساسية والمهنية',
            subtitle: 'معلومات التواصل والرخصة والتعيين التشغيلي للسائق.',
          ),
          const SizedBox(height: AppSpacing.large),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 620;
              final width = twoColumns
                  ? (constraints.maxWidth - AppSpacing.medium) / 2
                  : constraints.maxWidth;
                  
              final fields = [
                _InfoField(
                  icon: Icons.person_rounded,
                  label: 'الاسم الكامل',
                  value: driver.fullName,
                ),
                _InfoField(
                  icon: Icons.badge_rounded,
                  label: 'كود الموظف',
                  value: driver.employeeCode,
                ),
                _InfoField(
                  icon: Icons.credit_card_rounded,
                  label: 'الرقم القومي',
                  value: driver.nationalId,
                ),
                _InfoField(
                  icon: Icons.phone_android_rounded,
                  label: 'رقم الهاتف الأساسي',
                  value: driver.phone,
                ),
                _InfoField(
                  icon: Icons.contact_phone_rounded,
                  label: 'رقم هاتف الطوارئ',
                  value: driver.emergencyPhone,
                ),
                _InfoField(
                  icon: Icons.work_rounded,
                  label: 'تاريخ التعيين',
                  value: driver.hireDate,
                ),
                _InfoField(
                  icon: Icons.assignment_ind_rounded,
                  label: 'رقم رخصة القيادة',
                  value: driver.licenseNumber,
                ),
                _InfoField(
                  icon: Icons.event_available_rounded,
                  label: 'تاريخ انتهاء الرخصة',
                  value: driver.licenseExpiryDate,
                  valueColor: driver.isLicenseExpired
                      ? scheme.error
                      : driver.isLicenseExpiringSoon
                      ? scheme.tertiary
                      : scheme.primary,
                ),
                _InfoField(
                  icon: Icons.directions_bus_rounded,
                  label: 'المركبة الحالية',
                  value: vehicle.isEmpty ? 'بدون مركبة حالياً' : vehicle,
                ),
                _InfoField(
                  icon: Icons.verified_rounded,
                  label: 'حالة الحساب',
                  value: driver.status.label,
                ),
                _InfoField(
                  icon: Icons.home_rounded,
                  label: 'العنوان الكامل',
                  value: driver.address,
                  wide: true,
                ),
              ];

              return Wrap(
                spacing: AppSpacing.medium,
                runSpacing: AppSpacing.medium,
                children: fields
                    .map(
                      (field) => SizedBox(
                        width: field.wide ? constraints.maxWidth : width - (AppSpacing.medium / 2),
                        child: field,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (driver.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.large),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer.withAlpha(76),
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(
                  color: scheme.tertiary.withAlpha(51),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.tertiary.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, color: scheme.tertiary),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ملاحظات الإدارة',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          driver.notes,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outlineVariant.withAlpha(76)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(127),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: scheme.primary, size: 18),
          ),
          const SizedBox(width: AppSpacing.medium),
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
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'غير محدد' : value,
                  maxLines: wide ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: valueColor ?? scheme.onSurface,
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
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(76),
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(color: scheme.outlineVariant.withAlpha(51)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: scheme.onSurfaceVariant, size: 20),
                  const SizedBox(width: AppSpacing.small),
                  Text('لا توجد سجلات حالياً.', style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.surface,
                          border: Border.all(color: iconColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withAlpha(76),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 50,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [iconColor.withAlpha(127), iconColor.withAlpha(25)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.date} - ${item.description}',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
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
    final completed = driver.completedTripsCount;
    final cancelled = driver.cancelledTripsCount;
    final totalTrips = completed + cancelled;
    final completionRate = totalTrips == 0
        ? null
        : (completed / totalTrips * 100).round();
    final licenseExpired = driver.isLicenseExpired;
    final licenseWarn = driver.isLicenseExpiringSoon;

    final items = [
      _StatItem(
        label: 'الرحلات المكتملة',
        value: '$completed',
        icon: Icons.map_rounded,
        color: scheme.primary,
        subtitle: 'آخر 12 شهر',
      ),
      _StatItem(
        label: 'معدل الإتمام',
        value: completionRate == null ? '—' : '$completionRate%',
        icon: Icons.fact_check_rounded,
        color: completionRate != null && completionRate < 80
            ? scheme.error
            : scheme.primary,
        subtitle: totalTrips == 0 ? 'لا توجد رحلات بعد' : '$cancelled ملغاة',
      ),
      _StatItem(
        label: 'تقييم الركاب',
        value: driver.ratingCount > 0
            ? driver.rating.toStringAsFixed(1)
            : '—',
        icon: Icons.star_rounded,
        color: scheme.primary,
        subtitle: driver.ratingCount > 0
            ? '${driver.ratingCount} تقييم'
            : 'لا يوجد تقييم بعد',
      ),
      _StatItem(
        label: 'حالة الرخصة',
        value: licenseExpired
            ? 'منتهية'
            : licenseWarn
            ? 'تنتهي قريباً'
            : 'سارية',
        icon: Icons.badge_rounded,
        color: licenseExpired
            ? scheme.error
            : licenseWarn
            ? scheme.tertiary
            : scheme.primary,
        subtitle: licenseExpired || licenseWarn ? 'تتطلب تجديد' : 'صالحة للعمل',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'مؤشرات الأداء السريعة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            if (compact) {
              return Column(
                children: items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.small),
                  child: item,
                )).toList(),
              );
            }
            return Row(
              children: items.map((item) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: item == items.last ? 0 : AppSpacing.medium,
                  ),
                  child: item,
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: color.withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withAlpha(204),
                ),
          ),
        ],
      ),
    );
  }
}

