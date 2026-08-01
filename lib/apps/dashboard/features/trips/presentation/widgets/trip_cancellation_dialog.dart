import 'package:flutter/material.dart';

import '../../shared/domain/entities/operation_trip.dart';

/// Asks for a cancellation reason, and shows the operator what cancelling will do.
///
/// Cancelling a trip is not a status change with a tidy undo: it cancels every open
/// booking, releases every seat, cancels every passenger, and notifies every rider —
/// including the ones whose payment is still under review. Riders who already paid stay
/// owed a refund. None of that was visible anywhere before the operator committed to it.
///
/// Returns the reason, or null if the operator backed out.
Future<String?> showTripCancellationDialog(
  BuildContext context, {
  required OperationTrip trip,
  required bool reasonRequired,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _TripCancellationDialog(trip: trip, reasonRequired: reasonRequired),
  );
}

class _TripCancellationDialog extends StatefulWidget {
  const _TripCancellationDialog({
    required this.trip,
    required this.reasonRequired,
  });

  final OperationTrip trip;
  final bool reasonRequired;

  @override
  State<_TripCancellationDialog> createState() =>
      _TripCancellationDialogState();
}

class _TripCancellationDialogState extends State<_TripCancellationDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _activePassengers => widget.trip.passengers
      .where((p) => p.status != 'cancelled' && p.status != 'no_show')
      .length;

  int get _heldSeats => widget.trip.bookedSeats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('إلغاء الرحلة؟'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رحلة ${widget.trip.route} — ${widget.trip.date} ${widget.trip.departure}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (_activePassengers > 0 || _heldSeats > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withAlpha(70),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'سيتم إلغاء $_activePassengers راكب وتحرير $_heldSeats مقعد، '
                  'وإشعار جميع الركاب. الحجوزات المدفوعة ستحتاج إلى استرداد يدوي '
                  'من شاشة المدفوعات.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: widget.reasonRequired
                    ? 'سبب الإلغاء (مطلوب)'
                    : 'سبب الإلغاء',
                hintText: 'مثال: عطل بالمركبة',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (!widget.reasonRequired) return null;
                return (value ?? '').trim().isEmpty
                    ? 'سبب الإلغاء مطلوب لرحلة بدأ صعود ركابها أو انطلقت.'
                    : null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('تراجع'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final reason = _controller.text.trim();
            Navigator.pop(
              context,
              reason.isEmpty ? 'تم الإلغاء من لوحة التحكم' : reason,
            );
          },
          child: const Text('تأكيد الإلغاء'),
        ),
      ],
    );
  }
}
