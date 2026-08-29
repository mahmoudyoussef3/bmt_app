/// Visual QA harness for the rebuilt support queue.
///
/// Not a behaviour test and deliberately not an assertion — run it with
/// `--update-goldens` and *look* at the PNGs it writes to `_captures/`:
///
///     flutter test test/apps/dashboard/features/tickets/tickets_visual_capture.dart --update-goldens
///
/// What it is for: the queue moved from a raw Material `DataTable` to
/// `OpsDataTable`, and the things that change — column rhythm, the SLA badge
/// against the breached-row tint, the Arabic status chips, the empty state —
/// are all judged by eye, not by `expect`.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/assign_agent_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/close_ticket_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/get_ticket_attachments_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/get_tickets_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/mark_customer_contacted_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/save_internal_note_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/update_ticket_status_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/presentation/cubit/tickets_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/presentation/cubit/tickets_state.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/presentation/widgets/tickets_board.dart';

const _captureFont = 'CaptureArabic';

SupportTicket _t({
  required String number,
  required String client,
  required String title,
  required String category,
  required TicketPriority priority,
  required TicketStatus status,
  DateTime? slaDueAt,
  bool slaBreached = false,
  String? agent,
}) {
  final created = DateTime(2026, 8, 12, 9, 30);
  return SupportTicket(
    id: 'id-$number',
    ticketNumber: number,
    clientId: 'c-$number',
    clientName: client,
    clientPhone: '01000000000',
    category: category,
    title: title,
    description: 'وصف الشكوى',
    priority: priority,
    status: status,
    assignedAgentName: agent,
    createdAt: created,
    updatedAt: created,
    slaDueAt: slaDueAt,
    slaBreached: slaBreached,
  );
}

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(_captureFont)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  });

  testWidgets('a working queue — mixed status, priority and SLA', (
    tester,
  ) async {
    final now = DateTime.now();
    await _capture(
      tester,
      'tickets_1_queue_dark',
      state: TicketsLoaded(
        tickets: [
          _t(
            number: 'TCK-2026-0007',
            client: 'محمد عبد الرحمن',
            title: 'تأخر الرحلة أكثر من ساعة دون إشعار',
            category: 'تأخير الرحلات',
            priority: TicketPriority.urgent,
            status: TicketStatus.submitted,
            slaDueAt: now.subtract(const Duration(hours: 3)),
            slaBreached: true,
          ),
          _t(
            number: 'TCK-2026-0006',
            client: 'سارة إبراهيم',
            title: 'لم يتم استرداد قيمة التذكرة الملغاة',
            category: 'المدفوعات',
            priority: TicketPriority.high,
            status: TicketStatus.underReview,
            slaDueAt: now.add(const Duration(minutes: 55)),
            agent: 'خدمة العملاء',
          ),
          _t(
            number: 'TCK-2026-0005',
            client: 'أحمد فتحي',
            title: 'مقعد محجوز لشخص آخر',
            category: 'الحجوزات',
            priority: TicketPriority.medium,
            status: TicketStatus.contacted,
            slaDueAt: now.add(const Duration(hours: 9)),
            agent: 'خدمة العملاء',
          ),
          _t(
            number: 'TCK-2026-0004',
            client: 'منى عبد الله',
            title: 'سائق غير ملتزم بنقطة التحميل',
            category: 'جودة الخدمة',
            priority: TicketPriority.low,
            status: TicketStatus.resolved,
          ),
        ],
        agents: const [],
      ),
      width: 1480,
      height: 560,
    );
  });

  testWidgets('nothing has ever arrived — the empty state says where from', (
    tester,
  ) async {
    await _capture(
      tester,
      'tickets_2_empty_dark',
      state: const TicketsLoaded(tickets: [], agents: []),
      width: 1480,
      height: 420,
    );
  });

  testWidgets('filtered to nothing — the way back out is on screen', (
    tester,
  ) async {
    await _capture(
      tester,
      'tickets_3_filtered_empty_dark',
      state: TicketsLoaded(
        tickets: [
          _t(
            number: 'TCK-2026-0004',
            client: 'منى عبد الله',
            title: 'سائق غير ملتزم بنقطة التحميل',
            category: 'جودة الخدمة',
            priority: TicketPriority.low,
            status: TicketStatus.resolved,
          ),
        ],
        agents: const [],
        searchQuery: 'اسم لا يوجد',
      ),
      width: 1480,
      height: 460,
    );
  });
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required TicketsLoaded state,
  required double width,
  required double height,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = _cubit();
  addTearDown(cubit.close);
  cubit.emit(state);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _dashboardDarkWithHostFont(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: BlocProvider.value(
                value: cubit,
                child: SingleChildScrollView(child: TicketsBoard(state: state)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

/// See the note in `live_ops_visual_capture.dart`: the real dashboard themes
/// build their text theme through google_fonts, which fetches over the network
/// the test binding blocks and throws after the test completes.
ThemeData _dashboardDarkWithHostFont() {
  final scheme = darkColorSchemeFromPalette();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: AppDarkColors.background,
    canvasColor: AppDarkColors.background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: AppDarkColors.shadow,
    extensions: [AppSurfaceStyle.flat(scheme)],
  );
}

class _UnusedRepository implements TicketsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('the capture harness never hits the repository');
}

TicketsCubit _cubit() {
  final repository = _UnusedRepository();
  return TicketsCubit(
    getTickets: GetTicketsUseCase(repository),
    updateTicketStatus: UpdateTicketStatusUseCase(repository),
    saveInternalNote: SaveInternalNoteUseCase(repository),
    markCustomerContacted: MarkCustomerContactedUseCase(repository),
    closeTicket: CloseTicketUseCase(repository),
    getTicketAttachments: GetTicketAttachmentsUseCase(repository),
    assignAgent: AssignAgentUseCase(repository),
    getAgents: GetAgentsUseCase(repository),
  );
}
