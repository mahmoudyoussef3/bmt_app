import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';

/// Segmented switch between the flat list, grouped sections, and the
/// chronological timeline.
class TripsViewModeSwitch extends StatelessWidget {
  const TripsViewModeSwitch({
    super.key,
    required this.viewMode,
    required this.onChanged,
  });

  final TripsViewMode viewMode;
  final ValueChanged<TripsViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TripsViewMode>(
      segments: const [
        ButtonSegment(
          value: TripsViewMode.list,
          label: Text('قائمة'),
          icon: Icon(Icons.view_list_rounded),
        ),
        ButtonSegment(
          value: TripsViewMode.grouped,
          label: Text('تجميع'),
          icon: Icon(Icons.dashboard_customize_rounded),
        ),
        ButtonSegment(
          value: TripsViewMode.timeline,
          label: Text('الجدول الزمني'),
          icon: Icon(Icons.timeline_rounded),
        ),
      ],
      selected: {viewMode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
