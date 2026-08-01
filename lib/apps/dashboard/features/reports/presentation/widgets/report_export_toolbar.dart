import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

class ReportExportToolbar extends StatelessWidget {
  final ReportsLoaded state;
  const ReportExportToolbar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportsCubit>();

    return AppCard(
      child: Row(
        children: [
          Icon(Icons.ios_share, color: context.status(AppStatusTone.info).ink),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تصدير التقرير التنفيذي',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'توليد وتنزيل نسخ التقارير بتنسيقات مختلفة لحفظها ومشاركتها.',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.status(AppStatusTone.neutral).ink,
                  ),
                ),
              ],
            ),
          ),
          if (state.actionLoading)
            const CircularProgressIndicator()
          else ...[
            OutlinedButton.icon(
              onPressed: () => cubit.triggerExport('pdf'),
              icon: Icon(
                Icons.picture_as_pdf,
                color: context.status(AppStatusTone.error).ink,
              ),
              label: const Text('PDF'),
            ),
            const SizedBox(width: AppSpacing.small),
            OutlinedButton.icon(
              onPressed: () => cubit.triggerExport('excel'),
              icon: Icon(
                Icons.grid_on,
                color: context.status(AppStatusTone.success).ink,
              ),
              label: const Text('Excel'),
            ),
            const SizedBox(width: AppSpacing.small),
            OutlinedButton.icon(
              onPressed: () => cubit.triggerExport('csv'),
              icon: Icon(
                Icons.description,
                color: context.status(AppStatusTone.warning).ink,
              ),
              label: const Text('CSV'),
            ),
          ],
        ],
      ),
    );
  }
}
