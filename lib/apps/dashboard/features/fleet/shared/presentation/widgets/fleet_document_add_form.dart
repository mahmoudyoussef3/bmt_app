import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/pending_fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_upload_helpers.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_validators.dart';
import 'package:bmt_app/core/theme/spacing.dart';

/// Mini-form to queue a new [PendingFleetDocument]. Validates locally and calls
/// [onAdd] with the completed document; the parent section holds the queue.
class FleetDocumentAddForm extends StatefulWidget {
  final List<FleetDocumentType> allowedTypes;
  final ValueChanged<PendingFleetDocument> onAdd;

  const FleetDocumentAddForm({
    super.key,
    required this.allowedTypes,
    required this.onAdd,
  });

  @override
  State<FleetDocumentAddForm> createState() => _FleetDocumentAddFormState();
}

class _FleetDocumentAddFormState extends State<FleetDocumentAddForm> {
  FleetDocumentType? _type;
  final _expiry = TextEditingController();
  PlatformFile? _file;
  List<int>? _bytes;
  String _error = '';

  @override
  void dispose() {
    _expiry.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final picked = await FleetUploadHelpers.pickDocumentFile();
      if (picked == null) return;
      setState(() {
        _file = picked.file;
        _bytes = picked.bytes;
        _error = '';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _pickExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _expiry.text = date.toIso8601String().substring(0, 10));
    }
  }

  void _submit() {
    if (_type == null) {
      setState(() => _error = 'يرجى اختيار نوع الوثيقة');
      return;
    }
    final dateErr = FleetValidators.validateDate(
      _expiry.text,
      'تاريخ الانتهاء',
    );
    if (dateErr != null) {
      setState(() => _error = dateErr);
      return;
    }
    if (_file == null || _bytes == null) {
      setState(() => _error = 'يرجى اختيار ملف الوثيقة');
      return;
    }
    widget.onAdd(
      PendingFleetDocument(
        type: _type!,
        expiryDate: _expiry.text.trim(),
        bytes: _bytes!,
        fileName: _file!.name,
      ),
    );
    setState(() {
      _type = null;
      _expiry.clear();
      _file = null;
      _bytes = null;
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<FleetDocumentType>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'نوع الوثيقة',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
            ),
            items: widget.allowedTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: AppSpacing.small),
          TextField(
            controller: _expiry,
            readOnly: true,
            onTap: _pickExpiry,
            decoration: const InputDecoration(
              labelText: 'تاريخ الانتهاء',
              hintText: 'سنة-شهر-يوم',
              prefixIcon: Icon(Icons.calendar_today_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(_file != null ? 'تغيير الملف' : 'اختيار ملف'),
              ),
              if (_file != null)
                Chip(
                  avatar: const Icon(Icons.description_outlined, size: 18),
                  label: Text(_file!.name, overflow: TextOverflow.ellipsis),
                ),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة للقائمة'),
              ),
            ],
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              _error,
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
