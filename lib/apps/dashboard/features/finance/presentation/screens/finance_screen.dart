import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

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
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No load() here: the shell creates the cubit with `..load()` already
    // applied. Calling it again fired a second full fetch on every visit.
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
        FinanceLoaded() => _FinanceWorkspace(state: state),
      },
    );
  }
}

class _FinanceWorkspace extends StatelessWidget {
  final FinanceLoaded state;

  const _FinanceWorkspace({required this.state});

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
            child: FinancePeriodBar(
              selected: state.period,
              onSelected: cubit.setPeriod,
              loadedAt: state.loadedAt,
              capReached: state.ledgerCapReached,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          _SectionTabs(
            selected: state.section,
            onSelected: cubit.selectSection,
          ),
          const SizedBox(height: AppSpacing.medium),
          Expanded(
            child: switch (state.section) {
              FinanceSection.overview => FinanceOverviewTab(state: state),
              FinanceSection.ledger => FinanceLedgerTab(state: state),
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

  const _SectionTabs({required this.selected, required this.onSelected});

  static const _icons = {
    FinanceSection.overview: Icons.dashboard_customize_outlined,
    FinanceSection.ledger: Icons.receipt_long_rounded,
    FinanceSection.analytics: Icons.insights_rounded,
    FinanceSection.reports: Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        children: [
          for (final section in FinanceSection.values)
            ChoiceChip(
              avatar: Icon(_icons[section], size: 18),
              label: Text(section.label),
              selected: selected == section,
              onSelected: (isSelected) {
                if (isSelected) onSelected(section);
              },
            ),
        ],
      ),
    );
  }
}
