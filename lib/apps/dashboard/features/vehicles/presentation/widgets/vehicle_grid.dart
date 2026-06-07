import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../../domain/entities/vehicle.dart';
import '../models/vehicle_filters.dart';
import 'vehicle_card.dart';

class VehicleGrid extends StatelessWidget {
  final List<Vehicle> vehicles;
  final VehicleFilters filters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<VehicleStatus?> onStatusChanged;
  final ValueChanged<Vehicle> onVehicleSelected;

  const VehicleGrid({
    required this.vehicles,
    required this.filters,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onVehicleSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          child: Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.medium,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'بحث في الأسطول',
                    hintText: 'لوحة، سائق، مسار، موديل',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<VehicleStatus?>(
                  initialValue: filters.status,
                  decoration: const InputDecoration(labelText: 'حالة المركبة'),
                  items: [
                    const DropdownMenuItem<VehicleStatus?>(
                      value: null,
                      child: Text('كل الحالات'),
                    ),
                    ...VehicleStatus.values.map(
                      (status) => DropdownMenuItem<VehicleStatus?>(
                        value: status,
                        child: Text(status.label),
                      ),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        if (vehicles.isEmpty)
          const AppCard(
            child: EmptyState(
              title: 'لا توجد مركبات',
              subtitle: 'غيّر البحث أو الفلتر لعرض مركبات أخرى.',
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1180
                  ? 3
                  : constraints.maxWidth >= 760
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vehicles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppSpacing.medium,
                  mainAxisSpacing: AppSpacing.medium,
                  mainAxisExtent: 320,
                ),
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return VehicleCard(
                    vehicle: vehicle,
                    onTap: () => onVehicleSelected(vehicle),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
