import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_route.dart';

class StationsManager extends StatelessWidget {
  final OperationRoute route;
  final ReorderCallback onReorder;
  final VoidCallback onAddStation;
  final ValueChanged<RouteStation> onEditStation;
  final ValueChanged<RouteStation> onDeleteStation;

  const StationsManager({
    required this.route,
    required this.onReorder,
    required this.onAddStation,
    required this.onEditStation,
    required this.onDeleteStation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'إدارة المحطات',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              AppButton(
                label: 'إضافة محطة',
                height: 40,
                onPressed: onAddStation,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: route.stations.length,
            onReorder: onReorder,
            itemBuilder: (context, index) {
              final station = route.stations[index];
              return AppCard(
                key: ValueKey(station.id),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    CircleAvatar(radius: 15, child: Text('${index + 1}')),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xSmall),
                          Text('${station.area} • ${station.arrivalOffset}'),
                          if (station.notes.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xSmall),
                            Text(station.notes),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'تعديل',
                      onPressed: () => onEditStation(station),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'حذف',
                      onPressed: () => onDeleteStation(station),
                      icon: const Icon(Icons.delete_outline),
                    ),
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
