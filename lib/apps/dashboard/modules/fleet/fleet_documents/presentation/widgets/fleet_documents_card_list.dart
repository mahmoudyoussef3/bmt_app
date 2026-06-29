import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_document.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

class FleetDocumentsCardList extends StatelessWidget {
  final List<FleetDocument> documents;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<FleetDocument> onDelete;

  const FleetDocumentsCardList({
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

    if (paged.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.large),
          child: Text('لا توجد بيانات مطابقة'),
        ),
      );
    }

    final pages = (documents.length / pageSize).ceil().clamp(1, 9999);

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paged.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.small),
          itemBuilder: (context, index) {
            final document = paged[index];
            final docColor = _documentColor(context, document.status);

            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        document.type.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      StatusChip(
                        label: document.status.label,
                        color: docColor.withAlpha(30),
                        textColor: docColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.small),
                  FleetMetaRow(
                    icon: Icons.person_outline_rounded,
                    label: 'صاحب الوثيقة',
                    value: document.ownerName,
                  ),
                  FleetMetaRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'رقم المرجع',
                    value: document.referenceNumber,
                  ),
                  FleetMetaRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'تاريخ الانتهاء',
                    value: document.expiryDate,
                  ),
                  if (document.fileUrl.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.small),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: AppSpacing.small,
                        children: [
                          TextButton.icon(
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            label: const Text('فتح الملف'),
                            onPressed: () => launchUrl(
                              Uri.parse(document.fileUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            label: Text(
                              'حذف',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            onPressed: () => onDelete(document),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.small),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        label: Text(
                          'حذف',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        onPressed: () => onDelete(document),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.small),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: page == 0 ? null : () => onPageChanged(page - 1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              Text('صفحة ${page + 1} من $pages'),
              IconButton(
                onPressed: page >= pages - 1
                    ? null
                    : () => onPageChanged(page + 1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
