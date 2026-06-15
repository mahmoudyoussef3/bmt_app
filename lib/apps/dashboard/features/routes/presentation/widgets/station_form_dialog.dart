import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/operation_route.dart';

class StationFormDialog extends StatefulWidget {
  final RouteStation? station;
  final ValueChanged<RouteStation> onSubmit;

  const StationFormDialog({required this.onSubmit, this.station, super.key});

  @override
  State<StationFormDialog> createState() => _StationFormDialogState();
}

class _StationFormDialogState extends State<StationFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _area;
  late final TextEditingController _offset;
  late final TextEditingController _notes;
  late bool _pickupAllowed;
  late bool _dropoffAllowed;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.station?.name ?? '');
    _area = TextEditingController(text: widget.station?.area ?? '');
    _offset = TextEditingController(text: widget.station?.arrivalOffset ?? '');
    _notes = TextEditingController(text: widget.station?.notes ?? '');
    _pickupAllowed = widget.station?.pickupAllowed ?? true;
    _dropoffAllowed = widget.station?.dropoffAllowed ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _offset.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.station == null ? 'إضافة محطة' : 'تعديل محطة'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'اسم المحطة'),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextField(
              controller: _area,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'المنطقة'),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextField(
              controller: _offset,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'وقت الوصول المتوقع',
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextField(
              controller: _notes,
              textDirection: TextDirection.ltr,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'ملاحظات المحطة'),
            ),
            CheckboxListTile(
              value: _pickupAllowed,
              onChanged: (value) {
                setState(() => _pickupAllowed = value ?? true);
              },
              title: const Text('يسمح بالصعود'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: _dropoffAllowed,
              onChanged: (value) {
                setState(() => _dropoffAllowed = value ?? true);
              },
              title: const Text('يسمح بالنزول'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final existing = widget.station;
            widget.onSubmit(
              RouteStation(
                id: existing?.id ?? '',
                name: _name.text.trim(),
                area: _area.text.trim(),
                arrivalOffset: _offset.text.trim(),
                estimatedArrivalTime: _offset.text.trim(),
                pickupAllowed: _pickupAllowed,
                dropoffAllowed: _dropoffAllowed,
                notes: _notes.text.trim(),
                order: existing?.order ?? 0,
              ),
            );
            Navigator.of(context).pop();
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
