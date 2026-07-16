import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import 'trip_row_card.dart';

/// Always-visible sections (upcoming / active / completed, plus stale /
/// cancelled when non-empty), each independently respecting search and the
/// advanced filters — unlike the single quick-filtered list view.
class TripsGroupedView extends StatelessWidget {
  const TripsGroupedView({
    super.key,
    required this.state,
    required this.onOpenDetails,
  });

  final TripsListLoaded state;
  final void Function(OperationTrip trip) onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _TripsGroupSection(
          title: 'الرحلات القادمة',
          icon: Icons.upcoming_rounded,
          color: scheme.primary,
          trips: state.upcomingGroupTrips,
          emptyMessage: 'لا توجد رحلات قادمة مطابقة للبحث الحالي.',
          onOpenDetails: onOpenDetails,
        ),
        const SizedBox(height: AppSpacing.medium),
        _TripsGroupSection(
          title: 'قيد التشغيل',
          icon: Icons.directions_bus_filled_rounded,
          color: Colors.green,
          trips: state.activeGroupTrips,
          emptyMessage: 'لا توجد رحلات قيد التشغيل الآن.',
          onOpenDetails: onOpenDetails,
        ),
        if (state.staleGroupTrips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          _TripsGroupSection(
            title: 'فات موعدها',
            icon: Icons.report_problem_rounded,
            color: scheme.error,
            trips: state.staleGroupTrips,
            emptyMessage: '',
            onOpenDetails: onOpenDetails,
          ),
        ],
        const SizedBox(height: AppSpacing.medium),
        _TripsGroupSection(
          title: 'مكتملة',
          icon: Icons.task_alt_rounded,
          color: Colors.teal,
          trips: state.completedGroupTrips,
          emptyMessage: 'لا توجد رحلات مكتملة بعد.',
          onOpenDetails: onOpenDetails,
          initiallyExpanded: false,
        ),
        if (state.cancelledGroupTrips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          _TripsGroupSection(
            title: 'ملغاة',
            icon: Icons.cancel_outlined,
            color: scheme.outline,
            trips: state.cancelledGroupTrips,
            emptyMessage: '',
            onOpenDetails: onOpenDetails,
            initiallyExpanded: false,
          ),
        ],
      ],
    );
  }
}

class _TripsGroupSection extends StatefulWidget {
  const _TripsGroupSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.trips,
    required this.emptyMessage,
    required this.onOpenDetails,
    this.initiallyExpanded = true,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<OperationTrip> trips;
  final String emptyMessage;
  final void Function(OperationTrip trip) onOpenDetails;
  final bool initiallyExpanded;

  @override
  State<_TripsGroupSection> createState() => _TripsGroupSectionState();
}

class _TripsGroupSectionState extends State<_TripsGroupSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withAlpha(24),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${widget.trips.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: widget.color,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            if (widget.trips.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    widget.emptyMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...widget.trips.indexed.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(top: entry.$1 == 0 ? 0 : 10),
                  child: TripRowCard(
                    trip: entry.$2,
                    onOpenDetails: () => widget.onOpenDetails(entry.$2),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
