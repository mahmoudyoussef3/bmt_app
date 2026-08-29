/// Visual QA harness for محفظة العملاء' three tabs.
///
/// The point of the المالية unification pass is that the three tabs look like
/// one module, and that is a claim you can only settle by putting the three
/// screens next to each other. Not a test of behaviour and deliberately not
/// part of the suite's assertions: run it with `--update-goldens` and look at
/// the PNGs it writes to `_captures/`.
///
///     flutter test test/apps/dashboard/features/wallet/wallet_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_vocabulary.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/presentation/cubit/wallet_state.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';

import 'wallet_test_fixtures.dart';

const _captureFont = 'CaptureArabic';

/// Resolved by walking up from the running test binary until the SDK's font
/// cache appears: `flutter_tester` sits at a different depth per platform, so
/// counting `.parent`s is a guess that breaks on someone else's machine.
File? _findMaterialIcons() {
  const suffix = 'artifacts/material_fonts/MaterialIcons-Regular.otf';
  var dir = File(Platform.resolvedExecutable).parent;
  for (var hop = 0; hop < 8; hop++) {
    final candidate = File('${dir.path}/$suffix');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (file.existsSync()) {
      final loader = FontLoader(_captureFont)
        ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      await loader.load();
    }
    final icons = _findMaterialIcons();
    if (icons != null) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
      await loader.load();
    }
  });

  setUp(DashboardSectionStateStore.instance.clear);

  testWidgets('directory — customers, their balances and the open wallet', (
    tester,
  ) async {
    await _capture(tester, 'wallet_1_directory', _state());
  });

  testWidgets('activity — the office-wide ledger', (tester) async {
    await _capture(
      tester,
      'wallet_2_activity',
      _state(tab: WalletTab.activity),
    );
  });

  testWidgets('refunds — the decision queue', (tester) async {
    await _capture(tester, 'wallet_3_refunds', _state(tab: WalletTab.refunds));
  });

  testWidgets('refunds at a narrow console width', (tester) async {
    await _capture(
      tester,
      'wallet_4_refunds_narrow',
      _state(tab: WalletTab.refunds),
      width: 900,
      height: 1000,
    );
  });
}

WalletLoadedState _state({WalletTab tab = WalletTab.directory}) {
  final now = DateTime.now();
  return WalletLoadedState(
    overview: overviewFixture(),
    directory: WalletDirectoryPage(
      total: 34,
      rows: [
        for (var i = 0; i < 6; i++)
          WalletDirectoryEntry(
            clientId: 'c$i',
            fullName: const [
              'أحمد محمود سيد',
              'منى عبد الرحمن',
              'كريم الشناوي',
              'سارة فتحي',
              'محمد أبو زيد',
              'هالة مصطفى',
            ][i],
            phone: '0100000000$i',
            balance: [250.0, 0.0, 1180.5, 40.0, 0.0, 620.0][i],
            walletStatus: i == 2 ? WalletStatus.frozen : WalletStatus.active,
            entryCount: [12, 0, 41, 3, 0, 18][i],
            pendingRefunds: i == 3 ? 1 : 0,
            lastActivityAt: now.subtract(Duration(hours: i * 7)),
          ),
      ],
    ),
    tab: tab,
    selectedClientId: tab == WalletTab.directory ? 'c0' : null,
    summary: tab == WalletTab.directory ? summaryFixture() : null,
    ledger: WalletLedgerPage(
      total: 128,
      sumCredit: 4310,
      sumDebit: 980,
      rows: [
        for (var i = 0; i < 5; i++)
          entryFixture(clientName: 'أحمد محمود سيد').copyForCapture(
            seq: 40 - i,
            kind: const [
              WalletKind.cashback,
              WalletKind.refund,
              WalletKind.manualDebit,
              WalletKind.manualCredit,
              WalletKind.reversal,
            ][i],
            amount: [120.0, 250.0, -60.0, 300.0, -120.0][i],
            createdAt: now.subtract(Duration(hours: i * 5)),
            reversed: i == 4,
          ),
      ],
    ),
    refundQueue: [
      for (var i = 0; i < 4; i++)
        refundFixture(
          id: 'r$i',
          status: const [
            RefundStatus.pending,
            RefundStatus.pending,
            RefundStatus.approved,
            RefundStatus.settled,
          ][i],
          amount: [120.0, 480.0, 75.0, 220.0][i],
        ),
    ],
  );
}

/// Rebuilds one fixture entry with the fields the capture wants to vary. The
/// entity is immutable and has no `copyWith`, and adding one to production code
/// for a screenshot would be the tail wagging the dog.
extension on WalletTransaction {
  WalletTransaction copyForCapture({
    required int seq,
    required WalletKind kind,
    required double amount,
    required DateTime createdAt,
    required bool reversed,
  }) => WalletTransaction(
    id: '$id-$seq',
    seq: seq,
    kind: kind,
    category: category,
    source: source,
    amount: amount,
    balanceBefore: balanceBefore,
    balanceAfter: balanceBefore + amount,
    status: reversed ? WalletEntryStatus.reversed : WalletEntryStatus.posted,
    reason: reason,
    performedByName: performedByName,
    createdAt: createdAt,
    bookingNumber: bookingNumber,
    clientId: clientId,
    clientName: clientName,
  );
}

Future<void> _capture(
  WidgetTester tester,
  String name,
  WalletLoadedState state, {
  double width = 1440,
  double height = 1100,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

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
            body: BlocProvider<WalletCubit>.value(
              value: _StaticWalletCubit(state),
              child: const WalletScreen(canAdjust: true, canApprove: true),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

/// The real dashboard dark palette and card surfaces, typeset in a host font.
///
/// Neither `DashboardAppTheme.dark()` nor `AppTheme.darkTheme()` can be used
/// here: both build their text theme through google_fonts, which tries to fetch
/// the typeface over the network the test binding blocks and then throws after
/// the test completes.
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

class _StaticWalletCubit extends Cubit<WalletState> implements WalletCubit {
  _StaticWalletCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
