import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../cubit/finance_cubit.dart';
import '../cubit/finance_state.dart';
import '../widgets/finance_analytics_tab.dart';
import '../widgets/finance_ledger_tab.dart';
import '../widgets/finance_overview_tab.dart';
import '../widgets/finance_period_bar.dart';
import '../widgets/finance_reports_tab.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

/// The money module: what was earned, what is still owed, what went back, and
/// what that means. It reads — payment verification, refund decisions and
/// subscription changes live in the modules that own those workflows.
///
/// [onOpenModule] is how it stays read-only while still being useful: the
/// attention panel and the transaction detail hand the operator off to the
/// module that owns the decision rather than growing a decision of their own.
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
            // The period bar is pinned: every figure on the page is scoped by
            // it, so an operator who cannot see it cannot read the page.
            pinned: FinancePeriodBar(
              window: state.analytics.window,
              onSelected: cubit.setPeriod,
              onCustomRange: cubit.setCustomRange,
              loadedAt: state.loadedAt,
              capReached: state.ledgerCapReached,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          _SectionTabs(
            selected: state.section,
            onSelected: cubit.selectSection,
            attentionCount: state.attention.totalItems,
          ),
          const SizedBox(height: AppSpacing.medium),
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

class _SectionTabs extends StatelessWidget {
  final FinanceSection selected;
  final ValueChanged<FinanceSection> onSelected;

  /// How many rows are waiting on a decision. Shown on the overview chip so an
  /// operator working in الحركات or التقارير is not the last to know.
  final int attentionCount;

  const _SectionTabs({
    required this.selected,
    required this.onSelected,
    this.attentionCount = 0,
  });

  static const _icons = {
    FinanceSection.overview: Icons.dashboard_customize_outlined,
    FinanceSection.ledger: Icons.receipt_long_rounded,
    FinanceSection.analytics: Icons.insights_rounded,
    FinanceSection.reports: Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<FinanceSection>(
        segments: [
          for (final section in FinanceSection.values)
            ButtonSegment(
              value: section,
              icon: Icon(_icons[section]),
              label: _SegmentLabel(
                text: section.label,
                badgeCount: section == FinanceSection.overview
                    ? attentionCount
                    : 0,
              ),
            ),
        ],
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onSelected(selection.first),
      ),
    );
  }
}

/// A segment's label with an optional red count badge — used only for the
/// overview segment, which is where the attention panel lives.
class _SegmentLabel extends StatelessWidget {
  final String text;
  final int badgeCount;

  const _SegmentLabel({required this.text, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    if (badgeCount <= 0) return Text(text);

    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.xSmall),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: scheme.error,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$badgeCount',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(
                color: scheme.onError,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
