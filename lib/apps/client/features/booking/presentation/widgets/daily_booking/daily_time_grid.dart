import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/widgets/time_selection_chip.dart';

/// Grid of arrival-time chips for the daily booking wizard.
class DailyTimeGrid extends StatelessWidget {
  const DailyTimeGrid({super.key, required this.times, required this.onSelect});

  final List<String> times;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        for (final time in times)
          TimeSelectionChip(time: time, onTap: () => onSelect(time)),
      ],
    );
  }
}
