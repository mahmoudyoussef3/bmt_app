import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_summary_cards.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';

/// Widths the dashboard is actually used at: a narrow drawer-mode window, a
/// tablet split, and a wide desktop workspace.
const _widths = <double>[360, 720, 1024, 1440];

/// Renders [child] at [width] inside the real dashboard theme and RTL, and
/// fails if layout overflowed.
///
/// An overflowing `Row`/`Column` throws a `FlutterError` during paint in debug
/// builds, which the test binding captures — so `takeException()` being null is
/// a genuine assertion that nothing clipped, not a proxy for it.
Future<void> _expectNoOverflow(
  WidgetTester tester,
  Widget child, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: DashboardAppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(
    tester.takeException(),
    isNull,
    reason: 'layout overflowed at ${width}px',
  );
}

void main() {
  group('dashboard design system lays out without overflow', () {
    for (final width in _widths) {
      testWidgets('module header with long title and actions @ $width', (
        tester,
      ) async {
        await _expectNoOverflow(
          tester,
          DashboardModuleHeader(
            icon: Icons.local_shipping_rounded,
            title: 'إدارة الأسطول والسائقين والمركبات والتعيينات',
            subtitle:
                'تحكم في السائقين والمركبات والتعيينات والوثائق من مكان واحد '
                'مع متابعة كاملة لحالة كل عنصر.',
            actions: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تحديث'),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة سائق جديد'),
              ),
            ],
          ),
          width: width,
        );
      });

      testWidgets('KPI grid with long labels @ $width', (tester) async {
        await _expectNoOverflow(
          tester,
          const DashboardKpiGrid(
            children: [
              DashboardKpiCard(
                label: 'إجمالي السائقين المسجلين في المكتب',
                detail: 'نشط وموقوف ومؤرشف',
                value: '1٬284',
                icon: Icons.badge_rounded,
              ),
              DashboardKpiCard(
                label: 'وثائق للمراجعة',
                detail: 'منتهية أو تقارب الانتهاء',
                value: '37',
                icon: Icons.fact_check_rounded,
              ),
              DashboardKpiCard(
                label: 'تعيينات نشطة',
                value: '96',
                icon: Icons.link_rounded,
              ),
              DashboardKpiCard(
                label: 'إجمالي المركبات',
                value: '412',
                icon: Icons.directions_bus_rounded,
              ),
            ],
          ),
          width: width,
        );
      });

      testWidgets('fleet summary cards @ $width', (tester) async {
        await _expectNoOverflow(
          tester,
          const FleetSummaryCards(
            summary: FleetSummary(
              driversCount: 1284,
              vehiclesCount: 412,
              activeAssignmentsCount: 96,
              documentsNeedFollowUpCount: 37,
            ),
          ),
          width: width,
        );
      });

      testWidgets('panel with trailing action @ $width', (tester) async {
        await _expectNoOverflow(
          tester,
          DashboardPanel(
            icon: Icons.insights_rounded,
            title: 'توزيع حالات الرحلات على مدار الشهر',
            subtitle: 'كل الرحلات حسب الحالة التشغيلية الحالية',
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz_rounded),
            ),
            child: const SizedBox(height: 80),
          ),
          width: width,
        );
      });

      testWidgets('collapsible section with long title and actions @ $width', (
        tester,
      ) async {
        await _expectNoOverflow(
          tester,
          DashboardCollapsibleSection(
            icon: Icons.insights_rounded,
            title: 'توزيع حالات الرحلات على مدار الشهر الحالي والشهر السابق',
            subtitle:
                'كل الرحلات حسب الحالة التشغيلية الحالية، مع مقارنة بالفترة '
                'السابقة ونسب الإشغال.',
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
            child: const SizedBox(height: 80),
          ),
          width: width,
        );
      });

      testWidgets('collapsed section summary wraps @ $width', (tester) async {
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
                'محفظة إلكترونية',
                'بانتظار المراجعة',
              ],
            ),
            child: SizedBox(height: 80),
          ),
          width: width,
        );
      });
    }
  });
}
