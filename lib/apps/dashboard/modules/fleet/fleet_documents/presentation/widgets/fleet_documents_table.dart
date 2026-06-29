import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_document.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

class FleetDocumentsTable extends StatelessWidget {
  final List<FleetDocument> documents;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<FleetDocument> onDelete;

  const FleetDocumentsTable({
    super.key,
    required this.documents,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.onDelete,
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

    return OpsDataTable(
      columns: const [
        OpsColumn('الوثيقة', flex: 4),
        OpsColumn('صاحب الوثيقة', flex: 3),
        OpsColumn('تاريخ الانتهاء', flex: 2),
        OpsColumn('الحالة', flex: 2),
        OpsColumn('إجراءات', flex: 1),
      ],
      total: documents.length,
      currentPage: page,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      rows: paged.map((document) {
        final docColor = _documentColor(context, document.status);
        return [
          _DocumentIdentityCell(document: document),
          Text(
            document.ownerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            document.expiryDate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          StatusChip(
            label: document.status.label,
            color: docColor.withAlpha(30),
            textColor: docColor,
          ),
          IconButton(
            tooltip: 'حذف الوثيقة',
            onPressed: () => onDelete(document),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ];
      }).toList(),
    );
  }
}

class _DocumentIdentityCell extends StatelessWidget {
  const _DocumentIdentityCell({required this.document});

  final FleetDocument document;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.description_outlined, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                document.referenceNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
