import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

import 'widgets/report_sidebar_selector.dart';
import 'widgets/report_workspace.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير التحليلية والإحصائيات'),
          actions: [
            IconButton(
              tooltip: 'تحديث البيانات',
              onPressed: () => context.read<ReportsCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocConsumer<ReportsCubit, ReportsState>(
          listenWhen: (previous, current) {
            return current is ReportsLoaded && current.actionMessage != null;
          },
          listener: (context, state) {
            if (state is ReportsLoaded && state.actionMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionMessage!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<ReportsCubit>().clearActionMessage();
            }
          },
          builder: (context, state) {
            return switch (state) {
              ReportsLoading() => const Center(child: CircularProgressIndicator()),
              ReportsError(:final message) => _ErrorView(message: message),
              ReportsLoaded() => _LoadedView(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.read<ReportsCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
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
                  onSelect: (type) => context.read<ReportsCubit>().changeReportType(type),
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
              child: AppCard(
                margin: const EdgeInsets.only(right: AppSpacing.medium, top: AppSpacing.medium, bottom: AppSpacing.medium),
                child: ReportSidebarSelector(
                  selectedType: state.activeReportType,
                  onSelect: (type) => context.read<ReportsCubit>().changeReportType(type),
                ),
              ),
            ),
            // 80% Main Workspace
            Expanded(
              child: ReportWorkspace(state: state),
            ),
          ],
        );
      },
    );
  }
}
