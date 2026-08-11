import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
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
          current is BookingsLoaded && current.actionError != null,
      listener: (context, state) {
        if (state is! BookingsLoaded || state.actionError == null) return;
        AppSnackbar.error(context, state.actionError!);
        context.read<BookingsCubit>().clearActionError();
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
        StatusChip(label: '${state.bookings.length} طلب'),
        IconButton(
          tooltip: 'تحديث البيانات',
          onPressed: state.isProcessing ? null : cubit.load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: _SummaryCards(state: state),
    );
  }
}

/// The KPI strip, built on the shared [DashboardKpiCard] instead of a private
/// tile, and reporting what an office is asked about — the review backlog and
/// the money accepted — rather than six raw status tallies (the per-status
/// counts now live on the queue tabs, next to the tab that opens them).
class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DashboardKpiGrid(
      maxColumns: 3,
      children: [
        DashboardKpiCard(
          label: 'إجمالي الطلبات',
          value: '${state.bookings.length}',
          detail: 'كل الحجوزات المحمّلة',
          icon: Icons.receipt_long_rounded,
          color: scheme.primary,
        ),
        DashboardKpiCard(
          label: 'بانتظار المراجعة',
          value: '${state.awaitingReviewCount}',
          detail: 'إيصالات تنتظر قراراً',
          icon: Icons.hourglass_top_rounded,
          color: context.status(AppStatusTone.warning).ink,
        ),
        DashboardKpiCard(
          label: 'محجوزة',
          value: '${state.countByStatus(BookingStatus.reserved)}',
          detail: 'مقاعد محجوزة لم تُؤكد',
          icon: Icons.event_seat_rounded,
          color: context.status(AppStatusTone.info).ink,
        ),
        DashboardKpiCard(
          label: 'مؤكدة',
          value: '${state.countByStatus(BookingStatus.confirmed)}',
          detail: 'دفع معتمد وحجز مؤكد',
          icon: Icons.verified_rounded,
          color: context.status(AppStatusTone.success).ink,
        ),
        DashboardKpiCard(
          label: 'إيرادات معتمدة',
          value: '${state.approvedRevenue.toStringAsFixed(0)} ج.م',
          detail: 'مجموع المدفوعات المقبولة',
          icon: Icons.payments_rounded,
          color: context.status(AppStatusTone.success).ink,
        ),
        DashboardKpiCard(
          label: 'مرفوضة أو ملغاة',
          value: '${state.settledOutCount}',
          detail: 'دفع مرفوض أو حجز ملغى',
          icon: Icons.block_rounded,
          color: context.status(AppStatusTone.error).ink,
        ),
      ],
    );
  }
}
