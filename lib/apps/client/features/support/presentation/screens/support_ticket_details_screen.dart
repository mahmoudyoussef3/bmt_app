import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_ticket.dart';

import '../widgets/support_chat_bubble.dart';
import '../widgets/support_timeline.dart';

class SupportTicketDetailsScreen extends StatefulWidget {
  final String ticketId;

  const SupportTicketDetailsScreen({super.key, required this.ticketId});

  @override
  State<SupportTicketDetailsScreen> createState() => _SupportTicketDetailsScreenState();
}

class _SupportTicketDetailsScreenState extends State<SupportTicketDetailsScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  File? _attachment;

  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().openTicketDetails(widget.ticketId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachment = File(result.files.single.path!);
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _attachment == null) return;

    context.read<SupportCubit>().sendUserMessage(widget.ticketId, text, _attachment);
    _messageController.clear();
    setState(() {
      _attachment = null;
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open: return Colors.blue;
      case TicketStatus.underReview:
      case TicketStatus.inProgress: return Colors.orange;
      case TicketStatus.resolved:
      case TicketStatus.closed: return Colors.green;
    }
  }

  String _getStatusLabel(TicketStatus status) {
    switch (status) {
      case TicketStatus.open: return 'Open';
      case TicketStatus.underReview: return 'Under Review';
      case TicketStatus.inProgress: return 'In Progress';
      case TicketStatus.resolved: return 'Resolved';
      case TicketStatus.closed: return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Ticket Details',
          style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
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

          if (state is SupportTicketDetailsLoaded) {
            final ticket = state.ticket;
            final isClosed = ticket.status == TicketStatus.closed || ticket.status == TicketStatus.resolved;

            return Column(
              children: [
                // Header Details
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ticket.ticketNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(ticket.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusLabel(ticket.status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(ticket.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.title,
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                
                // Content Switcher
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const Material(
                          color: Colors.white,
                          child: TabBar(
                            labelColor: Colors.black87,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.blue,
                            tabs: [
                              Tab(text: 'Chat'),
                              Tab(text: 'Timeline'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Chat View
                              ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(top: 16, bottom: 80), // Padding for input
                                itemCount: state.messages.length,
                                itemBuilder: (context, index) {
                                  return SupportChatBubble(message: state.messages[index]);
                                },
                              ),
                              // Timeline View
                              ListView(
                                children: [
                                  SupportTimeline(events: state.timeline),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Chat Input
                if (!isClosed)
                  Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 8,
                      top: 8,
                      left: 16,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_attachment != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.image, size: 20, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _attachment!.path.split('/').last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() => _attachment = null),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.attach_file),
                              color: Colors.grey[600],
                              onPressed: _pickAttachment,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                minLines: 1,
                                maxLines: 4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                                onPressed: _sendMessage,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }

          return const Center(child: Text('Failed to load ticket details'));
        },
      ),
    );
  }
}
