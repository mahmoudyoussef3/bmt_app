import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import '../widgets/booking_bulk_actions.dart';
import '../widgets/booking_details_panel.dart';
import '../widgets/booking_filters_bar.dart';
import '../widgets/bookings_analytics.dart';
import '../widgets/bookings_queue_board.dart';

/// Bookings operations centre: review the payment queue, act on receipts, and
/// inspect the real booking / customer / trip data behind each request.
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocBuilder<BookingsCubit, BookingsState>(
        builder: (context, state) => switch (state) {
          BookingsLoading() => const Center(child: CircularProgressIndicator()),
          BookingsError(:final message) => _ErrorView(message: message),
          BookingsLoaded() => _LoadedView(state: state),
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final opened = state.openedBooking;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1180;
        final isCompact = constraints.maxWidth < 760;

        final content = CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(
                isCompact ? AppSpacing.medium : AppSpacing.large,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _Header(total: state.bookings.length),
                  const SizedBox(height: AppSpacing.medium),
                  _SummaryCards(state: state),
                  const SizedBox(height: AppSpacing.medium),
                  BookingsAnalytics(bookings: state.bookings),
                  const SizedBox(height: AppSpacing.medium),
                  BookingsToolbar(state: state),
                  const SizedBox(height: AppSpacing.medium),
                  BookingBulkActions(selectedCount: state.selectedIds.length),
                  BookingsQueueBoard(state: state),
                ]),
              ),
            ),
          ],
        );

        if (!isWide) {
          return Stack(
            children: [
              content,
              if (opened != null)
                _DetailsSheet(booking: opened, state: state),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: opened == null ? 0 : 440,
              child: opened == null
                  ? const SizedBox.shrink()
                  : Padding(
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
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({required this.booking, required this.state});

  final OperationBooking booking;
  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withAlpha(65),
        child: Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: BookingDetailsPanel(
                booking: booking,
                clientBookingsCount: state.bookingsForClient(booking.clientId),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return DashboardModuleHeader(
      icon: Icons.event_seat_rounded,
      title: 'مركز عمليات الحجوزات',
      subtitle: 'راجع الطلبات، تحقق من الدفع، وافتح تفاصيل الحجز من مكان واحد.',
      actions: [StatusChip(label: '$total طلب')],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        'مسودة',
        state.countByStatus(BookingStatus.draft),
        Icons.fiber_new_rounded,
        AppStatusColors.onInfoContainer,
      ),
      _SummaryItem(
        'مراجعة الدفع',
        state.countByPaymentStatus(PaymentStatus.underReview) +
            state.countByPaymentStatus(PaymentStatus.submitted),
        Icons.hourglass_top_rounded,
        AppStatusColors.onWarningContainer,
      ),
      _SummaryItem(
        'محجوزة',
        state.countByStatus(BookingStatus.reserved),
        Icons.book_online_outlined,
        AppStatusColors.onSuccessContainer,
      ),
      _SummaryItem(
        'مؤكدة',
        state.countByStatus(BookingStatus.confirmed),
        Icons.verified_outlined,
        AppStatusColors.onSpecialContainer,
      ),
      _SummaryItem(
        'مرفوضة الدفع',
        state.countByPaymentStatus(PaymentStatus.rejected),
        Icons.cancel_outlined,
        AppStatusColors.onErrorContainer,
      ),
      _SummaryItem(
        'ملغاة',
        state.countByStatus(BookingStatus.cancelled),
        Icons.block_outlined,
        AppStatusColors.onNeutralContainer,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 6
            : constraints.maxWidth >= 860
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, index) => _SummaryCard(item: items[index]),
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.count, this.icon, this.color);

  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withAlpha(22),
              borderRadius: BorderRadius.circular(AppTokens.radius),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${item.count}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: item.color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
