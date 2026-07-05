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
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text(
          'Support Center',
          style: ClientTypography.headingSmall(context).copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: scheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: scheme.primary),
            onPressed: () {
              context.read<SupportCubit>().refreshTickets();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create_ticket');
        },
        backgroundColor: scheme.primary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.add_rounded, color: scheme.onPrimary),
        label: Text(
          'Create Ticket',
          style: ClientTypography.labelLarge(context).copyWith(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: BlocConsumer<SupportCubit, SupportState>(
        listener: (context, state) {
          if (state is SupportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SupportLoading || state is SupportInitial) {
            return Center(
              child: CircularProgressIndicator(color: scheme.primary),
            );
          }

          if (state is SupportLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<SupportCubit>().refreshTickets(),
              color: scheme.primary,
              backgroundColor: scheme.surface,
              child: state.tickets.isEmpty
                  ? CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: scheme.primary.withAlpha(20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.support_agent_rounded,
                                      size: 64,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Text(
                                    'How can we help you?',
                                    textAlign: TextAlign.center,
                                    style: ClientTypography.headingMedium(context).copyWith(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'You don\'t have any active support tickets. If you have an issue, feel free to create a new ticket and our team will get back to you shortly.',
                                    textAlign: TextAlign.center,
                                    style: ClientTypography.bodyMedium(context).copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 120), // Space for FAB
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: state.tickets.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
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

          return Center(
            child: Text(
              'Something went wrong',
              style: ClientTypography.bodyLarge(context).copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}
