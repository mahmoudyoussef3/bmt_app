import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/fleet_workspace.dart';
import '../cubit/fleet_cubit.dart';
import '../cubit/fleet_state.dart';

/// Local navigation state for the Fleet feature.
enum _FleetViewState {
  list,
  driverDetails,
  driverForm,
  vehicleDetails,
  vehicleForm,
}

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  _FleetViewState _viewState = _FleetViewState.list;
  FleetDriver? _selectedDriver;
  FleetVehicle? _selectedVehicle;

  void _navigateTo(_FleetViewState state, {FleetDriver? driver, FleetVehicle? vehicle}) {
    setState(() {
      _viewState = state;
      _selectedDriver = driver;
      _selectedVehicle = vehicle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FleetCubit, FleetState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: switch (state) {
            FleetLoading() => const Center(key: ValueKey('loading'), child: CircularProgressIndicator()),
            FleetError(:final message) => _FleetError(key: const ValueKey('error'), message: message),
            FleetLoaded() => _buildLoadedContent(state),
          },
        );
      },
    );
  }

  Widget _buildLoadedContent(FleetLoaded state) {
    // Lookup latest version of driver/vehicle in case state reloads/refreshes
    final currentDriver = _selectedDriver != null
        ? state.workspace.drivers.firstWhere((d) => d.id == _selectedDriver!.id, orElse: () => _selectedDriver!)
        : null;
    final currentVehicle = _selectedVehicle != null
        ? state.workspace.vehicles.firstWhere((v) => v.id == _selectedVehicle!.id, orElse: () => _selectedVehicle!)
        : null;

    return SingleChildScrollView(
      key: ValueKey('scroll-${_viewState.name}'),
      padding: const EdgeInsets.all(AppSpacing.large),
      child: switch (_viewState) {
        _FleetViewState.list => _FleetLoadedListView(
            key: const ValueKey('list'),
            state: state,
            onViewDriver: (d) => _navigateTo(_FleetViewState.driverDetails, driver: d),
            onEditDriver: (d) => _navigateTo(_FleetViewState.driverForm, driver: d),
            onAddDriver: () => _navigateTo(_FleetViewState.driverForm),
            onViewVehicle: (v) => _navigateTo(_FleetViewState.vehicleDetails, vehicle: v),
            onEditVehicle: (v) => _navigateTo(_FleetViewState.vehicleForm, vehicle: v),
            onAddVehicle: () => _navigateTo(_FleetViewState.vehicleForm),
          ),
        _FleetViewState.driverDetails => _DriverDetailsScreen(
            key: ValueKey('driver-details-${currentDriver?.id}'),
            driver: currentDriver!,
            workspace: state.workspace,
            onBack: () => _navigateTo(_FleetViewState.list),
            onEdit: () => _navigateTo(_FleetViewState.driverForm, driver: currentDriver),
          ),
        _FleetViewState.driverForm => _DriverFormScreen(
            key: ValueKey('driver-form-${currentDriver?.id ?? "new"}'),
            driver: currentDriver,
            workspace: state.workspace,
            onBack: () {
              if (currentDriver != null) {
                _navigateTo(_FleetViewState.driverDetails, driver: currentDriver);
              } else {
                _navigateTo(_FleetViewState.list);
              }
            },
            onSave: (savedDriver) async {
              final cubit = context.read<FleetCubit>();
              await cubit.saveDriver(savedDriver);
              _navigateTo(_FleetViewState.list);
            },
          ),
        _FleetViewState.vehicleDetails => _VehicleDetailsScreen(
            key: ValueKey('vehicle-details-${currentVehicle?.id}'),
            vehicle: currentVehicle!,
            workspace: state.workspace,
            onBack: () => _navigateTo(_FleetViewState.list),
            onEdit: () => _navigateTo(_FleetViewState.vehicleForm, vehicle: currentVehicle),
          ),
        _FleetViewState.vehicleForm => _VehicleFormScreen(
            key: ValueKey('vehicle-form-${currentVehicle?.id ?? "new"}'),
            vehicle: currentVehicle,
            workspace: state.workspace,
            onBack: () {
              if (currentVehicle != null) {
                _navigateTo(_FleetViewState.vehicleDetails, vehicle: currentVehicle);
              } else {
                _navigateTo(_FleetViewState.list);
              }
            },
            onSave: (savedVehicle) async {
              final cubit = context.read<FleetCubit>();
              await cubit.saveVehicle(savedVehicle);
              _navigateTo(_FleetViewState.list);
            },
          ),
      },
    );
  }
}

class _FleetLoadedListView extends StatelessWidget {
  final FleetLoaded state;
  final ValueChanged<FleetDriver> onViewDriver;
  final ValueChanged<FleetDriver> onEditDriver;
  final VoidCallback onAddDriver;
  final ValueChanged<FleetVehicle> onViewVehicle;
  final ValueChanged<FleetVehicle> onEditVehicle;
  final VoidCallback onAddVehicle;

  const _FleetLoadedListView({
    super.key,
    required this.state,
    required this.onViewDriver,
    required this.onEditDriver,
    required this.onAddDriver,
    required this.onViewVehicle,
    required this.onEditVehicle,
    required this.onAddVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          state: state,
          onAddDriver: onAddDriver,
          onAddVehicle: onAddVehicle,
        ),
        const SizedBox(height: AppSpacing.large),
        _Summary(summary: state.workspace.summary),
        const SizedBox(height: AppSpacing.large),
        _FleetTabs(active: state.tab),
        const SizedBox(height: AppSpacing.medium),
        _Toolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            return switch (state.tab) {
              FleetTab.drivers => isDesktop
                  ? _DriversTable(state: state, onView: onViewDriver, onEdit: onEditDriver)
                  : _DriversCardList(state: state, onViewDetails: onViewDriver, onEdit: onEditDriver),
              FleetTab.vehicles => isDesktop
                  ? _VehiclesTable(state: state, onView: onViewVehicle, onEdit: onEditVehicle)
                  : _VehiclesCardList(state: state, onViewDetails: onViewVehicle, onEdit: onEditVehicle),
              FleetTab.assignments => isDesktop
                  ? _AssignmentsTable(state: state)
                  : _AssignmentsCardList(state: state),
              FleetTab.documents => isDesktop
                  ? _DocumentsTable(state: state)
                  : _DocumentsCardList(state: state),
            };
          },
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final FleetLoaded state;
  final VoidCallback onAddDriver;
  final VoidCallback onAddVehicle;

  const _Header({
    required this.state,
    required this.onAddDriver,
    required this.onAddVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<FleetCubit>();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;
          final widgets = [
            Expanded(
              flex: isCompact ? 0 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة الأسطول',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    'إدارة السائقين والمركبات والتعيينات والوثائق اليومية.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (isCompact) const SizedBox(height: AppSpacing.medium),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              alignment: WrapAlignment.end,
              children: [
                if (state.tab == FleetTab.drivers)
                  FilledButton.icon(
                    onPressed: onAddDriver,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('إضافة سائق'),
                  ),
                if (state.tab == FleetTab.vehicles)
                  FilledButton.icon(
                    onPressed: onAddVehicle,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إضافة مركبة'),
                  ),
                if (state.tab == FleetTab.assignments)
                  FilledButton.icon(
                    onPressed: () => _openAssignDialog(context),
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('تعيين سائق'),
                  ),
                OutlinedButton.icon(
                  onPressed: cubit.load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('تحديث'),
                ),
              ],
            ),
          ];

          return isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widgets,
                )
              : Row(
                  children: widgets,
                );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final FleetSummary summary;

  const _Summary({required this.summary});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 600
                ? 2
                : 1;
        final items = [
          ('عدد السائقين', '${summary.driversCount}', Icons.badge_outlined),
          (
            'عدد المركبات',
            '${summary.vehiclesCount}',
            Icons.directions_bus_outlined,
          ),
          (
            'تعيينات نشطة',
            '${summary.activeAssignmentsCount}',
            Icons.link_rounded,
          ),
          (
            'وثائق تحتاج متابعة',
            '${summary.documentsNeedFollowUpCount}',
            Icons.fact_check_outlined,
          ),
        ];
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, index) {
            final (label, value, icon) = items[index];
            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FleetTabs extends StatelessWidget {
  final FleetTab active;

  const _FleetTabs({required this.active});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FleetCubit>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final items = FleetTab.values.map((tab) {
          final selected = tab == active;
          return Expanded(
            flex: isCompact ? 0 : 1,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xSmall),
              child: selected
                  ? FilledButton(
                      onPressed: () => cubit.changeTab(tab),
                      child: Text(tab.label),
                    )
                  : TextButton(
                      onPressed: () => cubit.changeTab(tab),
                      child: Text(tab.label),
                    ),
            ),
          );
        }).toList();

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.xSmall),
          child: isCompact
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: items.map((w) => SizedBox(width: 120, child: w)).toList(),
                  ),
                )
              : Row(children: items),
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  final FleetLoaded state;

  const _Toolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FleetCubit>();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              onChanged: cubit.search,
              decoration: InputDecoration(
                labelText: _searchLabel(state.tab),
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 230,
            child: DropdownButtonFormField<String>(
              initialValue: state.filter,
              decoration: const InputDecoration(
                labelText: 'مصفاة البحث',
                border: OutlineInputBorder(),
              ),
              items: _filtersFor(state.tab)
                  .map(
                    (filter) => DropdownMenuItem(value: filter, child: Text(filter)),
                  )
                  .toList(),
              onChanged: (value) => cubit.filter(value ?? 'الكل'),
            ),
          ),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<FleetSortField>(
              initialValue: state.sortField,
              decoration: const InputDecoration(
                labelText: 'ترتيب حسب',
                border: OutlineInputBorder(),
              ),
              items: _sortsFor(state.tab)
                  .map(
                    (sort) => DropdownMenuItem(
                      value: sort,
                      child: Text(_sortLabel(sort)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) cubit.sort(value);
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => cubit.sort(state.sortField),
            icon: Icon(
              state.sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            ),
            label: const Text('اتجاه الترتيب'),
          ),
          if (state.selectedIds.isNotEmpty && state.tab == FleetTab.drivers)
            FilledButton.tonal(
              onPressed: cubit.bulkArchiveDrivers,
              child: Text('أرشفة المحدد (${state.selectedIds.length})'),
            ),
          if (state.selectedIds.isNotEmpty && state.tab == FleetTab.vehicles)
            FilledButton.tonal(
              onPressed: cubit.bulkSuspendVehicles,
              child: Text('إيقاف المحدد (${state.selectedIds.length})'),
            ),
        ],
      ),
    );
  }
}

class _DriversTable extends StatelessWidget {
  final FleetLoaded state;
  final ValueChanged<FleetDriver> onView;
  final ValueChanged<FleetDriver> onEdit;

  const _DriversTable({
    required this.state,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FleetCubit>();
    final rows = _page(_sortDrivers(_filterDrivers(state), state), state);
    return _TableShell(
      headers: const [
        'تحديد',
        'الصورة',
        'الاسم',
        'رقم الهاتف',
        'الرقم القومي',
        'رقم الرخصة',
        'انتهاء الرخصة',
        'الحالة',
        'المركبة الحالية',
        'إجراءات',
      ],
      total: _filterDrivers(state).length,
      state: state,
      rows: rows.map((driver) {
        final vehicle = _vehicleName(state.workspace, driver.currentVehicleId);
        return [
          Checkbox(
            value: state.selectedIds.contains(driver.id),
            onChanged: (_) => cubit.toggleSelection(driver.id),
          ),
          _Avatar(label: driver.imageLabel),
          Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(driver.phone),
          Text(driver.nationalId),
          Text(driver.licenseNumber),
          Text(driver.licenseExpiry),
          StatusChip(label: driver.status.label),
          Text(vehicle.isEmpty ? 'بدون مركبة' : vehicle),
          Wrap(
            spacing: AppSpacing.xSmall,
            children: [
              TextButton(
                onPressed: () => onView(driver),
                child: const Text('عرض'),
              ),
              TextButton(
                onPressed: () => onEdit(driver),
                child: const Text('تعديل'),
              ),
              TextButton(
                onPressed: driver.status == FleetDriverStatus.active
                    ? () => cubit.updateDriverStatus(driver.id, FleetDriverStatus.suspended)
                    : null,
                child: const Text('إيقاف'),
              ),
              TextButton(
                onPressed: driver.status == FleetDriverStatus.suspended
                    ? () => cubit.updateDriverStatus(driver.id, FleetDriverStatus.active)
                    : null,
                child: const Text('تفعيل'),
              ),
              TextButton(
                onPressed: () => cubit.updateDriverStatus(driver.id, FleetDriverStatus.archived),
                child: const Text('أرشفة'),
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }
}

class _VehiclesTable extends StatelessWidget {
  final FleetLoaded state;
  final ValueChanged<FleetVehicle> onView;
  final ValueChanged<FleetVehicle> onEdit;

  const _VehiclesTable({
    required this.state,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FleetCubit>();
    final rows = _page(_sortVehicles(_filterVehicles(state), state), state);
    return _TableShell(
      headers: const [
        'تحديد',
        'الصورة',
        'رقم المركبة',
        'رقم اللوحة',
        'الموديل',
        'السنة',
        'عدد المقاعد',
        'السائق الحالي',
        'الحالة',
        'الرخصة',
        'التأمين',
        'الفحص',
        'إجراءات',
      ],
      total: _filterVehicles(state).length,
      state: state,
      rows: rows.map((vehicle) {
        return [
          Checkbox(
            value: state.selectedIds.contains(vehicle.id),
            onChanged: (_) => cubit.toggleSelection(vehicle.id),
          ),
          _VehicleThumb(label: vehicle.imageLabel),
          Text(vehicle.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(vehicle.plateNumber),
          Text(vehicle.model),
          Text('${vehicle.modelYear}'),
          Text('${vehicle.seatsCount}'),
          Text(
            _driverName(
              state.workspace,
              vehicle.currentDriverId,
            ).ifEmpty('بدون سائق'),
          ),
          StatusChip(label: vehicle.status.label),
          Text(vehicle.licenseExpiry),
          Text(vehicle.insuranceExpiry),
          Text(vehicle.inspectionExpiry),
          Wrap(
            spacing: AppSpacing.xSmall,
            children: [
              TextButton(
                onPressed: () => onView(vehicle),
                child: const Text('عرض'),
              ),
              TextButton(
                onPressed: () => onEdit(vehicle),
                child: const Text('تعديل'),
              ),
              TextButton(
                onPressed: () => cubit.updateVehicleStatus(vehicle.id, FleetVehicleStatus.suspended),
                child: const Text('إيقاف'),
              ),
              TextButton(
                onPressed: () => cubit.updateVehicleStatus(vehicle.id, FleetVehicleStatus.archived),
                child: const Text('أرشفة'),
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }
}

class _AssignmentsTable extends StatelessWidget {
  final FleetLoaded state;

  const _AssignmentsTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FleetCubit>();
    final rows = _page(
      _sortAssignments(_filterAssignments(state), state),
      state,
    );
    return _TableShell(
      headers: const [
        'السائق',
        'المركبة',
        'تاريخ التعيين',
        'الحالة',
        'إجراءات',
      ],
      total: _filterAssignments(state).length,
      state: state,
      rows: rows.map((assignment) {
        return [
          Text(_driverName(state.workspace, assignment.driverId), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(_vehicleName(state.workspace, assignment.vehicleId)),
          Text(assignment.assignedAt),
          StatusChip(label: assignment.status.label),
          Wrap(
            spacing: AppSpacing.xSmall,
            children: [
              TextButton(
                onPressed: () => _openReassignDialog(context, assignment),
                child: const Text('تغيير المركبة'),
              ),
              TextButton(
                onPressed: assignment.status == FleetAssignmentStatus.active
                    ? () => cubit.removeAssignment(assignment.id)
                    : null,
                child: const Text('فك التعيين'),
              ),
              TextButton(
                onPressed: () => _openHistory(context, 'سجل التعيين', assignment.history),
                child: const Text('عرض السجل'),
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }
}

class _DocumentsTable extends StatelessWidget {
  final FleetLoaded state;

  const _DocumentsTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final rows = _page(_filterDocuments(state), state);
    return _TableShell(
      headers: const [
        'الفئة',
        'صاحب الوثيقة',
        'رقم المرجع',
        'تاريخ الانتهاء',
        'الحالة',
      ],
      total: _filterDocuments(state).length,
      state: state,
      rows: rows.map((document) {
        return [
          Text(document.type.label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(document.ownerName),
          Text(document.referenceNumber),
          Text(document.expiryDate),
          StatusChip(
            label: document.status.label,
            color: _documentColor(context, document.status).withAlpha(30),
            textColor: _documentColor(context, document.status),
          ),
        ];
      }).toList(),
    );
  }
}

class _TableShell extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final FleetLoaded state;
  final int total;

  const _TableShell({
    required this.headers,
    required this.rows,
    required this.state,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<FleetCubit>();
    final pages = (total / state.pageSize).ceil().clamp(1, 999);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: headers.length * 150,
              child: Column(
                children: [
                  Container(
                    color: scheme.surfaceContainerHighest.withAlpha(90),
                    padding: const EdgeInsets.all(AppSpacing.small),
                    child: Row(
                      children: headers
                          .map(
                            (header) => Expanded(
                              child: Text(
                                header,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.large),
                      child: Text('لا توجد بيانات مطابقة'),
                    )
                  else
                    ...rows.map(
                      (cells) => Container(
                        padding: const EdgeInsets.all(AppSpacing.small),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: scheme.outline.withAlpha(90),
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: cells.map((cell) => Expanded(child: cell)).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.small),
            child: Row(
              children: [
                Text('الإجمالي $total'),
                const Spacer(),
                Text('صفحة ${state.page + 1} من $pages'),
                const SizedBox(width: AppSpacing.small),
                IconButton(
                  onPressed: state.page == 0 ? null : () => cubit.page(state.page - 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                IconButton(
                  onPressed: state.page >= pages - 1 ? null : () => cubit.page(state.page + 1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String label;

  const _Avatar({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text(label),
    );
  }
}

class _VehicleThumb extends StatelessWidget {
  final String label;

  const _VehicleThumb({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 54,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(90)),
      ),
      child: Icon(Icons.directions_bus_rounded, color: scheme.primary),
    );
  }
}

class _FleetError extends StatelessWidget {
  final String message;

  const _FleetError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: AppSpacing.medium),
            FilledButton(
              onPressed: context.read<FleetCubit>().load,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

List<FleetDriver> _filterDrivers(FleetLoaded state) {
  final query = state.searchQuery.trim();
  return state.workspace.drivers.where((driver) {
    final matchesSearch = query.isEmpty ||
        driver.name.contains(query) ||
        driver.phone.contains(query) ||
        driver.nationalId.contains(query);
    final vehicleMissing = driver.currentVehicleId.isEmpty;
    final expiring = driver.documents.any(
      (doc) => doc.status == FleetDocumentStatus.expiringSoon,
    );
    final matchesFilter = switch (state.filter) {
      'نشط' => driver.status == FleetDriverStatus.active,
      'موقوف' => driver.status == FleetDriverStatus.suspended,
      'بدون مركبة' => vehicleMissing,
      'الرخصة قاربت على الانتهاء' => expiring,
      _ => true,
    };
    return matchesSearch && matchesFilter && driver.status != FleetDriverStatus.archived;
  }).toList();
}

List<FleetVehicle> _filterVehicles(FleetLoaded state) {
  final query = state.searchQuery.trim();
  return state.workspace.vehicles.where((vehicle) {
    final matchesSearch = query.isEmpty ||
        vehicle.vehicleNumber.contains(query) ||
        vehicle.plateNumber.contains(query) ||
        vehicle.model.contains(query);
    final matchesFilter = switch (state.filter) {
      'نشطة' => vehicle.status == FleetVehicleStatus.active,
      'صيانة' => vehicle.status == FleetVehicleStatus.maintenance,
      'بدون سائق' => vehicle.currentDriverId.isEmpty,
      'الرخصة قاربت على الانتهاء' => _documentStatus(vehicle.licenseExpiry) == FleetDocumentStatus.expiringSoon,
      _ => true,
    };
    return matchesSearch && matchesFilter && vehicle.status != FleetVehicleStatus.archived;
  }).toList();
}

List<FleetAssignment> _filterAssignments(FleetLoaded state) {
  final query = state.searchQuery.trim();
  return state.workspace.assignments.where((assignment) {
    final driver = _driverName(state.workspace, assignment.driverId);
    final vehicle = _vehicleName(state.workspace, assignment.vehicleId);
    final matchesSearch = query.isEmpty || driver.contains(query) || vehicle.contains(query);
    final matchesFilter = switch (state.filter) {
      'نشط' => assignment.status == FleetAssignmentStatus.active,
      'منتهي' => assignment.status == FleetAssignmentStatus.ended,
      _ => true,
    };
    return matchesSearch && matchesFilter;
  }).toList();
}

List<FleetDocument> _filterDocuments(FleetLoaded state) {
  final query = state.searchQuery.trim();
  return state.workspace.documents.where((document) {
    final matchesSearch = query.isEmpty || document.ownerName.contains(query) || document.referenceNumber.contains(query);
    final matchesFilter = switch (state.filter) {
      'منتهي' => document.status == FleetDocumentStatus.expired,
      'ينتهي قريباً' => document.status == FleetDocumentStatus.expiringSoon,
      'سليم' => document.status == FleetDocumentStatus.valid,
      'رخص السائقين' => document.type == FleetDocumentType.driverLicense,
      'رخص المركبات' => document.type == FleetDocumentType.vehicleLicense,
      'التأمين' => document.type == FleetDocumentType.insurance,
      'الفحص الفني' => document.type == FleetDocumentType.inspection,
      _ => true,
    };
    return matchesSearch && matchesFilter;
  }).toList();
}

List<FleetDriver> _sortDrivers(List<FleetDriver> drivers, FleetLoaded state) {
  final next = [...drivers];
  next.sort(
    (a, b) => switch (state.sortField) {
      FleetSortField.licenseExpiry => a.licenseExpiry.compareTo(b.licenseExpiry),
      FleetSortField.status => a.status.label.compareTo(b.status.label),
      _ => a.name.compareTo(b.name),
    },
  );
  return state.sortAscending ? next : next.reversed.toList();
}

List<FleetVehicle> _sortVehicles(List<FleetVehicle> vehicles, FleetLoaded state) {
  final next = [...vehicles];
  next.sort(
    (a, b) => switch (state.sortField) {
      FleetSortField.seats => a.seatsCount.compareTo(b.seatsCount),
      FleetSortField.modelYear => a.modelYear.compareTo(b.modelYear),
      FleetSortField.status => a.status.label.compareTo(b.status.label),
      _ => a.vehicleNumber.compareTo(b.vehicleNumber),
    },
  );
  return state.sortAscending ? next : next.reversed.toList();
}

List<FleetAssignment> _sortAssignments(List<FleetAssignment> assignments, FleetLoaded state) {
  final next = [...assignments];
  next.sort((a, b) => a.assignedAt.compareTo(b.assignedAt));
  return state.sortAscending ? next : next.reversed.toList();
}

List<T> _page<T>(List<T> items, FleetLoaded state) {
  final start = state.page * state.pageSize;
  if (start >= items.length) return const [];
  final end = (start + state.pageSize).clamp(0, items.length);
  return items.sublist(start, end);
}

String _driverName(FleetWorkspace workspace, String driverId) {
  if (driverId.isEmpty) return '';
  return workspace.drivers
      .firstWhere(
        (driver) => driver.id == driverId,
        orElse: () => const FleetDriver(
          id: '',
          employeeCode: '',
          fullName: '',
          phone: '',
          emergencyPhone: '',
          address: '',
          nationalId: '',
          profileImageUrl: '',
          licenseNumber: '',
          licenseExpiryDate: '',
          hireDate: '',
          notes: '',
          status: FleetDriverStatus.archived,
        ),
      )
      .name;
}

String _vehicleName(FleetWorkspace workspace, String vehicleId) {
  if (vehicleId.isEmpty) return '';
  return workspace.vehicles
      .firstWhere(
        (vehicle) => vehicle.id == vehicleId,
        orElse: () => const FleetVehicle(
          id: '',
          vehicleCode: '',
          plateNumber: '',
          vehicleType: '',
          brand: '',
          model: '',
          manufactureYear: 0,
          color: '',
          capacity: 0,
          seatLayoutType: '',
          imageUrl: '',
          notes: '',
          status: FleetVehicleStatus.archived,
          seatConfiguration: SeatConfiguration(rows: 0, columns: 0, seats: []),
          licenseExpiry: '',
          insuranceExpiry: '',
          inspectionExpiry: '',
        ),
      )
      .vehicleNumber;
}

List<String> _filtersFor(FleetTab tab) {
  return switch (tab) {
    FleetTab.drivers => const [
        'الكل',
        'نشط',
        'موقوف',
        'بدون مركبة',
        'الرخصة قاربت على الانتهاء',
      ],
    FleetTab.vehicles => const [
        'الكل',
        'نشطة',
        'صيانة',
        'بدون سائق',
        'الرخصة قاربت على الانتهاء',
      ],
    FleetTab.assignments => const ['الكل', 'نشط', 'منتهي'],
    FleetTab.documents => const [
        'الكل',
        'منتهي',
        'ينتهي قريباً',
        'سليم',
        'رخص السائقين',
        'رخص المركبات',
        'التأمين',
        'الفحص الفني',
      ],
  };
}

List<FleetSortField> _sortsFor(FleetTab tab) {
  return switch (tab) {
    FleetTab.drivers => const [
        FleetSortField.name,
        FleetSortField.status,
        FleetSortField.licenseExpiry,
      ],
    FleetTab.vehicles => const [
        FleetSortField.name,
        FleetSortField.modelYear,
        FleetSortField.seats,
        FleetSortField.status,
      ],
    FleetTab.assignments => const [FleetSortField.assignedAt],
    FleetTab.documents => const [
        FleetSortField.licenseExpiry,
        FleetSortField.status,
      ],
  };
}

String _sortLabel(FleetSortField sort) {
  return switch (sort) {
    FleetSortField.name => 'الاسم / الرقم',
    FleetSortField.status => 'الحالة',
    FleetSortField.licenseExpiry => 'انتهاء الوثيقة',
    FleetSortField.seats => 'عدد المقاعد',
    FleetSortField.modelYear => 'السنة',
    FleetSortField.assignedAt => 'تاريخ التعيين',
  };
}

String _searchLabel(FleetTab tab) {
  return switch (tab) {
    FleetTab.drivers => 'بحث بالاسم أو الهاتف أو الرقم القومي',
    FleetTab.vehicles => 'بحث برقم المركبة أو اللوحة أو الموديل',
    FleetTab.assignments => 'بحث بالسائق أو المركبة',
    FleetTab.documents => 'بحث بصاحب الوثيقة أو المرجع',
  };
}

FleetDocumentStatus _documentStatus(String expiry) {
  if (expiry.isEmpty) return FleetDocumentStatus.valid;
  if (expiry.contains('أبريل') || expiry.contains('مايو')) {
    return FleetDocumentStatus.expired;
  }
  if (expiry.contains('يونيو')) return FleetDocumentStatus.expiringSoon;
  return FleetDocumentStatus.valid;
}

Color _documentColor(BuildContext context, FleetDocumentStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    FleetDocumentStatus.expired => scheme.error,
    FleetDocumentStatus.expiringSoon => scheme.tertiary,
    FleetDocumentStatus.valid => scheme.primary,
  };
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

void _openHistory(
  BuildContext context,
  String title,
  List<FleetHistoryItem> items,
) {
  showDialog<void>(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items
                .map(
                  (item) => ListTile(
                    title: Text(item.title),
                    subtitle: Text('${item.date} - ${item.description}'),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('إغلاق'),
          ),
        ],
      ),
    ),
  );
}

class _Breadcrumbs extends StatelessWidget {
  final String currentLabel;
  final VoidCallback onBack;

  const _Breadcrumbs({required this.currentLabel, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'رجوع',
        ),
        const SizedBox(width: AppSpacing.small),
        TextButton(
          onPressed: onBack,
          child: Text(
            'إدارة الأسطول',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
        Icon(Icons.chevron_left_rounded, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(
            currentLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DriversCardList extends StatelessWidget {
  final FleetLoaded state;
  final ValueChanged<FleetDriver> onViewDetails;
  final ValueChanged<FleetDriver> onEdit;

  const _DriversCardList({
    required this.state,
    required this.onViewDetails,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FleetCubit>();
    final drivers = _filterDrivers(state);
    final sorted = _sortDrivers(drivers, state);
    final paged = _page(sorted, state);

    if (paged.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.large),
          child: Text('لا توجد بيانات مطابقة'),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paged.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.small),
          itemBuilder: (context, index) {
            final driver = paged[index];
            final vehicle = _vehicleName(state.workspace, driver.currentVehicleId);
            final documentExpired = driver.documents.any((d) => d.status == FleetDocumentStatus.expired);
            final documentExpiring = driver.documents.any((d) => d.status == FleetDocumentStatus.expiringSoon);

            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Avatar(label: driver.imageLabel),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              driver.employeeCode,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(label: driver.status.label),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.small),
                  _metaRow(context, Icons.phone_android_rounded, 'الهاتف', driver.phone),
                  _metaRow(context, Icons.badge_outlined, 'الرقم القومي', driver.nationalId),
                  _metaRow(context, Icons.directions_bus_outlined, 'المركبة', vehicle.isEmpty ? 'بدون مركبة' : vehicle),
                  _metaRow(
                    context,
                    Icons.calendar_today_rounded,
                    'انتهاء الرخصة',
                    driver.licenseExpiry,
                    valueColor: documentExpired
                        ? scheme.error
                        : documentExpiring
                            ? scheme.tertiary
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => onViewDetails(driver),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('عرض'),
                      ),
                      TextButton.icon(
                        onPressed: () => onEdit(driver),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('تعديل'),
                      ),
                      IconButton(
                        tooltip: 'تغيير الحالة',
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () => _showDriverActions(context, driver, cubit),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        _pagination(context, state, sorted.length),
      ],
    );
  }
}

void _showDriverActions(BuildContext context, FleetDriver driver, FleetCubit cubit) {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(driver.employeeCode),
            ),
            const Divider(),
            if (driver.status == FleetDriverStatus.active)
              ListTile(
                leading: const Icon(Icons.block_rounded, color: Colors.amber),
                title: const Text('إيقاف الحساب مؤقتاً'),
                onTap: () {
                  cubit.updateDriverStatus(driver.id, FleetDriverStatus.suspended);
                  Navigator.of(context).pop();
                },
              ),
            if (driver.status == FleetDriverStatus.suspended)
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                title: const Text('إعادة تفعيل الحساب'),
                onTap: () {
                  cubit.updateDriverStatus(driver.id, FleetDriverStatus.active);
                  Navigator.of(context).pop();
                },
              ),
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.red),
              title: const Text('أرشفة السائق'),
              onTap: () {
                cubit.updateDriverStatus(driver.id, FleetDriverStatus.archived);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _VehiclesCardList extends StatelessWidget {
  final FleetLoaded state;
  final ValueChanged<FleetVehicle> onViewDetails;
  final ValueChanged<FleetVehicle> onEdit;

  const _VehiclesCardList({
    required this.state,
    required this.onViewDetails,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FleetCubit>();
    final vehicles = _filterVehicles(state);
    final sorted = _sortVehicles(vehicles, state);
    final paged = _page(sorted, state);

    if (paged.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.large),
          child: Text('لا توجد بيانات مطابقة'),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paged.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.small),
          itemBuilder: (context, index) {
            final vehicle = paged[index];
            final driverName = _driverName(state.workspace, vehicle.currentDriverId).ifEmpty('بدون سائق');

            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _VehicleThumb(label: vehicle.imageLabel),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.vehicleNumber,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${vehicle.brand} ${vehicle.model} | ${vehicle.plateNumber}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(label: vehicle.status.label),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.small),
                  _metaRow(context, Icons.person_outline_rounded, 'السائق الحالي', driverName),
                  _metaRow(context, Icons.event_seat_outlined, 'السعة الركابية', '${vehicle.capacity} مقعد'),
                  _metaRow(context, Icons.calendar_today_rounded, 'رخصة المركبة', vehicle.licenseExpiry),
                  _metaRow(context, Icons.verified_user_outlined, 'التأمين', vehicle.insuranceExpiry),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => onViewDetails(vehicle),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('عرض'),
                      ),
                      TextButton.icon(
                        onPressed: () => onEdit(vehicle),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('تعديل'),
                      ),
                      IconButton(
                        tooltip: 'تغيير الحالة',
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () => _showVehicleActions(context, vehicle, cubit),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        _pagination(context, state, sorted.length),
      ],
    );
  }
}

void _showVehicleActions(BuildContext context, FleetVehicle vehicle, FleetCubit cubit) {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(vehicle.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${vehicle.brand} ${vehicle.model}'),
            ),
            const Divider(),
            if (vehicle.status == FleetVehicleStatus.active)
              ListTile(
                leading: const Icon(Icons.build_outlined, color: Colors.amber),
                title: const Text('إرسال للصيانة'),
                onTap: () {
                  cubit.updateVehicleStatus(vehicle.id, FleetVehicleStatus.maintenance);
                  Navigator.of(context).pop();
                },
              ),
            if (vehicle.status == FleetVehicleStatus.maintenance || vehicle.status == FleetVehicleStatus.suspended)
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                title: const Text('تفعيل وتشغيل'),
                onTap: () {
                  cubit.updateVehicleStatus(vehicle.id, FleetVehicleStatus.active);
                  Navigator.of(context).pop();
                },
              ),
            if (vehicle.status == FleetVehicleStatus.active)
              ListTile(
                leading: const Icon(Icons.block_rounded, color: Colors.orange),
                title: const Text('إيقاف المركبة مؤقتاً'),
                onTap: () {
                  cubit.updateVehicleStatus(vehicle.id, FleetVehicleStatus.suspended);
                  Navigator.of(context).pop();
                },
              ),
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.red),
              title: const Text('أرشفة المركبة'),
              onTap: () {
                cubit.updateVehicleStatus(vehicle.id, FleetVehicleStatus.archived);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _AssignmentsCardList extends StatelessWidget {
  final FleetLoaded state;

  const _AssignmentsCardList({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FleetCubit>();
    final assignments = _filterAssignments(state);
    final sorted = _sortAssignments(assignments, state);
    final paged = _page(sorted, state);

    if (paged.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.large),
          child: Text('لا توجد بيانات مطابقة'),
        ),
      );
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paged.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.small),
          itemBuilder: (context, index) {
            final assignment = paged[index];
            final driverName = _driverName(state.workspace, assignment.driverId);
            final vehicleName = _vehicleName(state.workspace, assignment.vehicleId);

            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تعيين #${assignment.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      StatusChip(label: assignment.status.label),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.small),
                  _metaRow(context, Icons.person_outline_rounded, 'السائق', driverName),
                  _metaRow(context, Icons.directions_bus_outlined, 'المركبة', vehicleName),
                  _metaRow(context, Icons.calendar_today_rounded, 'تاريخ التعيين', assignment.assignedAt),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _openReassignDialog(context, assignment),
                        child: const Text('تغيير المركبة'),
                      ),
                      TextButton(
                        onPressed: assignment.status == FleetAssignmentStatus.active
                            ? () => cubit.removeAssignment(assignment.id)
                            : null,
                        child: const Text('فك التعيين'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.history_rounded),
                        tooltip: 'عرض السجل',
                        onPressed: () => _openHistory(context, 'سجل التعيين', assignment.history),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        _pagination(context, state, sorted.length),
      ],
    );
  }
}

class _DocumentsCardList extends StatelessWidget {
  final FleetLoaded state;

  const _DocumentsCardList({required this.state});

  @override
  Widget build(BuildContext context) {
    final documents = _filterDocuments(state);
    final paged = _page(documents, state);

    if (paged.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.large),
          child: Text('لا توجد بيانات مطابقة'),
        ),
      );
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paged.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.small),
          itemBuilder: (context, index) {
            final document = paged[index];

            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        document.type.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      StatusChip(
                        label: document.status.label,
                        color: _documentColor(context, document.status).withAlpha(30),
                        textColor: _documentColor(context, document.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.small),
                  _metaRow(context, Icons.person_outline_rounded, 'صاحب الوثيقة', document.ownerName),
                  _metaRow(context, Icons.confirmation_number_outlined, 'رقم المرجع', document.referenceNumber),
                  _metaRow(context, Icons.calendar_today_rounded, 'تاريخ الانتهاء', document.expiryDate),
                  if (document.fileUrl.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.small),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text('فتح الملف'),
                        onPressed: () => launchUrl(Uri.parse(document.fileUrl), mode: LaunchMode.externalApplication),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        _pagination(context, state, documents.length),
      ],
    );
  }
}

Widget _metaRow(
  BuildContext context,
  IconData icon,
  String label,
  String value, {
  Color? valueColor,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
    child: Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.small),
        Text('$label:', style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? scheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget _pagination(BuildContext context, FleetLoaded state, int total) {
  final cubit = context.read<FleetCubit>();
  final pages = (total / state.pageSize).ceil().clamp(1, 999);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: state.page == 0 ? null : () => cubit.page(state.page - 1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        Text('صفحة ${state.page + 1} من $pages'),
        IconButton(
          onPressed: state.page >= pages - 1 ? null : () => cubit.page(state.page + 1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
      ],
    ),
  );
}

class _DriverDetailsScreen extends StatelessWidget {
  final FleetDriver driver;
  final FleetWorkspace workspace;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const _DriverDetailsScreen({
    super.key,
    required this.driver,
    required this.workspace,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vehicle = _vehicleName(workspace, driver.currentVehicleId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Breadcrumbs(
          currentLabel: 'تفاصيل السائق: ${driver.name}',
          onBack: onBack,
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
                child: Text(driver.imageLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                flex: isCompact ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text('كود الموظف: ${driver.employeeCode} | الرقم القومي: ${driver.nationalId}'),
                  ],
                ),
              ),
              if (isCompact) const SizedBox(height: AppSpacing.medium),
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('تعديل البيانات'),
              ),
            ];

            return isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: headerWidgets,
                  )
                : Row(
                    children: headerWidgets,
                  );
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
                        _DocumentManager(
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
                        _HistoryTimeline(title: 'سجل الرحلات', items: driver.tripHistory, icon: Icons.map_outlined),
                        const SizedBox(height: AppSpacing.medium),
                        _HistoryTimeline(title: 'سجل المخالفات', items: driver.violations, icon: Icons.gpp_bad_outlined, color: scheme.error),
                        const SizedBox(height: AppSpacing.medium),
                        _HistoryTimeline(title: 'سجل النشاط', items: driver.activityTimeline, icon: Icons.timeline_rounded),
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
                  _DocumentManager(
                    ownerId: driver.id,
                    isDriver: true,
                    documents: driver.documents,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(title: 'سجل الرحلات', items: driver.tripHistory, icon: Icons.map_outlined),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(title: 'سجل المخالفات', items: driver.violations, icon: Icons.gpp_bad_outlined, color: scheme.error),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(title: 'سجل النشاط', items: driver.activityTimeline, icon: Icons.timeline_rounded),
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
          Text('المعلومات الأساسية والمهنية', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
          _detailRow('المركبة الحالية', vehicle.isEmpty ? 'بدون مركبة حالياً' : vehicle),
          _detailRow('حالة الحساب', driver.status.label),
          if (driver.notes.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.small),
            Text('ملاحظات الإدارة:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xSmall),
            Text(driver.notes, style: const TextStyle(fontStyle: FontStyle.italic)),
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
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${item.date} - ${item.description}',
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
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

class _VehicleDetailsScreen extends StatelessWidget {
  final FleetVehicle vehicle;
  final FleetWorkspace workspace;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const _VehicleDetailsScreen({
    super.key,
    required this.vehicle,
    required this.workspace,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vehicleDocs = workspace.documents.where((d) => d.ownerId == vehicle.id).toList();
    final driverName = _driverName(workspace, vehicle.currentDriverId).ifEmpty('بدون سائق');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Breadcrumbs(
          currentLabel: 'تفاصيل المركبة: ${vehicle.vehicleNumber}',
          onBack: onBack,
        ),
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            final headerWidgets = [
              Container(
                width: 56,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  border: Border.all(color: scheme.outline.withAlpha(90)),
                ),
                child: Icon(Icons.directions_bus_rounded, color: scheme.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                flex: isCompact ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model} (${vehicle.vehicleNumber})',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text('رقم اللوحة: ${vehicle.plateNumber} | السعة الركابية: ${vehicle.capacity} مقعد'),
                  ],
                ),
              ),
              if (isCompact) const SizedBox(height: AppSpacing.medium),
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('تعديل البيانات'),
              ),
            ];

            return isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: headerWidgets,
                  )
                : Row(
                    children: headerWidgets,
                  );
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
                        _infoCard(context, vehicle, driverName),
                        const SizedBox(height: AppSpacing.medium),
                        _SeatLayoutVisualizer(seatConfig: vehicle.seatConfiguration),
                        const SizedBox(height: AppSpacing.medium),
                        _DocumentManager(
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
                        _HistoryTimeline(title: 'سجل السائقين السابقين', items: vehicle.previousDrivers, icon: Icons.people_outline_rounded),
                        const SizedBox(height: AppSpacing.medium),
                        _HistoryTimeline(title: 'سجل الرحلات', items: vehicle.tripHistory, icon: Icons.map_outlined),
                        const SizedBox(height: AppSpacing.medium),
                        _HistoryTimeline(title: 'سجل النشاط التشغيلي', items: vehicle.timeline, icon: Icons.timeline_rounded),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _infoCard(context, vehicle, driverName),
                  const SizedBox(height: AppSpacing.medium),
                  _SeatLayoutVisualizer(seatConfig: vehicle.seatConfiguration),
                  const SizedBox(height: AppSpacing.medium),
                  _DocumentManager(
                    ownerId: vehicle.id,
                    isDriver: false,
                    documents: vehicleDocs,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(title: 'سجل السائقين السابقين', items: vehicle.previousDrivers, icon: Icons.people_outline_rounded),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(title: 'سجل الرحلات', items: vehicle.tripHistory, icon: Icons.map_outlined),
                  const SizedBox(height: AppSpacing.medium),
                  _HistoryTimeline(title: 'سجل النشاط التشغيلي', items: vehicle.timeline, icon: Icons.timeline_rounded),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _infoCard(BuildContext context, FleetVehicle vehicle, String driverName) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بيانات تشغيل المركبة الكلية', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.medium),
          _detailRow('كود المركبة الداخلي', vehicle.vehicleCode),
          _detailRow('رقم لوحة المركبة', vehicle.plateNumber),
          _detailRow('الفئة والنوع', vehicle.vehicleType),
          _detailRow('العلامة التجارية', vehicle.brand),
          _detailRow('الموديل الطرازي', vehicle.model),
          _detailRow('سنة الصنع الموديل', '${vehicle.manufactureYear}'),
          _detailRow('لون الهيكل الخارجي', vehicle.color),
          _detailRow('السعة الركابية القصوى', '${vehicle.capacity} مقعد للركاب'),
          _detailRow('تخطيط المقاعد الداخلي', vehicle.seatLayoutType),
          _detailRow('السائق الحالي للمركبة', driverName),
          _detailRow('تاريخ انتهاء رخصة السير', vehicle.licenseExpiry),
          _detailRow('تاريخ انتهاء وثيقة التأمين', vehicle.insuranceExpiry),
          _detailRow('تاريخ انتهاء الفحص الفني', vehicle.inspectionExpiry),
          _detailRow('الحالة التشغيلية الحالية', vehicle.status.label),
          if (vehicle.notes.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.small),
            Text('ملاحظات التشغيل والصيانة:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xSmall),
            Text(vehicle.notes, style: const TextStyle(fontStyle: FontStyle.italic)),
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
            width: 180,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _DriverFormScreen extends StatefulWidget {
  final FleetDriver? driver;
  final FleetWorkspace workspace;
  final VoidCallback onBack;
  final ValueChanged<FleetDriver> onSave;

  const _DriverFormScreen({
    super.key,
    this.driver,
    required this.workspace,
    required this.onBack,
    required this.onSave,
  });

  @override
  State<_DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends State<_DriverFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController nationalId;
  late final TextEditingController license;
  late final TextEditingController expiry;
  late final TextEditingController address;
  late final TextEditingController emergency;
  late final TextEditingController employeeCode;
  late final TextEditingController hireDate;
  late final TextEditingController notes;
  String? selectedVehicleId;

  int _currentStep = 0;
  String _globalError = '';

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    name = TextEditingController(text: d?.fullName ?? '');
    phone = TextEditingController(text: d?.phone ?? '');
    nationalId = TextEditingController(text: d?.nationalId ?? '');
    license = TextEditingController(text: d?.licenseNumber ?? '');
    expiry = TextEditingController(text: d?.licenseExpiryDate ?? '');
    address = TextEditingController(text: d?.address ?? '');
    emergency = TextEditingController(text: d?.emergencyPhone ?? '');
    employeeCode = TextEditingController(text: d?.employeeCode ?? '');
    hireDate = TextEditingController(text: d?.hireDate ?? '');
    notes = TextEditingController(text: d?.notes ?? '');
    selectedVehicleId = d?.currentVehicleId.isNotEmpty == true ? d!.currentVehicleId : null;
  }

  List<FleetVehicle> _getAvailableVehicles() {
    return widget.workspace.vehicles.where((v) {
      if (v.status != FleetVehicleStatus.active) return false;
      
      final hasExpiredDocs = widget.workspace.documents.any((d) => d.ownerId == v.id && d.status == FleetDocumentStatus.expired);
      if (hasExpiredDocs) return false;
      
      final isAssignedToOther = widget.workspace.assignments.any((a) => 
          a.vehicleId == v.id && 
          a.status == FleetAssignmentStatus.active && 
          a.driverId != widget.driver?.id);
          
      return !isAssignedToOther;
    }).toList();
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    nationalId.dispose();
    license.dispose();
    expiry.dispose();
    address.dispose();
    emergency.dispose();
    employeeCode.dispose();
    hireDate.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.driver != null;

    final steps = [
      'البيانات الشخصية',
      'بيانات الاتصال والعنوان',
      'الرخصة وصلاحية العمل',
      'مراجعة وحفظ البيانات'
    ];

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Breadcrumbs(
            currentLabel: isEdit ? 'تعديل السائق: ${widget.driver!.name}' : 'إضافة سائق جديد',
            onBack: widget.onBack,
          ),
          const SizedBox(height: AppSpacing.large),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                final stepIndicators = List.generate(steps.length, (index) {
                  final active = index == _currentStep;
                  final done = index < _currentStep;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                              : done
                                  ? scheme.primaryContainer
                                  : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (done)
                              Icon(Icons.check_rounded, size: 14, color: scheme.onPrimaryContainer)
                            else
                              Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            const SizedBox(width: 6),
                            Text(
                              steps[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                color: active
                                    ? scheme.onPrimary
                                    : done
                                        ? scheme.onPrimaryContainer
                                        : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < steps.length - 1 && !isCompact)
                        Container(
                          width: 30,
                          height: 2,
                          color: done ? scheme.primary : scheme.outlineVariant,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                    ],
                  );
                });

                return isCompact
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: stepIndicators
                              .map((w) => Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: w,
                                  ))
                              .toList(),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: stepIndicators,
                      );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: _buildStepContent(),
          ),
          const SizedBox(height: AppSpacing.large),
          if (_globalError.isNotEmpty) ...[
            Text(_globalError, style: TextStyle(color: scheme.error, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.medium),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_currentStep > 0) ...[
                OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('السابق'),
                ),
                const SizedBox(width: AppSpacing.medium),
              ],
              FilledButton(
                onPressed: _onNext,
                child: Text(_currentStep == steps.length - 1 ? 'تأكيد وحفظ السائق' : 'التالي'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 720;
        final colCount = isDesktop ? 2 : 1;

        switch (_currentStep) {
          case 0:
            return _responsiveGrid(
              colCount,
              [
                _textFormField(
                  controller: name,
                  label: 'الاسم الكامل للسائق ثنائياً أو أكثر',
                  icon: Icons.person_outline_rounded,
                  validator: _validateName,
                ),
                _textFormField(
                  controller: nationalId,
                  label: 'الرقم القومي (14 رقماً مصرياً)',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  validator: _validateNationalId,
                ),
                _textFormField(
                  controller: employeeCode,
                  label: 'كود الموظف (EMP-XXX)',
                  icon: Icons.vpn_key_outlined,
                  validator: _validateEmployeeCode,
                ),
              ],
            );
          case 1:
            return _responsiveGrid(
              colCount,
              [
                _textFormField(
                  controller: phone,
                  label: 'رقم الهاتف الأساسي',
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (v) => _validatePhone(v ?? '', 'رقم الهاتف'),
                ),
                _textFormField(
                  controller: emergency,
                  label: 'رقم هاتف الطوارئ البديل',
                  icon: Icons.contact_phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    final err = _validatePhone(v ?? '', 'رقم هاتف الطوارئ');
                    if (err == null && phone.text.trim() == emergency.text.trim()) {
                      return 'رقم هاتف الطوارئ لا يمكن أن يكون هو نفسه رقم الهاتف الأساسي';
                    }
                    return err;
                  },
                ),
                _textFormField(
                  controller: address,
                  label: 'العنوان السكني التفصيلي',
                  icon: Icons.home_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'العنوان السكني مطلوب' : null,
                ),
              ],
            );
          case 2:
            final availableVehicles = _getAvailableVehicles();
            return _responsiveGrid(
              colCount,
              [
                _textFormField(
                  controller: license,
                  label: 'رقم رخصة القيادة',
                  icon: Icons.card_membership_rounded,
                  validator: _validateLicenseNumber,
                ),
                _dateFormField(
                  controller: expiry,
                  label: 'تاريخ انتهاء صلاحية الرخصة (YYYY-MM-DD)',
                  validator: (v) => _validateDate(v ?? '', 'تاريخ انتهاء الرخصة'),
                ),
                _dateFormField(
                  controller: hireDate,
                  label: 'تاريخ تعيين الموظف بالشركة (YYYY-MM-DD)',
                  validator: (v) => _validateDate(v ?? '', 'تاريخ التعيين'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedVehicleId,
                  decoration: const InputDecoration(
                    labelText: 'المركبة المعينة (اختياري)',
                    prefixIcon: Icon(Icons.directions_car_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('غير معين (بدون مركبة)'),
                    ),
                    ...availableVehicles.map((v) => DropdownMenuItem<String>(
                          value: v.id,
                          child: Text('${v.vehicleCode} (${v.plateNumber})'),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedVehicleId = val;
                    });
                  },
                ),
                _textFormField(
                  controller: notes,
                  label: 'ملاحظات إضافية عن السائق',
                  icon: Icons.notes_rounded,
                  maxLines: 2,
                ),
              ],
            );
          case 3:
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('يرجى مراجعة البيانات بعناية قبل التأكيد:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.medium),
                _reviewRow('الاسم الكامل', name.text),
                _reviewRow('الرقم القومي', nationalId.text),
                _reviewRow('كود الموظف', employeeCode.text),
                _reviewRow('رقم الهاتف', phone.text),
                _reviewRow('هاتف الطوارئ', emergency.text),
                _reviewRow('العنوان', address.text),
                _reviewRow('رقم الرخصة', license.text),
                _reviewRow('انتهاء الرخصة', expiry.text),
                _reviewRow('تاريخ التعيين', hireDate.text),
                _reviewRow(
                  'المركبة المعينة', 
                  selectedVehicleId != null 
                      ? (widget.workspace.vehicles.cast<FleetVehicle?>().firstWhere(
                            (v) => v?.id == selectedVehicleId,
                            orElse: () => null,
                          )?.vehicleCode ?? 'غير معروف')
                      : 'غير معين',
                ),
                if (notes.text.isNotEmpty) _reviewRow('الملاحظات', notes.text),
              ],
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _responsiveGrid(int columns, List<Widget> children) {
    if (columns == 1) {
      return Column(
        children: children
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                  child: c,
                ))
            .toList(),
      );
    }
    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.medium,
      children: children
          .map((c) => SizedBox(
                width: (MediaQuery.of(context).size.width - 320 - 48 - 16) / 2,
                child: c,
              ))
          .toList(),
    );
  }

  Widget _textFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _dateFormField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_rounded),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 365)),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (date != null) {
          setState(() {
            controller.text = date.toIso8601String().substring(0, 10);
          });
        }
      },
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _onNext() {
    setState(() => _globalError = '');
    if (_currentStep < 3) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      } else {
        setState(() => _globalError = 'يرجى تصحيح الأخطاء في الحقول المميزة بالأحمر');
      }
    } else {
      if (_formKey.currentState!.validate()) {
        final existing = widget.driver;
        final finalDriver = FleetDriver(
          id: existing?.id ?? '',
          employeeCode: employeeCode.text.trim(),
          fullName: name.text.trim(),
          phone: phone.text.trim(),
          emergencyPhone: emergency.text.trim(),
          address: address.text.trim(),
          nationalId: nationalId.text.trim(),
          profileImageUrl: existing?.profileImageUrl ?? '',
          licenseNumber: license.text.trim(),
          licenseExpiryDate: expiry.text.trim(),
          hireDate: hireDate.text.trim(),
          notes: notes.text.trim(),
          status: existing?.status ?? FleetDriverStatus.active,
          currentVehicleId: selectedVehicleId ?? '',
          tripHistory: existing?.tripHistory ?? const [],
          violations: existing?.violations ?? const [],
          documents: existing?.documents ?? const [],
          activityTimeline: existing?.activityTimeline ?? const [],
        );
        widget.onSave(finalDriver);
      } else {
        setState(() => _globalError = 'يرجى مراجعة وتصحيح الحقول أولاً');
      }
    }
  }
}

class _VehicleFormScreen extends StatefulWidget {
  final FleetVehicle? vehicle;
  final FleetWorkspace workspace;
  final VoidCallback onBack;
  final ValueChanged<FleetVehicle> onSave;

  const _VehicleFormScreen({
    super.key,
    this.vehicle,
    required this.workspace,
    required this.onBack,
    required this.onSave,
  });

  @override
  State<_VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<_VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController code;
  late final TextEditingController plate;
  late final TextEditingController model;
  late final TextEditingController year;
  late final TextEditingController seats;
  late final TextEditingController brand;
  late final TextEditingController color;
  late final TextEditingController notes;
  String vehicleType = 'Coaster';
  String seatLayoutType = 'standard';
  String? selectedDriverId;
  String _globalError = '';

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    code = TextEditingController(text: v?.vehicleCode ?? '');
    plate = TextEditingController(text: v?.plateNumber ?? '');
    model = TextEditingController(text: v?.model ?? '');
    year = TextEditingController(text: v == null ? '' : '${v.manufactureYear}');
    seats = TextEditingController(text: v == null ? '' : '${v.capacity}');
    brand = TextEditingController(text: v?.brand ?? '');
    color = TextEditingController(text: v?.color ?? '');
    notes = TextEditingController(text: v?.notes ?? '');
    if (v != null) {
      vehicleType = v.vehicleType.isEmpty ? 'Coaster' : v.vehicleType;
      seatLayoutType = v.seatLayoutType.isEmpty ? 'standard' : v.seatLayoutType;
    }
    selectedDriverId = v?.currentDriverId.isNotEmpty == true ? v!.currentDriverId : null;
  }

  List<FleetDriver> _getAvailableDrivers() {
    return widget.workspace.drivers.where((d) {
      if (d.status != FleetDriverStatus.active) return false;
      
      final hasExpiredDocs = d.documents.any((doc) => doc.status == FleetDocumentStatus.expired);
      if (hasExpiredDocs) return false;
      
      final isAssignedToOther = widget.workspace.assignments.any((a) => 
          a.driverId == d.id && 
          a.status == FleetAssignmentStatus.active && 
          a.vehicleId != widget.vehicle?.id);
          
      return !isAssignedToOther;
    }).toList();
  }

  @override
  void dispose() {
    code.dispose();
    plate.dispose();
    model.dispose();
    year.dispose();
    seats.dispose();
    brand.dispose();
    color.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicle != null;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Breadcrumbs(
            currentLabel: isEdit ? 'تعديل المركبة: ${widget.vehicle!.vehicleNumber}' : 'إضافة مركبة جديدة',
            onBack: widget.onBack,
          ),
          const SizedBox(height: AppSpacing.large),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 720;
                final colCount = isDesktop ? 2 : 1;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات ترخيص ومواصفات المركبة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    _responsiveGrid(
                      colCount,
                      [
                        _textFormField(
                          controller: code,
                          label: 'كود المركبة الداخلي (مثال: مركبة 101)',
                          icon: Icons.directions_bus_rounded,
                          validator: _validateVehicleCode,
                        ),
                        _textFormField(
                          controller: plate,
                          label: 'رقم اللوحة المرورية (أرقام وحروف)',
                          icon: Icons.confirmation_number_outlined,
                          validator: _validatePlateNumber,
                        ),
                        _textFormField(
                          controller: brand,
                          label: 'الماركة المصنعة للمركبة (مثال: Toyota)',
                          icon: Icons.branding_watermark_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم الماركة مطلوب' : null,
                        ),
                        _textFormField(
                          controller: model,
                          label: 'طراز الموديل (مثال: Coaster)',
                          icon: Icons.model_training_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم طراز الموديل مطلوب' : null,
                        ),
                        _textFormField(
                          controller: year,
                          label: 'سنة صنع الموديل المعتمد',
                          icon: Icons.calendar_today_rounded,
                          keyboardType: TextInputType.number,
                          validator: _validateManufactureYear,
                        ),
                        _textFormField(
                          controller: seats,
                          label: 'السعة الركابية (عدد المقاعد الفعلي)',
                          icon: Icons.event_seat_rounded,
                          keyboardType: TextInputType.number,
                          validator: _validateCapacity,
                        ),
                        _textFormField(
                          controller: color,
                          label: 'لون هيكل المركبة الفعلي',
                          icon: Icons.color_lens_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'لون الهيكل مطلوب' : null,
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: vehicleType,
                          decoration: const InputDecoration(
                            labelText: 'فئة ونوع المركبة التشغيلية',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Coaster', child: Text('Coaster (ميني باص كوستر)')),
                            DropdownMenuItem(value: 'Sprinter', child: Text('Sprinter (حافلة سبرنتر)')),
                            DropdownMenuItem(value: 'Hiace', child: Text('Hiace (ميكروباص هايس)')),
                            DropdownMenuItem(value: 'H1', child: Text('H1 (حافلة عائلية)')),
                            DropdownMenuItem(value: 'Other', child: Text('فئة تشغيلية أخرى')),
                          ],
                          onChanged: (v) => setState(() => vehicleType = v ?? 'Coaster'),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: seatLayoutType,
                          decoration: const InputDecoration(
                            labelText: 'توزيع وتخطيط المقاعد الداخلي',
                            prefixIcon: Icon(Icons.grid_view_rounded),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'standard', child: Text('Standard (توزيع ركاب قياسي)')),
                            DropdownMenuItem(value: 'VIP', child: Text('VIP (توزيع ركاب متميز)')),
                          ],
                          onChanged: (v) => setState(() => seatLayoutType = v ?? 'standard'),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: selectedDriverId,
                          decoration: const InputDecoration(
                            labelText: 'السائق المعين (اختياري)',
                            prefixIcon: Icon(Icons.person_rounded),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('غير معين (بدون سائق)'),
                            ),
                            ..._getAvailableDrivers().map((d) => DropdownMenuItem<String>(
                                  value: d.id,
                                  child: Text('${d.name} (${d.employeeCode})'),
                                )),
                          ],
                          onChanged: (val) {
                            setState(() {
                              selectedDriverId = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    _textFormField(
                      controller: notes,
                      label: 'ملاحظات الصيانة الوقائية والتشغيلية',
                      icon: Icons.edit_note_rounded,
                      maxLines: 2,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          if (_globalError.isNotEmpty) ...[
            Text(_globalError, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.medium),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: widget.onBack,
                child: const Text('إلغاء'),
              ),
              const SizedBox(width: AppSpacing.medium),
              FilledButton(
                onPressed: _onSave,
                child: const Text('حفظ المركبة'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _responsiveGrid(int columns, List<Widget> children) {
    if (columns == 1) {
      return Column(
        children: children
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                  child: c,
                ))
            .toList(),
      );
    }
    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.medium,
      children: children
          .map((c) => SizedBox(
                width: (MediaQuery.of(context).size.width - 320 - 48 - 16) / 2,
                child: c,
              ))
          .toList(),
    );
  }

  Widget _textFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  void _onSave() {
    setState(() => _globalError = '');
    if (_formKey.currentState!.validate()) {
      final seatsValue = int.parse(seats.text.trim());
      final yearValue = int.parse(year.text.trim());
      final existing = widget.vehicle;
      final seatConfig = existing != null && existing.capacity == seatsValue
          ? existing.seatConfiguration
          : SeatConfiguration.generateDefault(seatsValue);

      final finalVehicle = FleetVehicle(
        id: existing?.id ?? '',
        vehicleCode: code.text.trim(),
        plateNumber: plate.text.trim(),
        vehicleType: vehicleType,
        brand: brand.text.trim(),
        model: model.text.trim(),
        manufactureYear: yearValue,
        color: color.text.trim(),
        capacity: seatsValue,
        seatLayoutType: seatLayoutType,
        imageUrl: existing?.imageUrl ?? '',
        notes: notes.text.trim(),
        status: existing?.status ?? FleetVehicleStatus.active,
        currentDriverId: selectedDriverId ?? '',
        seatConfiguration: seatConfig,
        licenseExpiry: existing?.licenseExpiry ?? '',
        insuranceExpiry: existing?.insuranceExpiry ?? '',
        inspectionExpiry: existing?.inspectionExpiry ?? '',
        images: existing?.images ?? const [],
        previousDrivers: existing?.previousDrivers ?? const [],
        tripHistory: existing?.tripHistory ?? const [],
        timeline: existing?.timeline ?? const [],
      );
      widget.onSave(finalVehicle);
    } else {
      setState(() => _globalError = 'يرجى تصحيح الأخطاء في الحقول أولاً');
    }
  }
}

class _DocumentManager extends StatefulWidget {
  final String ownerId;
  final bool isDriver;
  final List<FleetDocument> documents;

  const _DocumentManager({
    required this.ownerId,
    required this.isDriver,
    required this.documents,
  });

  @override
  State<_DocumentManager> createState() => _DocumentManagerState();
}

class _DocumentManagerState extends State<_DocumentManager> {
  FleetDocumentType? selectedType;
  final expiryController = TextEditingController();
  PlatformFile? pickedFile;
  List<int>? pickedFileBytes;
  bool uploading = false;
  String error = '';

  @override
  void dispose() {
    expiryController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (result != null) {
        final file = result.files.single;
        List<int>? bytes = file.bytes;
        if (bytes == null && file.path != null && !kIsWeb) {
          bytes = await io.File(file.path!).readAsBytes();
        }
        if (bytes != null) {
          setState(() {
            pickedFile = file;
            pickedFileBytes = bytes;
            error = '';
          });
        } else {
          setState(() => error = 'تعذر قراءة محتوى الملف');
        }
      }
    } catch (_) {
      setState(() => error = 'تعذر اختيار الملف');
    }
  }

  Future<void> _uploadAndSave() async {
    setState(() => error = '');
    if (selectedType == null) {
      setState(() => error = 'يرجى اختيار نوع الوثيقة');
      return;
    }
    final dateErr = _validateDate(expiryController.text, 'تاريخ انتهاء الصلاحية');
    if (dateErr != null) {
      setState(() => error = dateErr);
      return;
    }
    if (pickedFile == null || pickedFileBytes == null) {
      setState(() => error = 'يرجى اختيار ملف الوثيقة');
      return;
    }
    setState(() {
      uploading = true;
      error = '';
    });
    try {
      final cubit = context.read<FleetCubit>();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile!.name}';
      final path = 'documents/$fileName';

      final url = await cubit.uploadDocumentFile('documents', path, pickedFileBytes!);
      if (url == null || url.isEmpty) {
        throw Exception('فشل رفع الملف إلى التخزين');
      }

      final saveError = await cubit.saveDocument(
        ownerId: widget.ownerId,
        isDriver: widget.isDriver,
        type: selectedType!,
        fileUrl: url,
        expiryDate: expiryController.text.trim(),
      );

      if (saveError != null) {
        throw Exception(saveError);
      }

      setState(() {
        pickedFile = null;
        pickedFileBytes = null;
        expiryController.clear();
        selectedType = null;
      });
    } catch (e) {
      setState(() => error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => uploading = false);
    }
  }

  Future<void> _deleteDoc(FleetDocument doc) async {
    setState(() => uploading = true);
    try {
      final cubit = context.read<FleetCubit>();
      final uri = Uri.tryParse(doc.fileUrl);
      if (uri != null) {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final path = pathSegments.skip(pathSegments.indexOf('documents') + 1).join('/');
          if (path.isNotEmpty) {
            await cubit.deleteFile('documents', 'documents/$path');
          }
        }
      }
      final delError = await cubit.deleteDocument(documentId: doc.id, isDriver: widget.isDriver);
      if (delError != null) throw Exception(delError);
    } catch (e) {
      setState(() => error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filteredTypes = widget.isDriver
        ? [
            FleetDocumentType.driverLicense,
            FleetDocumentType.nationalIdFront,
            FleetDocumentType.nationalIdBack,
            FleetDocumentType.criminalRecord,
            FleetDocumentType.employmentContract,
            FleetDocumentType.other,
          ]
        : [
            FleetDocumentType.vehicleLicense,
            FleetDocumentType.insurance,
            FleetDocumentType.inspection,
            FleetDocumentType.other,
          ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إدارة الوثائق والمستندات', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.medium),
          if (widget.documents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
              child: Text('لا توجد وثائق مرفوعة حالياً.'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.documents.length,
              itemBuilder: (context, index) {
                final doc = widget.documents[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.small),
                  child: ListTile(
                    leading: Icon(
                      doc.status == FleetDocumentStatus.expired ? Icons.warning_amber_rounded : Icons.description_rounded,
                      color: doc.status == FleetDocumentStatus.expired ? scheme.error : scheme.primary,
                    ),
                    title: Text(doc.type.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('تاريخ الانتهاء: ${doc.expiryDate} | الحالة: ${doc.status.label}'),
                    trailing: Wrap(
                      spacing: AppSpacing.xSmall,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded),
                          tooltip: 'عرض الملف',
                          onPressed: doc.fileUrl.isNotEmpty
                              ? () => launchUrl(Uri.parse(doc.fileUrl), mode: LaunchMode.externalApplication)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                          tooltip: 'حذف الوثيقة',
                          onPressed: () => _deleteDoc(doc),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: AppSpacing.medium),
          const Divider(),
          const SizedBox(height: AppSpacing.medium),
          Text('رفع وثيقة جديدة', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.small),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              final fields = [
                Expanded(
                  flex: isCompact ? 0 : 1,
                  child: DropdownButtonFormField<FleetDocumentType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'نوع الوثيقة',
                      border: OutlineInputBorder(),
                    ),
                    items: filteredTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                    onChanged: (v) => setState(() => selectedType = v),
                  ),
                ),
                if (isCompact) const SizedBox(height: AppSpacing.small) else const SizedBox(width: AppSpacing.small),
                Expanded(
                  flex: isCompact ? 0 : 1,
                  child: TextField(
                    controller: expiryController,
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الانتهاء (YYYY-MM-DD)',
                      suffixIcon: Icon(Icons.calendar_today_rounded),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) {
                        setState(() {
                          expiryController.text = date.toIso8601String().substring(0, 10);
                        });
                      }
                    },
                  ),
                ),
              ];

              return isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: fields,
                    )
                  : Row(children: fields);
            },
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(pickedFile != null ? 'تغيير الملف' : 'اختر ملف الوثيقة'),
              ),
              if (pickedFile != null) ...[
                const SizedBox(width: AppSpacing.small),
                Expanded(child: Text(pickedFile!.name, overflow: TextOverflow.ellipsis)),
              ],
              const Spacer(),
              if (uploading)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: _uploadAndSave,
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text('رفع وحفظ الوثيقة'),
                ),
            ],
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(error, style: TextStyle(color: scheme.error, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}

class _SeatLayoutVisualizer extends StatelessWidget {
  final SeatConfiguration seatConfig;

  const _SeatLayoutVisualizer({required this.seatConfig});

  @override
  Widget build(BuildContext context) {
    if (seatConfig.seats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
        child: Text('لا يوجد تخطيط مقاعد مدخل للمركبة.'),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تخطيط المقاعد الداخلي', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.medium),
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(color: scheme.outline.withAlpha(50)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
                    margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withAlpha(100),
                      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                    ),
                    child: const Text('مقدمة الحافلة (التابلوه)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: seatConfig.rows,
                    itemBuilder: (context, rIndex) {
                      final row = rIndex + 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.small),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(seatConfig.columns, (cIndex) {
                            final col = cIndex + 1;
                            final seat = seatConfig.seats.firstWhere(
                              (s) => s.row == row && s.column == col,
                              orElse: () => const SeatLayoutItem(seatNumber: '', seatType: 'empty', row: 0, column: 0),
                            );

                            if (seat.seatType == 'empty' || seat.row == 0) {
                              return const SizedBox(width: 48, height: 48);
                            }

                            final isDriver = seat.seatType == 'driver';
                            final isVip = seat.seatType == 'vip';

                            return Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDriver
                                    ? scheme.secondaryContainer
                                    : isVip
                                        ? Colors.amber.shade100
                                        : scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                                border: Border.all(
                                  color: isDriver
                                      ? scheme.secondary
                                      : isVip
                                          ? Colors.amber.shade800
                                          : scheme.primary,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isDriver
                                        ? Icons.settings_accessibility_rounded
                                        : isVip
                                            ? Icons.star_rounded
                                            : Icons.event_seat_rounded,
                                    size: 18,
                                    color: isDriver
                                        ? scheme.onSecondaryContainer
                                        : isVip
                                            ? Colors.amber.shade900
                                            : scheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    seat.seatNumber,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDriver
                                          ? scheme.onSecondaryContainer
                                          : isVip
                                              ? Colors.amber.shade900
                                              : scheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _openAssignDialog(BuildContext context) {
  final state = context.read<FleetCubit>().state as FleetLoaded;
  final drivers = state.workspace.drivers
      .where(
        (driver) => driver.status == FleetDriverStatus.active && driver.currentVehicleId.isEmpty,
      )
      .toList();
  final vehicles = state.workspace.vehicles
      .where(
        (vehicle) => vehicle.status == FleetVehicleStatus.active && vehicle.currentDriverId.isEmpty,
      )
      .toList();
  _openAssignmentDialog(context, drivers: drivers, vehicles: vehicles);
}

void _openReassignDialog(BuildContext context, FleetAssignment assignment) {
  final state = context.read<FleetCubit>().state as FleetLoaded;
  final vehicles = state.workspace.vehicles
      .where(
        (vehicle) => vehicle.status == FleetVehicleStatus.active && vehicle.currentDriverId.isEmpty,
      )
      .toList();
  _openAssignmentDialog(context, assignment: assignment, vehicles: vehicles);
}

void _openAssignmentDialog(
  BuildContext context, {
  FleetAssignment? assignment,
  List<FleetDriver> drivers = const [],
  required List<FleetVehicle> vehicles,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<FleetCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: _AssignmentDialog(
          assignment: assignment,
          drivers: drivers,
          vehicles: vehicles,
        ),
      ),
    ),
  );
}

class _AssignmentDialog extends StatefulWidget {
  final FleetAssignment? assignment;
  final List<FleetDriver> drivers;
  final List<FleetVehicle> vehicles;

  const _AssignmentDialog({
    this.assignment,
    required this.drivers,
    required this.vehicles,
  });

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  String driverId = '';
  String vehicleId = '';
  String error = '';

  @override
  void initState() {
    super.initState();
    driverId = widget.drivers.isEmpty ? '' : widget.drivers.first.id;
    vehicleId = widget.vehicles.isEmpty ? '' : widget.vehicles.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final reassign = widget.assignment != null;
    return AlertDialog(
      title: Text(reassign ? 'تغيير المركبة' : 'تعيين سائق لمركبة'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!reassign)
              DropdownButtonFormField<String>(
                initialValue: driverId.isEmpty ? null : driverId,
                decoration: const InputDecoration(
                  labelText: 'السائق',
                  border: OutlineInputBorder(),
                ),
                items: widget.drivers
                    .map(
                      (driver) => DropdownMenuItem(
                        value: driver.id,
                        child: Text(driver.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => driverId = value ?? ''),
              ),
            if (!reassign) const SizedBox(height: AppSpacing.small),
            DropdownButtonFormField<String>(
              initialValue: vehicleId.isEmpty ? null : vehicleId,
              decoration: const InputDecoration(
                labelText: 'المركبة',
                border: OutlineInputBorder(),
              ),
              items: widget.vehicles
                  .map(
                    (vehicle) => DropdownMenuItem(
                      value: vehicle.id,
                      child: Text(
                        '${vehicle.vehicleNumber} - ${vehicle.plateNumber}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => vehicleId = value ?? ''),
            ),
            if (widget.vehicles.isEmpty || (!reassign && widget.drivers.isEmpty)) ...[
              const SizedBox(height: AppSpacing.small),
              Text(
                'لا توجد بيانات متاحة غير معينة حالياً',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (error.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.small),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }

  Future<void> _save() async {
    if (vehicleId.isEmpty || (widget.assignment == null && driverId.isEmpty)) {
      setState(() => error = 'اختر السائق والمركبة أولاً');
      return;
    }
    final cubit = context.read<FleetCubit>();
    final result = widget.assignment == null ? await cubit.assign(driverId, vehicleId) : await cubit.reassign(widget.assignment!.id, vehicleId);
    if (result != null) {
      setState(() => error = result);
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }
}

// ==========================================
// Fleet Input Validation Helpers (Arabic)
// ==========================================

String? _validateName(String? value) {
  if (value == null || value.trim().isEmpty) return 'الاسم الكامل مطلوب';
  final trimmed = value.trim();
  final words = trimmed.split(RegExp(r'\s+'));
  if (words.length < 2) return 'يرجى إدخال الاسم ثنائياً على الأقل';
  return null;
}

String? _validateNationalId(String? value) {
  if (value == null || value.trim().isEmpty) return 'الرقم القومي مطلوب';
  final trimmed = value.trim();
  if (trimmed.length != 14 || !RegExp(r'^\d{14}$').hasMatch(trimmed)) {
    return 'الرقم القومي يجب أن يتكون من 14 رقماً فقط';
  }
  return null;
}

String? _validatePhone(String value, String fieldLabel) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '$fieldLabel مطلوب';
  if (trimmed.length != 11 || !RegExp(r'^\d{11}$').hasMatch(trimmed)) {
    return '$fieldLabel يجب أن يتكون من 11 رقماً';
  }
  if (!RegExp(r'^(010|011|012|015)').hasMatch(trimmed)) {
    return '$fieldLabel يجب أن يبدأ برقم هاتف مصري صحيح (010, 011, 012, 015)';
  }
  return null;
}

String? _validateDate(String value, String fieldLabel) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '$fieldLabel مطلوب';
  final dateRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (!dateRegExp.hasMatch(trimmed)) {
    return '$fieldLabel يجب أن يكون بالتنسيق YYYY-MM-DD (مثال: 2026-06-18)';
  }
  final date = DateTime.tryParse(trimmed);
  if (date == null) {
    return 'التاريخ المدخل غير صحيح';
  }
  return null;
}

String? _validateEmployeeCode(String? value) {
  if (value == null || value.trim().isEmpty) return 'كود الموظف مطلوب';
  final trimmed = value.trim();
  if (trimmed.length < 3) return 'كود الموظف يجب أن يتكون من 3 رموز على الأقل';
  return null;
}

String? _validateLicenseNumber(String? value) {
  if (value == null || value.trim().isEmpty) return 'رقم الرخصة مطلوب';
  final trimmed = value.trim();
  if (trimmed.length < 4) return 'رقم الرخصة قصير جداً';
  return null;
}

String? _validateVehicleCode(String? value) {
  if (value == null || value.trim().isEmpty) return 'كود المركبة مطلوب';
  final trimmed = value.trim();
  if (trimmed.length < 3) return 'كود المركبة يجب أن يتكون من 3 رموز على الأقل';
  return null;
}

String? _validatePlateNumber(String? value) {
  if (value == null || value.trim().isEmpty) return 'رقم اللوحة مطلوب';
  final trimmed = value.trim();
  final hasDigits = RegExp(r'\d').hasMatch(trimmed);
  final hasLetters = RegExp(r'[\u0600-\u06FFa-zA-Z]').hasMatch(trimmed);
  if (!hasDigits || !hasLetters) {
    return 'رقم اللوحة يجب أن يحتوي على أرقام وحروف معاً (مثال: 123 أ ب ج)';
  }
  return null;
}

String? _validateManufactureYear(String? value) {
  if (value == null || value.trim().isEmpty) return 'سنة الصنع مطلوبة';
  final trimmed = value.trim();
  final year = int.tryParse(trimmed);
  if (year == null) return 'سنة الصنع يجب أن تكون رقماً صحيحاً';
  final currentYear = DateTime.now().year;
  if (year < 1990 || year > currentYear + 1) {
    return 'سنة الصنع يجب أن تكون بين 1990 و ${currentYear + 1}';
  }
  return null;
}

String? _validateCapacity(String? value) {
  if (value == null || value.trim().isEmpty) return 'السعة الركابية مطلوبة';
  final trimmed = value.trim();
  final capacity = int.tryParse(trimmed);
  if (capacity == null) return 'السعة الركابية يجب أن تكون رقماً صحيحاً';
  if (capacity < 2 || capacity > 100) {
    return 'السعة الركابية يجب أن تكون بين 2 و 100 مقعد';
  }
  return null;
}
