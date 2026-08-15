import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import '../cubit/reports_state.dart';

import 'report_filters_bar.dart';
import 'report_export_toolbar.dart';
import 'report_kpi_grid.dart';
import 'report_trend_chart.dart';
import 'report_data_table.dart';

class ReportWorkspace extends StatelessWidget {
  final ReportsLoaded state;
  const ReportWorkspace({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportExportToolbar(state: state),
          const SizedBox(height: AppSpacing.medium),

          ReportFiltersBar(state: state),
          const SizedBox(height: AppSpacing.medium),

          if (state.isRefreshing)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.small),
              child: LinearProgressIndicator(minHeight: 2),
            ),

          Expanded(
            // Only the results dim while a refetch is in flight. The selector,
            // the filter bar and the export toolbar stay live and stay put —
            // switching report type used to tear the whole page down.
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: state.isRefreshing ? 0.45 : 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReportKpiGrid(state: state),
                    const SizedBox(height: AppSpacing.medium),

                    ReportTrendChart(state: state),
                    const SizedBox(height: AppSpacing.medium),

                    ReportDataTable(state: state),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
