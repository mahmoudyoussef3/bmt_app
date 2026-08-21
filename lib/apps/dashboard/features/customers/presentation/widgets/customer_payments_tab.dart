import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/customer_payment.dart';
import '../cubit/customer_profile_cubit.dart';
import '../cubit/customer_profile_state.dart';
import 'customer_tab_scaffold.dart';
import 'customers_format.dart';

/// المدفوعات — what this customer paid the office, and their wallet position.
///
/// ## What is deliberately not here
///
/// No card numbers, no processor tokens, no gateway payload. The RPC behind
/// this tab does not select `booking_payments.gateway_response`,
/// `gateway_transaction_id` or `gateway_order_id` at all — a read path that
/// never fetches them cannot leak them, which is a stronger guarantee than a
/// widget that chooses not to draw them. `payment_reference` *is* shown: it is
/// the transfer reference the customer themselves quotes when they call.
class CustomerPaymentsTab extends StatelessWidget {
  const CustomerPaymentsTab({super.key, required this.state});

  final CustomerProfileLoadedState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerProfileCubit>();
    final page = state.payments;

    return CustomerTabScaffold(
      status: state.paymentsStatus,
      onRetry: () => cubit.loadPayments(force: true),
      loadingRows: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MoneySummary(page: page),
          const SizedBox(height: AppSpacing.medium),
          if (page.rows.isEmpty)
            const AppCard(
              child: DashboardEmptyState(
                icon: DashboardIcons.payments,
                title: 'لا توجد مدفوعات',
                message: 'لم يسجّل المكتب أي عملية دفع لهذا العميل.',
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth < 900
                  ? _PaymentCards(rows: page.rows)
                  : _PaymentsTable(state: state, page: page, cubit: cubit),
            ),
          if (page.walletTransactions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.medium),
            _WalletActivity(entries: page.walletTransactions),
          ],
        ],
      ),
    );
  }
}

class _MoneySummary extends StatelessWidget {
  const _MoneySummary({required this.page});

  final CustomerPaymentsPage page;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final wallet = page.wallet;

    return AppCard(
      child: Wrap(
        spacing: AppSpacing.xLarge,
        runSpacing: AppSpacing.medium,
        children: [
          _Figure(
            label: 'إجمالي المدفوع',
            value: CustomersFormat.moneyPrecise(page.totalApproved),
            tone: palette.positive,
            detail: '${page.total} عملية مسجّلة',
          ),
          if (wallet != null) ...[
            _Figure(
              label: 'رصيد المحفظة',
              value: CustomersFormat.moneyPrecise(wallet.balance),
              tone: wallet.isFrozen ? palette.warning : palette.accent,
              detail: wallet.isFrozen ? 'المحفظة مجمّدة' : null,
            ),
            _Figure(
              label: 'إجمالي ما أُضيف',
              value: CustomersFormat.moneyPrecise(wallet.lifetimeCredited),
              tone: palette.neutral,
            ),
            _Figure(
              label: 'إجمالي ما خُصم',
              value: CustomersFormat.moneyPrecise(wallet.lifetimeDebited),
              tone: palette.neutral,
            ),
          ] else
            _Figure(
              label: 'المحفظة',
              value: '—',
              tone: palette.neutral,
              // Not the same statement as a zero balance.
              detail: 'لم تُفتح محفظة لهذا العميل',
            ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.tone,
    this.detail,
  });

  final String label;
  final String value;
  final Color tone;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: DashboardColors.mutedInk(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: tone,
          ),
        ),
        if (detail != null)
          Text(
            detail!,
            style: TextStyle(
              fontSize: 11.5,
              color: DashboardColors.faintInk(context),
            ),
          ),
      ],
    );
  }
}

class _PaymentsTable extends StatelessWidget {
  const _PaymentsTable({
    required this.state,
    required this.page,
    required this.cubit,
  });

  final CustomerProfileLoadedState state;
  final CustomerPaymentsPage page;
  final CustomerProfileCubit cubit;

  @override
  Widget build(BuildContext context) {
    return OpsDataTable(
      columns: const [
        OpsColumn('التاريخ', minWidth: 130),
        OpsColumn('المبلغ', minWidth: 110, numeric: true),
        OpsColumn('الطريقة', minWidth: 110),
        OpsColumn('الحالة', minWidth: 100),
        OpsColumn('الحجز', flex: 2, minWidth: 170),
        OpsColumn('المرجع', minWidth: 130),
      ],
      rows: [
        for (final payment in page.rows)
          [
            Text(
              payment.submittedAt == null
                  ? '—'
                  : CustomersFormat.dateTime(payment.submittedAt!),
              style: const TextStyle(fontSize: 12.5),
            ),
            Text(
              CustomersFormat.moneyPrecise(payment.amount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(CustomersFormat.paymentMethod(payment.method)),
            Text(
              CustomersFormat.paymentStatus(payment.status),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: CustomersFormat.paymentTone(payment.status, context),
              ),
            ),
            _BookingCell(payment: payment),
            Text(
              payment.paymentReference ?? '—',
              style: const TextStyle(fontSize: 12),
            ),
          ],
      ],
      total: page.total,
      currentPage: state.paymentsPageIndex,
      pageSize: customerPaymentsPageSize,
      onPageChanged: cubit.setPaymentsPage,
    );
  }
}

class _BookingCell extends StatelessWidget {
  const _BookingCell({required this.payment});

  final CustomerPayment payment;

  @override
  Widget build(BuildContext context) {
    if (payment.bookingNumber == null && payment.route == null) {
      return const Text('—');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (payment.route != null)
          Text(
            payment.route!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5),
          ),
        if (payment.bookingNumber != null)
          Text(
            payment.bookingNumber!,
            style: TextStyle(
              fontSize: 11.5,
              color: DashboardColors.mutedInk(context),
            ),
          ),
      ],
    );
  }
}

class _PaymentCards extends StatelessWidget {
  const _PaymentCards({required this.rows});

  final List<CustomerPayment> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final payment in rows) ...[
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CustomersFormat.moneyPrecise(payment.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${CustomersFormat.paymentMethod(payment.method)}'
                        ' · '
                        '${payment.submittedAt == null ? '—' : CustomersFormat.date(payment.submittedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: DashboardColors.mutedInk(context),
                        ),
                      ),
                      if (payment.bookingNumber != null)
                        Text(
                          payment.bookingNumber!,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: DashboardColors.faintInk(context),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  CustomersFormat.paymentStatus(payment.status),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: CustomersFormat.paymentTone(payment.status, context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.small),
        ],
      ],
    );
  }
}

/// The wallet ledger, capped at the newest 50 entries.
///
/// محفظة العملاء owns the full ledger, its export and every adjustment; this is
/// a read of the same rows so the operator does not have to leave the customer
/// to see whether a refund landed.
class _WalletActivity extends StatelessWidget {
  const _WalletActivity({required this.entries});

  final List<CustomerWalletEntry> entries;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);

    return DashboardPanel(
      icon: DashboardIcons.wallet,
      title: 'حركة المحفظة',
      subtitle: 'أحدث ${entries.length} حركة — السجل الكامل في محفظة العملاء',
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: DashboardColors.divider(context)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CustomersFormat.walletKind(entries[i].kind),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          entries[i].reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: DashboardColors.mutedInk(context),
                          ),
                        ),
                        Text(
                          '${CustomersFormat.dateTime(entries[i].createdAt)} · ${entries[i].performedByName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: DashboardColors.faintInk(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        // U+2212, not a hyphen: at this size in an RTL column a
                        // hyphen is easy to miss, and "was that a debit?" is the
                        // question this string exists to answer.
                        '${entries[i].isCredit ? '+' : '−'}${CustomersFormat.moneyPrecise(entries[i].amount.abs())}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: entries[i].isCredit
                              ? palette.positive
                              : palette.negative,
                        ),
                      ),
                      Text(
                        'الرصيد: ${CustomersFormat.moneyPrecise(entries[i].balanceAfter)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: DashboardColors.mutedInk(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
