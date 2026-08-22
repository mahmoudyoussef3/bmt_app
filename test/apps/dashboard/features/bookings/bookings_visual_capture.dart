/// Visual QA harness for the bookings review queue's **card** layout — the
/// surface an operator works the payment backlog on below 1040px, and the one
/// that cannot be judged from code: two state machines, a fare, a corridor name
/// that is often half-latin, and up to four controls, all inside ~320px.
///
/// Not a test of behaviour and deliberately not part of the suite's assertions:
/// run it with `--update-goldens` and look at the PNGs it writes to
/// `_captures/`.
///
///     flutter test test/apps/dashboard/features/bookings/bookings_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_light_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';
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
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/cubit/bookings_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/cubit/bookings_state.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/models/booking_queue_tab.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/screens/bookings_screen.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/widgets/bookings_queue_board.dart';

const _captureFont = 'CaptureArabic';

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(_captureFont)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  });

  testWidgets('the card queue, dark', (tester) async {
    await _capture(tester, 'bookings_1_cards_dark', dark: true, width: 1000);
  });

  testWidgets('the card queue, light', (tester) async {
    await _capture(tester, 'bookings_2_cards_light', dark: false, width: 1000);
  });

  testWidgets('one column', (tester) async {
    await _capture(
      tester,
      'bookings_3_cards_narrow_dark',
      dark: true,
      width: 560,
    );
  });

  testWidgets('the whole module', (tester) async {
    await _capture(
      tester,
      'bookings_4_screen_dark',
      dark: true,
      width: 1000,
      height: 1500,
      wholeScreen: true,
    );
  });
}

/// The four rows worth looking at together: the ordinary review, one with no
/// receipt to review, the cancelled booking whose payment was still submitted
/// (the row that used to offer three buttons the server refuses), and a settled
/// one that should sit quietly.
List<OperationBooking> _seed() => [
  _booking(
    1,
    name: 'محمود يوسف',
    route:
        'Al Marj, Cairo, Egypt → American University in Cairo (AUC) - New Cairo',
    amount: 85,
    seat: 'B1',
  ),
  _booking(
    2,
    name: 'سارة عبد الرحمن',
    route: 'المنصورة - القاهرة',
    amount: 280,
    seat: '13',
    receipt: false,
  ),
  _booking(
    3,
    name: 'أحمد الشرقاوي',
    route: 'American University in Cairo (AUC) - New Cairo → Banha',
    amount: 85,
    seat: 'C1',
    status: BookingStatus.cancelled,
  ),
  _booking(
    4,
    name: 'ندى مصطفى',
    route: 'طنطا - الإسكندرية',
    amount: 150,
    seat: 'A4',
    status: BookingStatus.confirmed,
    paymentStatus: PaymentStatus.approved,
  ),
];

OperationBooking _booking(
  int index, {
  required String name,
  required String route,
  required double amount,
  required String seat,
  BookingStatus status = BookingStatus.reserved,
  PaymentStatus paymentStatus = PaymentStatus.submitted,
  bool receipt = true,
}) => OperationBooking(
  id: 'b$index',
  bookingNumber: 'BK-96A2F45$index',
  clientId: 'c$index',
  passengerName: name,
  phone: '+20106712080$index',
  route: route,
  tripTime: '01:00',
  date: '2026-07-04',
  seat: seat,
  paymentMethod: BookingPaymentMethod.instaPay,
  status: status,
  paymentStatus: paymentStatus,
  paymentAmount: amount,
  packageName: '',
  createdAt: DateTime.now().subtract(Duration(hours: index * 3)),
  tripDetails: BookingTripDetails.empty,
  notes: const [],
  timeline: const [],
  receiptUrl: receipt ? 'https://example.test/receipt.png' : null,
);

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required bool dark,
  required double width,
  double height = 1100,
  bool wholeScreen = false,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = _cubit(_seed());
  addTearDown(cubit.close);
  await cubit.load();
  cubit.switchTab(BookingQueueTab.all);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _themeWithHostFont(dark: dark),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: wholeScreen
                  ? const BookingsScreen()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: BookingsQueueBoard(
                        state: cubit.state as BookingsLoaded,
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
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
  addNote: AddBookingNoteUseCase(_FakeRepo(seed)),
);

/// See the note in the Live Ops harness: the real themes build their text theme
/// through google_fonts, which the test binding's blocked network turns into a
/// post-test throw. The palette is the real one; only the glyphs differ.
ThemeData _themeWithHostFont({required bool dark}) {
  final scheme = dark
      ? darkColorSchemeFromPalette()
      : lightColorSchemeFromPalette();
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: dark
        ? AppDarkColors.background
        : AppLightColors.background,
    canvasColor: dark ? AppDarkColors.background : AppLightColors.background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: dark ? AppDarkColors.shadow : AppLightColors.shadow,
    extensions: [
      dark ? AppSurfaceStyle.flat(scheme) : AppSurfaceStyle.dashboardLight(scheme),
    ],
  );
}

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
  Future<OperationBooking> addNote(String id, String note) async =>
      seed.firstWhere((b) => b.id == id);

  @override
  Stream<List<OperationBooking>> watchBookings() => const Stream.empty();
}
