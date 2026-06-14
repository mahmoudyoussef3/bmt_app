import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';
import 'package:bmt_app/core/widgets/app_button.dart';

import '../widgets/support_home_header.dart';
import '../widgets/support_category_card.dart';
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Support Center',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SupportCubit>().loadWorkspace();
            },
          ),
        ],
      ),
      body: BlocConsumer<SupportCubit, SupportState>(
        listener: (context, state) {
          if (state is SupportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SupportHomeHeader(),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.primary(
                          text: 'Create Ticket',
                          onPressed: () {
                            Navigator.pushNamed(context, '/create_ticket');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton.secondary(
                          text: 'Request Refund',
                          onPressed: () {
                            Navigator.pushNamed(context, '/create_refund');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Categories
                  Text(
                    'Help Topics',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: state.categories.length,
                    itemBuilder: (context, index) {
                      return SupportCategoryCard(
                        title: state.categories[index],
                        onTap: () {
                          Navigator.pushNamed(
                            context, 
                            '/create_ticket',
                            arguments: state.categories[index],
                          );
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Active Tickets
                  Text(
                    'My Tickets',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (state.tickets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No active tickets',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.tickets.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                ],
              ),
            );
          }

          // Fallback
          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }
}
