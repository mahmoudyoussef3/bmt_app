import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/reassignment_target.dart';

/// Picks the trip an existing booking should be moved onto.
///
/// Targets are loaded when the dialog opens rather than held in list state:
/// moving a booking is an exception path, and pre-fetching every eligible trip
/// for a queue nobody has opened is wasted work on each bookings refresh.
class BookingReassignDialog extends StatefulWidget {
  const BookingReassignDialog({
    super.key,
    required this.passengerName,
    required this.currentTrip,
    required this.loadTargets,
  });

  final String passengerName;
  final String currentTrip;
  final Future<List<ReassignmentTarget>> Function() loadTargets;

  /// Returns the chosen trip id, or `null` when dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String passengerName,
    required String currentTrip,
    required Future<List<ReassignmentTarget>> Function() loadTargets,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => BookingReassignDialog(
        passengerName: passengerName,
        currentTrip: currentTrip,
        loadTargets: loadTargets,
      ),
    );
  }

  @override
  State<BookingReassignDialog> createState() => _BookingReassignDialogState();
}

class _BookingReassignDialogState extends State<BookingReassignDialog> {
  late Future<List<ReassignmentTarget>> _targets = widget.loadTargets();
  String? _selectedTripId;

  void _retry() => setState(() => _targets = widget.loadTargets());

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('نقل الحجز إلى رحلة أخرى'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.passengerName} — حالياً على ${widget.currentTrip}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.medium),
            Flexible(
              child: FutureBuilder<List<ReassignmentTarget>>(
                future: _targets,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.large),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return _DialogMessage(
                      icon: Icons.error_outline_rounded,
                      color: scheme.error,
                      message: '${snapshot.error}'.replaceFirst(
                        'Exception: ',
                        '',
                      ),
                      onRetry: _retry,
                    );
                  }
                  final targets = snapshot.data ?? const <ReassignmentTarget>[];
                  if (targets.isEmpty) {
                    return _DialogMessage(
                      icon: Icons.event_busy_rounded,
                      color: scheme.onSurfaceVariant,
                      message:
                          'لا توجد رحلات قادمة مفتوحة يمكن نقل الحجز إليها.',
                    );
                  }
                  return _TargetList(
                    targets: targets,
                    selectedTripId: _selectedTripId,
                    onSelected: (id) => setState(() => _selectedTripId = id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _selectedTripId == null
              ? null
              : () => Navigator.pop(context, _selectedTripId),
          child: const Text('نقل الحجز'),
        ),
      ],
    );
  }
}

class _TargetList extends StatelessWidget {
  const _TargetList({
    required this.targets,
    required this.selectedTripId,
    required this.onSelected,
  });

  final List<ReassignmentTarget> targets;
  final String? selectedTripId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: RadioGroup<String>(
        groupValue: selectedTripId,
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: targets.length,
          itemBuilder: (context, index) {
            final target = targets[index];
            return RadioListTile<String>(
              value: target.tripId,
              title: Text(
                target.routeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${target.tripDate} · ${target.departureTime}'),
            );
          },
        ),
      ),
    );
  }
}

class _DialogMessage extends StatelessWidget {
  const _DialogMessage({
    required this.icon,
    required this.color,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final Color color;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: AppSpacing.small),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.small),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    );
  }
}
