import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/master_detail_layout.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';

/// Enlarged text is the most common accessibility setting there is, and this
/// console is Arabic — where the same label is routinely 30–40% wider than its
/// English equivalent before any scaling is applied.
///
/// The existing overflow suite pumps the design system at four widths but only
/// ever at 1.0×, and the one text-scale bug that was caught (the trip wizard's
/// fixed 220px tile) was found by hand. This sweep is the systematic version:
/// every shared primitive, at the narrow end of each breakpoint, at the two
/// enlarged scales Android and iOS actually ship.
///
/// The narrow widths matter more than the wide ones. A component that survives
/// 1.6× at 1440px proves very little; the failure mode is a dense row at 360px
/// or a laptop split pane at 720px, which is where operators on smaller
/// machines live.
const _widths = <double>[360, 720, 1024];
const _textScales = <double>[1.0, 1.3, 1.6];

Future<void> _expectNoOverflow(
  WidgetTester tester,
  Widget child, {
  required double width,
  required double textScale,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: DashboardAppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(
    tester.takeException(),
    isNull,
    reason: 'overflowed at ${width}px @ $textScale× text',
  );
}

/// A realistically dense table: seven columns is what الحجوزات and تذاكر
/// actually render, and the pagination bar underneath carries two live counts.
Widget _densTable() => OpsDataTable(
  columns: const [
    OpsColumn('العميل', flex: 2),
    OpsColumn('المسار', flex: 2),
    OpsColumn('التاريخ'),
    OpsColumn('المقاعد', numeric: true),
    OpsColumn('المبلغ', numeric: true, sortable: true),
    OpsColumn('طريقة الدفع'),
    OpsColumn('الحالة'),
  ],
  rows: const [
    [
      Text('محمد عبد الرحمن السيد'),
      Text('القاهرة — الإسكندرية الصحراوي'),
      Text('٢٠٢٦/٠٨/١٥'),
      Text('٣'),
      Text('٤٥٠ ج.م'),
      Text('محفظة إلكترونية'),
      Text('بانتظار المراجعة'),
    ],
  ],
  total: 248,
  currentPage: 12,
  pageSize: 12,
  onPageChanged: _noop,
);

void _noop(int _) {}

void main() {
  group('shared dashboard primitives survive enlarged Arabic text', () {
    for (final width in _widths) {
      for (final scale in _textScales) {
        final at = '@ ${width.toInt()}px $scale×';

        testWidgets('module header $at', (tester) async {
          await _expectNoOverflow(
            tester,
            DashboardModuleHeader(
              icon: DashboardIcons.refresh,
              title: 'إدارة الأسطول والسائقين والمركبات والتعيينات',
              subtitle:
                  'تحكم في السائقين والمركبات والتعيينات والوثائق من مكان '
                  'واحد مع متابعة كاملة لحالة كل عنصر.',
              actions: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(DashboardIcons.refresh),
                  label: const Text('تحديث'),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(DashboardIcons.add),
                  label: const Text('إضافة سائق جديد'),
                ),
              ],
            ),
            width: width,
            textScale: scale,
          );
        });

        testWidgets('KPI grid $at', (tester) async {
          await _expectNoOverflow(
            tester,
            const DashboardKpiGrid(
              children: [
                DashboardKpiCard(
                  label: 'إجمالي السائقين المسجلين في المكتب',
                  detail: 'نشط وموقوف ومؤرشف',
                  value: '١٬٢٨٤',
                  icon: Icons.badge_rounded,
                ),
                DashboardKpiCard(
                  label: 'وثائق للمراجعة',
                  detail: 'منتهية أو تقارب الانتهاء',
                  value: '٣٧',
                  icon: Icons.fact_check_rounded,
                ),
              ],
            ),
            width: width,
            textScale: scale,
          );
        });

        testWidgets('dense table with pagination $at', (tester) async {
          await _expectNoOverflow(
            tester,
            _densTable(),
            width: width,
            textScale: scale,
          );
        });

        testWidgets('collapsed filter summary $at', (tester) async {
          await _expectNoOverflow(
            tester,
            const DashboardCollapsibleSection(
              icon: Icons.filter_alt_outlined,
              title: 'البحث والتصفية',
              initiallyExpanded: false,
              collapsedSummary: DashboardSectionSummary(
                items: [
                  'بحث: محمد عبد الرحمن السيد',
                  'مسار: القاهرة — الإسكندرية الصحراوي',
                  'تاريخ: ٢٠٢٦-٠٨-٠٧',
                  'بانتظار المراجعة',
                ],
              ),
              child: SizedBox(height: 80),
            ),
            width: width,
            textScale: scale,
          );
        });

        testWidgets('panel with empty state $at', (tester) async {
          await _expectNoOverflow(
            tester,
            DashboardPanel(
              icon: Icons.insights_rounded,
              title: 'توزيع حالات الرحلات على مدار الشهر',
              child: DashboardEmptyState(
                icon: DashboardIcons.trips,
                title: 'لا توجد رحلات اليوم',
                message:
                    'لم تُنشئ أي رحلة لهذا اليوم بعد. أنشئ رحلة لتبدأ '
                    'استقبال الحجوزات عليها.',
                action: FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(DashboardIcons.add),
                  label: const Text('إنشاء رحلة'),
                ),
              ),
            ),
            width: width,
            textScale: scale,
          );
        });

        testWidgets('error state with retry $at', (tester) async {
          await _expectNoOverflow(
            tester,
            const DashboardErrorState(
              message:
                  'تعذّر الوصول إلى الخادم. تحقّق من الاتصال ثم أعد المحاولة.',
              onRetry: _noopVoid,
            ),
            width: width,
            textScale: scale,
          );
        });

        testWidgets('partial data notice $at', (tester) async {
          await _expectNoOverflow(
            tester,
            const DashboardPartialDataNotice(
              sources: ['الإيرادات', 'الحجوزات الأخيرة', 'أعلى المسارات'],
            ),
            width: width,
            textScale: scale,
          );
        });

        testWidgets('master/detail placeholder $at', (tester) async {
          await _expectNoOverflow(
            tester,
            const SizedBox(
              height: 700,
              child: MasterDetailLayout(
                master: SizedBox.shrink(),
                placeholderTitle: 'اختر عميلاً لعرض محفظته',
                placeholderSubtitle:
                    'ستظهر هنا الحركات والرصيد الحالي وطلبات الاسترداد '
                    'الخاصة بالعميل المحدد.',
              ),
            ),
            width: width,
            textScale: scale,
          );
        });
      }
    }
  });
}

void _noopVoid() {}
