import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_table_shell.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

class FleetDocumentsTable extends StatelessWidget {
  final List<FleetDocument> documents;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const FleetDocumentsTable({
    super.key,
    required this.documents,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  Color _documentColor(BuildContext context, FleetDocumentStatus status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      FleetDocumentStatus.expired => scheme.error,
      FleetDocumentStatus.expiringSoon => scheme.tertiary,
      FleetDocumentStatus.valid => scheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, documents.length);
    final paged = start >= documents.length
        ? <FleetDocument>[]
        : documents.sublist(start, end);

    return FleetTableShell(
      headers: const [
        'الفئة',
        'صاحب الوثيقة',
        'رقم المرجع',
        'تاريخ الانتهاء',
        'الحالة',
      ],
      total: documents.length,
      currentPage: page,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      rows: paged.map((document) {
        final docColor = _documentColor(context, document.status);
        return [
          Text(
            document.type.label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(document.ownerName),
          Text(document.referenceNumber),
          Text(document.expiryDate),
          StatusChip(
            label: document.status.label,
            color: docColor.withAlpha(30),
            textColor: docColor,
          ),
        ];
      }).toList(),
    );
  }
}
