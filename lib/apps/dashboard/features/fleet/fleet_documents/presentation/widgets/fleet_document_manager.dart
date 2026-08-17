import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/widgets/fleet_shared_widgets.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_validators.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_upload_helpers.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
import 'package:bmt_app/core/theme/tokens.dart';

class FleetDocumentManager extends StatefulWidget {
  final String ownerId;
  final bool isDriver;
  final List<FleetDocument> documents;

  const FleetDocumentManager({
    super.key,
    required this.ownerId,
    required this.isDriver,
    required this.documents,
  });

  @override
  State<FleetDocumentManager> createState() => _FleetDocumentManagerState();
}

class _FleetDocumentManagerState extends State<FleetDocumentManager> {
  FleetDocumentType? selectedType;
  final expiryController = TextEditingController();
  PlatformFile? pickedFile;
  List<int>? pickedFileBytes;
  bool uploading = false;
  String error = '';

  @override
  void dispose() {
    expiryController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    FleetDocument document,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الوثيقة'),
        content: Text(
          'هل تريد حذف "${document.type.label}"؟ سيتم حذف الملف من التخزين وسجل الوثيقة من قاعدة البيانات.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickFile() async {
    try {
      final picked = await FleetUploadHelpers.pickDocumentFile();
      if (picked == null) return;
      setState(() {
        pickedFile = picked.file;
        pickedFileBytes = picked.bytes;
        error = '';
      });
    } catch (e) {
      setState(() => error = e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _uploadAndSave() async {
    setState(() => error = '');

    if (selectedType == null) {
      setState(() => error = 'يرجى اختيار نوع الوثيقة');
      return;
    }

    final dateErr = FleetValidators.validateDate(
      expiryController.text,
      'تاريخ انتهاء الصلاحية',
    );
    if (dateErr != null) {
      setState(() => error = dateErr);
      return;
    }

    if (pickedFile == null || pickedFileBytes == null) {
      setState(() => error = 'يرجى اختيار ملف الوثيقة');
      return;
    }

    setState(() {
      uploading = true;
      error = '';
    });

    try {
      final cubit = context.read<FleetDocumentsCubit>();
      final ownerFolder = widget.isDriver ? 'drivers' : 'vehicles';
      final typeFolder = selectedType!.wireName;
      final fileName = FleetUploadHelpers.safeStorageFileName(pickedFile!.name);
      final path =
          '$ownerFolder/${widget.ownerId}/$typeFolder/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final url = await cubit.uploadDocumentFile(
        'documents',
        path,
        pickedFileBytes!,
      );

      if (url == null || url.isEmpty) {
        throw Exception(
          'فشل رفع الملف إلى Supabase Storage. تأكد من وجود bucket باسم documents.',
        );
      }

      final saveError = await cubit.saveDocument(
        ownerId: widget.ownerId,
        isDriver: widget.isDriver,
        type: selectedType!,
        fileUrl: url,
        expiryDate: expiryController.text.trim(),
      );

      if (saveError != null) {
        throw Exception(saveError);
      }

      setState(() {
        pickedFile = null;
        pickedFileBytes = null;
        expiryController.clear();
        selectedType = null;
      });
    } catch (e) {
      setState(() => error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _deleteDoc(FleetDocument doc) async {
    final cubit = context.read<FleetDocumentsCubit>();
    final confirmed = await _confirmDelete(context, doc);
    if (!confirmed) return;

    setState(() {
      uploading = true;
      error = '';
    });

    try {
      final storagePath = FleetUploadHelpers.storagePathFromPublicUrl(
        doc.fileUrl,
        bucket: 'documents',
      );

      if (storagePath != null && storagePath.isNotEmpty) {
        await cubit.deleteDocumentFile('documents', storagePath);
      }

      final delError = await cubit.deleteDocument(
        documentId: doc.id,
        isDriver: widget.isDriver,
      );

      if (delError != null) throw Exception(delError);
    } catch (e) {
      setState(() => error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

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
    final scheme = Theme.of(context).colorScheme;
    final filteredTypes = widget.isDriver
        ? [
            FleetDocumentType.driverLicense,
            FleetDocumentType.nationalIdFront,
            FleetDocumentType.nationalIdBack,
            FleetDocumentType.criminalRecord,
            FleetDocumentType.employmentContract,
            FleetDocumentType.other,
          ]
        : [
            FleetDocumentType.vehicleLicense,
            FleetDocumentType.insurance,
            FleetDocumentType.inspection,
            FleetDocumentType.other,
          ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FleetSectionTitle(
            icon: Icons.folder_copy_outlined,
            title: 'الوثائق والمستندات',
            subtitle:
                'ارفع ملفات PDF أو صور، وسيتم حفظ الرابط والبيانات في Supabase.',
          ),
          const SizedBox(height: AppSpacing.medium),
          if (widget.documents.isEmpty)
            const FleetEmptyInlineState(
              icon: Icons.description_outlined,
              title: 'لا توجد وثائق محفوظة',
              subtitle: 'أضف أول وثيقة من النموذج بالأسفل.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final useGrid = constraints.maxWidth >= 680;
                if (!useGrid) {
                  return Column(
                    children: widget.documents
                        .map(
                          (doc) => _DocumentCard(
                            doc: doc,
                            onDelete: () => _deleteDoc(doc),
                            docColor: _documentColor(context, doc.status),
                          ),
                        )
                        .toList(),
                  );
                }

                // The grid gives every tile the same height, so the cards there
                // push their actions to the bottom edge. The stacked list above
                // cannot: it is measured inside a page that scrolls, so a card
                // that tries to fill its height has no height to fill.
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.documents.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.medium,
                    mainAxisSpacing: AppSpacing.medium,
                    mainAxisExtent: 156,
                  ),
                  itemBuilder: (context, index) {
                    final doc = widget.documents[index];
                    return _DocumentCard(
                      doc: doc,
                      onDelete: () => _deleteDoc(doc),
                      docColor: _documentColor(context, doc.status),
                      fillHeight: true,
                    );
                  },
                );
              },
            ),
          const SizedBox(height: AppSpacing.large),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(70),
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
              border: Border.all(color: scheme.outline.withAlpha(70)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 700;

                final fields = [
                  DropdownButtonFormField<FleetDocumentType>(
                    initialValue: selectedType,
                    // The field is measured against its widest item label, and
                    // 'الرقم القومي (أمام)' is wider than the half-row it gets
                    // beside the expiry date. Expanded, it ellipsizes instead of
                    // overflowing the row.
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'نوع الوثيقة',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: filteredTypes
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedType = v),
                  ),
                  TextField(
                    controller: expiryController,
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الانتهاء',
                      hintText: 'سنة-شهر-يوم',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: _pickExpiryDate,
                  ),
                ];

                final form = isCompact
                    ? Column(
                        children: fields
                            .map(
                              (field) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.small,
                                ),
                                child: field,
                              ),
                            )
                            .toList(),
                      )
                    : Row(
                        children: [
                          Expanded(child: fields[0]),
                          const SizedBox(width: AppSpacing.small),
                          Expanded(child: fields[1]),
                        ],
                      );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    form,
                    const SizedBox(height: AppSpacing.medium),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: uploading ? null : _pickFile,
                          icon: const Icon(Icons.attach_file_rounded),
                          label: Text(
                            pickedFile != null
                                ? 'تغيير الملف'
                                : 'اختيار ملف الوثيقة',
                          ),
                        ),
                        if (pickedFile != null)
                          Chip(
                            avatar: const Icon(
                              Icons.description_outlined,
                              size: 18,
                            ),
                            label: Text(
                              pickedFile!.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        FilledButton.icon(
                          onPressed: uploading ? null : _uploadAndSave,
                          icon: uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_rounded),
                          label: const Text('رفع وحفظ'),
                        ),
                      ],
                    ),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        error,
                        style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date != null) {
      setState(() {
        expiryController.text = date.toIso8601String().substring(0, 10);
      });
    }
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.doc,
    required this.onDelete,
    required this.docColor,
    this.fillHeight = false,
  });

  final FleetDocument doc;
  final VoidCallback onDelete;
  final Color docColor;

  /// Whether the card was given a height to fill (the grid tiles were), which
  /// is what lets it push its actions to the bottom edge. Off by default: in a
  /// scrolling column the card only has the height of its own content.
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: scheme.outline.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: docColor.withAlpha(18),
                child: Icon(Icons.description_outlined, color: docColor),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.type.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      doc.expiryDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: doc.status.label,
                color: docColor.withAlpha(30),
                textColor: docColor,
              ),
            ],
          ),
          if (fillHeight)
            const Spacer()
          else
            const SizedBox(height: AppSpacing.xSmall),
          Row(
            children: [
              TextButton.icon(
                onPressed: doc.fileUrl.isEmpty
                    ? null
                    : () => launchUrl(
                        Uri.parse(doc.fileUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('فتح'),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'حذف الوثيقة',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
