import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_cap_notice.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/customer_activity.dart';
import '../cubit/customer_profile_cubit.dart';
import '../cubit/customer_profile_state.dart';
import 'customer_tab_scaffold.dart';
import 'customers_format.dart';

/// النشاط — a chronological feed built from real timestamps.
///
/// Eleven columns across seven tables, unioned server-side: a booking's
/// `created_at`, a receipt's `submitted_at`, the moment a passenger was marked
/// aboard, a wallet movement, a review, a ticket, a settled refund. Nothing is
/// inferred from an absence and nothing is synthesised — if the database did
/// not record when something happened, it is not on this list.
///
/// Events are grouped by day, because "اليوم" and "أمس" answer the question the
/// operator is actually asking faster than eleven repeated dates.
class CustomerActivityTab extends StatelessWidget {
  const CustomerActivityTab({
    super.key,
    required this.state,
    required this.now,
  });

  final CustomerProfileLoadedState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerProfileCubit>();
    final events = state.activity;

    return CustomerTabScaffold(
      status: state.activityStatus,
      onRetry: () => cubit.loadActivity(force: true),
      loadingRows: 5,
      child: events.isEmpty
          ? const AppCard(
              child: DashboardEmptyState(
                icon: DashboardIcons.activity,
                title: 'لا يوجد نشاط مسجّل',
                message:
                    'يظهر هنا كل ما سجّله النظام لهذا العميل: الحجوزات والمدفوعات والصعود والاشتراكات.',
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The feed is a window, and says so rather than letting the
                // oldest row it happens to hold read as the beginning of time.
                if (state.activityWindowed) ...[
                  const DashboardCapNotice(
                    rowCap: customerActivityLimit,
                    noun: 'حدث',
                    hint:
                        'هذه أحدث الأحداث فقط — السجل الكامل في تبويبات الرحلات والمدفوعات والاشتراكات.',
                  ),
                  const SizedBox(height: AppSpacing.small),
                ],
                AppCard(
                  // A chronological feed is prose, not a table. Left to the
                  // full width of the workspace its rows run past 1,400px and
                  // the amount at the end of a row ends up a thousand pixels
                  // from the event it belongs to.
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: _Timeline(events: events, now: now),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events, required this.now});

  final List<CustomerActivityEvent> events;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDay(events);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.small,
              bottom: AppSpacing.xSmall,
            ),
            child: Text(
              CustomersFormat.relativeDay(entry.key, now),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: DashboardColors.mutedInk(context),
                fontSize: 12.5,
              ),
            ),
          ),
          for (final event in entry.value) _Event(event: event),
        ],
      ],
    );
  }

  /// Preserves the server's newest-first order: [Map] literals iterate in
  /// insertion order, and the events arrive already sorted.
  static Map<DateTime, List<CustomerActivityEvent>> _groupByDay(
    List<CustomerActivityEvent> events,
  ) {
    final grouped = <DateTime, List<CustomerActivityEvent>>{};
    for (final event in events) {
      final day = DateTime(event.at.year, event.at.month, event.at.day);
      grouped.putIfAbsent(day, () => []).add(event);
    }
    return grouped;
  }
}

class _Event extends StatelessWidget {
  const _Event({required this.event});

  final CustomerActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final (icon, tone) = _mark(event.kind, palette);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              CustomersFormat.dateTime(event.at).split(' — ').last,
              style: TextStyle(
                fontSize: 11.5,
                color: DashboardColors.faintInk(context),
              ),
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: tone.withAlpha(28),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: tone),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.kind.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (event.subject != null)
                  Text(
                    event.subject!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: DashboardColors.mutedInk(context),
                    ),
                  ),
                if (event.reference != null)
                  Text(
                    event.reference!,
                    style: TextStyle(
                      fontSize: 11,
                      color: DashboardColors.faintInk(context),
                    ),
                  ),
              ],
            ),
          ),
          if (event.amount != null && event.amount != 0)
            Text(
              CustomersFormat.money(event.amount!),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  static (IconData, Color) _mark(
    CustomerActivityKind kind,
    DashboardChartPalette palette,
  ) => switch (kind) {
    CustomerActivityKind.bookingCreated => (
      DashboardIcons.bookings,
      palette.active,
    ),
    CustomerActivityKind.bookingCancelled => (
      Icons.cancel_outlined,
      palette.negative,
    ),
    CustomerActivityKind.paymentSubmitted => (
      DashboardIcons.paymentReview,
      palette.warning,
    ),
    CustomerActivityKind.paymentApproved => (
      DashboardIcons.payments,
      palette.positive,
    ),
    CustomerActivityKind.boarded => (Icons.login_rounded, palette.positive),
    CustomerActivityKind.noShow => (
      Icons.person_off_outlined,
      palette.negative,
    ),
    CustomerActivityKind.subscriptionCreated => (
      DashboardIcons.subscriptions,
      palette.accent,
    ),
    CustomerActivityKind.walletCashback ||
    CustomerActivityKind.walletCredit ||
    CustomerActivityKind.walletRefund => (
      DashboardIcons.wallet,
      palette.positive,
    ),
    CustomerActivityKind.walletDebit => (
      DashboardIcons.wallet,
      palette.negative,
    ),
    CustomerActivityKind.reviewSubmitted => (
      DashboardIcons.reviews,
      palette.accent,
    ),
    CustomerActivityKind.ticketOpened => (
      DashboardIcons.tickets,
      palette.warning,
    ),
    CustomerActivityKind.refundSettled => (Icons.undo_rounded, palette.neutral),
    CustomerActivityKind.unknown => (DashboardIcons.activity, palette.neutral),
  };
}
