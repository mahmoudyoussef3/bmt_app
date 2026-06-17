import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

class ReportExportToolbar extends StatelessWidget {
  final ReportsLoaded state;
  const ReportExportToolbar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportsCubit>();

    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.ios_share, color: AppStatusColors.onInfoContainer),
          const SizedBox(width: AppSpacing.small),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تصدير التقرير التنفيذي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('توليد وتنزيل نسخ التقارير بتنسيقات مختلفة لحفظها ومشاركتها.', style: TextStyle(fontSize: 10, color: AppStatusColors.onNeutralContainer)),
              ],
            ),
          ),
          if (state.actionLoading)
            const CircularProgressIndicator()
          else ...[
            OutlinedButton.icon(
              onPressed: () => cubit.triggerExport('pdf'),
              icon: const Icon(Icons.picture_as_pdf, color: AppStatusColors.onErrorContainer),
              label: const Text('PDF'),
            ),
            const SizedBox(width: AppSpacing.small),
            OutlinedButton.icon(
              onPressed: () => cubit.triggerExport('excel'),
              icon: const Icon(Icons.grid_on, color: AppStatusColors.onSuccessContainer),
              label: const Text('Excel'),
            ),
            const SizedBox(width: AppSpacing.small),
            OutlinedButton.icon(
              onPressed: () => cubit.triggerExport('csv'),
              icon: const Icon(Icons.description, color: AppStatusColors.onWarningContainer),
              label: const Text('CSV'),
            ),
          ],
        ],
      ),
    );
  }
}
