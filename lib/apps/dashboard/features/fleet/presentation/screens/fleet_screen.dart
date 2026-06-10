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

class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FleetCubit, FleetState>(
      builder: (context, state) {
        return switch (state) {
          FleetLoading() => const Center(child: CircularProgressIndicator()),
          FleetError(:final message) => _FleetError(message: message),
          FleetLoaded() => _FleetLoadedView(state: state),
        };
      },
    );
  }
}

class _FleetLoadedView extends StatelessWidget {
  final FleetLoaded state;

  const _FleetLoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _Header(state: state),
        const SizedBox(height: AppSpacing.large),
        _Summary(summary: state.workspace.summary),
        const SizedBox(height: AppSpacing.large),
        _FleetTabs(active: state.tab),
        const SizedBox(height: AppSpacing.medium),
        _Toolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        switch (state.tab) {
          FleetTab.drivers => _DriversTable(state: state),
          FleetTab.vehicles => _VehiclesTable(state: state),
          FleetTab.assignments => _AssignmentsTable(state: state),
          FleetTab.documents => _DocumentsTable(state: state),
        },
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final FleetLoaded state;

  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<FleetCubit>();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الأسطول',
                  style: Theme.of(context).textTheme.headlineSmall,
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
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              if (state.tab == FleetTab.drivers)
                FilledButton.icon(
                  onPressed: () => _openDriverForm(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('إضافة سائق'),
                ),
              if (state.tab == FleetTab.vehicles)
                FilledButton.icon(
                  onPressed: () => _openVehicleForm(context),
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
        ],
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
        final columns = constraints.maxWidth >= 980 ? 4 : 2;
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
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(child: Text(label)),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xSmall),
      child: Row(
        children: FleetTab.values.map((tab) {
          final selected = tab == active;
          return Expanded(
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
        }).toList(),
      ),
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
              ),
            ),
          ),
          SizedBox(
            width: 230,
            child: DropdownButtonFormField<String>(
              initialValue: state.filter,
              decoration: const InputDecoration(labelText: 'فلتر'),
              items: _filtersFor(state.tab)
                  .map(
                    (filter) =>
                        DropdownMenuItem(value: filter, child: Text(filter)),
                  )
                  .toList(),
              onChanged: (value) => cubit.filter(value ?? 'الكل'),
            ),
          ),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<FleetSortField>(
              initialValue: state.sortField,
              decoration: const InputDecoration(labelText: 'ترتيب'),
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
              state.sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
            ),
            label: const Text('عكس الترتيب'),
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

  const _DriversTable({required this.state});

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
          Text(driver.name),
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
                onPressed: () => _openDriverDetails(context, driver),
                child: const Text('عرض'),
              ),
              TextButton(
                onPressed: () => _openDriverForm(context, driver: driver),
                child: const Text('تعديل'),
              ),
              TextButton(
                onPressed: driver.status == FleetDriverStatus.active
                    ? () => cubit.updateDriverStatus(
                        driver.id,
                        FleetDriverStatus.suspended,
                      )
                    : null,
                child: const Text('إيقاف'),
              ),
              TextButton(
                onPressed: driver.status == FleetDriverStatus.suspended
                    ? () => cubit.updateDriverStatus(
                        driver.id,
                        FleetDriverStatus.active,
                      )
                    : null,
                child: const Text('إعادة تفعيل'),
              ),
              TextButton(
                onPressed: () => cubit.updateDriverStatus(
                  driver.id,
                  FleetDriverStatus.archived,
                ),
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

  const _VehiclesTable({required this.state});

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
          Text(vehicle.vehicleNumber),
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
                onPressed: () => _openVehicleDetails(context, vehicle),
                child: const Text('عرض'),
              ),
              TextButton(
                onPressed: () => _openVehicleForm(context, vehicle: vehicle),
                child: const Text('تعديل'),
              ),
              TextButton(
                onPressed: () => cubit.updateVehicleStatus(
                  vehicle.id,
                  FleetVehicleStatus.suspended,
                ),
                child: const Text('إيقاف'),
              ),
              TextButton(
                onPressed: () => cubit.updateVehicleStatus(
                  vehicle.id,
                  FleetVehicleStatus.archived,
                ),
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
          Text(_driverName(state.workspace, assignment.driverId)),
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
                onPressed: () =>
                    _openHistory(context, 'سجل التعيين', assignment.history),
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
          Text(document.type.label),
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
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.large),
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
                          children: cells
                              .map((cell) => Expanded(child: cell))
                              .toList(),
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
                  onPressed: state.page == 0
                      ? null
                      : () => cubit.page(state.page - 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                IconButton(
                  onPressed: state.page >= pages - 1
                      ? null
                      : () => cubit.page(state.page + 1),
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

  const _FleetError({required this.message});

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
    final matchesSearch =
        query.isEmpty ||
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
    return matchesSearch &&
        matchesFilter &&
        driver.status != FleetDriverStatus.archived;
  }).toList();
}

List<FleetVehicle> _filterVehicles(FleetLoaded state) {
  final query = state.searchQuery.trim();
  return state.workspace.vehicles.where((vehicle) {
    final matchesSearch =
        query.isEmpty ||
        vehicle.vehicleNumber.contains(query) ||
        vehicle.plateNumber.contains(query) ||
        vehicle.model.contains(query);
    final matchesFilter = switch (state.filter) {
      'نشطة' => vehicle.status == FleetVehicleStatus.active,
      'صيانة' => vehicle.status == FleetVehicleStatus.maintenance,
      'بدون سائق' => vehicle.currentDriverId.isEmpty,
      'الرخصة قاربت على الانتهاء' =>
        _documentStatus(vehicle.licenseExpiry) ==
            FleetDocumentStatus.expiringSoon,
      _ => true,
    };
    return matchesSearch &&
        matchesFilter &&
        vehicle.status != FleetVehicleStatus.archived;
  }).toList();
}

List<FleetAssignment> _filterAssignments(FleetLoaded state) {
  final query = state.searchQuery.trim();
  return state.workspace.assignments.where((assignment) {
    final driver = _driverName(state.workspace, assignment.driverId);
    final vehicle = _vehicleName(state.workspace, assignment.vehicleId);
    final matchesSearch =
        query.isEmpty || driver.contains(query) || vehicle.contains(query);
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
    final matchesSearch =
        query.isEmpty ||
        document.ownerName.contains(query) ||
        document.referenceNumber.contains(query);
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
      FleetSortField.licenseExpiry => a.licenseExpiry.compareTo(
        b.licenseExpiry,
      ),
      FleetSortField.status => a.status.label.compareTo(b.status.label),
      _ => a.name.compareTo(b.name),
    },
  );
  return state.sortAscending ? next : next.reversed.toList();
}

List<FleetVehicle> _sortVehicles(
  List<FleetVehicle> vehicles,
  FleetLoaded state,
) {
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

List<FleetAssignment> _sortAssignments(
  List<FleetAssignment> assignments,
  FleetLoaded state,
) {
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

void _openDriverDetails(BuildContext context, FleetDriver driver) {
  final workspace = (context.read<FleetCubit>().state as FleetLoaded).workspace;
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<FleetCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(driver.name),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailsSection(
                    title: 'البيانات الشخصية والمهنية',
                    rows: [
                      ('الاسم الكامل', driver.fullName),
                      ('كود الموظف', driver.employeeCode),
                      ('الرقم القومي', driver.nationalId),
                      ('العنوان', driver.address),
                      ('تاريخ التعيين', driver.hireDate),
                    ],
                  ),
                  _DetailsSection(
                    title: 'بيانات التواصل والطوارئ',
                    rows: [
                      ('الهاتف', driver.phone),
                      ('رقم الطوارئ', driver.emergencyPhone),
                    ],
                  ),
                  _DetailsSection(
                    title: 'بيانات الرخصة والحالة',
                    rows: [
                      ('رقم الرخصة', driver.licenseNumber),
                      ('انتهاء الرخصة', driver.licenseExpiryDate),
                      ('الحالة', driver.status.label),
                    ],
                  ),
                  if (driver.notes.isNotEmpty)
                    _DetailsSection(
                      title: 'ملاحظات الإدارة',
                      rows: [('الملاحظات', driver.notes)],
                    ),
                  _DetailsSection(
                    title: 'المركبة الحالية',
                    rows: [
                      (
                        'المركبة',
                        _vehicleName(
                          workspace,
                          driver.currentVehicleId,
                        ).ifEmpty('بدون مركبة'),
                      ),
                    ],
                  ),
                  _DocumentManager(
                    ownerId: driver.id,
                    isDriver: true,
                    documents: driver.documents,
                  ),
                  _HistoryBlock(title: 'سجل الرحلات', items: driver.tripHistory),
                  _HistoryBlock(title: 'سجل المخالفات', items: driver.violations),
                  _HistoryBlock(
                    title: 'سجل النشاط',
                    items: driver.activityTimeline,
                  ),
                ],
              ),
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
    ),
  );
}

void _openVehicleDetails(BuildContext context, FleetVehicle vehicle) {
  final workspace = (context.read<FleetCubit>().state as FleetLoaded).workspace;
  final vehicleDocs = workspace.documents.where((d) => d.ownerId == vehicle.id).toList();

  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<FleetCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('${vehicle.brand} ${vehicle.model} (${vehicle.vehicleCode})'),
          content: SizedBox(
            width: 820,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailsSection(
                    title: 'البيانات الأساسية للمركبة',
                    rows: [
                      ('كود المركبة', vehicle.vehicleCode),
                      ('رقم اللوحة', vehicle.plateNumber),
                      ('فئة المركبة', vehicle.vehicleType),
                      ('الماركة', vehicle.brand),
                      ('الموديل', vehicle.model),
                      ('سنة الصنع', '${vehicle.manufactureYear}'),
                      ('اللون', vehicle.color),
                      ('السعة الركابية', '${vehicle.capacity} مقعد'),
                      ('نوع التخطيط', vehicle.seatLayoutType),
                      ('الحالة', vehicle.status.label),
                    ],
                  ),
                  if (vehicle.notes.isNotEmpty)
                    _DetailsSection(
                      title: 'ملاحظات الصيانة والتشغيل',
                      rows: [('ملاحظات', vehicle.notes)],
                    ),
                  _SeatLayoutVisualizer(seatConfig: vehicle.seatConfiguration),
                  _DocumentManager(
                    ownerId: vehicle.id,
                    isDriver: false,
                    documents: vehicleDocs,
                  ),
                  _DetailsSection(
                    title: 'السائق الحالي للمركبة',
                    rows: [
                      (
                        'السائق',
                        _driverName(
                          workspace,
                          vehicle.currentDriverId,
                        ).ifEmpty('بدون سائق'),
                      ),
                    ],
                  ),
                  _HistoryBlock(
                    title: 'سجل السائقين السابقين',
                    items: vehicle.previousDrivers,
                  ),
                  _HistoryBlock(title: 'سجل الرحلات', items: vehicle.tripHistory),
                  _HistoryBlock(title: 'سجل النشاط التشغيلي', items: vehicle.timeline),
                ],
              ),
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
    ),
  );
}

class _DetailsSection extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;

  const _DetailsSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withAlpha(70),
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.small),
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
                  child: Text('${row.$1}: ${row.$2}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryBlock extends StatelessWidget {
  final String title;
  final List<FleetHistoryItem> items;

  const _HistoryBlock({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _DetailsSection(
        title: title,
        rows: const [('الحالة', 'لا توجد سجلات')],
      );
    }
    return _DetailsSection(
      title: title,
      rows: items
          .map((item) => (item.date, '${item.title} - ${item.description}'))
          .toList(),
    );
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
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          pickedFile = result.files.single;
          error = '';
        });
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
    if (pickedFile == null) {
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
      
      final url = await cubit.uploadDocumentFile('documents', path, pickedFile!.bytes!);
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
        expiryController.clear();
        selectedType = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الوثيقة بنجاح')),
        );
      }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: AppSpacing.small),
        Text('إدارة الوثائق والمستندات', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.small),
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
                    doc.status == FleetDocumentStatus.expired
                        ? Icons.warning_amber_rounded
                        : Icons.description_rounded,
                    color: doc.status == FleetDocumentStatus.expired
                        ? scheme.error
                        : scheme.primary,
                  ),
                  title: Text(doc.type.label),
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
        Text('رفع وثيقة جديدة', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.small),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<FleetDocumentType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'نوع الوثيقة'),
                items: filteredTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => selectedType = v),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: TextField(
                controller: expiryController,
                decoration: const InputDecoration(
                  labelText: 'تاريخ الانتهاء (YYYY-MM-DD)',
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
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
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(pickedFile != null ? 'تغيير الملف' : 'اختر ملف'),
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
                label: const Text('رفع وحفظ'),
              ),
          ],
        ),
        if (error.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          Text(error, style: TextStyle(color: scheme.error)),
        ],
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: AppSpacing.small),
        Text('تخطيط المقاعد الداخلي', style: Theme.of(context).textTheme.titleMedium),
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
    );
  }
}

void _openDriverForm(BuildContext context, {FleetDriver? driver}) {
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<FleetCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: _DriverFormDialog(driver: driver),
      ),
    ),
  );
}

class _DriverFormDialog extends StatefulWidget {
  final FleetDriver? driver;

  const _DriverFormDialog({this.driver});

  @override
  State<_DriverFormDialog> createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends State<_DriverFormDialog> {
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

  int step = 0;
  String error = '';
  bool saved = false;

  @override
  void initState() {
    super.initState();
    final driver = widget.driver;
    name = TextEditingController(text: driver?.fullName ?? '');
    phone = TextEditingController(text: driver?.phone ?? '');
    nationalId = TextEditingController(text: driver?.nationalId ?? '');
    license = TextEditingController(text: driver?.licenseNumber ?? '');
    expiry = TextEditingController(text: driver?.licenseExpiryDate ?? '');
    address = TextEditingController(text: driver?.address ?? '');
    emergency = TextEditingController(text: driver?.emergencyPhone ?? '');
    employeeCode = TextEditingController(text: driver?.employeeCode ?? '');
    hireDate = TextEditingController(text: driver?.hireDate ?? '');
    notes = TextEditingController(text: driver?.notes ?? '');
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
    if (saved) {
      return AlertDialog(
        title: const Text('تم حفظ السائق'),
        content: Text(name.text),
        actions: [
          FilledButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('إغلاق'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text(widget.driver == null ? 'إضافة سائق' : 'تعديل سائق'),
      content: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stepper(
              currentStep: step,
              controlsBuilder: (_, _) => const SizedBox.shrink(),
              onStepTapped: (value) => setState(() => step = value),
              steps: [
                Step(
                  title: const Text('بيانات شخصية وبطاقة'),
                  content: Column(
                    children: [
                      _field(name, 'الاسم الكامل'),
                      _gap,
                      _field(nationalId, 'الرقم القومي'),
                      _gap,
                      _field(employeeCode, 'كود الموظف'),
                    ],
                  ),
                ),
                Step(
                  title: const Text('بيانات التواصل'),
                  content: Column(
                    children: [
                      _field(phone, 'الهاتف'),
                      _gap,
                      _field(address, 'العنوان'),
                      _gap,
                      _field(emergency, 'رقم الطوارئ'),
                    ],
                  ),
                ),
                Step(
                  title: const Text('الرخصة وتاريخ التعيين'),
                  content: Column(
                    children: [
                      _field(license, 'رقم الرخصة'),
                      _gap,
                      _field(expiry, 'انتهاء الرخصة (YYYY-MM-DD)'),
                      _gap,
                      _field(hireDate, 'تاريخ التعيين (YYYY-MM-DD)'),
                    ],
                  ),
                ),
                Step(
                  title: const Text('ملاحظات إضافية'),
                  content: Column(
                    children: [
                      _field(notes, 'ملاحظات وتفاصيل'),
                    ],
                  ),
                ),
                const Step(
                  title: Text('رفع الوثائق'),
                  content: Text(
                    'يمكنك رفع وإدارة المستندات الخاصة بالسائق (رخصة القيادة، الفيش، عقد العمل) بشكل كامل من صفحة تفاصيل السائق بعد حفظه.',
                  ),
                ),
                Step(
                  title: const Text('مراجعة وحفظ'),
                  content: Text(
                    'الاسم: ${name.text}\nالهاتف: ${phone.text}\nكود الموظف: ${employeeCode.text}\nالرقم القومي: ${nationalId.text}',
                  ),
                ),
              ],
            ),
            if (error.isNotEmpty)
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('إلغاء'),
        ),
        if (step > 0)
          TextButton(
            onPressed: () => setState(() => step -= 1),
            child: const Text('السابق'),
          ),
        FilledButton(
          onPressed: step == 5 ? _save : _nextStep,
          child: Text(step == 5 ? 'حفظ' : 'التالي'),
        ),
      ],
    );
  }

  void _nextStep() {
    setState(() => error = '');
    String? err;
    if (step == 0) {
      err = _validateName(name.text);
      if (err == null) err = _validateNationalId(nationalId.text);
      if (err == null) err = _validateEmployeeCode(employeeCode.text);
    } else if (step == 1) {
      err = _validatePhone(phone.text, 'الهاتف');
      if (err == null) err = _validatePhone(emergency.text, 'رقم الطوارئ');
      if (err == null && phone.text.trim() == emergency.text.trim()) {
        err = 'رقم هاتف الطوارئ لا يمكن أن يكون هو نفسه رقم الهاتف الأساسي';
      }
      if (err == null && address.text.trim().isEmpty) {
        err = 'العنوان مطلوب';
      }
    } else if (step == 2) {
      err = _validateLicenseNumber(license.text);
      if (err == null) err = _validateDate(expiry.text, 'تاريخ انتهاء الرخصة');
      if (err == null) err = _validateDate(hireDate.text, 'تاريخ التعيين');
    }

    if (err != null) {
      setState(() => error = err!);
      return;
    }
    setState(() => step += 1);
  }

  void _save() {
    setState(() => error = '');
    String? err;
    err = _validateName(name.text);
    if (err == null) err = _validateNationalId(nationalId.text);
    if (err == null) err = _validateEmployeeCode(employeeCode.text);
    if (err == null) err = _validatePhone(phone.text, 'الهاتف');
    if (err == null) err = _validatePhone(emergency.text, 'رقم الطوارئ');
    if (err == null && phone.text.trim() == emergency.text.trim()) {
      err = 'رقم هاتف الطوارئ لا يمكن أن يكون هو نفسه رقم الهاتف الأساسي';
    }
    if (err == null && address.text.trim().isEmpty) {
      err = 'العنوان مطلوب';
    }
    if (err == null) err = _validateLicenseNumber(license.text);
    if (err == null) err = _validateDate(expiry.text, 'تاريخ انتهاء الرخصة');
    if (err == null) err = _validateDate(hireDate.text, 'تاريخ التعيين');

    if (err != null) {
      setState(() => error = err!);
      return;
    }
    final existing = widget.driver;
    context.read<FleetCubit>().saveDriver(
      FleetDriver(
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
        currentVehicleId: existing?.currentVehicleId ?? '',
        tripHistory: existing?.tripHistory ?? const [],
        violations: existing?.violations ?? const [],
        documents: existing?.documents ?? const [],
        activityTimeline: existing?.activityTimeline ?? const [],
      ),
    );
    setState(() => saved = true);
  }
}

void _openVehicleForm(BuildContext context, {FleetVehicle? vehicle}) {
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<FleetCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: _VehicleFormDialog(vehicle: vehicle),
      ),
    ),
  );
}

class _VehicleFormDialog extends StatefulWidget {
  final FleetVehicle? vehicle;

  const _VehicleFormDialog({this.vehicle});

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
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
  String error = '';

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    code = TextEditingController(text: vehicle?.vehicleCode ?? '');
    plate = TextEditingController(text: vehicle?.plateNumber ?? '');
    model = TextEditingController(text: vehicle?.model ?? '');
    year = TextEditingController(
      text: vehicle == null ? '' : '${vehicle.manufactureYear}',
    );
    seats = TextEditingController(
      text: vehicle == null ? '' : '${vehicle.capacity}',
    );
    brand = TextEditingController(text: vehicle?.brand ?? '');
    color = TextEditingController(text: vehicle?.color ?? '');
    notes = TextEditingController(text: vehicle?.notes ?? '');
    if (vehicle != null) {
      vehicleType = vehicle.vehicleType.isEmpty ? 'Coaster' : vehicle.vehicleType;
      seatLayoutType = vehicle.seatLayoutType.isEmpty ? 'standard' : vehicle.seatLayoutType;
    }
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
    return AlertDialog(
      title: Text(widget.vehicle == null ? 'إضافة مركبة' : 'تعديل مركبة'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _field(code, 'كود المركبة')),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(child: _field(plate, 'رقم اللوحة')),
                ],
              ),
              _gap,
              Row(
                children: [
                  Expanded(child: _field(brand, 'الماركة (مثال: Toyota)')),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(child: _field(model, 'الموديل (مثال: كوستر)')),
                ],
              ),
              _gap,
              Row(
                children: [
                  Expanded(child: _field(year, 'سنة الصنع')),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(child: _field(seats, 'السعة الركابية (المقاعد)')),
                ],
              ),
              _gap,
              Row(
                children: [
                  Expanded(child: _field(color, 'اللون')),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: vehicleType,
                      decoration: const InputDecoration(labelText: 'فئة المركبة'),
                      items: const [
                        DropdownMenuItem(value: 'Coaster', child: Text('Coaster')),
                        DropdownMenuItem(value: 'Sprinter', child: Text('Sprinter')),
                        DropdownMenuItem(value: 'Hiace', child: Text('Hiace')),
                        DropdownMenuItem(value: 'H1', child: Text('H1')),
                        DropdownMenuItem(value: 'Other', child: Text('فئة أخرى')),
                      ],
                      onChanged: (v) => setState(() => vehicleType = v ?? 'Coaster'),
                    ),
                  ),
                ],
              ),
              _gap,
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: seatLayoutType,
                      decoration: const InputDecoration(labelText: 'نوع تخطيط المقاعد'),
                      items: const [
                        DropdownMenuItem(value: 'standard', child: Text('Standard (عادي)')),
                        DropdownMenuItem(value: 'VIP', child: Text('VIP (مميز)')),
                      ],
                      onChanged: (v) => setState(() => seatLayoutType = v ?? 'standard'),
                    ),
                  ),
                ],
              ),
              _gap,
              _field(notes, 'ملاحظات أو تفاصيل الصيانة'),
              if (error.isNotEmpty) ...[
                _gap,
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
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

  void _save() {
    setState(() => error = '');
    String? err;
    err = _validateVehicleCode(code.text);
    if (err == null) err = _validatePlateNumber(plate.text);
    if (err == null) {
      if (brand.text.trim().isEmpty) err = 'الماركة مطلوبة';
    }
    if (err == null) {
      if (model.text.trim().isEmpty) err = 'الموديل مطلوب';
    }
    if (err == null) err = _validateManufactureYear(year.text);
    if (err == null) err = _validateCapacity(seats.text);
    if (err == null) {
      if (color.text.trim().isEmpty) err = 'اللون مطلوب';
    }

    if (err != null) {
      setState(() => error = err!);
      return;
    }
    final seatsValue = int.parse(seats.text.trim());
    final yearValue = int.parse(year.text.trim());
    final existing = widget.vehicle;
    final seatConfig = SeatConfiguration.generateDefault(seatsValue);

    context.read<FleetCubit>().saveVehicle(
      FleetVehicle(
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
        currentDriverId: existing?.currentDriverId ?? '',
        seatConfiguration: seatConfig,
        licenseExpiry: existing?.licenseExpiry ?? '',
        insuranceExpiry: existing?.insuranceExpiry ?? '',
        inspectionExpiry: existing?.inspectionExpiry ?? '',
        images: existing?.images ?? const [],
        previousDrivers: existing?.previousDrivers ?? const [],
        tripHistory: existing?.tripHistory ?? const [],
        timeline: existing?.timeline ?? const [],
      ),
    );
    Navigator.of(context).pop();
  }
}

void _openAssignDialog(BuildContext context) {
  final state = context.read<FleetCubit>().state as FleetLoaded;
  final drivers = state.workspace.drivers
      .where(
        (driver) =>
            driver.status == FleetDriverStatus.active &&
            driver.currentVehicleId.isEmpty,
      )
      .toList();
  final vehicles = state.workspace.vehicles
      .where(
        (vehicle) =>
            vehicle.status == FleetVehicleStatus.active &&
            vehicle.currentDriverId.isEmpty,
      )
      .toList();
  _openAssignmentDialog(context, drivers: drivers, vehicles: vehicles);
}

void _openReassignDialog(BuildContext context, FleetAssignment assignment) {
  final state = context.read<FleetCubit>().state as FleetLoaded;
  final vehicles = state.workspace.vehicles
      .where(
        (vehicle) =>
            vehicle.status == FleetVehicleStatus.active &&
            vehicle.currentDriverId.isEmpty,
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
                decoration: const InputDecoration(labelText: 'السائق'),
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
            if (!reassign) _gap,
            DropdownButtonFormField<String>(
              initialValue: vehicleId.isEmpty ? null : vehicleId,
              decoration: const InputDecoration(labelText: 'المركبة'),
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
            if (widget.vehicles.isEmpty ||
                (!reassign && widget.drivers.isEmpty)) ...[
              _gap,
              Text(
                'لا توجد بيانات متاحة غير معينة حالياً',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (error.isNotEmpty) ...[
              _gap,
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
    final result = widget.assignment == null
        ? await cubit.assign(driverId, vehicleId)
        : await cubit.reassign(widget.assignment!.id, vehicleId);
    if (result != null) {
      setState(() => error = result);
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }
}

Widget _field(TextEditingController controller, String label) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
  );
}

const _gap = SizedBox(height: AppSpacing.small);

// ==========================================
// Fleet Input Validation Helpers (Arabic)
// ==========================================

String? _validateName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'الاسم الكامل مطلوب';
  final words = trimmed.split(RegExp(r'\s+'));
  if (words.length < 2) return 'يرجى إدخال الاسم ثنائياً على الأقل';
  return null;
}

String? _validateNationalId(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'الرقم القومي مطلوب';
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

String? _validateEmployeeCode(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'كود الموظف مطلوب';
  if (trimmed.length < 3) return 'كود الموظف يجب أن يتكون من 3 رموز على الأقل';
  return null;
}

String? _validateLicenseNumber(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'رقم الرخصة مطلوب';
  if (trimmed.length < 4) return 'رقم الرخصة قصير جداً';
  return null;
}

String? _validateVehicleCode(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'كود المركبة مطلوب';
  if (trimmed.length < 3) return 'كود المركبة يجب أن يتكون من 3 رموز على الأقل';
  return null;
}

String? _validatePlateNumber(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'رقم اللوحة مطلوب';
  final hasDigits = RegExp(r'\d').hasMatch(trimmed);
  final hasLetters = RegExp(r'[\u0600-\u06FFa-zA-Z]').hasMatch(trimmed);
  if (!hasDigits || !hasLetters) {
    return 'رقم اللوحة يجب أن يحتوي على أرقام وحروف معاً (مثال: 123 أ ب ج)';
  }
  return null;
}

String? _validateManufactureYear(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'سنة الصنع مطلوبة';
  final year = int.tryParse(trimmed);
  if (year == null) return 'سنة الصنع يجب أن تكون رقماً صحيحاً';
  final currentYear = DateTime.now().year;
  if (year < 1990 || year > currentYear + 1) {
    return 'سنة الصنع يجب أن تكون بين 1990 و ${currentYear + 1}';
  }
  return null;
}

String? _validateCapacity(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'السعة الركابية مطلوبة';
  final capacity = int.tryParse(trimmed);
  if (capacity == null) return 'السعة الركابية يجب أن تكون رقماً صحيحاً';
  if (capacity < 2 || capacity > 100) {
    return 'السعة الركابية يجب أن تكون بين 2 و 100 مقعد';
  }
  return null;
}
