import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_state.dart';
import 'complaint_tabs.dart';
import 'tickets_shared_widgets.dart';

class DetailWorkspace extends StatefulWidget {
  final Complaint complaint;
  final TicketsLoaded state;

  const DetailWorkspace({
    super.key,
    required this.complaint,
    required this.state,
  });

  @override
  State<DetailWorkspace> createState() => _DetailWorkspaceState();
}

class _DetailWorkspaceState extends State<DetailWorkspace> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didUpdateWidget(covariant DetailWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep tab selected when changing ticket
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'تفاصيل الشكوى: ${widget.complaint.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: widget.complaint.status),
                          const SizedBox(width: 8),
                          PriorityBadge(priority: widget.complaint.priority),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'العميل: ${widget.complaint.clientName} · ${widget.complaint.clientPhone}',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (widget.state.actionLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.outline,
            tabs: const [
              Tab(text: 'معلومات'),
              Tab(text: 'المحادثة'),
              Tab(text: 'الإجراءات'),
              Tab(text: 'السجل'),
            ],
          ),

          // Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                InfoTab(complaint: widget.complaint),
                ConversationTab(complaint: widget.complaint),
                ActionsTab(complaint: widget.complaint),
                HistoryTab(complaint: widget.complaint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
