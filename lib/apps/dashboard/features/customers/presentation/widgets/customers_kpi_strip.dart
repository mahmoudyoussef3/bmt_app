import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/core/theme/colors.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_filters.dart';
import '../models/customer_queue_tab.dart';
import 'customers_format.dart';

/// العملاء' headline counts.
///
/// ## Why four, and why each one is also a tab
///
/// "٣ عملاء لديهم رحلة قادمة" is only useful if the next question — *which
/// three* — is one press away. Every tile applies the [CustomerQueueTab] that
/// produced it, so the number, the tab under it and the list behind them can
/// never disagree: they are the same predicate, asked of the same function.
///
/// Four rather than five, so the strip is one full row at every console width
/// and matches its neighbours in المبيعات — a fifth tile wrapped onto a line of
/// its own and made this module's header a different shape from الحجوزات' and
/// الاشتراكات'. "عملاء جدد" was the tile with no filter behind it, so it now
/// rides on the total's detail line, where it reads as what it is: a share of
/// that number rather than a separate population.
///
/// ## Why there is no trend on any of them
///
/// A trend needs a comparable prior period, and none of these counts has one
/// stored. Drawing "+12%" from an arithmetic the database cannot support is the
/// exact fabrication this console refuses elsewhere.
class CustomersKpiStrip extends StatelessWidget {
  const CustomersKpiStrip({
    super.key,
    required this.overview,
    required this.filters,
    required this.onFilter,
  });

  final CustomersOverview overview;
  final CustomerFilters filters;

  /// Applies one tile's filter. Passing the whole filter set rather than a
  /// single field keeps the toolbar, the tab strip and the tiles writing to one
  /// place.
  final ValueChanged<CustomerFilters> onFilter;

  @override
  Widget build(BuildContext context) {
    return DashboardKpiGrid(
      maxColumns: 4,
      itemExtent: 132,
      children: [
        _tile(
          context,
          tab: CustomerQueueTab.all,
          label: 'إجمالي العملاء',
          value: overview.totalCustomers,
          icon: DashboardIcons.customers,
          // "New to this office", not "newly registered on the platform".
          detail:
              'منهم ${CustomersFormat.count(overview.newCustomers)} '
              'أول حجز خلال ٣٠ يوماً',
          tone: AppStatusTone.info,
          hint: 'عرض كل العملاء',
        ),
        _tile(
          context,
          tab: CustomerQueueTab.active,
          label: 'العملاء النشطون',
          value: overview.activeCustomers,
          icon: DashboardIcons.trend,
          detail: 'حجزوا خلال ٣٠ يوماً',
          tone: AppStatusTone.success,
          hint: 'عرض العملاء النشطين',
        ),
        _tile(
          context,
          tab: CustomerQueueTab.subscribed,
          label: 'لديهم اشتراك ساري',
          value: overview.withActiveSubscription,
          icon: DashboardIcons.subscriptions,
          detail: 'اشتراك لم ينتهِ بعد',
          tone: AppStatusTone.special,
          hint: 'عرض أصحاب الاشتراكات السارية',
        ),
        _tile(
          context,
          tab: CustomerQueueTab.upcoming,
          label: 'لديهم رحلة قادمة',
          value: overview.withUpcomingTrip,
          icon: DashboardIcons.trips,
          detail: 'حجز قائم اليوم أو بعده',
          tone: AppStatusTone.warning,
          hint: 'عرض من لديهم رحلات قادمة',
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required CustomerQueueTab tab,
    required String label,
    required int value,
    required IconData icon,
    required String detail,
    required AppStatusTone tone,
    required String hint,
  }) {
    return DashboardKpiCard(
      label: label,
      value: CustomersFormat.count(value),
      icon: icon,
      detail: detail,
      // The tone's `accent`, not its `ink`: a tile's fill is near-white, and
      // `ink` is the *container* ink, which on it reads as black type rather
      // than as a status.
      color: DashboardColors.status(context, tone).accent,
      emphasized: true,
      onTap: () => onFilter(tab.applyTo(filters)),
      tapHint: hint,
    );
  }
}
