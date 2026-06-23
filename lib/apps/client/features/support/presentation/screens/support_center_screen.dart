import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';

import '../widgets/support_ticket_card.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().loadWorkspace();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest.withAlpha(80),
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        title: Text(
          'Support Tickets',
          style: ClientTypography.headingMedium(context).copyWith(
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: scheme.onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<SupportCubit>().refreshTickets();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create_ticket');
        },
        backgroundColor: scheme.primary,
        elevation: 4,
        icon: Icon(Icons.add_rounded, color: scheme.onPrimary),
        label: Text(
          'Create Ticket',
          style: ClientTypography.labelLarge(context).copyWith(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: BlocConsumer<SupportCubit, SupportState>(
        listener: (context, state) {
          if (state is SupportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SupportLoading || state is SupportInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SupportLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<SupportCubit>().refreshTickets(),
              child: state.tickets.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                size: 64,
                                color: scheme.onSurface.withAlpha(100),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No active tickets',
                                style: ClientTypography.headingSmall(context).copyWith(
                                  color: scheme.onSurface.withAlpha(180),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to create a new ticket',
                                style: ClientTypography.bodyMedium(context).copyWith(
                                  color: scheme.onSurface.withAlpha(130),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.tickets.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return SupportTicketCard(
                          ticket: state.tickets[index],
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/ticket_details',
                              arguments: state.tickets[index].id,
                            );
                          },
                        );
                      },
                    ),
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }
}
