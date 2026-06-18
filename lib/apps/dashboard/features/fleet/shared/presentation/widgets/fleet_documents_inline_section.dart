import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/pending_fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_document_add_form.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// Inline documents section embedded in the driver/vehicle create & edit forms.
///
/// Collects [PendingFleetDocument]s in-memory (uploaded by the screen after the
/// owning entity is saved). Existing saved documents are shown read-only.
class FleetDocumentsInlineSection extends StatefulWidget {
  final bool isDriver;
  final List<FleetDocument> existingDocuments;
  final ValueChanged<List<PendingFleetDocument>> onChanged;

  const FleetDocumentsInlineSection({
    super.key,
    required this.isDriver,
    required this.onChanged,
    this.existingDocuments = const [],
  });

  @override
  State<FleetDocumentsInlineSection> createState() =>
      _FleetDocumentsInlineSectionState();
}

class _FleetDocumentsInlineSectionState
    extends State<FleetDocumentsInlineSection> {
  final List<PendingFleetDocument> _queue = [];

  List<FleetDocumentType> get _allowedTypes => widget.isDriver
      ? const [
          FleetDocumentType.driverLicense,
          FleetDocumentType.nationalIdFront,
          FleetDocumentType.nationalIdBack,
          FleetDocumentType.criminalRecord,
          FleetDocumentType.employmentContract,
          FleetDocumentType.other,
        ]
      : const [
          FleetDocumentType.vehicleLicense,
          FleetDocumentType.insurance,
          FleetDocumentType.inspection,
          FleetDocumentType.other,
        ];

  void _add(PendingFleetDocument doc) {
    setState(() => _queue.add(doc));
    widget.onChanged(List.unmodifiable(_queue));
  }

  void _removeAt(int index) {
    setState(() => _queue.removeAt(index));
    widget.onChanged(List.unmodifiable(_queue));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FleetSectionTitle(
            icon: Icons.folder_copy_outlined,
            title: 'المستندات والوثائق',
            subtitle: 'أضف وثائق PDF أو صور؛ سيتم رفعها بعد حفظ البيانات.',
          ),
          const SizedBox(height: AppSpacing.medium),
          if (widget.existingDocuments.isNotEmpty) ...[
            Text(
              'وثائق محفوظة',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: widget.existingDocuments
                  .map(
                    (d) => Chip(
                      avatar: const Icon(Icons.verified_outlined, size: 18),
                      label: Text('${d.type.label} · ${d.expiryDate}'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.medium),
          ],
          if (_queue.isEmpty)
            const FleetEmptyInlineState(
              icon: Icons.description_outlined,
              title: 'لم تتم إضافة وثائق بعد',
              subtitle: 'استخدم النموذج بالأسفل لإضافة وثيقة للقائمة.',
            )
          else
            Column(
              children: List.generate(_queue.length, (i) {
                final doc = _queue[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.small),
                  padding: const EdgeInsets.all(AppSpacing.small),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outline.withAlpha(70)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined, color: scheme.primary),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.type.label,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              '${doc.fileName} · ${doc.expiryDate}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'إزالة',
                        onPressed: () => _removeAt(i),
                        icon: Icon(
                          Icons.close_rounded,
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          const SizedBox(height: AppSpacing.medium),
          FleetDocumentAddForm(allowedTypes: _allowedTypes, onAdd: _add),
        ],
      ),
    );
  }
}
