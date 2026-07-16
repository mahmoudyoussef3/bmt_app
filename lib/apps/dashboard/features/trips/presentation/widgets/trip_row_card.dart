import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/presentation/cubit/trip_creation_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import 'trip_creation_wizard.dart';
import 'trip_ui_helpers.dart';

/// A single trip summary row used by the list, grouped, and timeline views.
class TripRowCard extends StatelessWidget {
  const TripRowCard({super.key, required this.trip, required this.onOpenDetails});

  final OperationTrip trip;

  /// Opens the trip details workspace. Kept as a callback so this widget
  /// stays reusable outside `trips_screen.dart`, where the details dialog
  /// itself is defined.
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final occupancy = trip.capacity == 0
        ? 0.0
        : (trip.bookedSeats / trip.capacity).clamp(0.0, 1.0);
    final isStale = trip.isStaleBooking();
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpenDetails,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: tripStatusColor(
                            context,
                            trip.status,
                          ).withAlpha(22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.route_rounded,
                          color: tripStatusColor(context, trip.status),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.route,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${tripFriendlyDate(trip.date)}، ${trip.departure}'
                              '${trip.arrival.isEmpty ? '' : ' - ${trip.arrival}'}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: trip.status.label,
                        color: isStale
                            ? scheme.error.withAlpha(28)
                            : tripStatusColor(context, trip.status).withAlpha(28),
                        textColor: isStale
                            ? scheme.error
                            : tripStatusColor(context, trip.status),
                      ),
                    ],
                  ),
                  if (isStale) ...[
                    const SizedBox(height: 12),
                    const StaleTripBanner(),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TripFact(
                          icon: Icons.person_outline_rounded,
                          text: trip.driver,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TripFact(
                          icon: Icons.directions_bus_outlined,
                          text: trip.vehicle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: occupancy,
                            minHeight: 7,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${trip.bookedSeats} من ${trip.capacity} مقعد',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              );
              final actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: onOpenDetails,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('عرض التفاصيل'),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'المزيد',
                    onSelected: (value) {
                      if (value == 'copy') _duplicate(context);
                      if (value == 'delete') _delete(context);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'copy',
                        child: ListTile(
                          leading: Icon(Icons.copy_rounded),
                          title: Text('نسخ الرحلة'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline_rounded),
                          title: Text('حذف الرحلة'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    content,
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: actions,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _duplicate(BuildContext context) {
    final listCubit = context.read<TripsListCubit>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => dashboardDi<TripCreationCubit>()..loadWizardData(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: TripCreationWizardDialog(prefillTrip: trip),
        ),
      ),
    ).then((_) => listCubit.load());
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الرحلة؟'),
        content: Text('سيتم حذف رحلة ${trip.route} نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<TripsListCubit>().deleteTrip(trip.id);
    }
  }
}

/// Explains why an open trip is missing from the client app: its departure
/// day has passed, so the booking search filters it out no matter what
/// status the dashboard shows. [actions] lets the details dialog offer a way
/// to resolve it.
class StaleTripBanner extends StatelessWidget {
  const StaleTripBanner({super.key, this.actions});

  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withAlpha(70),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.visibility_off_rounded, size: 18, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'فات موعد هذه الرحلة وما زالت مفتوحة للحجز، لذلك لا تظهر '
                  'للعملاء في التطبيق. أنهِها أو ألغِها لتصحيح الحالة.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (actions != null) ...[
            const SizedBox(height: 10),
            Align(alignment: AlignmentDirectional.centerStart, child: actions!),
          ],
        ],
      ),
    );
  }
}

class TripFact extends StatelessWidget {
  const TripFact({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
