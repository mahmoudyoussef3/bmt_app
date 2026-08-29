import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_cap_notice.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import '../models/booking_queue_tab.dart';
import '../widgets/booking_bulk_actions.dart';
import '../widgets/booking_details_panel.dart';
import '../widgets/booking_filters_bar.dart';
import '../widgets/bookings_analytics.dart';
import '../widgets/bookings_queue_board.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

/// Bookings operations centre: review the payment queue, act on receipts, and
/// inspect the real booking / customer / trip data behind each request.
///
/// The page is ordered by what an operator does, not by what is easiest to
/// render: summary → filters → **the queue** → reporting. Four analytics charts
/// used to sit between the header and the list, so the screen the office opens
/// dozens of times a day started with a scroll.
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingsCubit, BookingsState>(
      listenWhen: (previous, current) =>
          current is BookingsLoaded &&
          (current.actionError != null || current.exportedFileName != null),
      listener: (context, state) {
        if (state is! BookingsLoaded) return;
        final cubit = context.read<BookingsCubit>();
        if (state.actionError != null) {
          AppSnackbar.error(context, state.actionError!);
          cubit.clearActionError();
        }
        if (state.exportedFileName != null) {
          AppSnackbar.success(
            context,
            'تم تصدير الملف: ${state.exportedFileName}',
          );
          cubit.clearExportedFileName();
        }
      },
      builder: (context, state) => switch (state) {
        BookingsLoading() => const DashboardLoading(),
        BookingsError(:final message) => DashboardErrorState(
          message: message,
          onRetry: () => context.read<BookingsCubit>().load(),
        ),
        BookingsLoaded() => _LoadedView(state: state),
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  /// Below this the inspector takes the whole screen as a sheet instead of
  /// splitting it, because a 440px panel beside a 700px board leaves neither
  /// side usable.
  static const double splitBreakpoint = 1180;

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final opened = state.openedBooking;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= splitBreakpoint;
        final isCompact = constraints.maxWidth < 760;

        final content = CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(
                isCompact ? AppSpacing.medium : AppSpacing.large,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _Header(state: state),
                  const SizedBox(height: AppSpacing.medium),
                  BookingsToolbar(state: state),
                  const SizedBox(height: AppSpacing.medium),
                  BookingBulkActions(state: state),
                  BookingsQueueBoard(state: state),
                  const SizedBox(height: AppSpacing.large),
                  BookingsAnalyticsSection(bookings: state.bookings),
                ]),
              ),
            ),
          ],
        );

        if (!isWide) {
          return Stack(
            children: [
              content,
              if (opened != null) _DetailsSheet(booking: opened, state: state),
            ],
          );
        }

        final panelWidth = constraints.maxWidth.clamp(0.0, 3000.0) * 0.30;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            AnimatedContainer(
              duration: AppTokens.motionSlow,
              curve: Curves.easeOutCubic,
              width: opened == null
                  ? 0
                  : panelWidth.clamp(380.0, 460.0).toDouble(),

              child: opened == null
                  ? const SizedBox.shrink()
                  : ClipRect(
                      child: OverflowBox(
                        alignment: AlignmentDirectional.centerStart,
                        minWidth: 380,
                        maxWidth: 460,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            0,
                            AppSpacing.large,
                            AppSpacing.large,
                            AppSpacing.large,
                          ),
                          child: BookingDetailsPanel(
                            booking: opened,
                            clientBookingsCount: state.bookingsForClient(
                              opened.clientId,
                            ),
                            isProcessing: state.isProcessing,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Full-height inspector for narrow layouts.
///
/// The scrim now dismisses the sheet: it looked like a modal barrier but
/// swallowed taps, so the only way out was the small close button.
class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({required this.booking, required this.state});

  final OperationBooking booking;
  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: cubit.closePanel,
            child: ColoredBox(
              color: Colors.black.withAlpha(90),
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.92,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.small),
                child: BookingDetailsPanel(
                  booking: booking,
                  clientBookingsCount: state.bookingsForClient(
                    booking.clientId,
                  ),
                  isProcessing: state.isProcessing,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return DashboardModuleHeader(
      icon: DashboardIcons.bookingsActive,
      title: 'مركز عمليات الحجوزات',
      subtitle: 'راجع الطلبات، تحقق من الدفع، وافتح تفاصيل الحجز من مكان واحد.',
      actions: [
        DashboardStatusChip(label: '${state.bookings.length} طلب'),
        if (state.capReached)
          const DashboardCapNotice(
            rowCap: DashboardQueryCaps.bookings,
            noun: 'حجز',
            hint: 'ضيّق الفلاتر للوصول لحجوزات أقدم.',
          ),
        OutlinedButton.icon(
          onPressed: state.isExporting ? null : cubit.exportBookings,
          icon: state.isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.file_download_outlined, size: 18),
          label: const Text('تصدير'),
        ),
        IconButton(
          tooltip: 'تحديث البيانات',
          onPressed: state.isProcessing ? null : cubit.load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      sectionId: DashboardSectionIds.bookingsHeader,
      // Unlike most module summaries, this strip starts open: it is the "today
      // at a glance" reading the queue is opened for, not a once-a-shift figure
      // worth folding away by default.
      initiallyExpanded: true,
      collapsedSummary: DashboardSectionSummary(
        items: [
          'اليوم ${state.bookingsCreatedToday}',
          'بانتظار المراجعة ${state.awaitingReviewCount}',
          'قيمة اليوم ${state.todayBookingValue.toStringAsFixed(0)} ج.م',
          'ملغاة اليوم ${state.cancelledTodayCount}',
        ],
      ),
      summary: _SummaryCards(state: state),
    );
  }
}

/// The "today at a glance" strip, built on the shared [DashboardKpiCard].
///
/// Four numbers an operator opens this board to check first thing: how much
/// came in today, what is still waiting on a decision, how much money that
/// represents, and how much fell through — rather than the standing totals a
/// shift-long queue already shows on its tabs.
///
/// Tinted with each tone's `accent`, not its `ink`: a tile's fill is that same
/// colour at low alpha, so the glyph on it is a standalone mark. `ink` is the
/// *container* ink — `#164E63` for success — and on a near-white tile it read as
/// black type rather than as a status.
class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final diff = state.bookingsCreatedToday - state.bookingsCreatedYesterday;
    final trendTone = diff > 0
        ? KpiTrendTone.positive
        : diff < 0
        ? KpiTrendTone.negative
        : KpiTrendTone.neutral;
    final trendIcon = diff > 0
        ? DashboardIcons.trendUp
        : diff < 0
        ? DashboardIcons.trendDown
        : DashboardIcons.trendFlat;

    return DashboardKpiGrid(
      maxColumns: 4,
      itemExtent: 132,
      children: [
        DashboardKpiCard(
          label: 'حجوزات اليوم',
          value: '${state.bookingsCreatedToday}',
          icon: Icons.receipt_long_rounded,
          color: context.status(AppStatusTone.info).accent,
          emphasized: true,
          trend: KpiTrend(
            label: diff == 0 ? 'بدون تغيير' : (diff > 0 ? '+$diff' : '$diff'),
            icon: trendIcon,
            tone: trendTone,
            caption: 'مقارنة بأمس',
          ),
        ),
        DashboardKpiCard(
          label: 'بانتظار المراجعة',
          value: '${state.awaitingReviewCount}',
          detail: 'إيصالات تنتظر قراراً',
          icon: Icons.hourglass_top_rounded,
          color: context.status(AppStatusTone.warning).accent,
          emphasized: true,
          // The tile and the tab are the same predicate — `awaitingReview` —
          // so pressing the number can only ever show exactly those rows.
          onTap: () => context.read<BookingsCubit>().switchTab(
            BookingQueueTab.needsReview,
          ),
          tapHint: 'عرض ما ينتظر المراجعة',
        ),
        DashboardKpiCard(
          label: 'قيمة اليوم',
          value: '${state.todayBookingValue.toStringAsFixed(0)} ج.م',
          detail: 'من حجوزات اليوم',
          icon: Icons.account_balance_wallet_rounded,
          color: context.status(AppStatusTone.success).accent,
          emphasized: true,
        ),
        // Deliberately not a shortcut: this counts *today's* cancellations
        // while the cancelled tab holds every one the office ever had, and a
        // tile that opens a different set than it counts is a lie.
        DashboardKpiCard(
          label: 'ملغاة اليوم',
          value: '${state.cancelledTodayCount}',
          detail: state.cancelledTodayRefundedCount > 0
              ? 'منها ${state.cancelledTodayRefundedCount} مسترد'
              : 'لا استردادات اليوم',
          icon: Icons.event_busy_rounded,
          color: context.status(AppStatusTone.error).accent,
          emphasized: true,
        ),
      ],
    );
  }
}
