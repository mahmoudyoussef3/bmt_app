import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';

import '../widgets/tickets_summary.dart';
import '../widgets/tickets_table.dart';
import '../widgets/complaint_workspace.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TicketsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مركز إدارة الشكاوى والمقترحات'),
          actions: [
            IconButton(
              tooltip: 'تحديث البيانات',
              onPressed: () => context.read<TicketsCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocConsumer<TicketsCubit, TicketsState>(
          listenWhen: (previous, current) {
            return current is TicketsLoaded && current.actionMessage != null;
          },
          listener: (context, state) {
            if (state is TicketsLoaded && state.actionMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionMessage!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<TicketsCubit>().clearActionMessage();
            }
          },
          builder: (context, state) {
            return switch (state) {
              TicketsLoading() => const Center(child: CircularProgressIndicator()),
              TicketsError(:final message) => _ErrorView(message: message),
              TicketsLoaded() => _LoadedView(state: state),
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
              onPressed: () => context.read<TicketsCubit>().load(),
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
  final TicketsLoaded state;
  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedComplaint;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        children: [
          // 1. Stats Row
          SummaryStats(state: state),
          const SizedBox(height: AppSpacing.medium),

          // 2. Filter Bar
          FilterBar(state: state),
          const SizedBox(height: AppSpacing.medium),

          // 3. Workspace Layout
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useSplit = constraints.maxWidth > 950;

                if (!useSplit) {
                  // Single view layout: Show table if no selected, else detail
                  if (selected != null) {
                    return Column(
                      children: [
                        TextButton.icon(
                          onPressed: () => context.read<TicketsCubit>().selectComplaint(''),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('العودة لقائمة الشكاوى'),
                        ),
                        Expanded(child: DetailWorkspace(complaint: selected, state: state)),
                      ],
                    );
                  }
                  return ComplaintsTable(state: state);
                }

                // Split Layout: 40% Table / 60% Detail Workspace
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: ComplaintsTable(state: state),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      flex: 6,
                      child: selected == null
                          ? const AppCard(
                              child: EmptyState(
                                title: 'اختر شكوى من الجدول لعرض تفاصيلها',
                                subtitle: 'تظهر هنا المحادثات والملفات والإجراءات والسجل الخاص بالشكوى.',
                              ),
                            )
                          : DetailWorkspace(complaint: selected, state: state),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
