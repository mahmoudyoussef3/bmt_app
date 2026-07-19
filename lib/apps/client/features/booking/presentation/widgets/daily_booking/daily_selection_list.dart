import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_selection_tile.dart';

/// A titled list of selectable options (pickup or destination) for the daily
/// booking wizard.
class DailySelectionList extends StatelessWidget {
  const DailySelectionList({
    super.key,
    required this.title,
    required this.items,
    required this.activeColor,
    required this.onSelect,
  });

  final String title;
  final List<String> items;
  final Color activeColor;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final item in items) ...[
          RouteSelectionTile(
            label: item,
            color: activeColor,
            onTap: () => onSelect(item),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
