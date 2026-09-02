import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_page_title_block.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_segmented_bar.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/business_health.dart';
import '../../domain/entities/business_overview.dart';
import '../models/overview_window.dart';
import 'overview_kit.dart';

/// Who is signed in, which office, which period, when the figures were taken,
/// and the one action an owner starts from here — **a bare line on the page,
/// not a card**.
///
/// This is [HomeHeaderBanner]'s block, deliberately to the letter. The previous
/// revision opened with a full-bleed gradient hero carrying a display-size
/// money figure and a chart; الرئيسية retired exactly that treatment in the EWT
/// pass, and every other module's [DashboardModuleHeader] made the same trade.
/// Keeping a brand sweep on this one page meant the console's two most-opened
/// screens greeted the same person in two different visual languages, one
/// after the other, all day.
///
/// So the money moved to where Home keeps it — a KPI tile with its own
/// sparkline, and a chart panel of its own — and what is left here is what a
/// title block is for: identity, control, and the facts that are true only
/// right now.
///
/// Under the title sits the **strip**: the period switcher first, because every
/// time-scoped figure below answers to it, then the standing verdict — what is
/// off target and what is waiting for a decision. Home's pulse chips, same
/// shape, same weight.
class BusinessOverviewHeader extends StatelessWidget {
  const BusinessOverviewHeader({
    super.key,
    required this.office,
    required this.overview,
    required this.window,
    required this.onWindowChanged,
    this.onRefresh,
    this.isRefreshing = false,
    this.onCreateTrip,
  });

  final OfficeContext office;
  final BusinessOverview overview;
  final OverviewWindow window;
  final ValueChanged<OverviewWindow> onWindowChanged;
  final VoidCallback? onRefresh;
  final bool isRefreshing;

  /// The one genuine one-click job on this page. It sits on the title line, as
  /// «رحلة جديدة» does on Home — not five screens down in «إجراءات سريعة»,
  /// where it used to be. An action nobody scrolls to is not a shortcut.
  final VoidCallback? onCreateTrip;

  @override
  Widget build(BuildContext context) {
    final officeName = office.officeName.trim().isEmpty
        ? 'مكتبك'
        : office.officeName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashboardPageTitleBlock(
          title: 'نظرة تنفيذية',
          monogramSource: officeName,
          meta: [
            officeName,
            window.title,
            'آخر تحديث ${_clock(overview.generatedAt)}',
          ],
          trailingMeta: isRefreshing ? const _RefreshingNote() : null,
          actions: [
            if (onCreateTrip != null)
              FilledButton.icon(
                onPressed: onCreateTrip,
                icon: const Icon(DashboardIcons.add, size: 18),
                label: const Text('رحلة جديدة'),
              ),
            if (onRefresh != null)
              OutlinedButton.icon(
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(DashboardIcons.refresh, size: 18),
                label: const Text('تحديث'),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.medium),
          child: Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DashboardSegmentedBar<OverviewWindow>(
                tone: DashboardSegmentTone.raised,
                dense: true,
                selected: window,
                onSelected: onWindowChanged,
                segments: [
                  for (final value in OverviewWindow.values)
                    DashboardSegment(
                      value: value,
                      label: value.label,
                      tooltip: value.title,
                    ),
                ],
              ),
              ..._verdictChips(overview),
            ],
          ),
        ),
      ],
    );
  }
}

/// «جارٍ التحديث…» beside the timestamp rather than replacing it: a reader
/// mid-refresh still needs to know how old the figures on screen are.
class _RefreshingNote extends StatelessWidget {
  const _RefreshingNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 11,
          height: 11,
          child: CircularProgressIndicator(
            strokeWidth: 1.8,
            color: DashboardColors.accentInk(context),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'جارٍ التحديث…',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: DashboardColors.accentInk(context),
          ),
        ),
      ],
    );
  }
}

/// What is off target and what is waiting — the handoff to the panels that can
/// do something about either.
///
/// Only non-zero readings appear. A row that always shows «٠ حرجة» trains the
/// eye to skip the whole strip, which is the one thing it cannot afford.
List<Widget> _verdictChips(BusinessOverview overview) {
  final signals = overview.healthSignals;
  int countOf(BusinessHealthStatus status) =>
      signals.where((s) => s.status == status).length;

  final critical = countOf(BusinessHealthStatus.critical);
  final warning = countOf(BusinessHealthStatus.warning);
  final pending = overview.attentionItems.length;

  return [
    if (critical > 0)
      OverviewChip(
        icon: DashboardIcons.attention,
        label: 'حرجة',
        value: '$critical',
        tone: AppStatusTone.error,
      ),
    if (warning > 0)
      OverviewChip(
        icon: DashboardIcons.health,
        label: 'تحتاج متابعة',
        value: '$warning',
        tone: AppStatusTone.warning,
      ),
    if (critical == 0 && warning == 0)
      OverviewChip(
        icon: DashboardIcons.allClear,
        label: 'المؤشرات',
        value: 'ضمن المستهدف',
        tone: AppStatusTone.success,
      ),
    OverviewChip(
      icon: pending == 0 ? DashboardIcons.allClear : DashboardIcons.quickAction,
      label: 'بانتظار قرارك',
      value: pending == 0 ? 'لا شيء' : '$pending',
      tone: pending == 0 ? AppStatusTone.neutral : AppStatusTone.info,
    ),
  ];
}

/// Says so when the selected window reaches further back than the rows the
/// console actually fetched.
///
/// Only shown when the booking query hit its own ceiling — that is what
/// separates "this office is three weeks old" (nothing missing, and saying
/// otherwise would be alarming) from "older rows were never loaded, so this
/// 90-day figure is short" (a real caveat on a real number).
///
/// Styled as [DashboardPartialDataNotice] is, so the page's two notices are one
/// shape.
class OverviewCoverageNotice extends StatelessWidget {
  const OverviewCoverageNotice({
    super.key,
    required this.overview,
    required this.window,
  });

  final BusinessOverview overview;
  final OverviewWindow window;

  /// Whether the notice has anything to say — asked by the page so it does not
  /// leave a gap above a widget that renders nothing.
  static bool isNeeded(BusinessOverview overview, OverviewWindow window) {
    if (overview.loadedBookings < DashboardQueryCaps.bookings) return false;
    final earliest = overview.earliestLoadedBookingDay;
    if (earliest == null) return false;
    final start = DateTime(
      overview.generatedAt.year,
      overview.generatedAt.month,
      overview.generatedAt.day,
    ).subtract(Duration(days: window.days - 1));
    return earliest.isAfter(start);
  }

  @override
  Widget build(BuildContext context) {
    if (!isNeeded(overview, window)) return const SizedBox.shrink();
    final earliest = overview.earliestLoadedBookingDay!;

    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(DashboardIcons.time, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'الحجوزات المحمَّلة تبدأ من ${earliest.day}/${earliest.month}، '
              'فأرقام ${window.title} تغطي هذه المدة فقط. للفترات الأطول '
              'استخدم التقارير.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// `12:00` — 24h plain digits, matching every other timestamp in the console
/// (Home's own banner, trip departures, table cells), which are ASCII
/// throughout. Hand-rolled rather than `DateFormat.jm('ar')`, which needs
/// locale data initialised and would make every widget test that renders this
/// header depend on it.
String _clock(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(at.hour)}:${two(at.minute)}';
}
