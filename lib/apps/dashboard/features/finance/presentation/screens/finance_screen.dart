import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_segmented_bar.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../cubit/finance_cubit.dart';
import '../cubit/finance_state.dart';
import '../widgets/finance_analytics_tab.dart';
import '../widgets/finance_format.dart';
import '../widgets/finance_ledger_tab.dart';
import '../widgets/finance_overview_tab.dart';
import '../widgets/finance_period_bar.dart';
import '../widgets/finance_reports_tab.dart';

/// The money module: what was earned, what is still owed, what went back, and
/// what that means. It reads — payment verification, refund decisions and
/// subscription changes live in the modules that own those workflows.
///
/// [onOpenModule] is how it stays read-only while still being useful: the
/// attention panel, the KPI band and the transaction detail hand the operator
/// off to the module that owns the decision rather than growing a decision of
/// their own.
class FinanceScreen extends StatelessWidget {
  final ValueChanged<String>? onOpenModule;

  const FinanceScreen({super.key, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FinanceCubit, FinanceState>(
      listenWhen: (previous, current) =>
          current is FinanceLoaded && current.actionMessage != null,
      listener: (context, state) {
        if (state is! FinanceLoaded || state.actionMessage == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.actionMessage!),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
          ),
        );
        context.read<FinanceCubit>().clearActionMessage();
      },
      builder: (context, state) => switch (state) {
        FinanceLoading() => const DashboardLoading(),
        FinanceError(:final message) => DashboardErrorState(
          message: message,
          onRetry: () => context.read<FinanceCubit>().load(),
        ),
        FinanceLoaded() => _FinanceWorkspace(
          state: state,
          onOpenModule: onOpenModule,
        ),
      },
    );
  }
}

class _FinanceWorkspace extends StatelessWidget {
  final FinanceLoaded state;
  final ValueChanged<String>? onOpenModule;

  const _FinanceWorkspace({required this.state, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceCubit>();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardModuleHeader(
            icon: DashboardIcons.paymentsActive,
            title: 'المركز المالي',
            subtitle:
                'كل أرقام المال في مكان واحد: الإيراد، التحصيل، المرتجعات، التحليلات والتقارير.',
            actions: [
              OutlinedButton.icon(
                onPressed: cubit.load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تحديث'),
              ),
            ],
            // Both controls are pinned: every figure on the page is scoped by
            // the period and reached through the section, so an operator who
            // cannot see them cannot read the page.
            pinned: _Workbench(state: state, cubit: cubit),
          ),
          Expanded(
            child: switch (state.section) {
              FinanceSection.overview => FinanceOverviewTab(
                state: state,
                onOpenModule: onOpenModule,
              ),
              FinanceSection.ledger => FinanceLedgerTab(
                state: state,
                onOpenModule: onOpenModule,
              ),
              FinanceSection.analytics => FinanceAnalyticsTab(state: state),
              FinanceSection.reports => FinanceReportsTab(state: state),
            },
          ),
        ],
      ),
    );
  }
}

/// One toolbar carrying both of the module's global controls — *which* report
/// (the sections) and *over what* (the period) — plus the line that says what
/// the period resolved to.
///
/// They used to be three stacked blocks: a chip row, a tinted restatement
/// panel, and a segmented button on its own line, together about 190px of
/// chrome before the first figure on the console's most-read screen. Pairing
/// them on one line and demoting the restatement to a footnote gives that back
/// to the numbers without hiding a single fact.
class _Workbench extends StatelessWidget {
  const _Workbench({required this.state, required this.cubit});

  final FinanceLoaded state;
  final FinanceCubit cubit;

  static const _icons = {
    FinanceSection.overview: Icons.dashboard_customize_outlined,
    FinanceSection.ledger: Icons.receipt_long_rounded,
    FinanceSection.analytics: Icons.insights_rounded,
    FinanceSection.reports: Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final sections = DashboardSegmentedBar<FinanceSection>(
      selected: state.section,
      onSelected: cubit.selectSection,
      segments: [
        for (final section in FinanceSection.values)
          DashboardSegment(
            value: section,
            label: section.label,
            icon: _icons[section],
            // Only the overview carries a count: it is where «يحتاج المتابعة»
            // lives, and an operator working in الحركات or التقارير must not be
            // the last to know that money is waiting on a decision.
            badge:
                section == FinanceSection.overview &&
                    state.attention.totalItems > 0
                ? FinanceFormat.count(state.attention.totalItems)
                : null,
          ),
      ],
    );

    final period = FinancePeriodBar(
      window: state.analytics.window,
      onSelected: cubit.setPeriod,
      onCustomRange: cubit.setCustomRange,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A `Wrap`, not a `LayoutBuilder` with a stacking breakpoint: both bars
        // are built from Arabic labels whose width depends on the font the
        // console actually loaded and on the reader's text scale, so any
        // pixel number picked here would be wrong on some machine. Wrap
        // measures instead of guessing — one line with the bars pushed to
        // opposite ends while they fit, two lines the moment they do not.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.small,
          children: [sections, period],
        ),
        const SizedBox(height: AppSpacing.small),
        FinanceWindowNote(
          window: state.analytics.window,
          loadedAt: state.loadedAt,
          capReached: state.ledgerCapReached,
        ),
      ],
    );
  }
}
