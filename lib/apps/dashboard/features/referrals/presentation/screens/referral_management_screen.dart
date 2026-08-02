import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';

import '../../domain/entities/referral_dashboard_data.dart';
import '../cubit/referral_cubit.dart';
import '../cubit/referral_state.dart';
import '../widgets/referral_history_tab.dart';
import '../widgets/referral_leaderboard_tab.dart';
import '../widgets/referral_overview_tab.dart';
import '../widgets/referral_settings_tab.dart';
import '../widgets/referral_transactions_tab.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

class ReferralManagementScreen extends StatelessWidget {
  const ReferralManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReferralCubit, ReferralState>(
      listener: (context, state) {
        if (state is ReferralActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return switch (state) {
          ReferralInitial() || ReferralLoading() => const DashboardLoading(),
          ReferralError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<ReferralCubit>().load(),
          ),
          ReferralLoaded() => _ReferralTabs(
            data: state.data,
            isSaving: state.isSaving,
          ),
          ReferralActionSuccess() => _ReferralTabs(
            data: state.data,
            isSaving: false,
          ),
        };
      },
    );
  }
}

class _ReferralTabs extends StatelessWidget {
  const _ReferralTabs({required this.data, required this.isSaving});

  final ReferralDashboardData data;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReferralCubit>();
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.large,
              AppSpacing.large,
              AppSpacing.large,
              0,
            ),
            child: DashboardModuleHeader(
              icon: DashboardIcons.referralsActive,
              title: 'برنامج الإحالات',
              subtitle:
                  'تابع أداء الإحالات وأدر إعدادات المكافآت والمتصدّرين والسجل.',
              actions: [
                FilledButton.icon(
                  onPressed: cubit.load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('تحديث'),
                ),
              ],
              child: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'نظرة عامة'),
                  Tab(text: 'إعدادات المكافآت'),
                  Tab(text: 'المتصدّرون'),
                  Tab(text: 'سجل الإحالات'),
                  Tab(text: 'حركات المكافآت'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ReferralOverviewTab(
                  analytics: data.analytics,
                  config: data.config,
                ),
                ReferralSettingsTab(
                  key: ValueKey(data.config.updatedAt),
                  config: data.config,
                  isSaving: isSaving,
                  onSave: cubit.saveConfig,
                ),
                ReferralLeaderboardTab(items: data.leaderboard),
                ReferralHistoryTab(records: data.records),
                ReferralTransactionsTab(transactions: data.transactions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
