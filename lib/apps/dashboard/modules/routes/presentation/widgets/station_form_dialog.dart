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
  final _formKey = GlobalKey<FormState>();
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
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'اسم المحطة',
                  border: OutlineInputBorder(),
                ),
                validator: _required('اسم المحطة'),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextFormField(
                controller: _area,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'المنطقة',
                  border: OutlineInputBorder(),
                ),
                validator: _required('المنطقة'),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextFormField(
                controller: _offset,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'وقت الوصول المتوقع',
                  hintText: 'مثال: 20 دقيقة أو 08:30',
                  border: OutlineInputBorder(),
                ),
                validator: _required('وقت الوصول المتوقع'),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextFormField(
                controller: _notes,
                textDirection: TextDirection.ltr,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات المحطة',
                  border: OutlineInputBorder(),
                ),
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
              if (!_pickupAllowed && !_dropoffAllowed)
                Text(
                  'يجب أن تكون المحطة صعوداً أو نزولاً على الأقل.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            if (!_pickupAllowed && !_dropoffAllowed) return;
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

  String? Function(String?) _required(String label) {
    return (value) =>
        value == null || value.trim().isEmpty ? '$label مطلوب' : null;
  }
}
