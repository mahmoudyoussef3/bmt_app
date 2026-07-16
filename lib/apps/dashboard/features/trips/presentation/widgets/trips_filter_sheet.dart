import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';

/// Opens the advanced-filter bottom sheet (route/driver/vehicle/occupancy/
/// date/status) on top of the caller's [TripsListCubit].
Future<void> showTripsFilterSheet(BuildContext context) {
  final cubit = context.read<TripsListCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const Directionality(
        textDirection: TextDirection.rtl,
        child: _TripsFilterSheetBody(),
      ),
    ),
  );
}

class _TripsFilterSheetBody extends StatelessWidget {
  const _TripsFilterSheetBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripsListCubit, TripsListState>(
      builder: (context, state) {
        if (state is! TripsListLoaded) return const SizedBox.shrink();
        final cubit = context.read<TripsListCubit>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'فلاتر متقدمة',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      if (state.hasAdvancedFilters)
                        TextButton(
                          onPressed: cubit.clearAdvancedFilters,
                          child: const Text('مسح الكل'),
                        ),
                      IconButton(
                        tooltip: 'إغلاق',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _FilterLabel('الحالة'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('الكل'),
                        selected: state.statusFilter == null,
                        showCheckmark: false,
                        onSelected: (_) => cubit.filterStatus(null),
                      ),
                      ...OperationTripStatus.values.map(
                        (status) => ChoiceChip(
                          label: Text(status.label),
                          selected: state.statusFilter == status,
                          showCheckmark: false,
                          onSelected: (_) => cubit.filterStatus(status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _FilterDropdown(
                    label: 'المسار',
                    value: state.routeFilter,
                    options: state.routes,
                    onChanged: cubit.filterRoute,
                  ),
                  const SizedBox(height: 16),
                  _FilterDropdown(
                    label: 'السائق',
                    value: state.driverFilter,
                    options: state.drivers,
                    onChanged: cubit.filterDriver,
                  ),
                  const SizedBox(height: 16),
                  _FilterDropdown(
                    label: 'المركبة',
                    value: state.vehicleFilter,
                    options: state.vehicles,
                    onChanged: cubit.filterVehicle,
                  ),
                  const SizedBox(height: 16),
                  _FilterDropdown(
                    label: 'نسبة الإشغال',
                    value: state.occupancyFilter,
                    options: state.occupancyBands,
                    onChanged: cubit.filterOccupancy,
                  ),
                  const SizedBox(height: 16),
                  _FilterDropdown(
                    label: 'التاريخ',
                    value: state.dateFilter,
                    options: state.dates,
                    onChanged: cubit.filterDate,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('تم'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterLabel(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : options.first,
          isExpanded: true,
          decoration: const InputDecoration(isDense: true),
          items: options
              .map(
                (option) => DropdownMenuItem(value: option, child: Text(option)),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ],
    );
  }
}
