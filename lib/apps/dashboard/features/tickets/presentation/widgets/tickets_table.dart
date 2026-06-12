import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';
import 'tickets_shared_widgets.dart';

class ComplaintsTable extends StatelessWidget {
  final TicketsLoaded state;
  const ComplaintsTable({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final filtered = state.filteredComplaints;
    final cubit = context.read<TicketsCubit>();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'قائمة الشكاوى (${filtered.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'الشكاوى المفلترة',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (filtered.isEmpty)
            const Expanded(
              child: Center(
                child: EmptyState(
                  title: 'لم يتم العثور على أي شكاوى مطابقة للفلاتر',
                  subtitle: 'يرجى تهيئة الفلاتر أو تغيير كلمة البحث.',
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('رقم الشكوى', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('نوع الشكوى', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الرحلة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('تاريخ الإنشاء', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('المسؤول', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الأولوية', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((c) {
                      final isSelected = c.id == state.selectedComplaintId;
                      return DataRow(
                        selected: isSelected,
                        onSelectChanged: (_) => cubit.selectComplaint(c.id),
                        cells: [
                          DataCell(Text(c.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(c.clientName)),
                          DataCell(Text(c.category.label)),
                          DataCell(Text(c.tripCode)),
                          DataCell(Text(
                            '${c.createdAt.year}/${c.createdAt.month}/${c.createdAt.day}',
                          )),
                          DataCell(Text(c.assignedTo ?? 'غير معين', style: TextStyle(color: c.assignedTo == null ? Colors.red : null))),
                          DataCell(StatusBadge(status: c.status)),
                          DataCell(PriorityBadge(priority: c.priority)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
