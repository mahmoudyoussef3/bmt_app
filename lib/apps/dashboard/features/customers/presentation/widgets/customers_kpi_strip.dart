import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_filters.dart';
import 'customers_format.dart';

/// The five headline counts.
///
/// ## Why each tile is also a filter
///
/// "٣ عملاء لديهم رحلة قادمة" is only useful if the next question — *which
/// three* — is one press away. Every tile except the total applies the filter
/// that produced it, so the number and the list behind it can never disagree:
/// they are the same predicate, asked of the same function.
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
  /// single field keeps the toolbar and the tiles writing to one place.
  final ValueChanged<CustomerFilters> onFilter;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);

    return DashboardKpiGrid(
      maxColumns: 5,
      children: [
        DashboardKpiCard(
          label: 'إجمالي العملاء',
          value: CustomersFormat.count(overview.totalCustomers),
          icon: DashboardIcons.customers,
          detail: 'من حجز أو اشترك مع المكتب',
          color: palette.active,
          onTap: () => onFilter(const CustomerFilters()),
          tapHint: 'عرض كل العملاء',
        ),
        DashboardKpiCard(
          label: 'العملاء النشطون',
          value: CustomersFormat.count(overview.activeCustomers),
          icon: DashboardIcons.trend,
          detail: 'حجزوا خلال ٣٠ يوماً',
          color: palette.positive,
          onTap: () => onFilter(
            filters.copyWith(activity: CustomerActivityFilter.active),
          ),
          tapHint: 'عرض العملاء النشطين',
        ),
        DashboardKpiCard(
          label: 'لديهم اشتراك ساري',
          value: CustomersFormat.count(overview.withActiveSubscription),
          icon: DashboardIcons.subscriptions,
          detail: 'اشتراك لم ينتهِ بعد',
          color: palette.accent,
          onTap: () => onFilter(
            filters.copyWith(subscription: CustomerSubscriptionFilter.active),
          ),
          tapHint: 'عرض أصحاب الاشتراكات السارية',
        ),
        DashboardKpiCard(
          label: 'لديهم رحلة قادمة',
          value: CustomersFormat.count(overview.withUpcomingTrip),
          icon: DashboardIcons.trips,
          detail: 'حجز قائم اليوم أو بعده',
          color: palette.warning,
          onTap: () =>
              onFilter(filters.copyWith(upcoming: CustomerUpcomingFilter.has)),
          tapHint: 'عرض من لديهم رحلات قادمة',
        ),
        DashboardKpiCard(
          label: 'عملاء جدد',
          value: CustomersFormat.count(overview.newCustomers),
          icon: DashboardIcons.passenger,
          // "New to this office", not "newly registered on the platform" —
          // kept short enough to survive the tile without ellipsis.
          detail: 'أول حجز خلال ٣٠ يوماً',
          color: palette.neutral,
        ),
      ],
    );
  }
}
