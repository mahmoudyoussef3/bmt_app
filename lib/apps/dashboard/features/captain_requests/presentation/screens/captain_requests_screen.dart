import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/captain_request.dart';
import '../cubit/captain_requests_cubit.dart';
import '../cubit/captain_requests_state.dart';
import '../widgets/captain_request_approve_flow.dart';
import '../widgets/captain_request_card.dart';
import '../widgets/captain_request_reject_dialog.dart';

class CaptainRequestsScreen extends StatefulWidget {
  const CaptainRequestsScreen({super.key});

  @override
  State<CaptainRequestsScreen> createState() => _CaptainRequestsScreenState();
}

class _CaptainRequestsScreenState extends State<CaptainRequestsScreen> {
  bool _pendingOnly = true;

  Future<void> _approve(CaptainRequest r) => CaptainRequestApproveFlow.start(
    context,
    context.read<CaptainRequestsCubit>(),
    r,
  );

  Future<void> _reject(CaptainRequest r) async {
    final reason = await CaptainRequestRejectDialog.show(context, r.fullName);
    if (reason == null || !mounted) return;
    await context.read<CaptainRequestsCubit>().reject(
      requestId: r.id,
      reason: reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CaptainRequestsCubit, CaptainRequestsState>(
      listenWhen: (p, c) => c is CaptainRequestsLoaded && c.actionError != null,
      listener: (context, state) {
        if (state is CaptainRequestsLoaded && state.actionError != null) {
          AppSnackbar.error(context, state.actionError!);
        }
      },
      builder: (context, state) {
        return switch (state) {
          CaptainRequestsLoading() => const DashboardLoading(),
          CaptainRequestsError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<CaptainRequestsCubit>().load(),
          ),
          CaptainRequestsLoaded(:final requests, :final pendingCount) => _list(
            context,
            requests,
            pendingCount,
          ),
        };
      },
    );
  }

  Widget _list(
    BuildContext context,
    List<CaptainRequest> requests,
    int pendingCount,
  ) {
    final visible = _pendingOnly
        ? requests.where((r) => r.isPending).toList()
        : requests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.large,
            AppSpacing.large,
            AppSpacing.large,
            AppSpacing.small,
          ),
          child: DashboardModuleHeader(
            icon: Icons.how_to_reg_rounded,
            title: 'طلبات انضمام الكباتن',
            subtitle:
                'راجع طلبات الكباتن الجدد ووافق عليها أو ارفضها مع بيان السبب.',
            actions: [
              StatusChip(label: '$pendingCount قيد المراجعة'),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('قيد المراجعة')),
                  ButtonSegment(value: false, label: Text('الكل')),
                ],
                selected: {_pendingOnly},
                onSelectionChanged: (s) =>
                    setState(() => _pendingOnly = s.first),
              ),
              OutlinedButton.icon(
                onPressed: () => context.read<CaptainRequestsCubit>().load(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تحديث'),
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? EmptyState(
                  emoji: '🧑‍✈️',
                  title: _pendingOnly
                      ? 'لا توجد طلبات قيد المراجعة'
                      : 'لا توجد طلبات',
                  subtitle:
                      'ستظهر هنا طلبات الكباتن الجدد فور تسجيلهم من التطبيق.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.small),
                  itemBuilder: (context, i) => CaptainRequestCard(
                    request: visible[i],
                    onApprove: () => _approve(visible[i]),
                    onReject: () => _reject(visible[i]),
                  ),
                ),
        ),
      ],
    );
  }
}
