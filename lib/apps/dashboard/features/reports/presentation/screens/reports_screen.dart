import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

import '../widgets/report_sidebar_selector.dart';
import '../widgets/report_workspace.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // No load() here: the shell creates the cubit with `..load()` already applied.
  // Calling it again from initState fired a second full fetch on every visit.

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportsCubit, ReportsState>(
      listenWhen: (previous, current) {
        return current is ReportsLoaded && current.exportedFileName != null;
      },
      listener: (context, state) {
        if (state is ReportsLoaded && state.exportedFileName != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم تصدير التقرير بنجاح: ${state.exportedFileName}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ReportsCubit>().clearExport();
        }
      },
      builder: (context, state) {
        return switch (state) {
          ReportsLoading() => const DashboardLoading(),
          ReportsError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<ReportsCubit>().load(),
          ),
          ReportsLoaded() => Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              children: [
                DashboardModuleHeader(
                  icon: DashboardIcons.reportsActive,
                  title: 'التقارير التحليلية والإحصائيات',
                  subtitle: 'تابع الأداء المالي والتشغيلي وصدّر التقارير.',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () => context.read<ReportsCubit>().load(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('تحديث'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                Expanded(child: _LoadedView(state: state)),
              ],
            ),
          ),
        };
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  final ReportsLoaded state;
  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSplit = constraints.maxWidth > 800;

        if (!useSplit) {
          // Mobile/Tablet Portrait Layout
          return Column(
            children: [
              SizedBox(
                height: 120,
                child: ReportSidebarSelector(
                  selectedType: state.activeReportType,
                  onSelect: (type) =>
                      context.read<ReportsCubit>().switchReportType(type),
                ),
              ),
              Expanded(child: ReportWorkspace(state: state)),
            ],
          );
        }

        // Desktop/Tablet Landscape Layout
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 20% Sidebar for Report Categories
            SizedBox(
              width: 240,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: AppSpacing.medium,
                  top: AppSpacing.medium,
                  bottom: AppSpacing.medium,
                ),
                child: AppCard(
                  child: ReportSidebarSelector(
                    selectedType: state.activeReportType,
                    onSelect: (type) =>
                        context.read<ReportsCubit>().switchReportType(type),
                  ),
                ),
              ),
            ),
            // 80% Main Workspace
            Expanded(child: ReportWorkspace(state: state)),
          ],
        );
      },
    );
  }
}
