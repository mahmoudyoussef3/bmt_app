import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_seat_layout_visualizer.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/widgets/fleet_document_manager.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

class FleetVehicleDetailsView extends StatelessWidget {
  final FleetVehicle vehicle;
  final FleetWorkspace workspace;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final ScrollController? scrollController;

  const FleetVehicleDetailsView({
    super.key,
    required this.vehicle,
    required this.workspace,
    required this.onBack,
    required this.onEdit,
    this.scrollController,
  });

  String _driverName(String driverId) {
    if (driverId.isEmpty) return '';
    final match = workspace.drivers.where((d) => d.id == driverId);
    if (match.isEmpty) return '';
    return match.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final vehicleDocs = workspace.documents
        .where((d) => d.ownerId == vehicle.id)
        .toList();
    final driverName = _driverName(vehicle.currentDriverId);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FleetBreadcrumbs(
            currentLabel: 'تفاصيل المركبة: ${vehicle.vehicleNumber}',
            onBack: onBack,
          ),
          const SizedBox(height: AppSpacing.medium),
          _VehicleHeroCard(
            vehicle: vehicle,
            driverName: driverName,
            onEdit: onEdit,
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
                        _VehicleImageGallery(vehicle: vehicle),
                        const SizedBox(height: AppSpacing.medium),
                        _infoCard(context, vehicle, driverName),
                        const SizedBox(height: AppSpacing.medium),
                        FleetSeatLayoutVisualizer(
                          seatConfig: vehicle.seatConfiguration,
                          vehicleType: VehicleTypeParser.fromDatabase(
                            vehicle.vehicleType,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        FleetDocumentManager(
                          ownerId: vehicle.id,
                          isDriver: false,
                          documents: vehicleDocs,
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
                          title: 'سجل السائقين السابقين',
                          items: vehicle.previousDrivers,
                          icon: Icons.people_outline_rounded,
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        _HistoryTimeline(
                          title: 'سجل الرحلات (آخر 12 شهر)',
                          items: vehicle.tripHistory,
                          icon: Icons.map_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _VehicleImageGallery(vehicle: vehicle),
                  const SizedBox(height: AppSpacing.medium),
                  _infoCard(context, vehicle, driverName),
                  const SizedBox(height: AppSpacing.medium),
                  FleetSeatLayoutVisualizer(
                    seatConfig: vehicle.seatConfiguration,
                    vehicleType: VehicleTypeParser.fromDatabase(
                      vehicle.vehicleType,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  FleetDocumentManager(
                    ownerId: vehicle.id,
                    isDriver: false,
                    documents: vehicleDocs,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(
                    title: 'سجل السائقين السابقين',
                    items: vehicle.previousDrivers,
                    icon: Icons.people_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(
                    title: 'سجل الرحلات (آخر 12 شهر)',
                    items: vehicle.tripHistory,
                    icon: Icons.map_outlined,
                  ),
                ],
              );
            }
          },
        ),
      ],
    ),
  );
}

  Widget _infoCard(
    BuildContext context,
    FleetVehicle vehicle,
    String driverName,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المعلومات الأساسية والتشغيلية',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.medium),
          _detailRow(context, 'كود المركبة', vehicle.vehicleCode),
          _detailRow(context, 'رقم اللوحة المرورية', vehicle.plateNumber),
          _detailRow(context, 'نوع المركبة', vehicle.vehicleType),
          _detailRow(context, 'الماركة', vehicle.brand),
          _detailRow(context, 'طراز الموديل', vehicle.model),
          _detailRow(context, 'سنة الصنع', '${vehicle.manufactureYear}'),
          _detailRow(context, 'لون المركبة', vehicle.color),
          _detailRow(context, 'السعة الركابية', '${vehicle.capacity} مقعد'),
          _detailRow(context, 'نوع تخطيط المقاعد', vehicle.seatLayoutType),
          _detailRow(
            context,
            'السائق الحالي',
            driverName.isEmpty ? 'بدون سائق حالياً' : driverName,
          ),
          _detailRow(context, 'حالة المركبة', vehicle.status.label),
          _detailRow(
            context,
            'الرحلات المكتملة (آخر 12 شهر)',
            '${vehicle.completedTripsCount}',
          ),
          _detailRow(
            context,
            'تقييم الركاب',
            vehicle.ratingCount > 0
                ? '${vehicle.rating.toStringAsFixed(1)} (${vehicle.ratingCount} تقييم)'
                : 'لا يوجد تقييم بعد',
          ),
          _detailRow(context, 'انتهاء الرخصة', vehicle.licenseExpiry),
          _detailRow(context, 'انتهاء التأمين', vehicle.insuranceExpiry),
          _detailRow(context, 'انتهاء الفحص الفني', vehicle.inspectionExpiry),
          if (vehicle.notes.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.small),
            Text(
              'ملاحظات التشغيل والصيانة:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              vehicle.notes,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: context.status(AppStatusTone.neutral).ink,
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

class _HistoryTimeline extends StatelessWidget {
  final String title;
  final List<FleetHistoryItem> items;
  final IconData icon;

  const _HistoryTimeline({
    required this.title,
    required this.items,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

class _VehicleImageGallery extends StatefulWidget {
  const _VehicleImageGallery({required this.vehicle});

  final FleetVehicle vehicle;

  @override
  State<_VehicleImageGallery> createState() => _VehicleImageGalleryState();
}

class _VehicleImageGalleryState extends State<_VehicleImageGallery> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant _VehicleImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vehicle.images.length <= _selectedIndex) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final images = widget.vehicle.images;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معرض صور المركبة',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.medium),
          if (images.isEmpty)
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(color: scheme.outline.withAlpha(60)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 44,
                    color: scheme.primary.withAlpha(140),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  const Text(
                    'لا توجد صور للمركبة حالياً',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اضغط على زر "تعديل البيانات" لإضافة صور للأسطول.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radius),
              child: Container(
                height: 260,
                width: double.infinity,
                color: scheme.surfaceContainerHighest,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: Image.network(
                    images[_selectedIndex].url,
                    key: ValueKey<int>(_selectedIndex),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (images.length > 1) ...[
              const SizedBox(height: AppSpacing.medium),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedIndex;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.small,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusSmall,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.outline.withAlpha(60),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusSmall,
                            ),
                            child: Image.network(
                              images[index].url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.broken_image_outlined,
                                size: 20,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _VehicleHeroCard extends StatelessWidget {
  const _VehicleHeroCard({
    required this.vehicle,
    required this.driverName,
    required this.onEdit,
  });

  final FleetVehicle vehicle;
  final String driverName;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = context.status(
      vehicle.status == FleetVehicleStatus.active
          ? AppStatusTone.success
          : vehicle.status == FleetVehicleStatus.maintenance
              ? AppStatusTone.warning
              : AppStatusTone.error,
    );

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
                  child: CircleAvatar(
                    backgroundColor: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.directions_bus_filled_rounded,
                      size: 40,
                      color: scheme.primary,
                    ),
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
                      '${vehicle.brand} ${vehicle.model}',
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
                        DashboardStatusChip(
                          label: vehicle.status.label,
                          color: status.tint,
                          textColor: status.ink,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withAlpha(100),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Text(
                            vehicle.vehicleNumber,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withAlpha(100),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Text(
                            vehicle.plateNumber,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
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

          final metrics = Row(
            mainAxisAlignment: compact ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              _MetricBlock(
                label: 'المقاعد',
                value: '${vehicle.capacity}',
                icon: Icons.event_seat_rounded,
              ),
              const SizedBox(width: AppSpacing.large),
              _MetricBlock(
                label: 'سنة الصنع',
                value: '${vehicle.manufactureYear}',
                icon: Icons.calendar_today_rounded,
              ),
            ],
          );

          final actions = FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('تعديل البيانات'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: AppSpacing.large),
                metrics,
                const SizedBox(height: AppSpacing.large),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: identity),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    actions,
                    const SizedBox(height: AppSpacing.large),
                    metrics,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
        ),
      ],
    );
  }
}
