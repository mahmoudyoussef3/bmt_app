import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/customer_trip.dart';
import '../cubit/customer_profile_cubit.dart';
import '../cubit/customer_profile_state.dart';
import 'customer_tab_scaffold.dart';
import 'customers_format.dart';

/// الرحلات — the customer's bookings, split قادمة / سابقة.
///
/// The three status axes are drawn as three separate marks, never merged:
/// what the booking is, what the money did, and what the passenger did are
/// different facts, and a confirmed booking with an approved payment and a
/// `no_show` manifest row is a coherent record the operator needs to see whole.
class CustomerTripsTab extends StatelessWidget {
  const CustomerTripsTab({super.key, required this.state});

  final CustomerProfileLoadedState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerProfileCubit>();
    final page = state.visibleTrips;

    return CustomerTabScaffold(
      status: state.tripsStatus,
      onRetry: () => cubit.loadTrips(force: true),
      loadingRows: 4,
      header: _ScopeToggle(
        showPast: state.showPastTrips,
        upcomingCount: state.showPastTrips ? null : page.total,
        pastCount: state.showPastTrips ? page.total : null,
        onChanged: cubit.showPastTrips,
      ),
      child: page.rows.isEmpty
          ? AppCard(
              child: DashboardEmptyState(
                icon: DashboardIcons.trips,
                title: state.showPastTrips
                    ? 'لا توجد رحلات سابقة'
                    : 'لا توجد رحلات قادمة',
                message: state.showPastTrips
                    ? 'لم يسافر هذا العميل مع المكتب بعد.'
                    : 'يظهر هنا أي حجز قائم بتاريخ اليوم أو بعده.',
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth < 1000
                  ? _TripCards(rows: page.rows)
                  : _TripTable(state: state, page: page, cubit: cubit),
            ),
    );
  }
}

class _TripTable extends StatelessWidget {
  const _TripTable({
    required this.state,
    required this.page,
    required this.cubit,
  });

  final CustomerProfileLoadedState state;
  final CustomerTripsPage page;
  final CustomerProfileCubit cubit;

  @override
  Widget build(BuildContext context) {
    return OpsDataTable(
      columns: const [
        OpsColumn('الرحلة', flex: 3, minWidth: 200),
        OpsColumn('التاريخ', minWidth: 110),
        OpsColumn('الوقت', minWidth: 74),
        OpsColumn('الصعود / النزول', flex: 2, minWidth: 160),
        OpsColumn('المقعد', minWidth: 70),
        OpsColumn('حالة الحجز', minWidth: 100),
        OpsColumn('الدفع', minWidth: 110),
        OpsColumn('الصعود', minWidth: 100),
        OpsColumn('رقم الحجز', minWidth: 130),
      ],
      rows: [
        for (final trip in page.rows)
          [
            _RouteCell(trip: trip),
            Text(
              trip.tripDate == null
                  ? '—'
                  : CustomersFormat.date(trip.tripDate!),
            ),
            Text(CustomersFormat.tripTime(trip.tripTime)),
            _StopsCell(trip: trip),
            Text(trip.seat ?? '—'),
            _Pill(
              label: CustomersFormat.bookingStatus(trip.status),
              tone: CustomersFormat.bookingTone(trip.status, context),
            ),
            _PaymentCell(trip: trip),
            _Pill(
              label: CustomersFormat.boardingStatus(trip.boardingStatus),
              tone: CustomersFormat.boardingTone(trip.boardingStatus, context),
            ),
            Text(
              trip.bookingNumber ?? '—',
              style: const TextStyle(fontSize: 12),
            ),
          ],
      ],
      total: page.total,
      currentPage: state.tripsPageIndex,
      pageSize: customerTripsPageSize,
      onPageChanged: cubit.setTripsPage,
    );
  }
}

class _RouteCell extends StatelessWidget {
  const _RouteCell({required this.trip});

  final CustomerTrip trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          trip.route,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (trip.subscriptionName != null)
          Text(
            'ضمن باقة: ${trip.subscriptionName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: DashboardColors.mutedInk(context),
            ),
          )
        else if (trip.tripCode != null)
          Text(
            trip.tripCode!,
            style: TextStyle(
              fontSize: 11.5,
              color: DashboardColors.faintInk(context),
            ),
          ),
      ],
    );
  }
}

class _StopsCell extends StatelessWidget {
  const _StopsCell({required this.trip});

  final CustomerTrip trip;

  @override
  Widget build(BuildContext context) {
    final pickup = trip.pickupPointName;
    final dropoff = trip.dropoffPointName;
    if (pickup == null && dropoff == null) return const Text('—');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          pickup ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5),
        ),
        Text(
          dropoff ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            color: DashboardColors.mutedInk(context),
          ),
        ),
      ],
    );
  }
}

class _PaymentCell extends StatelessWidget {
  const _PaymentCell({required this.trip});

  final CustomerTrip trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          CustomersFormat.paymentStatus(trip.paymentStatus),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: CustomersFormat.paymentTone(trip.paymentStatus, context),
          ),
        ),
        Text(
          CustomersFormat.money(trip.paymentAmount),
          style: TextStyle(
            fontSize: 11.5,
            color: DashboardColors.mutedInk(context),
          ),
        ),
      ],
    );
  }
}

class _TripCards extends StatelessWidget {
  const _TripCards({required this.rows});

  final List<CustomerTrip> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final trip in rows) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.route,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _Pill(
                      label: CustomersFormat.bookingStatus(trip.status),
                      tone: CustomersFormat.bookingTone(trip.status, context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                Wrap(
                  spacing: AppSpacing.medium,
                  runSpacing: AppSpacing.xSmall,
                  children: [
                    _Fact(
                      label: 'التاريخ',
                      value: trip.tripDate == null
                          ? '—'
                          : CustomersFormat.date(trip.tripDate!),
                    ),
                    _Fact(
                      label: 'الوقت',
                      value: CustomersFormat.tripTime(trip.tripTime),
                    ),
                    _Fact(label: 'المقعد', value: trip.seat ?? '—'),
                    _Fact(
                      label: 'الدفع',
                      value:
                          '${CustomersFormat.paymentStatus(trip.paymentStatus)} · ${CustomersFormat.money(trip.paymentAmount)}',
                    ),
                    _Fact(
                      label: 'الصعود',
                      value: CustomersFormat.boardingStatus(
                        trip.boardingStatus,
                      ),
                    ),
                    if (trip.bookingNumber != null)
                      _Fact(label: 'رقم الحجز', value: trip.bookingNumber!),
                  ],
                ),
                if (trip.cancellationReason != null) ...[
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    'سبب الإلغاء: ${trip.cancellationReason}',
                    style: TextStyle(
                      fontSize: 12,
                      color: DashboardColors.mutedInk(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.small),
        ],
      ],
    );
  }
}

class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({
    required this.showPast,
    required this.onChanged,
    this.upcomingCount,
    this.pastCount,
  });

  final bool showPast;
  final ValueChanged<bool> onChanged;

  /// Only the visible side's total is known — the other has not been fetched,
  /// and printing a count for a list nobody has loaded would be a guess.
  final int? upcomingCount;
  final int? pastCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment(
            value: false,
            label: Text(
              upcomingCount == null ? 'القادمة' : 'القادمة ($upcomingCount)',
            ),
          ),
          ButtonSegment(
            value: true,
            label: Text(pastCount == null ? 'السابقة' : 'السابقة ($pastCount)'),
          ),
        ],
        selected: {showPast},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: tone.withAlpha(28),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: tone,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: DashboardColors.mutedInk(context),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
