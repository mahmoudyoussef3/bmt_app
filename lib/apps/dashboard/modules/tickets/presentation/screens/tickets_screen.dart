import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';

import '../widgets/tickets_summary.dart';
import '../widgets/tickets_table.dart';

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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تذاكر الدعم الفني'),
          actions: [
            IconButton(
              tooltip: 'تحديث',
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
              TicketsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
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
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppStatusColors.onErrorContainer,
            ),
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        children: [
          // 1. Stats Row
          SummaryStats(state: state),
          const SizedBox(height: AppSpacing.medium),

          // 2. Search & Filters (Could extract to separate widget if needed)
          _buildFilterBar(context),
          const SizedBox(height: AppSpacing.medium),

          // 3. Table
          Expanded(child: TicketsTable(state: state)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'ابحث عن تذكرة...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) =>
                context.read<TicketsCubit>().setSearchQuery(val),
          ),
        ),
        const SizedBox(width: 16),
        // Filter button or dropdowns could go here if needed.
      ],
    );
  }
}
