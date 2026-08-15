import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_filter_memory.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/reassignment_target.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/approve_booking_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/bulk_approve_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/bulk_reject_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/get_operation_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/reassign_booking_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/reject_booking_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/request_reupload_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/watch_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/cubit/bookings_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/cubit/bookings_state.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/models/booking_queue_tab.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/models/booking_sort.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/screens/bookings_screen.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/widgets/booking_card.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/widgets/booking_details_panel.dart';

OperationBooking _booking(
  int index, {
  BookingStatus status = BookingStatus.reserved,
  PaymentStatus paymentStatus = PaymentStatus.submitted,
  double amount = 250,
  String route = 'المنصورة - القاهرة',
}) => OperationBooking(
  id: 'b$index',
  bookingNumber: 'BK-${1000 + index}',
  clientId: 'c$index',
  passengerName: 'أحمد محمد عبد الرحمن الشرقاوي $index',
  phone: '0100123456$index',
  route: route,
  tripTime: '08:00',
  date: '2026-07-2${index % 10}',
  seat: 'A$index',
  paymentMethod: BookingPaymentMethod.instaPay,
  status: status,
  paymentStatus: paymentStatus,
  paymentAmount: amount,
  packageName: '',
  createdAt: DateTime(2026, 7, 20).add(Duration(hours: index)),
  tripDetails: BookingTripDetails.empty,
  notes: const [],
  timeline: const [],
  receiptUrl: 'https://example.test/receipt.png',
);

class _FakeRepo implements BookingsRepository {
  _FakeRepo(this.seed);

  final List<OperationBooking> seed;

  @override
  Future<List<OperationBooking>> getBookings() async => seed;

  @override
  Future<OperationBooking> approveBooking(String id, String? note) async =>
      seed.firstWhere((b) => b.id == id);

  @override
  Future<OperationBooking> rejectBooking(String id, String reason) async =>
      seed.firstWhere((b) => b.id == id);

  @override
  Future<OperationBooking> requestReupload(String id, String reason) async =>
      seed.firstWhere((b) => b.id == id);

  @override
  Future<List<OperationBooking>> bulkApprove(
    List<String> ids,
    String? n,
  ) async => [for (final id in ids) await approveBooking(id, n)];

  @override
  Future<List<OperationBooking>> bulkReject(List<String> ids, String r) async =>
      [for (final id in ids) await rejectBooking(id, r)];

  @override
  Future<List<ReassignmentTarget>> getReassignmentTargets() async => const [];

  @override
  Future<OperationBooking> reassignBooking(String id, String tripId) async =>
      seed.firstWhere((b) => b.id == id);

  @override
  Stream<List<OperationBooking>> watchBookings() => const Stream.empty();
}

BookingsCubit _cubit(List<OperationBooking> seed) => BookingsCubit(
  getBookings: GetOperationBookingsUseCase(_FakeRepo(seed)),
  approveBooking: ApproveBookingUseCase(_FakeRepo(seed)),
  rejectBooking: RejectBookingUseCase(_FakeRepo(seed)),
  requestReupload: RequestReuploadUseCase(_FakeRepo(seed)),
  bulkApprove: BulkApproveBookingsUseCase(_FakeRepo(seed)),
  bulkReject: BulkRejectBookingsUseCase(_FakeRepo(seed)),
  watchBookings: WatchBookingsUseCase(_FakeRepo(seed)),
  reassignBooking: ReassignBookingUseCase(_FakeRepo(seed)),
  getReassignmentTargets: GetReassignmentTargetsUseCase(_FakeRepo(seed)),
);

Future<BookingsCubit> _pumpScreen(
  WidgetTester tester,
  List<OperationBooking> seed, {
  required double width,
  double height = 1400,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = _cubit(seed);
  await cubit.load();

  await tester.pumpWidget(
    MaterialApp(
      theme: DashboardAppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const BookingsScreen(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  addTearDown(cubit.close);
  return cubit;
}

void main() {
  // Filters are remembered per session in a process-wide store, so one test's
  // search term would otherwise narrow the next test's board to nothing —
  // which is precisely the behaviour operators want and tests must not inherit.
  setUp(DashboardFilterMemory.instance.clear);
  tearDown(DashboardFilterMemory.instance.clear);

  group('Queue tabs', () {
    test('the board opens on the review queue, not on a status', () async {
      final cubit = _cubit([
        _booking(1),
        _booking(2, paymentStatus: PaymentStatus.approved),
      ]);
      await cubit.load();

      final state = cubit.state as BookingsLoaded;
      expect(state.activeTab, BookingQueueTab.needsReview);
      // Only the awaiting-review booking is on the board, so the landing view is
      // the operator's actual work list.
      expect(state.filteredBookings.map((b) => b.id), ['b1']);
      await cubit.close();
    });

    test('needsReview spans statuses that a status tab would split', () async {
      final cubit = _cubit([
        _booking(1, status: BookingStatus.draft),
        _booking(2, status: BookingStatus.reserved),
        _booking(3, status: BookingStatus.confirmed),
        _booking(4, paymentStatus: PaymentStatus.approved),
      ]);
      await cubit.load();

      final state = cubit.state as BookingsLoaded;
      expect(state.countForTab(BookingQueueTab.needsReview), 3);
      expect(state.countForTab(BookingQueueTab.all), 4);
      await cubit.close();
    });
  });

  group('Sorting and pagination', () {
    test(
      'a page never exceeds the page size and clamps when it shrinks',
      () async {
        final cubit = _cubit([for (var i = 0; i < 20; i++) _booking(i)]);
        await cubit.load();

        expect((cubit.state as BookingsLoaded).pageBookings.length, 12);
        expect((cubit.state as BookingsLoaded).pageCount, 2);

        cubit.goToPage(1);
        expect((cubit.state as BookingsLoaded).pageBookings.length, 8);

        // Filtering down to a single page while parked on page 2 must not leave
        // the operator staring at an empty board.
        cubit.updateFilters(
          (cubit.state as BookingsLoaded).filters.copyWith(search: 'BK-1000'),
        );
        final filtered = cubit.state as BookingsLoaded;
        expect(filtered.currentPage, 0);
        expect(filtered.pageBookings, isNotEmpty);
        await cubit.close();
      },
    );

    test('sorting by the active field flips direction', () async {
      final cubit = _cubit([
        _booking(1, amount: 100),
        _booking(2, amount: 900),
        _booking(3, amount: 500),
      ]);
      await cubit.load();

      cubit.sortBy(BookingSortField.amount);
      expect(
        (cubit.state as BookingsLoaded).sortedBookings
            .map((b) => b.paymentAmount)
            .toList(),
        [900.0, 500.0, 100.0],
      );

      cubit.sortBy(BookingSortField.amount);
      expect(
        (cubit.state as BookingsLoaded).sortedBookings
            .map((b) => b.paymentAmount)
            .toList(),
        [100.0, 500.0, 900.0],
      );
      await cubit.close();
    });
  });

  group('Selection', () {
    test('select-all takes only the reviewable rows on the page', () async {
      final cubit = _cubit([
        _booking(1),
        _booking(2),
        _booking(3, paymentStatus: PaymentStatus.approved),
        // Submitted receipt, but the seat was released: `approve_payment`
        // refuses anything that is not `reserved`, so this is not selectable
        // either even though its payment is "awaiting review".
        _booking(4, status: BookingStatus.cancelled),
      ]);
      await cubit.load();
      cubit.switchTab(BookingQueueTab.all);

      cubit.toggleSelectAllOnPage();
      final state = cubit.state as BookingsLoaded;
      // b3 is already approved: a bulk approve would fail on it server-side, so
      // it is never selectable in the first place.
      expect(state.selectedIds, {'b1', 'b2'});
      expect(state.allPageSelected, isTrue);

      cubit.toggleSelectAllOnPage();
      expect((cubit.state as BookingsLoaded).selectedIds, isEmpty);
      await cubit.close();
    });

    testWidgets('a released seat offers no decision, and says why', (
      tester,
    ) async {
      await _pumpScreen(tester, [
        _booking(1, status: BookingStatus.cancelled),
      ], width: 760);

      // It still belongs on the review queue — the payment is genuinely
      // unresolved — but the three controls the server would refuse are gone,
      // replaced by the reason.
      expect(find.byType(BookingCard), findsOneWidget);
      expect(find.text('قبول'), findsNothing);
      expect(find.text('رفض'), findsNothing);
      expect(find.text('إعادة رفع'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.textContaining('الحجز ملغى'), findsOneWidget);
    });

    testWidgets('a reviewable card keeps both decisions', (tester) async {
      await _pumpScreen(tester, [_booking(1)], width: 760);

      expect(find.text('قبول'), findsOneWidget);
      expect(find.text('رفض'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });
  });

  group('Filters', () {
    test('clearFilters resets every axis and returns to page one', () async {
      final cubit = _cubit([for (var i = 0; i < 20; i++) _booking(i)]);
      await cubit.load();

      cubit.updateFilters(
        (cubit.state as BookingsLoaded).filters.copyWith(
          search: 'nothing-matches',
          route: 'X',
          paymentStatus: PaymentStatus.rejected,
        ),
      );
      expect((cubit.state as BookingsLoaded).resultCount, 0);
      expect((cubit.state as BookingsLoaded).filters.activeCount, 3);

      cubit.clearFilters();
      final state = cubit.state as BookingsLoaded;
      expect(state.filters.isActive, isFalse);
      expect(state.currentPage, 0);
      expect(state.resultCount, 20);
      await cubit.close();
    });

    test('availableRoutes lists each route in the data once', () async {
      final cubit = _cubit([
        _booking(1, route: 'المنصورة - القاهرة'),
        _booking(2, route: 'المنصورة - القاهرة'),
        _booking(3, route: 'طنطا - الإسكندرية'),
      ]);
      await cubit.load();

      expect((cubit.state as BookingsLoaded).availableRoutes, [
        'المنصورة - القاهرة',
        'طنطا - الإسكندرية',
      ]);
      await cubit.close();
    });
  });

  group('Layout', () {
    // The board carries long Arabic names, routes and status pills side by side;
    // these are the widths and scales where that combination breaks.
    for (final width in <double>[420, 760, 1100, 1500]) {
      for (final scale in <double>[1.0, 1.3]) {
        testWidgets('screen never overflows @ ${width}px ${scale}x', (
          tester,
        ) async {
          await _pumpScreen(
            tester,
            [for (var i = 0; i < 14; i++) _booking(i)],
            width: width,
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('narrow layouts render cards, wide layouts render the table', (
      tester,
    ) async {
      await _pumpScreen(tester, [
        for (var i = 0; i < 4; i++) _booking(i),
      ], width: 760);
      expect(find.byType(BookingCard), findsWidgets);

      await _pumpScreen(tester, [
        for (var i = 0; i < 4; i++) _booking(i),
      ], width: 1500);
      expect(find.byType(BookingCard), findsNothing);
      expect(find.byType(OpsDataTable), findsOneWidget);
    });

    // The inspector is the narrowest surface on the screen and changes shape
    // twice: a clipped side panel on desktop, a full-height sheet below that.
    for (final width in <double>[420, 900, 1500]) {
      testWidgets('the open inspector never overflows @ ${width}px', (
        tester,
      ) async {
        final cubit = await _pumpScreen(tester, [
          for (var i = 0; i < 6; i++) _booking(i),
        ], width: width);
        cubit.openBooking(_booking(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull);
        expect(find.byType(BookingDetailsPanel), findsOneWidget);
      });
    }

    testWidgets(
      'an empty review queue says so instead of showing a blank list',
      (tester) async {
        await _pumpScreen(tester, [
          _booking(1, paymentStatus: PaymentStatus.approved),
        ], width: 1100);

        expect(find.text('لا توجد مدفوعات بانتظار المراجعة'), findsOneWidget);
      },
    );
  });
}
