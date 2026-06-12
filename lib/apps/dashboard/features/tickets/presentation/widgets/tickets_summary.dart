import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';
import 'tickets_shared_widgets.dart';

class SummaryStats extends StatelessWidget {
  final TicketsLoaded state;
  const SummaryStats({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'شكاوى جديدة',
            value: state.newCount,
            color: Colors.blue,
            icon: Icons.mark_email_unread_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: StatCard(
            title: 'قيد المعالجة',
            value: state.inProgressCount,
            color: Colors.orange,
            icon: Icons.pending_actions_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: StatCard(
            title: 'تم الحل',
            value: state.resolvedCount,
            color: Colors.green,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: StatCard(
            title: 'متأخرة (>24 ساعة)',
            value: state.delayedCount,
            color: Colors.red,
            icon: Icons.running_with_errors_outlined,
            isAlert: state.delayedCount > 0,
          ),
        ),
      ],
    );
  }
}

class FilterBar extends StatelessWidget {
  final TicketsLoaded state;
  const FilterBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TicketsCubit>();

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.small),
        child: Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Search Input
            SizedBox(
              width: 260,
              child: TextField(
                onChanged: cubit.setSearchQuery,
                decoration: const InputDecoration(
                  hintText: 'البحث عن شكوى (الرقم، العميل، الرحلة)...',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),

            // Status Filter Dropdown
            DropdownFilter<ComplaintStatus>(
              label: 'الحالة',
              value: state.filterStatus,
              items: ComplaintStatus.values,
              labelMapper: (v) => v.label,
              onChanged: cubit.setFilterStatus,
            ),

            // Priority Filter Dropdown
            DropdownFilter<ComplaintPriority>(
              label: 'الأولوية',
              value: state.filterPriority,
              items: ComplaintPriority.values,
              labelMapper: (v) => v.label,
              onChanged: cubit.setFilterPriority,
            ),

            // Category Filter Dropdown
            DropdownFilter<ComplaintCategory>(
              label: 'نوع الشكوى',
              value: state.filterCategory,
              items: ComplaintCategory.values,
              labelMapper: (v) => v.label,
              onChanged: cubit.setFilterCategory,
            ),

            // Reset Button
            if (state.filterStatus != null ||
                state.filterPriority != null ||
                state.filterCategory != null ||
                state.searchQuery.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  cubit.setFilterStatus(null);
                  cubit.setFilterPriority(null);
                  cubit.setFilterCategory(null);
                  cubit.setSearchQuery('');
                },
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('تهيئة الفلاتر'),
              ),
          ],
        ),
      ),
    );
  }
}
