import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_ticket.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  // Support Center Views:
  // 1 = Support Home
  // 2 = Create Ticket Form
  // 3 = Ticket Details (Chat)
  // 4 = Ticket Tracking (Timeline)
  // 5 = Refund Request Form
  int _currentView = 1;

  // Search input query
  final TextEditingController _searchController = TextEditingController();

  // Create Ticket Form controllers
  final TextEditingController _ticketTitleController = TextEditingController();
  final TextEditingController _ticketDescController = TextEditingController();
  String _selectedCreateCategory = 'Booking Issue';
  String _selectedCreatePriority = 'Medium';
  bool _ticketImageAttached = false;

  // Refund Request Form state
  String _selectedRefundBooking = 'Trip #MGT-8492 (Cairo → Banha) - EGP 68';
  String _selectedRefundReason = 'Shuttle AC was malfunctioning';
  bool _refundEvidenceAttached = false;

  // Chat message controller
  final TextEditingController _chatReplyController = TextEditingController();

  SupportLoaded? _support;

  List<String> get _categories => _support?.categories ?? const [];

  List<SupportTicket> get _myTickets => _support?.tickets ?? const [];

  SupportTicket? get _activeTicket => _support?.activeTicket;

  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ticketTitleController.dispose();
    _ticketDescController.dispose();
    _chatReplyController.dispose();
    super.dispose();
  }

  void _onBackPress() {
    if (_currentView == 4) {
      // Go back from Tracking to Details
      setState(() => _currentView = 3);
    } else if (_currentView > 1) {
      // Go back from any sub-screen to Home
      setState(() => _currentView = 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  String _getViewTitle() {
    return switch (_currentView) {
      1 => 'Customer Support',
      2 => 'Create Support Ticket',
      3 => 'Ticket Support Thread',
      4 => 'Resolution Timeline',
      5 => 'Submit Refund Request',
      _ => 'Support Center',
    };
  }

  // Action methods
  void _submitNewTicket() async {
    final title = _ticketTitleController.text.trim();
    final desc = _ticketDescController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    final newTicket = await context.read<SupportCubit>().createTicket(
      category: _selectedCreateCategory,
      title: title,
      description: desc,
      priority: _selectedCreatePriority,
      imageAttached: _ticketImageAttached,
    );

    if (!mounted) return;
    if (newTicket == null) return;

    setState(() {
      _currentView = 1;
      // Reset fields
      _ticketTitleController.clear();
      _ticketDescController.clear();
      _ticketImageAttached = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ticket ${newTicket.id} created successfully!')),
    );
  }

  void _submitRefundRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Refund request submitted successfully! We will review your request in 2-3 business days.',
        ),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {
      _currentView = 1;
      _refundEvidenceAttached = false;
    });
  }

  void _sendChatMessage() {
    final reply = _chatReplyController.text.trim();
    if (reply.isEmpty || _activeTicket == null) return;
    final ticketId = _activeTicket!.id;
    context.read<SupportCubit>().addUserMessage(reply);

    setState(() {
      _chatReplyController.clear();
    });

    // Simulate agent auto-reply after 1.5 seconds
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || _activeTicket?.id != ticketId) return;
      context.read<SupportCubit>().addAgentReply(ticketId);
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<SupportCubit, SupportState>(
      builder: (context, state) {
        if (state is SupportLoaded) {
          _support = state;
        }

        return Scaffold(
          backgroundColor: scheme.surfaceContainerHighest,
          appBar: AppBar(
            title: Text(
              _getViewTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            leading: IconButton(
              onPressed: _onBackPress,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            elevation: 0,
          ),
          body: SafeArea(
            child: switch (state) {
              SupportLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              SupportError(:final message) => EmptyState(
                title: 'Support unavailable',
                subtitle: message,
              ),
              SupportLoaded() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentView(scheme),
              ),
            },
          ),
        );
      },
    );
  }

  Widget _buildCurrentView(ColorScheme scheme) {
    return switch (_currentView) {
      1 => _buildHomeView(scheme),
      2 => _buildCreateTicketView(scheme),
      3 => _buildDetailsView(scheme),
      4 => _buildTrackingView(scheme),
      5 => _buildRefundRequestView(scheme),
      _ => const SizedBox.shrink(),
    };
  }

  // --- SCREEN 1: SUPPORT HOME SCREEN ---
  Widget _buildHomeView(ColorScheme scheme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        // Welcome Header & Search Bar
        _buildSearchHeader(scheme),
        const SizedBox(height: 20),

        // Quick refund request promo banner
        _buildRefundPromoBanner(scheme),
        const SizedBox(height: 20),

        // Categories Grid Title
        const Text(
          'Browse Help Categories',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        _buildCategoriesGrid(scheme),
        const SizedBox(height: 24),

        // Active Tickets list
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Active Tickets',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _currentView = 2),
              icon: Icon(Icons.add, size: 14, color: scheme.primary),
              label: Text(
                'New Ticket',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTicketsList(scheme),
      ],
    );
  }

  Widget _buildSearchHeader(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How can we help today?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search FAQs, articles, or issues...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              fillColor: scheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundPromoBanner(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.error.withAlpha(45), scheme.tertiary.withAlpha(25)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.error.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.currency_exchange_rounded,
              color: scheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trip delay or cancellation?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Instantly request a refund to your user wallet.',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => setState(() => _currentView = 5),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              backgroundColor: scheme.error,
            ),
            child: const Text(
              'Refund',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(ColorScheme scheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 520 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, idx) {
            final cat = _categories[idx];
            IconData icon = Icons.info_outline_rounded;
            Color color = scheme.primary;

            switch (cat) {
              case 'Booking Issue':
                icon = Icons.confirmation_number_rounded;
                color = scheme.primary;
                break;
              case 'Driver Issue':
                icon = Icons.person_rounded;
                color = scheme.secondary;
                break;
              case 'Vehicle Issue':
                icon = Icons.directions_bus_rounded;
                color = scheme.tertiary;
                break;
              case 'Route Issue':
                icon = Icons.route_rounded;
                color = Colors.teal;
                break;
              case 'Technical Issue':
                icon = Icons.phonelink_setup_rounded;
                color = Colors.indigo;
                break;
              case 'Refund Request':
                icon = Icons.monetization_on_rounded;
                color = scheme.error;
                break;
              case 'Other':
              default:
                icon = Icons.more_horiz_rounded;
                color = Colors.grey;
                break;
            }

            return GestureDetector(
              onTap: () {
                if (cat == 'Refund Request') {
                  setState(() => _currentView = 5);
                } else {
                  setState(() {
                    _selectedCreateCategory = cat;
                    _currentView = 2;
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outline.withAlpha(45)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTicketsList(ColorScheme scheme) {
    if (_myTickets.isEmpty) {
      return const AppCard(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'No active tickets found. Create one above.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: _myTickets.map((ticket) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline.withAlpha(45)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.read<SupportCubit>().openTicket(ticket);
                  setState(() {
                    _currentView = 3;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                ticket.id,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ticket
                                      .statusColor(scheme)
                                      .withAlpha(24),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ticket.statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: ticket.statusColor(scheme),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            ticket.dateCreated,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.forum_outlined,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${ticket.conversation.length} responses',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Track Resolution',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: scheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- SCREEN 2: CREATE TICKET SCREEN ---
  Widget _buildCreateTicketView(ColorScheme scheme) {
    return Column(
      key: const ValueKey('step2'),
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Ticket Title
              const Text(
                'Ticket Title',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ticketTitleController,
                decoration: InputDecoration(
                  hintText: 'E.g., Shuttle was 10 mins late',
                  fillColor: scheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Category & Priority
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: scheme.outline.withAlpha(55),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCreateCategory,
                              items: _categories.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(
                                () => _selectedCreateCategory = val!,
                              ),
                              dropdownColor: scheme.surface,
                              isExpanded: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Priority',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: scheme.outline.withAlpha(55),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCreatePriority,
                              items: const ['Low', 'Medium', 'High'].map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(
                                () => _selectedCreatePriority = val!,
                              ),
                              dropdownColor: scheme.surface,
                              isExpanded: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Description Box
              const Text(
                'Detailed Description',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ticketDescController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Provide details about what happened. Include shuttle plate number if applicable.',
                  fillColor: scheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Upload File Section
              const Text(
                'Attachments (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _buildImageAttachmentZone(scheme),
            ],
          ),
        ),
        // Sticky bottom button
        _buildStickyCTAButton(
          'Submit Support Ticket',
          _submitNewTicket,
          scheme,
        ),
      ],
    );
  }

  Widget _buildImageAttachmentZone(ColorScheme scheme) {
    if (_ticketImageAttached) {
      return AppSurface(
        radius: 20,
        padding: const EdgeInsets.all(12),
        color: scheme.primary.withAlpha(15),
        border: Border.all(color: scheme.primary.withAlpha(80)),
        child: Row(
          children: [
            const Icon(Icons.image_rounded, color: Colors.green),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'ticket_screenshot_evidence.png (890 KB)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: scheme.error),
              onPressed: () => setState(() => _ticketImageAttached = false),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _ticketImageAttached = true),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withAlpha(80)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.grey,
                size: 28,
              ),
              SizedBox(height: 6),
              Text(
                'Attach Screenshot / Photo',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                'Select from library',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SCREEN 3: TICKET DETAILS SCREEN ---
  Widget _buildDetailsView(ColorScheme scheme) {
    if (_activeTicket == null) return const SizedBox.shrink();
    final ticket = _activeTicket!;

    return Column(
      key: const ValueKey('step3'),
      children: [
        // Ticket Overview Banner
        _buildTicketHeaderDetails(ticket, scheme),

        // Chat Message Log
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              // Original Ticket Description
              AppSurface(
                radius: 18,
                padding: const EdgeInsets.all(14),
                color: scheme.surfaceContainerHighest.withAlpha(150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Original Description',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withAlpha(150),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket.description,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                    if (ticket.attachedImages.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.attachment_rounded,
                            size: 14,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ticket.attachedImages.first,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Chat Thread bubbles
              const Center(
                child: Text(
                  'Support Thread',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...ticket.conversation.map((msg) {
                final isUser = msg['sender'] == 'user';
                return _buildChatBubble(
                  msg['text']!,
                  msg['time']!,
                  isUser,
                  scheme,
                );
              }),
            ],
          ),
        ),

        // Chat input sticky bar
        _buildChatInputBar(scheme),
      ],
    );
  }

  Widget _buildTicketHeaderDetails(SupportTicket ticket, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: scheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    ticket.id,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ticket.statusColor(scheme).withAlpha(24),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ticket.statusColor(scheme),
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _currentView = 4),
                child: Row(
                  children: [
                    Text(
                      'Track Timeline',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              ticket.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(
    String text,
    String time,
    bool isUser,
    ColorScheme scheme,
  ) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          border: isUser
              ? null
              : Border.all(color: scheme.outline.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isUser ? scheme.onPrimary : scheme.onSurface,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 9,
                  color: isUser ? Colors.white.withAlpha(160) : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInputBar(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline.withAlpha(60))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatReplyController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                fillColor: scheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendChatMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 4: TICKET TRACKING SCREEN ---
  Widget _buildTrackingView(ColorScheme scheme) {
    if (_activeTicket == null) return const SizedBox.shrink();
    final ticket = _activeTicket!;

    final steps = [
      'Ticket Opened',
      'Assigned to Agent',
      'Under Review',
      'In Progress',
      'Resolved',
    ];

    // Determine current index based on status
    int activeIdx = 0;
    switch (ticket.status) {
      case TicketStatus.open:
        activeIdx = 0;
        break;
      case TicketStatus.underReview:
        activeIdx = 2;
        break;
      case TicketStatus.inProgress:
        activeIdx = 3;
        break;
      case TicketStatus.resolved:
      case TicketStatus.closed:
        activeIdx = 4;
        break;
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Ticket meta summary
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resolution Status for ${ticket.id}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ticket.statusColor(scheme).withAlpha(24),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ticket.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ticket.statusColor(scheme),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Vertical timeline painter
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: List.generate(steps.length, (idx) {
              final isDone = idx < activeIdx;
              final isCurrent = idx == activeIdx;
              final isFuture = idx > activeIdx;

              Color stepColor = Colors.grey;
              if (isDone) {
                stepColor = Colors.green;
              } else if (isCurrent) {
                stepColor = scheme.primary;
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? stepColor
                                : isDone
                                ? stepColor
                                : Colors.transparent,
                            border: Border.all(
                              color: stepColor,
                              width: isCurrent ? 5 : 2,
                            ),
                          ),
                          child: isDone
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 9,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        if (idx < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: isDone
                                  ? Colors.green
                                  : scheme.outline.withAlpha(80),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              steps[idx],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isFuture
                                    ? Colors.grey
                                    : scheme.onSurface,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(height: 4),
                              Text(
                                _getStepDescription(idx),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Back to Details',
          onPressed: () => setState(() => _currentView = 3),
        ),
      ],
    );
  }

  String _getStepDescription(int index) {
    return switch (index) {
      0 => 'Ticket created successfully. Support queue notified.',
      1 => 'Support representative has been assigned to coordinate resolution.',
      2 => 'Representative is auditing logs and reviewing files.',
      3 => 'Actions are in progress. Checking back-end shuttle diagnostics.',
      4 => 'Issue resolved. Ticket resolved and archived.',
      _ => '',
    };
  }

  // --- SCREEN 5: REFUND REQUEST SCREEN ---
  Widget _buildRefundRequestView(ColorScheme scheme) {
    return Column(
      key: const ValueKey('step5'),
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Booking selection dropdown
              const Text(
                'Select Target Booking',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outline.withAlpha(55)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRefundBooking,
                    items:
                        const [
                          'Trip #MGT-8492 (Cairo → Banha) - EGP 68',
                          'Trip #MGT-2094 (Banha → Smart Village) - EGP 75',
                        ].map((b) {
                          return DropdownMenuItem(
                            value: b,
                            child: Text(
                              b,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedRefundBooking = val!),
                    dropdownColor: scheme.surface,
                    isExpanded: true,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Reason selection dropdown
              const Text(
                'Reason for Refund',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outline.withAlpha(55)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRefundReason,
                    items:
                        const [
                          'Shuttle AC was malfunctioning',
                          'Shuttle was delayed by >30 mins',
                          'Captain missed my pickup stop',
                          'Trip was cancelled by operator',
                        ].map((r) {
                          return DropdownMenuItem(
                            value: r,
                            child: Text(
                              r,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedRefundReason = val!),
                    dropdownColor: scheme.surface,
                    isExpanded: true,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Refund Amount breakdown
              const Text(
                'Refund Policy & Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRowDetailText('Base Booking Price', 'EGP 68'),
                    const SizedBox(height: 8),
                    _buildRowDetailText('Booking Service Fee', 'EGP 5'),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Refundable Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'EGP 73',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '* Approved refund amounts are instantly credited back to your account wallet.',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Upload bank/ticket screenshot evidence
              const Text(
                'Upload Supporting Evidence',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _buildRefundEvidenceZone(scheme),
            ],
          ),
        ),
        // Submit CTA button
        _buildStickyCTAButton(
          'Submit Refund Request',
          _submitRefundRequest,
          scheme,
        ),
      ],
    );
  }

  Widget _buildRefundEvidenceZone(ColorScheme scheme) {
    if (_refundEvidenceAttached) {
      return AppSurface(
        radius: 20,
        padding: const EdgeInsets.all(12),
        color: scheme.primary.withAlpha(15),
        border: Border.all(color: scheme.primary.withAlpha(80)),
        child: Row(
          children: [
            const Icon(Icons.image_rounded, color: Colors.green),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'refund_screenshot_evidence.png (910 KB)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: scheme.error),
              onPressed: () => setState(() => _refundEvidenceAttached = false),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _refundEvidenceAttached = true),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withAlpha(80)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.grey,
                size: 28,
              ),
              SizedBox(height: 6),
              Text(
                'Attach Screenshot / Receipt',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                'Select proof of payment/booking error',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowDetailText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Sticky bottom action buttons
  Widget _buildStickyCTAButton(
    String label,
    VoidCallback onPressed,
    ColorScheme scheme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: scheme.outline.withAlpha(55))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: AppButton(label: label, onPressed: onPressed),
            ),
          ],
        ),
      ),
    );
  }
}

extension _SupportTicketPresentation on SupportTicket {
  Color statusColor(ColorScheme scheme) => switch (status) {
    TicketStatus.open => scheme.primary,
    TicketStatus.underReview => scheme.tertiary,
    TicketStatus.inProgress => scheme.secondary,
    TicketStatus.resolved => Colors.green,
    TicketStatus.closed => Colors.grey,
  };
}
