import 'package:flutter_test/flutter_test.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/reassignment_target.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/add_booking_note_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/approve_booking_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/bulk_approve_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/bulk_reject_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/get_operation_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/reassign_booking_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/reject_booking_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/request_reupload_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/watch_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_filter_memory.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/models/booking_filters.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/models/booking_queue_tab.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/cubit/bookings_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/cubit/bookings_state.dart';

OperationBooking _booking(
  String id, {
  String clientId = 'c-1',
  BookingStatus status = BookingStatus.reserved,
  PaymentStatus paymentStatus = PaymentStatus.submitted,
}) {
  return OperationBooking(
    id: id,
    bookingNumber: 'BK-$id',
    clientId: clientId,
    passengerName: 'Passenger $id',
    phone: '0100',
    route: 'A - B',
    tripTime: '08:00',
    date: '2026-07-10',
    seat: 'A1',
    paymentMethod: BookingPaymentMethod.instaPay,
    status: status,
    paymentStatus: paymentStatus,
    paymentAmount: 100,
    packageName: 'pkg',
    createdAt: DateTime(2026, 7, 6),
    tripDetails: BookingTripDetails.empty,
    notes: const [],
    timeline: const [],
  );
}

class _FakeRepo implements BookingsRepository {
  _FakeRepo(this.seed);
  List<OperationBooking> seed;

  @override
  Future<List<OperationBooking>> getBookings() async => seed;

  @override
  Future<OperationBooking> approveBooking(String id, String? note) async =>
      _booking(
        id,
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.approved,
      );

  @override
  Future<OperationBooking> rejectBooking(String id, String reason) async =>
      _booking(
        id,
        status: BookingStatus.cancelled,
        paymentStatus: PaymentStatus.rejected,
      );

  @override
  Future<OperationBooking> requestReupload(String id, String reason) async =>
      _booking(id, paymentStatus: PaymentStatus.underReview);

  @override
  Future<List<OperationBooking>> bulkApprove(
    List<String> ids,
    String? n,
  ) async => [for (final id in ids) await approveBooking(id, n)];

  @override
  Future<List<OperationBooking>> bulkReject(List<String> ids, String r) async =>
      [for (final id in ids) await rejectBooking(id, r)];

  /// Set to make the next reassignment fail, so tests can assert the workspace
  /// survives a failed action.
  Object? reassignError;

  List<ReassignmentTarget> targets = const [
    ReassignmentTarget(
      tripId: 't-9',
      routeName: 'A - B',
      tripDate: '2026-07-11',
      departureTime: '09:00',
    ),
  ];

  @override
  Future<List<ReassignmentTarget>> getReassignmentTargets() async => targets;

  @override
  Future<OperationBooking> reassignBooking(String id, String newTripId) async {
    if (reassignError != null) throw Exception(reassignError);
    return _booking(id, status: BookingStatus.confirmed);
  }

  /// Records what it was asked to save so a test can assert the note reached
  /// the repository, not merely that the call did not throw.
  final List<({String id, String note})> notesAdded = [];

  @override
  Future<OperationBooking> addNote(String id, String note) async {
    notesAdded.add((id: id, note: note));
    return _booking(id);
  }

  @override
  Stream<List<OperationBooking>> watchBookings() => const Stream.empty();
}

BookingsCubit _cubit(_FakeRepo repo) {
  return BookingsCubit(
    getBookings: GetOperationBookingsUseCase(repo),
    approveBooking: ApproveBookingUseCase(repo),
    rejectBooking: RejectBookingUseCase(repo),
    requestReupload: RequestReuploadUseCase(repo),
    bulkApprove: BulkApproveBookingsUseCase(repo),
    bulkReject: BulkRejectBookingsUseCase(repo),
    watchBookings: WatchBookingsUseCase(repo),
    reassignBooking: ReassignBookingUseCase(repo),
    getReassignmentTargets: GetReassignmentTargetsUseCase(repo),
    addNote: AddBookingNoteUseCase(repo),
  );
}

void main() {
  group('BookingsCubit', () {
    // مراجعة المدفوعات was folded into this board: the `/payment-verification`
    // route now loads it with a preset instead of building a second module over
    // the same table. These pin the two halves of that — the preset lands on the
    // review queue and ignores remembered filters, and the note action the old
    // queue owned still exists here.
    group('the folded payment-review queue', () {
      setUp(DashboardFilterMemory.instance.clear);
      tearDown(DashboardFilterMemory.instance.clear);

      test('a preset opens the review tab and ignores remembered filters', () async {
        DashboardFilterMemory.instance.write(
          DashboardFilterIds.bookings,
          const BookingFilters(search: 'أحمد'),
        );

        final cubit = _cubit(_FakeRepo([_booking('1')]));
        await cubit.load(presetTab: BookingQueueTab.needsReview);

        final state = cubit.state as BookingsLoaded;
        expect(state.activeTab, BookingQueueTab.needsReview);
        expect(state.filters.search, isEmpty);
        await cubit.close();
      });

      test('without a preset the remembered filters are restored', () async {
        DashboardFilterMemory.instance.write(
          DashboardFilterIds.bookings,
          const BookingFilters(search: 'أحمد'),
        );

        final cubit = _cubit(_FakeRepo([_booking('1')]));
        await cubit.load();

        expect((cubit.state as BookingsLoaded).filters.search, 'أحمد');
        await cubit.close();
      });

      test('a note reaches the repository trimmed', () async {
        final repo = _FakeRepo([_booking('1')]);
        final cubit = _cubit(repo);
        await cubit.load();

        await cubit.addNote('1', '  اتصلت بالراكب  ');

        expect(repo.notesAdded, [(id: '1', note: 'اتصلت بالراكب')]);
        await cubit.close();
      });

      test('an empty note is refused without touching the repository', () async {
        final repo = _FakeRepo([_booking('1')]);
        final cubit = _cubit(repo);
        await cubit.load();

        await cubit.addNote('1', '   ');

        expect(repo.notesAdded, isEmpty);
        // Refused as an action failure, so the queue, its filters and the open
        // booking all survive it.
        expect((cubit.state as BookingsLoaded).actionError, isNotNull);
        await cubit.close();
      });
    });

    test('load emits BookingsLoaded with the fetched bookings', () async {
      final cubit = _cubit(_FakeRepo([_booking('1'), _booking('2')]));
      await cubit.load();

      final state = cubit.state;
      expect(state, isA<BookingsLoaded>());
      expect((state as BookingsLoaded).bookings.length, 2);
      await cubit.close();
    });

    test('approveBooking replaces the row with the approved result', () async {
      final cubit = _cubit(_FakeRepo([_booking('1')]));
      await cubit.load();

      await cubit.approveBooking('1', null);
      final state = cubit.state as BookingsLoaded;
      expect(state.bookings.single.status, BookingStatus.confirmed);
      expect(state.bookings.single.paymentStatus, PaymentStatus.approved);
      await cubit.close();
    });

    test(
      'bulkApprove approves every selected booking and clears selection',
      () async {
        final cubit = _cubit(_FakeRepo([_booking('1'), _booking('2')]));
        await cubit.load();

        cubit.toggleSelection('1');
        cubit.toggleSelection('2');
        await cubit.bulkApprove(null);

        final state = cubit.state as BookingsLoaded;
        expect(state.selectedIds, isEmpty);
        expect(
          state.bookings.every((b) => b.status == BookingStatus.confirmed),
          isTrue,
        );
        await cubit.close();
      },
    );

    test('bookingsForClient counts every booking a client has made', () async {
      final cubit = _cubit(
        _FakeRepo([
          _booking('1', clientId: 'c-1'),
          _booking('2', clientId: 'c-1'),
          _booking('3', clientId: 'c-2'),
        ]),
      );
      await cubit.load();

      final state = cubit.state as BookingsLoaded;
      expect(state.bookingsForClient('c-1'), 2);
      expect(state.bookingsForClient('c-2'), 1);
      await cubit.close();
    });
    test('reassignBooking moves the booking onto the chosen trip', () async {
      final cubit = _cubit(_FakeRepo([_booking('1')]));
      await cubit.load();

      await cubit.reassignBooking('1', 't-9');

      final state = cubit.state as BookingsLoaded;
      expect(state.bookings.single.status, BookingStatus.confirmed);
      expect(state.actionError, isNull);
      await cubit.close();
    });

    test('loadReassignmentTargets returns only eligible trips', () async {
      final cubit = _cubit(_FakeRepo([_booking('1')]));
      await cubit.load();

      final targets = await cubit.loadReassignmentTargets();
      expect(targets.single.tripId, 't-9');
      await cubit.close();
    });

    test(
      'a failed action reports an error without discarding the workspace',
      () async {
        final repo = _FakeRepo([_booking('1'), _booking('2')])
          ..reassignError = 'seat_taken';
        final cubit = _cubit(repo);
        await cubit.load();
        cubit.toggleSelection('1');

        await cubit.reassignBooking('1', 't-9');

        // Still a loaded workspace: the list, the selection and the tab survive,
        // and the failure is surfaced alongside them rather than replacing them.
        final state = cubit.state;
        expect(state, isA<BookingsLoaded>());
        final loaded = state as BookingsLoaded;
        expect(loaded.bookings.length, 2);
        expect(loaded.selectedIds, {'1'});
        expect(loaded.actionError, contains('seat_taken'));
        expect(loaded.isProcessing, isFalse);

        cubit.clearActionError();
        expect((cubit.state as BookingsLoaded).actionError, isNull);
        await cubit.close();
      },
    );

    test('countByStatus tallies every status in one pass', () async {
      final cubit = _cubit(
        _FakeRepo([
          _booking('1'),
          _booking('2'),
          _booking('3', status: BookingStatus.cancelled),
        ]),
      );
      await cubit.load();

      final state = cubit.state as BookingsLoaded;
      expect(state.countByStatus(BookingStatus.reserved), 2);
      expect(state.countByStatus(BookingStatus.cancelled), 1);
      expect(state.countByStatus(BookingStatus.completed), 0);
      await cubit.close();
    });
  });

  group('filters survive the shell rebuilding the module', () {
    // The shell disposes a module on every navigation and calls
    // `dashboardDi<BookingsCubit>()..load()` on return, so "a second cubit
    // over the same repo" is exactly what going to a booking and back does.
    setUp(DashboardFilterMemory.instance.clear);
    tearDown(DashboardFilterMemory.instance.clear);

    test('a filter set before navigating away is restored on return', () async {
      final repo = _FakeRepo([_booking('1')]);
      final before = _cubit(repo);
      await before.load();
      before.updateFilters(const BookingFilters(search: 'محمد'));
      await before.close();

      final after = _cubit(repo);
      await after.load();

      expect((after.state as BookingsLoaded).filters.search, 'محمد');
      await after.close();
    });

    test('clearing filters also survives, rather than reappearing', () async {
      final repo = _FakeRepo([_booking('1')]);
      final before = _cubit(repo);
      await before.load();
      before.updateFilters(const BookingFilters(search: 'محمد'));
      before.clearFilters();
      await before.close();

      final after = _cubit(repo);
      await after.load();

      expect((after.state as BookingsLoaded).filters.isActive, isFalse);
      await after.close();
    });

    test('a restored filter still reports its active count', () async {
      // Persistence is only safe because the bar keeps saying it is filtered.
      final repo = _FakeRepo([_booking('1')]);
      final before = _cubit(repo);
      await before.load();
      before.updateFilters(
        const BookingFilters(search: 'محمد', route: 'القاهرة'),
      );
      await before.close();

      final after = _cubit(repo);
      await after.load();

      expect((after.state as BookingsLoaded).filters.activeCount, 2);
      await after.close();
    });

    test('signing out drops filters for the next operator', () async {
      final repo = _FakeRepo([_booking('1')]);
      final before = _cubit(repo);
      await before.load();
      before.updateFilters(const BookingFilters(search: 'محمد'));
      await before.close();

      // What DashboardAuthCubit._clearSession does.
      DashboardFilterMemory.instance.clear();

      final after = _cubit(repo);
      await after.load();

      expect((after.state as BookingsLoaded).filters.isActive, isFalse);
      await after.close();
    });
  });
}
