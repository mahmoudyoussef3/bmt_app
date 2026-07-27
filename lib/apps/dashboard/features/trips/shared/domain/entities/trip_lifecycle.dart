import 'operation_trip.dart';

/// The trip state machine, mirroring `public.update_trip_status` exactly.
///
/// The database is the authority — since migration `20260727160000` a status can only
/// change from inside that function, and a direct table write raises
/// `trip_status_direct_update_forbidden`. This table exists so the dashboard can *offer*
/// the right actions, never to decide whether one is allowed. Anything it permits, the
/// server re-checks; anything it forbids, the server would refuse anyway.
///
/// It lives in one place because it used to live in two: `_canTransitionTripStatus` in
/// the repository forbade `in_progress → cancelled` while the database allowed it, so
/// the same machine had two definitions that disagreed.
abstract final class TripLifecycle {
  const TripLifecycle._();

  /// Every transition the server accepts, keyed by the state being left.
  static const Map<OperationTripStatus, Set<OperationTripStatus>> _allowed = {
    OperationTripStatus.scheduled: {
      OperationTripStatus.openForBooking,
      OperationTripStatus.cancelled,
    },
    OperationTripStatus.openForBooking: {
      OperationTripStatus.boarding,
      OperationTripStatus.cancelled,
    },
    OperationTripStatus.boarding: {
      OperationTripStatus.inProgress,
      OperationTripStatus.cancelled,
    },
    OperationTripStatus.inProgress: {
      OperationTripStatus.completed,
      OperationTripStatus.cancelled,
    },
    OperationTripStatus.completed: {},
    OperationTripStatus.cancelled: {},
  };

  static bool canTransition(
    OperationTripStatus current,
    OperationTripStatus next,
  ) => _allowed[current]?.contains(next) ?? false;

  static Set<OperationTripStatus> nextStatesFrom(OperationTripStatus current) =>
      _allowed[current] ?? const {};

  static bool isTerminal(OperationTripStatus status) =>
      status == OperationTripStatus.completed ||
      status == OperationTripStatus.cancelled;

  /// The single forward step an operator is offered, or null in a terminal state.
  /// Cancellation is deliberately not part of this — it is an exception, not the
  /// next step, and is offered as its own action.
  static OperationTripStatus? nextStep(OperationTripStatus current) {
    return switch (current) {
      OperationTripStatus.scheduled => OperationTripStatus.openForBooking,
      OperationTripStatus.openForBooking => OperationTripStatus.boarding,
      OperationTripStatus.boarding => OperationTripStatus.inProgress,
      OperationTripStatus.inProgress => OperationTripStatus.completed,
      OperationTripStatus.completed || OperationTripStatus.cancelled => null,
    };
  }

  /// Cancelling a trip that is boarding or already running strands passengers who are
  /// at the stop or aboard, so the server refuses it without a reason
  /// (`cancellation_reason_required`).
  static bool cancellationNeedsReason(OperationTripStatus current) =>
      current == OperationTripStatus.boarding ||
      current == OperationTripStatus.inProgress;

  /// Only an unpublished trip with no bookings can be deleted; everything else must be
  /// cancelled so its riders are told and its seats are released. Enforced by
  /// `trg_enforce_trip_delete_guard`.
  static bool canDelete(OperationTrip trip) =>
      trip.status == OperationTripStatus.scheduled && trip.passengers.isEmpty;
}

/// Why a trip cannot be published yet. Mirrors `public.trip_publish_blocker`.
///
/// Publishing used to be unconditional, which is how a trip with no pricing rows could
/// reach the marketplace and be sold at the package catalogue price instead of the fare
/// the operator set. Showing the operator the blocker *before* they click is the point:
/// the server refuses either way, but only this turns the refusal into an instruction.
enum TripPublishBlocker {
  noDriver('لا يوجد سائق معيّن لهذه الرحلة.'),
  noVehicle('لا توجد مركبة معيّنة لهذه الرحلة.'),
  noSeats('لم يتم تجهيز مقاعد لهذه الرحلة.'),
  noPricing('لم يتم ضبط أسعار الرحلة — لا يمكن بيع مقاعد بدون سعر.'),
  pastDate('تاريخ الرحلة قد فات بالفعل.');

  const TripPublishBlocker(this.message);

  /// Operator-facing Arabic explanation of what to fix.
  final String message;

  /// Maps the server's `trip_not_publishable:<reason>` suffix.
  static TripPublishBlocker? fromCode(String code) => switch (code) {
    'no_driver' => TripPublishBlocker.noDriver,
    'no_vehicle' => TripPublishBlocker.noVehicle,
    'no_seats' => TripPublishBlocker.noSeats,
    'no_pricing' => TripPublishBlocker.noPricing,
    'past_date' => TripPublishBlocker.pastDate,
    _ => null,
  };

  /// The same five checks the server runs, evaluated against a loaded trip so the
  /// dashboard can explain the block without a round trip. The server remains the
  /// authority; this only decides what the button says.
  static TripPublishBlocker? evaluate(OperationTrip trip, {DateTime? now}) {
    if (trip.driverId.trim().isEmpty) return TripPublishBlocker.noDriver;
    if (trip.vehicleId.trim().isEmpty) return TripPublishBlocker.noVehicle;
    if (trip.seats.isEmpty) return TripPublishBlocker.noSeats;

    final date = DateTime.tryParse(trip.date);
    if (date != null) {
      final today = now ?? DateTime.now();
      if (DateTime(
        date.year,
        date.month,
        date.day,
      ).isBefore(DateTime(today.year, today.month, today.day))) {
        return TripPublishBlocker.pastDate;
      }
    }
    // Pricing is not carried on the trip entity, so it is not evaluated here; the
    // server's `no_pricing` block is surfaced through [fromCode] when it fires.
    return null;
  }
}

/// How a stale trip — one whose departure day passed while it was still open — is
/// closed. Mirrors `public.office_close_stale_trip`.
enum StaleTripOutcome {
  /// It ran and nobody closed it. Walks the real machine to `completed`, with rider
  /// notifications suppressed so a week-old departure is not replayed to them.
  operated('operated'),

  /// It never departed. Cancels normally, so riders are told and seats are released.
  cancelled('cancelled');

  const StaleTripOutcome(this.dbValue);

  final String dbValue;
}
