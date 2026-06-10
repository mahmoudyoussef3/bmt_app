import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

class BookingApprovalDialog extends StatefulWidget {
  final String bookingId;
  final String passengerName;
  final void Function(String? note) onApprove;

  const BookingApprovalDialog({
    required this.bookingId,
    required this.passengerName,
    required this.onApprove,
    super.key,
  });

  @override
  State<BookingApprovalDialog> createState() => _BookingApprovalDialogState();
}

class _BookingApprovalDialogState extends State<BookingApprovalDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تأكيد قبول الدفع'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 28),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        'سيتم قبول دفع ${widget.passengerName} وتأكيد الحجز ${widget.bookingId}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  hintText: 'أضف ملاحظة للعميل أو للسجل...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
          FilledButton.icon(
            onPressed: () {
              widget.onApprove(
                _note.text.trim().isEmpty ? null : _note.text.trim(),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('قبول الدفع'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class BookingRejectionDialog extends StatefulWidget {
  final String bookingId;
  final String passengerName;
  final void Function(String reason, String? note) onReject;

  const BookingRejectionDialog({
    required this.bookingId,
    required this.passengerName,
    required this.onReject,
    super.key,
  });

  @override
  State<BookingRejectionDialog> createState() => _BookingRejectionDialogState();
}

class _BookingRejectionDialogState extends State<BookingRejectionDialog> {
  String? _selectedReason;
  final _note = TextEditingController();
  String _error = '';

  static const _reasons = [
    'الإيصال غير واضح',
    'المبلغ غير مطابق',
    'إيصال منتهي الصلاحية',
    'رقم المرجع غير صحيح',
    'صورة مقطوعة أو ناقصة',
    'إيصال مكرر',
    'سبب آخر',
  ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('رفض الدفع'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: scheme.error.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.error.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: scheme.error, size: 28),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        'سيتم رفض دفع ${widget.passengerName} للحجز ${widget.bookingId}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                decoration: InputDecoration(
                  labelText: 'سبب الرفض *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) =>
                    setState(() {
                      _selectedReason = value;
                      _error = '';
                    }),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'ملاحظة إضافية (اختياري)',
                  hintText: 'تفاصيل إضافية عن سبب الرفض...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.small),
                Text(_error,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.error)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
          FilledButton.icon(
            onPressed: () {
              if (_selectedReason == null) {
                setState(() => _error = 'يجب اختيار سبب الرفض');
                return;
              }
              widget.onReject(
                _selectedReason!,
                _note.text.trim().isEmpty ? null : _note.text.trim(),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close_rounded),
            label: const Text('رفض'),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class BookingReuploadDialog extends StatefulWidget {
  final String bookingId;
  final String passengerName;
  final void Function(String reason) onRequest;

  const BookingReuploadDialog({
    required this.bookingId,
    required this.passengerName,
    required this.onRequest,
    super.key,
  });

  @override
  State<BookingReuploadDialog> createState() => _BookingReuploadDialogState();
}

class _BookingReuploadDialogState extends State<BookingReuploadDialog> {
  String? _selectedReason;
  String _error = '';

  static const _reasons = [
    'الصورة غير واضحة',
    'الإيصال مقطوع',
    'التاريخ غير ظاهر',
    'المبلغ غير ظاهر',
    'يجب رفع إيصال بصيغة صحيحة',
    'سبب آخر',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('طلب إعادة رفع الإيصال'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded,
                        color: Colors.orange, size: 28),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        'سيُطلب من ${widget.passengerName} إعادة رفع إيصال الدفع',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                decoration: InputDecoration(
                  labelText: 'السبب *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) =>
                    setState(() {
                      _selectedReason = value;
                      _error = '';
                    }),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.small),
                Text(_error,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.error)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
          FilledButton.icon(
            onPressed: () {
              if (_selectedReason == null) {
                setState(() => _error = 'يجب اختيار السبب');
                return;
              }
              widget.onRequest(_selectedReason!);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('طلب إعادة رفع'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
